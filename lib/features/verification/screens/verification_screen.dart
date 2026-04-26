import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/verification_status.dart';

final _myProfileForVerificationProvider = FutureProvider((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getMyProfile();
});

/// Verification hub: ID, face match, LinkedIn, education. Uses [VerificationStatus]
/// from GET /profile/me for tile state and safety score. See docs/BACKEND_VERIFICATION.md.
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _listenDeepLinks();
  }

  void _listenDeepLinks() {
    final appLinks = AppLinks();
    _deepLinkSub = appLinks.uriLinkStream.listen((uri) async {
      if (uri.scheme == 'shubhmilan' && uri.host == 'linkedin-callback') {
        final code = uri.queryParameters['code'];
        if (code == null || code.isEmpty) return;
        await _handleLinkedInCode(code);
      }
    });
  }

  Future<void> _handleLinkedInCode(String code) async {
    try {
      await ref.read(verificationRepositoryProvider).linkedInCallback(code);
      ref.invalidate(_myProfileForVerificationProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('LinkedIn verified successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('LinkedIn verification failed. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final profileAsync = ref.watch(_myProfileForVerificationProvider);


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(AppLocalizations.of(context)!.verificationTitle),
      ),
      body: profileAsync.when(
        data: (profile) {
          final l = AppLocalizations.of(context)!;
          final vs = profile?.verificationStatus ?? const VerificationStatus();
          final score = vs.score.clamp(0.0, 1.0);
          final idRejected = vs.idVerificationStatus == 'rejected';
          final eduRejected = vs.educationVerificationStatus == 'rejected';
          final idPending = vs.idVerificationStatus == 'pending';
          final eduPending = vs.educationVerificationStatus == 'pending';
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(_myProfileForVerificationProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── ID rejection banner ───────────────────────────────────
                  if (idRejected) ...[
                    _RejectionBanner(
                      title: 'ID Verification Not Approved',
                      reason: vs.idVerificationRejectionReason ??
                          'Your ID verification was not approved.',
                      onResubmit: () async {
                        await context.push('/photo-verification');
                        ref.invalidate(_myProfileForVerificationProvider);
                      },
                    ).animate().fadeIn().slideY(begin: -0.05, end: 0),
                    const SizedBox(height: 16),
                  ],
                  // ── Education rejection banner ────────────────────────────
                  if (eduRejected) ...[
                    _RejectionBanner(
                      title: 'Education Verification Not Approved',
                      reason: vs.educationRejectionReason ??
                          'Your education verification was not approved.',
                      onResubmit: () => _showEducationVerification(context),
                    ).animate().fadeIn().slideY(begin: -0.05, end: 0),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    l.verifyPriority,
                    style: AppTypography.headlineMedium,
                  ).animate().fadeIn().slideY(begin: -0.05, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    l.verificationIntro,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ).animate().fadeIn(delay: 80.ms),
                  const SizedBox(height: 32),
                  // ID tile — shows pending/rejected status labels
                  _VerificationTile(
                    icon: Icons.badge_outlined,
                    title: AppLocalizations.of(context)!.idVerification,
                    subtitle: idPending
                        ? 'Under review — we\'ll notify you shortly.'
                        : idRejected
                            ? 'Rejected — tap to re-submit.'
                            : 'Take a selfie and upload your government ID.',
                    status: vs.idVerified
                        ? VerificationTileStatus.verified
                        : idPending
                            ? VerificationTileStatus.pending
                            : VerificationTileStatus.pending,
                    statusLabel: idPending
                        ? 'Pending'
                        : idRejected
                            ? 'Rejected'
                            : null,
                    onTap: vs.idVerified
                        ? null
                        : () async {
                            await context.push('/photo-verification');
                            ref.invalidate(_myProfileForVerificationProvider);
                          },
                    accent: accent,
                  ).animate().fadeIn(delay: 120.ms),
                  const SizedBox(height: 12),
                  _VerificationTile(
                    icon: Icons.face_retouching_natural,
                    title: AppLocalizations.of(context)!.faceMatch,
                    subtitle: vs.photoVerified
                        ? 'Your selfie has been verified.'
                        : idPending
                            ? 'Under review — submitted with your ID.'
                            : 'Your selfie is submitted together with your ID document.',
                    status: vs.photoVerified
                        ? VerificationTileStatus.verified
                        : VerificationTileStatus.pending,
                    statusLabel: !vs.photoVerified && idPending ? 'Under review' : null,
                    onTap: vs.photoVerified || idPending
                        ? null
                        : () async {
                            await context.push('/photo-verification');
                            ref.invalidate(_myProfileForVerificationProvider);
                          },
                    accent: accent,
                  ).animate().fadeIn(delay: 160.ms),
                  const SizedBox(height: 12),
                  _VerificationTile(
                    icon: Icons.work_outline,
                    title: AppLocalizations.of(context)!.linkedIn,
                    subtitle: vs.linkedInVerified
                        ? 'Verified via LinkedIn.'
                        : AppLocalizations.of(context)!.linkedInSubtitle,
                    status: vs.linkedInVerified
                        ? VerificationTileStatus.verified
                        : VerificationTileStatus.pending,
                    onTap: vs.linkedInVerified ? null : () => _startLinkedInVerification(context),
                    accent: accent,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 12),
                  // Education tile — shows pending/rejected status labels
                  _VerificationTile(
                    icon: Icons.school_outlined,
                    title: AppLocalizations.of(context)!.education,
                    subtitle: eduPending
                        ? 'Under review — we\'ll notify you shortly.'
                        : eduRejected
                            ? 'Rejected — tap to re-submit your degree.'
                            : AppLocalizations.of(context)!.educationSubtitle,
                    status: vs.educationVerified
                        ? VerificationTileStatus.verified
                        : VerificationTileStatus.pending,
                    statusLabel: eduPending
                        ? 'Pending'
                        : eduRejected
                            ? 'Rejected'
                            : null,
                    onTap: () => _showEducationVerification(context),
                    accent: accent,
                  ).animate().fadeIn(delay: 240.ms),
                  const SizedBox(height: 32),
                  Text(
                    l.safetyScore,
                    style: AppTypography.labelLarge.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: score,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.safetyScoreDescription,
                    style: AppTypography.caption.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
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
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(_myProfileForVerificationProvider),
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startLinkedInVerification(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    try {
      final repo = ref.read(verificationRepositoryProvider);
      final url = await repo.getLinkedInAuthUrl();
      if (url.isEmpty) throw Exception('auth-url-unavailable');
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('LinkedIn opened — return here after authorising.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.failedToSendTryAgain),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showEducationVerification(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EducationVerificationSheet(
        onSubmitted: () {
          ref.invalidate(_myProfileForVerificationProvider);
        },
      ),
    );
  }
}

// ── Education verification bottom sheet ──────────────────────────────────────

class _EducationVerificationSheet extends ConsumerStatefulWidget {
  const _EducationVerificationSheet({required this.onSubmitted});
  final VoidCallback onSubmitted;

  @override
  ConsumerState<_EducationVerificationSheet> createState() =>
      _EducationVerificationSheetState();
}

class _EducationVerificationSheetState
    extends ConsumerState<_EducationVerificationSheet> {
  final _institutionCtrl = TextEditingController();
  final _degreeCtrl = TextEditingController();

  // Document upload state
  PlatformFile? _pickedFile;
  double? _uploadProgress;
  bool _uploading = false;
  bool _submitting = false;
  String? _errorMessage;
  String? _documentKey;

  @override
  void dispose() {
    _institutionCtrl.dispose();
    _degreeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _pickedFile = result.files.first;
      _documentKey = null;
      _uploadProgress = null;
      _errorMessage = null;
    });
    await _uploadDocument(result.files.first);
  }

  Future<void> _uploadDocument(PlatformFile file) async {
    setState(() { _uploading = true; _uploadProgress = 0; _errorMessage = null; });
    try {
      final ext = (file.extension ?? 'jpg').toLowerCase();
      final contentType = ext == 'pdf' ? 'application/pdf' : 'image/jpeg';
      final repo = ref.read(verificationRepositoryProvider);
      final result = await repo.getEducationUploadUrl(contentType: contentType);

      final bytes = await File(file.path!).readAsBytes();
      final uploadReq = http.Request('PUT', Uri.parse(result.uploadUrl))
        ..headers['Content-Type'] = contentType
        ..bodyBytes = bytes;

      setState(() { _uploadProgress = 0.3; });
      final streamedResponse = await uploadReq.send();
      setState(() { _uploadProgress = 0.9; });

      if (streamedResponse.statusCode != 200) {
        throw Exception('Upload failed: ${streamedResponse.statusCode}');
      }
      setState(() {
        _documentKey = result.key;
        _uploadProgress = 1.0;
        _uploading = false;
      });
    } catch (e) {
      setState(() {
        _uploading = false;
        _uploadProgress = null;
        _errorMessage = 'Upload failed. Tap to retry.';
      });
    }
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    setState(() { _submitting = true; _errorMessage = null; });
    try {
      await ref.read(verificationRepositoryProvider).submitEducationVerification(
        institutionName: _institutionCtrl.text.trim().isEmpty ? null : _institutionCtrl.text.trim(),
        degree: _degreeCtrl.text.trim().isEmpty ? null : _degreeCtrl.text.trim(),
        documentKey: _documentKey,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSubmitted();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.idSubmittedNotify),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = AppLocalizations.of(context)!.failedToSendTryAgain;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.school_outlined, color: scheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(l.education, style: AppTypography.titleLarge),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Upload a degree or marksheet to get verified faster.',
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _institutionCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'School or college'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _degreeCtrl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Degree / course name'),
          ),
          const SizedBox(height: 16),
          // Document upload row
          GestureDetector(
            onTap: (_uploading || _submitting) ? null : _pickDocument,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _documentKey != null
                      ? Colors.green
                      : _errorMessage != null
                          ? Colors.red
                          : scheme.outline.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(12),
                color: _documentKey != null
                    ? Colors.green.withValues(alpha: 0.06)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              ),
              child: _uploading
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Uploading…',
                              style: AppTypography.bodySmall.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        if (_uploadProgress != null) ...[
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: _uploadProgress),
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        Icon(
                          _documentKey != null
                              ? Icons.check_circle
                              : Icons.upload_file_outlined,
                          color: _documentKey != null
                              ? Colors.green
                              : _errorMessage != null
                                  ? Colors.red
                                  : scheme.onSurface.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _documentKey != null
                                ? (_pickedFile?.name ?? 'Document uploaded')
                                : _errorMessage ?? 'Upload degree / marksheet (JPG, PNG, PDF)',
                            style: AppTypography.bodySmall.copyWith(
                              color: _documentKey != null
                                  ? Colors.green
                                  : _errorMessage != null
                                      ? Colors.red
                                      : scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        if (_errorMessage != null)
                          Icon(Icons.refresh, color: Colors.red, size: 18),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Optional — but helps our team verify faster.',
            style: AppTypography.caption.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (_submitting || _uploading) ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l.submit),
          ),
        ],
      ),
    );
  }
}

/// UI state for a single verification tile (not the domain VerificationStatus).
enum VerificationTileStatus { pending, verified }

// ── Rejection banner ──────────────────────────────────────────────────────────

class _RejectionBanner extends StatelessWidget {
  const _RejectionBanner({
    required this.title,
    required this.reason,
    required this.onResubmit,
  });
  final String title;
  final String reason;
  final VoidCallback onResubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: const Color(0xFFDC2626),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFF991B1B),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onResubmit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            icon: const Icon(Icons.upload_outlined, size: 18),
            label: const Text('Re-submit'),
          ),
        ],
      ),
    );
  }
}

// ── Verification tile ─────────────────────────────────────────────────────────

class _VerificationTile extends StatelessWidget {
  const _VerificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
    required this.accent,
    this.statusLabel,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VerificationTileStatus status;
  final VoidCallback? onTap;
  final Color accent;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final isRejected = statusLabel == 'Rejected';
    final isPending = statusLabel == 'Pending';
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isRejected
                ? const Color(0xFFFEE2E2)
                : accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isRejected ? const Color(0xFFDC2626) : accent,
          ),
        ),
        title: Text(title, style: AppTypography.titleMedium),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        trailing: status == VerificationTileStatus.verified
            ? Icon(Icons.check_circle, color: accent)
            : statusLabel != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRejected
                          ? const Color(0xFFFEE2E2)
                          : isPending
                              ? const Color(0xFFFEF3C7)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel!,
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isRejected
                            ? const Color(0xFFDC2626)
                            : isPending
                                ? const Color(0xFFD97706)
                                : null,
                      ),
                    ),
                  )
                : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
