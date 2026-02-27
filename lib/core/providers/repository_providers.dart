import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/location/app_location_service.dart';
import '../../core/notifications/notification_service.dart';
import '../../data/api/api_client.dart';
import '../../data/api/api_config.dart';
import '../../data/api/token_storage.dart';
import '../../data/services/photo_upload_service.dart';
import '../../data/services/security_service.dart';
import '../../data/repositories_api/api_auth_repository.dart';
import '../../data/repositories_api/api_chat_repository.dart';
import '../../data/repositories_api/api_discovery_repository.dart';
import '../../data/repositories_api/api_interactions_repository.dart';
import '../../data/repositories_api/api_interests_repository.dart';
import '../../data/repositories_api/api_matches_repository.dart';
import '../../data/repositories_api/api_profile_repository.dart';
import '../../data/repositories_api/api_safety_repository.dart';
import '../../data/repositories_api/api_shortlist_repository.dart';
import '../../data/repositories_api/api_subscription_repository.dart';
import '../../data/repositories_api/api_account_repository.dart';
import '../../data/repositories_api/api_contact_request_repository.dart';
import '../../data/repositories_api/api_photo_view_request_repository.dart';
import '../../data/repositories_api/api_visits_repository.dart';
import '../../data/repositories_api/api_referral_repository.dart';
import '../../data/repositories_api/api_verification_repository.dart';
import '../../data/repositories_fake/fake_account_repository.dart';
import '../../data/repositories_fake/fake_auth_repository.dart';
import '../../data/repositories_fake/fake_chat_repository.dart';
import '../../data/repositories_fake/fake_discovery_repository.dart';
import '../../data/repositories_fake/fake_interactions_repository.dart';
import '../../data/repositories_fake/fake_interests_repository.dart';
import '../../data/repositories_fake/fake_matches_repository.dart';
import '../../data/repositories_fake/fake_profile_repository.dart';
import '../../data/repositories_fake/fake_safety_repository.dart';
import '../../data/repositories_fake/fake_shortlist_repository.dart';
import '../../data/repositories_fake/fake_subscription_repository.dart';
import '../../data/repositories_fake/fake_contact_request_repository.dart';
import '../../data/repositories_fake/fake_photo_view_request_repository.dart';
import '../../data/repositories_fake/fake_visits_repository.dart';
import '../../data/repositories_fake/fake_referral_repository.dart';
import '../../data/repositories_fake/fake_verification_repository.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/contact_request_repository.dart';
import '../../domain/repositories/photo_view_request_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../../domain/repositories/interactions_repository.dart';
import '../../domain/repositories/interests_repository.dart';
import '../../domain/repositories/matches_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/safety_repository.dart';
import '../../domain/repositories/shortlist_repository.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/repositories/visits_repository.dart';
import '../../domain/repositories/referral_repository.dart';
import '../../domain/repositories/verification_repository.dart';

// ── Configuration ────────────────────────────────────────────────────────

/// Change this to ApiConfig.localDev or ApiConfig.production to use real API.
const _config = ApiConfig.localDev;

// ── Providers ────────────────────────────────────────────────────────────

final apiConfigProvider = Provider<ApiConfig>((_) => _config);

/// Override this in main.dart with a loaded TokenStorage instance.
final tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: _config.baseUrl,
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (_config.useFakeBackend) return FakeAuthRepository();
  return ApiAuthRepository(
    api: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (_config.useFakeBackend) return FakeProfileRepository();
  return ApiProfileRepository(api: ref.watch(apiClientProvider));
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  if (_config.useFakeBackend) return FakeAccountRepository();
  return ApiAccountRepository(api: ref.watch(apiClientProvider));
});

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  if (_config.useFakeBackend) {
    final profileRepo = ref.watch(profileRepositoryProvider);
    return FakeDiscoveryRepository(profileRepo);
  }
  return ApiDiscoveryRepository(api: ref.watch(apiClientProvider));
});

final interestsRepositoryProvider = Provider<InterestsRepository>((ref) {
  if (_config.useFakeBackend) return FakeInterestsRepository();
  return ApiInterestsRepository(api: ref.watch(apiClientProvider));
});

final interactionsRepositoryProvider = Provider<InteractionsRepository>((ref) {
  if (_config.useFakeBackend) return FakeInteractionsRepository();
  return ApiInteractionsRepository(api: ref.watch(apiClientProvider));
});

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  if (_config.useFakeBackend) return FakeMatchesRepository();
  return ApiMatchesRepository(api: ref.watch(apiClientProvider));
});

final shortlistRepositoryProvider = Provider<ShortlistRepository>((ref) {
  if (_config.useFakeBackend) return FakeShortlistRepository();
  return ApiShortlistRepository(api: ref.watch(apiClientProvider));
});

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  if (_config.useFakeBackend) return FakeSafetyRepository();
  return ApiSafetyRepository(api: ref.watch(apiClientProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (_config.useFakeBackend) return FakeChatRepository();
  return ApiChatRepository(api: ref.watch(apiClientProvider));
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  if (_config.useFakeBackend) return FakeSubscriptionRepository();
  return ApiSubscriptionRepository(api: ref.watch(apiClientProvider));
});

final visitsRepositoryProvider = Provider<VisitsRepository>((ref) {
  if (_config.useFakeBackend) return FakeVisitsRepository();
  return ApiVisitsRepository(api: ref.watch(apiClientProvider));
});

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  if (_config.useFakeBackend) return FakeReferralRepository();
  return ApiReferralRepository(api: ref.watch(apiClientProvider));
});

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  if (_config.useFakeBackend) return FakeVerificationRepository();
  return ApiVerificationRepository(api: ref.watch(apiClientProvider));
});

final contactRequestRepositoryProvider = Provider<ContactRequestRepository>((ref) {
  if (_config.useFakeBackend) {
    final repo = FakeContactRequestRepository();
    repo.seedReceivedRequests();
    return repo;
  }
  return ApiContactRequestRepository(api: ref.watch(apiClientProvider));
});

final photoViewRequestRepositoryProvider = Provider<PhotoViewRequestRepository>((ref) {
  if (_config.useFakeBackend) return FakePhotoViewRequestRepository();
  return ApiPhotoViewRequestRepository(api: ref.watch(apiClientProvider));
});

final photoUploadServiceProvider = Provider<PhotoUploadService>((ref) {
  return PhotoUploadService(api: ref.watch(apiClientProvider));
});

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService(api: ref.watch(apiClientProvider));
});

/// FCM push notification service. Initialize via [NotificationService.initialize] and
/// set tap callback from app startup; register token when user is logged in.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final profileRepo = ref.watch(profileRepositoryProvider);
  return FirebaseNotificationService(
    onRegisterToken: (token) => profileRepo.registerFcmToken(token),
    onLogoutCallback: () => profileRepo.deleteFcmToken(),
  );
});

/// One-shot: when read (e.g. from shell), registers FCM token with backend if user is logged in.
final registerFcmTokenProvider = FutureProvider<void>((ref) async {
  final tokenStorage = ref.read(tokenStorageProvider);
  if (!tokenStorage.isLoggedIn) return;
  final service = ref.read(notificationServiceProvider);
  final token = await service.getToken();
  if (token != null) {
    await service.registerTokenWithBackend(token);
    if (kDebugMode) debugPrint('[FCM] Token registered with backend');
  }
});

/// Tracks whether we have already fired the security location record this session.
final recordLocationFiredProvider = StateProvider<bool>((ref) => false);

/// Call once per app open when user is logged in to record location for security (POST /security/location).
/// Trigger from shell via ref.read(recordSecurityLocationProvider)() when !ref.read(recordLocationFiredProvider).
final recordSecurityLocationProvider = Provider<void Function()>((ref) {
  return () async {
    try {
      if (ref.read(recordLocationFiredProvider)) return;
      final userId = ref.read(authRepositoryProvider).currentUserId;
      if (userId == null) return;
      ref.read(recordLocationFiredProvider.notifier).state = true;
      final loc = await AppLocationService.instance
          .getCurrentCreationLocation();
      if (loc == null) return;
      await ref
          .read(securityServiceProvider)
          .recordLocation(
            lat: loc.latitude,
            lng: loc.longitude,
            address: loc.address,
          );
    } catch (_) {
      ref.read(recordLocationFiredProvider.notifier).state = false;
    }
  };
});
