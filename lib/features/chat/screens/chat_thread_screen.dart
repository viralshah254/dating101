import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' show ClientException;
import 'package:uuid/uuid.dart';

import '../../../core/ads/ad_loading_dialog.dart';
import '../../../core/datetime/app_time_format.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/entitlements/entitlements.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/safety/safety_reason_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../data/chat_thread_pagination_store.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../discovery/providers/discovery_providers.dart';
import '../../matches/providers/matches_providers.dart';
import '../providers/chat_providers.dart';

/// Single chat thread. Uses [threadId] and optional [otherUserId] for profile and "me" detection.
/// When [initialAdToken] is set (e.g. after watch-ad on profile), the first message send uses it
/// instead of prompting for another ad.
class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.threadId,
    this.otherUserId,
    this.initialAdToken,
    this.initialText,
  });

  final String threadId;
  final String? otherUserId;
  final String? initialAdToken;
  final String? initialText;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

const _icebreakerSuggestions = [
  'Hi!',
  'How are you?',
  'What brings you here?',
  'Tell me about yourself',
];

/// Idempotent HTTP retry uses same optimistic id as `clientDedupeKey` on the server.
const _kChatHttpFallbackDelay = Duration(seconds: 7);

/// One outbound line: FIFO with [gate] so network runs in tap order even when match/ad futures finish out of order.
class _OutboundSlot {
  _OutboundSlot({required this.text, required this.tempId});
  final String text;
  final String tempId;
  final Completer<_OutboundGateResult> gate = Completer<_OutboundGateResult>();
}

class _OutboundGateResult {
  const _OutboundGateResult({required this.proceed, this.adToken});
  final bool proceed;
  final String? adToken;
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  /// True after first send when we used [ChatThreadScreen.initialAdToken].
  bool _consumedInitialAdToken = false;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _connectivityRetryDebounce;

  /// Serialized network sends only; optimistic bubbles are added immediately on each tap (dating + matrimony).
  Future<void> _transportChain = Future.value();

  /// Tie-breaker for optimistic [ChatMessage.sentAt] when many sends share the same clock tick.
  int _localSendOrder = 0;

  final List<_OutboundSlot> _outboundSlots = [];

  final ScrollController _scrollController = ScrollController();

  /// History loaded above the live window (cursor pagination).
  final List<ChatMessage> _olderLoaded = [];

  bool _loadingOlderPage = false;
  bool _olderExhausted = false;
  DateTime? _lastOlderLoadAttempt;

  @override
  void initState() {
    super.initState();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      if (!results.any((r) => r != ConnectivityResult.none)) return;
      _connectivityRetryDebounce?.cancel();
      _connectivityRetryDebounce = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        unawaited(_retryFailedOutgoingAfterConnectivity());
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = ref.read(chatRepositoryProvider);
      final ws = ref.read(chatWebSocketClientProvider);
      try {
        await repo.markThreadRead(widget.threadId);
        ws?.sendMarkRead(widget.threadId);
        if (mounted) ref.invalidate(chatThreadsProvider);
      } catch (_) {}
      try {
        final peer = await repo.getPeerLastReadAt(widget.threadId);
        if (mounted) {
          ref.read(threadPeerReadAtProvider(widget.threadId).notifier).state = peer;
        }
      } catch (_) {}
    });
  }

  @override
  void didUpdateWidget(ChatThreadScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.threadId != widget.threadId) {
      _olderLoaded.clear();
      _olderExhausted = false;
      _loadingOlderPage = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final s in _outboundSlots) {
      if (!s.gate.isCompleted) {
        s.gate.complete(const _OutboundGateResult(proceed: false));
      }
    }
    _outboundSlots.clear();
    _connectivitySub?.cancel();
    _connectivityRetryDebounce?.cancel();
    super.dispose();
  }

  bool _isLikelyNetworkFailure(Object e) {
    if (e is SocketException || e is TimeoutException || e is ClientException) {
      return true;
    }
    if (e is ApiException) {
      return e.code == 'NETWORK_ERROR' ||
          e.code == 'CONNECTION_REFUSED' ||
          e.message.toLowerCase().contains('network') ||
          e.message.toLowerCase().contains('connection') ||
          e.message.toLowerCase().contains('internet');
    }
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('network is unreachable') ||
        s.contains('connection refused') ||
        s.contains('connection reset') ||
        s.contains('timed out');
  }

  void _markOutgoingAsFailedByTempId(String outgoingTempId) {
    ref.read(pendingSentMessagesProvider(widget.threadId).notifier).update(
          (list) => list
              .map(
                (m) => m.id == outgoingTempId
                    ? ChatMessage(
                        id: 'failed-$outgoingTempId',
                        senderId: m.senderId,
                        text: m.text,
                        sentAt: m.sentAt,
                        outboundSeq: m.outboundSeq,
                      )
                    : m,
              )
              .toList(),
        );
  }

  /// Best-effort resend when the device regains connectivity (no new ad prompt).
  Future<void> _retryFailedOutgoingAfterConnectivity() async {
    final queue = ref.read(pendingSentMessagesProvider(widget.threadId));
    final failed = queue.where((m) => m.id.startsWith('failed-')).toList();
    if (failed.isEmpty) return;
    final chatRepo = ref.read(chatRepositoryProvider);
    for (final m in failed) {
      try {
        await chatRepo.sendMessage(widget.threadId, m.text);
        if (!mounted) return;
        ref.invalidate(chatThreadsProvider);
      } on ApiException catch (e) {
        if (e.code == 'AD_REQUIRED' ||
            e.code == 'PREMIUM_OR_AD_REQUIRED' ||
            e.code == 'PREMIUM_REQUIRED') {
          continue;
        }
      } catch (_) {}
    }
  }

  void _removePendingByTempId(WidgetRef ref, String threadId, String tempId) {
    ref.read(pendingSentMessagesProvider(threadId).notifier).update(
          (list) => list.where((p) => p.id != tempId).toList(),
        );
  }

  Future<void> _sendMessageText(
    BuildContext context,
    WidgetRef ref,
    String text,
  ) async {
    final me = ref.read(authRepositoryProvider).currentUserId;
    if (me == null || me.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToSendTryAgain),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // First line that can use profile "watch ad" token (only one message per open).
    var useProfileAdToken = false;
    if (widget.initialAdToken != null && !_consumedInitialAdToken) {
      useProfileAdToken = true;
      _consumedInitialAdToken = true;
    }
    final profileTok = useProfileAdToken ? widget.initialAdToken : null;

    // WhatsApp-style: show this bubble immediately; transport runs on [_transportChain] in tap order.
    final order = _localSendOrder++;
    final baseUs = DateTime.now().microsecondsSinceEpoch;
    final outgoingTempId = 'temp_${baseUs}_$order';
    ref.read(pendingSentMessagesProvider(widget.threadId).notifier).update(
          (list) => [
                ...list,
                ChatMessage(
                  id: outgoingTempId,
                  senderId: me,
                  text: text,
                  sentAt: DateTime.fromMicrosecondsSinceEpoch(baseUs + order),
                  outboundSeq: order,
                ),
              ],
        );

    if (useProfileAdToken && mounted) {
      setState(() {});
    }

    final slot = _OutboundSlot(text: text, tempId: outgoingTempId);
    _outboundSlots.add(slot);
    _transportChain = _transportChain
        .then((_) async {
      if (!mounted || !context.mounted) return;
      await _drainNextOutboundSlot(context, ref);
    })
        .catchError((Object e, StackTrace st) {
      debugPrint('[Chat] transport chain: $e\n$st');
    });
    unawaited(_fillOutboundSlotGate(context, ref, slot, profileTok));
  }

  void _safeCompleteGate(_OutboundSlot slot, _OutboundGateResult result) {
    if (!slot.gate.isCompleted) slot.gate.complete(result);
  }

  /// Resolves [slot.gate] when match/ad rules are satisfied (any order); drain still runs FIFO by tap.
  Future<void> _fillOutboundSlotGate(
    BuildContext context,
    WidgetRef ref,
    _OutboundSlot slot,
    String? profileAdToken,
  ) async {
    if (!mounted || !context.mounted) {
      _safeCompleteGate(slot, const _OutboundGateResult(proceed: false));
      return;
    }
    try {
      final ent = ref.read(entitlementsProvider);
      final isMatch = widget.otherUserId != null &&
          (await ref.read(matchedUserIdsProvider.future)).contains(widget.otherUserId!);
      if (!mounted || !context.mounted) {
        _safeCompleteGate(slot, const _OutboundGateResult(proceed: false));
        return;
      }
      final requireAd = !ent.canSendMessageDirect && !isMatch;

      String? adToken = profileAdToken;
      if (requireAd && adToken == null) {
        final shown = await loadAndShowInterstitialWithLoading(
          context,
          ref,
          AdRewardReason.sendMessage,
        );
        if (!mounted || !context.mounted) {
          _safeCompleteGate(slot, const _OutboundGateResult(proceed: false));
          return;
        }
        if (!shown) {
          _removePendingByTempId(ref, widget.threadId, slot.tempId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.failedToSendTryAgain),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _safeCompleteGate(slot, const _OutboundGateResult(proceed: false));
          return;
        }
        adToken = const Uuid().v4();
      }

      if (!mounted) {
        _safeCompleteGate(slot, const _OutboundGateResult(proceed: false));
        return;
      }
      _safeCompleteGate(slot, _OutboundGateResult(proceed: true, adToken: adToken));
    } catch (e, st) {
      debugPrint('[Chat] fillOutboundSlotGate: $e\n$st');
      if (mounted) {
        _removePendingByTempId(ref, widget.threadId, slot.tempId);
      }
      _safeCompleteGate(slot, const _OutboundGateResult(proceed: false));
    }
  }

  Future<void> _drainNextOutboundSlot(BuildContext context, WidgetRef ref) async {
    if (_outboundSlots.isEmpty || !mounted) return;
    final slot = _outboundSlots.removeAt(0);
    final result = await slot.gate.future;
    if (!mounted || !context.mounted || !result.proceed) return;
    final chatRepo = ref.read(chatRepositoryProvider);
    await _completeOutgoingSend(
      context: context,
      ref: ref,
      chatRepo: chatRepo,
      text: slot.text,
      outgoingTempId: slot.tempId,
      adCompletionToken: result.adToken,
    );
    if (!mounted) return;
    await _waitUntilTempPendingCleared(ref, widget.threadId, slot.tempId);
  }

  /// After WebSocket submit, wait until hub clears this temp (or failed- replacement) so the next send stays in sequence.
  Future<void> _waitUntilTempPendingCleared(
    WidgetRef ref,
    String threadId,
    String tempId,
  ) async {
    const poll = Duration(milliseconds: 32);
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (DateTime.now().isBefore(deadline)) {
      if (!mounted) return;
      final pending = ref.read(pendingSentMessagesProvider(threadId));
      final still = pending.any((p) => p.id == tempId);
      if (!still) return;
      await Future<void>.delayed(poll);
    }
  }

  Future<void> _completeOutgoingSend({
    required BuildContext context,
    required WidgetRef ref,
    required ChatRepository chatRepo,
    required String text,
    required String outgoingTempId,
    String? adCompletionToken,
  }) async {
    try {
      final transport = await chatRepo.sendMessage(
        widget.threadId,
        text,
        adCompletionToken: adCompletionToken,
        outgoingTempId: outgoingTempId,
      );
      if (!context.mounted) return;
      if (transport == ChatSendTransport.http) {
        ref.read(pendingSentMessagesProvider(widget.threadId).notifier).update(
              (list) => list.where((p) => p.id != outgoingTempId).toList(),
            );
        ref.invalidate(threadMessagesProvider(widget.threadId));
      } else {
        final threadId = widget.threadId;
        // Idempotent HTTP retry: server dedupes ChatMessage (direct) and MessageRequest (ad) via clientDedupeKey.
        // WS ack wait runs once in [_enqueueTransportOnly] after this returns.
        Future<void>.delayed(_kChatHttpFallbackDelay, () async {
          if (!context.mounted) return;
          final stillPending = ref
              .read(pendingSentMessagesProvider(threadId))
              .any((p) => p.id == outgoingTempId);
          if (!stillPending) return;
          try {
            await chatRepo.sendMessage(
              threadId,
              text,
              adCompletionToken: adCompletionToken,
              outgoingTempId: outgoingTempId,
              forceHttp: true,
            );
            if (!context.mounted) return;
            ref.read(pendingSentMessagesProvider(threadId).notifier).update(
                  (list) => list.where((p) => p.id != outgoingTempId).toList(),
                );
            ref.invalidate(threadMessagesProvider(threadId));
            ref.invalidate(chatThreadsProvider);
            ref.invalidate(messageRequestsProvider);
            ref.invalidate(messageRequestsCountProvider);
          } catch (_) {}
        });
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      if (_isLikelyNetworkFailure(e)) {
        _markOutgoingAsFailedByTempId(outgoingTempId);
        return;
      }
      ref.read(pendingSentMessagesProvider(widget.threadId).notifier).update(
            (list) => list.where((m) => m.id != outgoingTempId).toList(),
          );
      final showUpgrade = e.code == 'PREMIUM_REQUIRED' ||
          e.code == 'INTRO_LIMIT' ||
          e.code == 'AD_REQUIRED' ||
          e.code == 'PREMIUM_OR_AD_REQUIRED';
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'INTRO_LIMIT' ? l.matchToContinueOrUpgrade : e.message,
          ),
          behavior: SnackBarBehavior.floating,
          action: showUpgrade
              ? SnackBarAction(
                  label: l.upgrade,
                  onPressed: () => context.push('/paywall'),
                )
              : null,
        ),
      );
      return;
    } catch (e) {
      if (!context.mounted) return;
      if (_isLikelyNetworkFailure(e)) {
        _markOutgoingAsFailedByTempId(outgoingTempId);
        return;
      }
      ref.read(pendingSentMessagesProvider(widget.threadId).notifier).update(
            (list) => list.where((m) => m.id != outgoingTempId).toList(),
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToSendTryAgain),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!context.mounted) return;
    unawaited(
      Future<void>.microtask(() {
        if (context.mounted) {
          ref.invalidate(chatThreadsProvider);
        }
      }),
    );
  }

  Future<void> _retryFailedOutgoingTap(String failedMessageId, String text) async {
    ref.read(pendingSentMessagesProvider(widget.threadId).notifier).update(
          (list) => list.where((m) => m.id != failedMessageId).toList(),
        );
    await _sendMessageText(context, ref, text);
  }

  void _showMoreOptions(
    BuildContext context,
    WidgetRef ref,
    String? otherUserId,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (otherUserId != null)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(AppLocalizations.of(ctx)!.viewProfile),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/profile/$otherUserId');
                },
              ),
            ListTile(
              leading: Icon(Icons.block, color: Theme.of(ctx).colorScheme.error),
              title: Text(
                AppLocalizations.of(ctx)!.blockUser,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                if (otherUserId == null) return;
                final reason = await showBlockReasonPicker(context);
                if (reason == null || !context.mounted) return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (d) {
                    final l = AppLocalizations.of(d)!;
                    return AlertDialog(
                      title: Text(l.blockUserConfirm),
                      content: Text(l.blockUserMessageChat),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(d, false),
                          child: Text(l.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(d, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(d).colorScheme.error,
                          ),
                          child: Text(l.block),
                        ),
                      ],
                    );
                  },
                );
                if (confirmed != true || !context.mounted) return;
                try {
                  await ref
                      .read(safetyRepositoryProvider)
                      .block(otherUserId, reason, source: 'chat');
                  if (context.mounted) {
                    context.pop();
                  }
                } catch (_) {}
              },
            ),
            ListTile(
              leading: Icon(Icons.flag_outlined, color: Theme.of(ctx).colorScheme.tertiary),
              title: Text(AppLocalizations.of(ctx)!.reportUser),
              onTap: () async {
                Navigator.pop(ctx);
                if (otherUserId == null) return;
                final result = await showReportReasonPicker(context);
                if (result == null || !context.mounted) return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (d) {
                    final l = AppLocalizations.of(d)!;
                    return AlertDialog(
                      title: Text(l.reportUserConfirm),
                      content: Text(l.reportUserMessageChat),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(d, false),
                          child: Text(l.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(d, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(d).colorScheme.tertiary,
                          ),
                          child: Text(l.report),
                        ),
                      ],
                    );
                  },
                );
                if (confirmed != true || !context.mounted) return;
                try {
                  await ref
                      .read(safetyRepositoryProvider)
                      .report(
                        otherUserId,
                        result.reason,
                        details: result.details,
                        source: 'chat',
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.reportSubmittedThankYou,
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (_) {}
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Parse `temp_<micros>_<order>` (or `failed-temp_...`) for stable ordering when [sentAt] ties.
  static int? _clientSendOrdinal(String id) {
    var s = id;
    if (s.startsWith('failed-')) {
      s = s.substring('failed-'.length);
    }
    final m = RegExp(r'^temp_(\d+)_(\d+)$').firstMatch(s);
    if (m == null) return null;
    final base = int.tryParse(m.group(1)!);
    final ord = int.tryParse(m.group(2)!);
    if (base == null || ord == null) return null;
    return base * 1000000 + ord;
  }

  /// Merge server messages with pending sent (from provider), deduping so we don't show the same message twice.
  List<ChatMessage> _mergeMessages(
    List<ChatMessage> server,
    String? currentUserId,
    List<ChatMessage> pendingSent,
  ) {
    bool sameSender(ChatMessage m, ChatMessage p) {
      if (m.senderId == p.senderId) return true;
      if (currentUserId != null &&
          m.senderId == currentUserId &&
          (p.senderId == 'me' || p.senderId == currentUserId)) {
        return true;
      }
      return false;
    }

    bool isMe(ChatMessage x) =>
        currentUserId != null &&
        (x.senderId == currentUserId || x.senderId == 'me');

    final merged = List<ChatMessage>.from(server);
    for (final p in pendingSent) {
      final match = merged.any(
        (m) =>
            sameSender(m, p) &&
            m.text == p.text &&
            (m.sentAt.difference(p.sentAt).inSeconds.abs() < 120),
      );
      if (!match) merged.add(p);
    }
    merged.sort((a, b) {
      if (isMe(a) && isMe(b)) {
        final sa = a.outboundSeq;
        final sb = b.outboundSeq;
        if (sa != null && sb != null && sa != sb) {
          return sa.compareTo(sb);
        }
      }
      final byTime = a.sentAt.compareTo(b.sentAt);
      if (byTime != 0) return byTime;
      final oa = _clientSendOrdinal(a.id);
      final ob = _clientSendOrdinal(b.id);
      if (oa != null && ob != null) return oa.compareTo(ob);
      return a.id.compareTo(b.id);
    });
    return merged;
  }

  List<ChatMessage> _serverWindowPlusOlder(List<ChatMessage> window) {
    final byId = <String, ChatMessage>{};
    for (final m in _olderLoaded) {
      byId[m.id] = m;
    }
    for (final m in window) {
      byId[m.id] = m;
    }
    return byId.values.toList();
  }

  Future<void> _maybeLoadOlderMessages() async {
    if (_loadingOlderPage || _olderExhausted) return;
    final uid = ref.read(authRepositoryProvider).currentUserId;
    if (uid == null || uid.isEmpty) return;
    if (!ref.read(threadMessagesProvider(widget.threadId)).hasValue) return;
    if (!ChatThreadPaginationStore.isPaginationKnown(uid, widget.threadId)) return;
    final cur = ChatThreadPaginationStore.getNextOlderCursor(uid, widget.threadId);
    if (cur == null || cur.isEmpty) {
      if (mounted) setState(() => _olderExhausted = true);
      return;
    }
    final now = DateTime.now();
    if (_lastOlderLoadAttempt != null &&
        now.difference(_lastOlderLoadAttempt!) < const Duration(milliseconds: 700)) {
      return;
    }
    _lastOlderLoadAttempt = now;
    if (mounted) setState(() => _loadingOlderPage = true);
    try {
      final page = await ref
          .read(chatRepositoryProvider)
          .loadOlderChatMessages(widget.threadId, viewerUserId: uid);
      if (!mounted) return;
      if (page.messages.isEmpty) {
        setState(() {
          _olderExhausted = true;
          _loadingOlderPage = false;
        });
        return;
      }
      setState(() {
        final seen = {for (final m in _olderLoaded) m.id};
        final incoming = page.messages.where((m) => !seen.contains(m.id)).toList();
        _olderLoaded.insertAll(0, incoming);
        if (page.nextOlderCursor == null || page.nextOlderCursor!.isEmpty) {
          _olderExhausted = true;
        }
        _loadingOlderPage = false;
        if (_olderLoaded.length > 400) {
          _olderLoaded.removeRange(0, _olderLoaded.length - 400);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingOlderPage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authRepositoryProvider).currentUserId;
    final messagesAsync = ref.watch(threadMessagesProvider(widget.threadId));
    final pendingSent = ref.watch(pendingSentMessagesProvider(widget.threadId));
    final peerReadAt = ref.watch(threadPeerReadAtProvider(widget.threadId));
    final suggestionsAsync = ref.watch(chatSuggestionsProvider);
    final icebreakerList =
        suggestionsAsync.valueOrNull ?? _icebreakerSuggestions;
    final otherUserId = widget.otherUserId;
    final profileAsync = otherUserId != null
        ? ref.watch(profileSummaryProvider(otherUserId))
        : null;

    ref.listen(threadMessagesProvider(widget.threadId), (prev, next) {
      if (!next.hasValue || !context.mounted) return;
      final outboundQueue =
          ref.read(pendingSentMessagesProvider(widget.threadId));
      if (outboundQueue.isEmpty) return;
      final serverList = next.value!;
      ref.read(pendingSentMessagesProvider(widget.threadId).notifier).update(
            (currentPending) => currentPending
                .where(
                  (p) => !serverList.any(
                    (m) =>
                        m.senderId == p.senderId &&
                        m.text == p.text &&
                        (m.sentAt.difference(p.sentAt).inSeconds.abs() < 120),
                  ),
                )
                .toList(),
          );
    });

    final profile = profileAsync?.valueOrNull;
    final displayName = profile?.name ?? 'Chat';
    ChatThreadSummary? threadRow;
    for (final t in ref.watch(chatThreadsProvider).valueOrNull ?? const <ChatThreadSummary>[]) {
      if (t.id == widget.threadId) {
        threadRow = t;
        break;
      }
    }
    final online = threadRow?.otherUserOnline ?? false;
    final lastActive =
        threadRow?.otherLastActiveAt ?? profile?.lastActiveAt;
    final headerPresence = _chatHeaderPresence(online: online, lastActive: lastActive);
    final presenceLabel =
        formatProfileLastSeenSubtitle(online: online, lastActive: lastActive);
    final compatibilityScore = profile?.compatibilityScore;
    final scoreLabel = compatibilityScore != null
        ? '${(compatibilityScore * 100).round()}% match'
        : null;
    final subtitle = [
      if (scoreLabel != null) scoreLabel,
      if (presenceLabel != null) presenceLabel,
    ].join(' · ');
    final subtitleFinal = subtitle.isNotEmpty
        ? subtitle
        : (profile?.city != null ? profile!.city! : '');
    final peerTypingHere = ref.watch(peerTypingProvider)[widget.threadId] == true;

    final avatarUrl = profile?.imageUrl;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final headerSubtitleText =
        peerTypingHere ? l10n.chatPeerTyping : subtitleFinal;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AppBar(
              backgroundColor: cs.surface.withValues(alpha: isDark ? 0.75 : 0.85),
              titleSpacing: 0,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              title: InkWell(
                onTap: () {
                  if (otherUserId != null) context.push('/profile/$otherUserId');
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: cs.primary.withValues(alpha: 0.2),
                            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Text(
                                    initial,
                                    style: AppTypography.titleMedium.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: headerPresence == _ChatHeaderPresence.reachable
                                    ? const Color(0xFF2196F3)
                                    : cs.onSurface.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cs.surface,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayName,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            headerSubtitleText,
                            style: AppTypography.caption.copyWith(
                              color: peerTypingHere
                                  ? const Color(0xFF34B7F1)
                                  : cs.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                              fontStyle: peerTypingHere
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                      if (otherUserId != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: () => _showMoreOptions(context, ref, otherUserId),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerLow.withValues(alpha: 0.4),
              child: messagesAsync.when(
                skipLoadingOnReload: true,
                skipLoadingOnRefresh: true,
                data: (serverMessages) {
                  final window = _serverWindowPlusOlder(serverMessages);
                  final messages = _mergeMessages(
                    window,
                    currentUserId,
                    pendingSent,
                  );
                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(
                                  alpha: 0.08,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.waving_hand_rounded,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Start the conversation!',
                              style: AppTypography.titleMedium.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Say hi, send an emoji — break the ice.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.55),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: icebreakerList.indexed.map((entry) {
                                final (idx, s) = entry;
                                return ActionChip(
                                  label: Text(s),
                                  onPressed: () =>
                                      _sendMessageText(context, ref, s),
                                )
                                    .animate(
                                      delay: AppMotion.stagger(idx, stepMs: 50),
                                    )
                                    .fadeIn(duration: AppMotion.medium)
                                    .slideX(begin: 0.15, curve: AppMotion.spring);
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final reversed = messages.reversed.toList();
                  return NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification n) {
                      if (n is! ScrollUpdateNotification) return false;
                      final m = n.metrics;
                      if (!m.hasPixels || m.maxScrollExtent <= 0) return false;
                      if (m.pixels >= m.maxScrollExtent - 140) {
                        unawaited(_maybeLoadOlderMessages());
                      }
                      return false;
                    },
                    child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(16, kToolbarHeight + MediaQuery.of(context).padding.top + 8, 16, 16),
                    reverse: true,
                    itemCount: reversed.length + (_loadingOlderPage ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_loadingOlderPage && i == reversed.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        );
                      }
                      final m = reversed[i];
                      final isMe =
                          currentUserId != null && m.senderId == currentUserId;
                      final outboundPending =
                          isMe && pendingSent.any((p) => p.id == m.id);
                      final showDateSeparator =
                          i == 0 ||
                          !isSameLocalDay(m.sentAt, reversed[i - 1].sentAt);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDateSeparator)
                            _DateSeparator(sentAt: m.sentAt),
                          _MessageBubble(
                                messageId: m.id,
                                text: m.text,
                                sentAt: m.sentAt,
                                isMe: isMe,
                                outboundPending: outboundPending,
                                isVoiceNote: m.isVoiceNote,
                                peerReadAt: peerReadAt,
                                otherUserOnline: online,
                                otherLastActiveAt: lastActive,
                                onRetryOutgoingFailed: isMe &&
                                        m.id.startsWith('failed-')
                                    ? () => unawaited(
                                          _retryFailedOutgoingTap(m.id, m.text),
                                        )
                                    : null,
                              ),
                        ],
                      );
                    },
                  ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => ref.invalidate(
                            threadMessagesProvider(widget.threadId),
                          ),
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _TypingBar(
            threadId: widget.threadId,
            initialText: widget.initialText,
            onSend: (text) => _sendMessageText(context, ref, text),
          ),
        ],
      ),
    );
  }
}

/// Bottom-right dot on chat header avatar: blue if online or active within [recentWithin], else pale.
enum _ChatHeaderPresence { offline, reachable }

_ChatHeaderPresence _chatHeaderPresence({
  required bool online,
  DateTime? lastActive,
  Duration recentWithin = const Duration(minutes: 10),
}) {
  if (online) return _ChatHeaderPresence.reachable;
  if (lastActive != null && DateTime.now().difference(lastActive) <= recentWithin) {
    return _ChatHeaderPresence.reachable;
  }
  return _ChatHeaderPresence.offline;
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.sentAt});
  final DateTime sentAt;

  @override
  Widget build(BuildContext context) {
    final label = formatChatDateSeparator(sentAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.messageId,
    required this.text,
    required this.sentAt,
    required this.isMe,
    this.outboundPending = false,
    this.isVoiceNote = false,
    this.peerReadAt,
    this.otherUserOnline = false,
    this.otherLastActiveAt,
    this.onRetryOutgoingFailed,
  });
  final String messageId;
  final String text;
  final DateTime sentAt;
  final bool isMe;
  /// Still in [pendingSentMessagesProvider] (waiting for server ack or refetch).
  final bool outboundPending;
  final bool isVoiceNote;
  /// Other participant's read time (for ✓ on your messages).
  final DateTime? peerReadAt;
  /// From thread summary / presence — for double-grey "reachable" ticks.
  final bool otherUserOnline;
  final DateTime? otherLastActiveAt;
  /// Tap to resend after a network failure (cloud icon).
  final VoidCallback? onRetryOutgoingFailed;

  static const Duration _recentlyActiveWindow = Duration(minutes: 10);

  static bool _isFailedOutbound(String id) => id.startsWith('failed-');

  /// Persisted on server (including pending message-request rows).
  static bool _isDeliveredToServer(String id, {required bool outboundPending}) =>
      !outboundPending && !_isFailedOutbound(id);

  static bool _readByPeer(DateTime sentAt, DateTime? peerReadAt) {
    if (peerReadAt == null) return false;
    return !peerReadAt.isBefore(sentAt.subtract(const Duration(seconds: 1)));
  }

  static bool _peerRecentlyReachable(bool online, DateTime? lastActive) {
    if (online) return true;
    if (lastActive == null) return false;
    return DateTime.now().difference(lastActive) <= _recentlyActiveWindow;
  }

  /// WhatsApp-style: clock while sending, single tick once on server, double grey/green for delivery/read.
  Widget? _outgoingReceiptRow(Color outgoingFg) {
    if (!isMe) return null;
    if (_isFailedOutbound(messageId)) {
      return Icon(
        Icons.cloud_off_rounded,
        size: 15,
        color: outgoingFg.withValues(alpha: 0.78),
      );
    }
    if (outboundPending) {
      return _SendingClockPulse(color: outgoingFg.withValues(alpha: 0.9));
    }
    if (!_isDeliveredToServer(messageId, outboundPending: outboundPending)) {
      return null;
    }

    final read = _readByPeer(sentAt, peerReadAt);
    if (read) {
      return Icon(
        Icons.done_all_rounded,
        size: 15,
        color: const Color(0xFF8FE1A0),
      );
    }
    if (_peerRecentlyReachable(otherUserOnline, otherLastActiveAt)) {
      return Icon(
        Icons.done_all_rounded,
        size: 15,
        color: outgoingFg.withValues(alpha: 0.52),
      );
    }
    return Icon(
      Icons.done_rounded,
      size: 15,
      color: outgoingFg.withValues(alpha: 0.88),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final onSurface = cs.onSurface;
    final timeStr = formatChatBubbleTime(sentAt);
    // Outgoing: use saturated brand oranges — ColorScheme.primary can resolve to a light
    // tint on some devices/themes (peach + white text = unreadable).
    final bool light = theme.brightness == Brightness.light;
    final bubbleBg = isMe
        ? (light ? AppColors.saffronDark : AppColors.darkAccentDim)
        : cs.surfaceContainerHighest;
    const outgoingFg = Colors.white;
    final textColor = isMe ? outgoingFg : onSurface;
    final timeColor = isMe
        ? outgoingFg.withValues(alpha: 0.88)
        : onSurface.withValues(alpha: 0.55);
    final receipt = _outgoingReceiptRow(outgoingFg);
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 6),
      bottomRight: Radius.circular(isMe ? 6 : 18),
    );

    Widget bubble = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.78,
      ),
      decoration: BoxDecoration(
        color: bubbleBg,
        borderRadius: borderRadius,
        border: isMe
            ? Border.all(
                color: outgoingFg.withValues(alpha: 0.2),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isVoiceNote)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mic_rounded,
                    size: 18,
                    color: isMe ? outgoingFg : cs.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '0:12',
                    style: AppTypography.caption.copyWith(color: textColor),
                  ),
                ],
              )
            else
              SelectableText(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor,
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    timeStr,
                    style: AppTypography.caption.copyWith(
                      color: timeColor,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (receipt != null) receipt,
              ],
            ),
          ],
        ),
    );

    if (onRetryOutgoingFailed != null) {
      bubble = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRetryOutgoingFailed,
          borderRadius: borderRadius,
          child: bubble,
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }

}

/// Subtle pulse like WhatsApp “sending” (clock).
class _SendingClockPulse extends StatefulWidget {
  const _SendingClockPulse({required this.color});
  final Color color;

  @override
  State<_SendingClockPulse> createState() => _SendingClockPulseState();
}

class _SendingClockPulseState extends State<_SendingClockPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Icon(
        Icons.schedule_rounded,
        size: 15,
        color: widget.color,
      ),
    );
  }
}

class _TypingBar extends ConsumerStatefulWidget {
  const _TypingBar({
    required this.threadId,
    required this.onSend,
    this.initialText,
  });
  final String threadId;
  final ValueChanged<String> onSend;
  final String? initialText;

  @override
  ConsumerState<_TypingBar> createState() => _TypingBarState();
}

class _TypingBarState extends ConsumerState<_TypingBar>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late final AnimationController _sendAnim;
  Timer? _typingDebounce;
  bool _typingActive = false;

  @override
  void initState() {
    super.initState();
    _sendAnim = AnimationController(
      vsync: this,
      duration: AppMotion.micro,
      lowerBound: 0.88,
      upperBound: 1.0,
    );
    final initial = widget.initialText;
    if (initial != null && initial.trim().isNotEmpty) {
      _controller.text = initial.trim();
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
    _controller.addListener(_onDraftChanged);
  }

  void _onDraftChanged() {
    _typingDebounce?.cancel();
    final ws = ref.read(chatWebSocketClientProvider);
    final hasText = _controller.text.trim().isNotEmpty;
    if (!hasText) {
      if (_typingActive) {
        ws?.sendTyping(widget.threadId, false);
        _typingActive = false;
      }
      return;
    }
    if (!_typingActive) {
      ws?.sendTyping(widget.threadId, true);
      _typingActive = true;
    }
    _typingDebounce = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (_controller.text.trim().isEmpty) return;
      ws?.sendTyping(widget.threadId, true);
    });
  }

  void _showEmojiPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.5,
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  ctx,
                ).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: EmojiPicker(
                textEditingController: _controller,
                config: Config(
                  height: 256,
                  emojiViewConfig: EmojiViewConfig(
                    emojiSizeMax: 28,
                    backgroundColor: Theme.of(ctx).colorScheme.surface,
                  ),
                  categoryViewConfig: CategoryViewConfig(
                    backgroundColor: Theme.of(ctx)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    indicatorColor: Theme.of(ctx).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerSend() async {
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    _typingDebounce?.cancel();
    if (_typingActive) {
      ref.read(chatWebSocketClientProvider)?.sendTyping(widget.threadId, false);
      _typingActive = false;
    }
    await _sendAnim.reverse();
    await _sendAnim.forward();
    widget.onSend(t);
    _controller.clear();
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _controller.removeListener(_onDraftChanged);
    if (_typingActive) {
      ref.read(chatWebSocketClientProvider)?.sendTyping(widget.threadId, false);
    }
    _sendAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: isDark ? 0.80 : 0.88),
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
          ),
          child: SafeArea(
            top: false,
        child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(
                Icons.emoji_emotions_outlined,
                color: onSurface.withValues(alpha: 0.6),
              ),
              onPressed: _showEmojiPicker,
              tooltip: l.chatEmojiTooltip,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: l.chatMessageHint,
                  filled: true,
                  fillColor: onSurface.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _triggerSend(),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedBuilder(
              animation: _sendAnim,
              builder: (_, child) => Transform.scale(
                scale: _sendAnim.value,
                child: child,
              ),
              child: IconButton.filled(
                icon: const Icon(Icons.send_rounded, size: 22),
                onPressed: _triggerSend,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
        ),
          ),
        ),
      ),
    );
  }
}
