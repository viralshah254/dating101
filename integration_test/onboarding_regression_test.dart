import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saathi/app.dart';
import 'package:saathi/core/location/app_location_service.dart';
import 'package:saathi/core/location/location_service_provider.dart';
import 'package:saathi/core/mode/mode_provider.dart';
import 'package:saathi/core/providers/repository_providers.dart';
import 'package:saathi/data/api/api_client.dart';
import 'package:saathi/domain/models/partner_preferences.dart';
import 'package:saathi/domain/models/profile_summary.dart';
import 'package:saathi/domain/models/user_profile.dart';
import 'package:saathi/domain/repositories/auth_repository.dart';
import 'package:saathi/domain/repositories/profile_repository.dart';
import 'package:saathi/features/mode_select/screens/mode_select_screen.dart';

class _StubAuth implements AuthRepository {
  _StubAuth(this._userId);
  final String? _userId;

  @override
  String? get currentUserId => _userId;
  @override
  Stream<String?> get authStateChanges => Stream.value(_userId);

  @override
  Future<AuthResult> signUpWithPassword({
    required String countryCode,
    required String phone,
    required String password,
    String? referralCode,
  }) async =>
      AuthSuccess(userId: _userId, isNewUser: true);

  @override
  Future<AuthResult> signInWithPassword({
    required String countryCode,
    required String phone,
    required String password,
  }) async =>
      AuthSuccess(userId: _userId, isNewUser: false);

  @override
  Future<AuthResult> signInWithGoogle() async =>
      AuthSuccess(userId: _userId, isNewUser: false);

  @override
  Future<AuthResult> signInWithApple() async =>
      AuthSuccess(userId: _userId, isNewUser: false);

  @override
  Future<void> signOut() async {}
}

class _StubLocation implements LocationService {
  @override
  Future<LocationAccess> checkAccess() async => LocationAccess.granted;
  @override
  Future<LocationAccess> requestPermission() async => LocationAccess.granted;
  @override
  Future<ProfileCreationLocation?> getCurrentCreationLocation() async =>
      ProfileCreationLocation(
        latitude: 12.97,
        longitude: 77.59,
        capturedAt: DateTime.now(),
      );
  @override
  Future<bool> openAppSettings() async => true;
}

/// Returns null for getMyProfile — simulates authenticated user with no profile.
class _NoProfileRepo implements ProfileRepository {
  @override
  Future<UserProfile?> getMyProfile() async => null;
  @override
  Stream<UserProfile?> watchMyProfile() => Stream.value(null);
  @override
  Future<UserProfile> createMyProfile(UserProfile p) async => p;
  @override
  Future<UserProfile> updateMyProfile(UserProfile p) async => p;
  @override
  Future<void> saveProfileJson(Map<String, dynamic> j, {bool create = false}) async {}
  @override
  Future<PartnerPreferences?> getMyPartnerPreferences() async => null;
  @override
  Future<PartnerPreferences> updatePartnerPreferences(PartnerPreferences p) async => p;
  @override
  Future<ProfileSummary?> getProfileSummary(String id) async => null;
  @override
  Future<UserProfile?> getProfile(String id) async => null;
  @override
  double computeCompleteness(UserProfile p) => 0.0;
  @override
  Future<Map<String, dynamic>> getPrivacy() async => {};
  @override
  Future<Map<String, dynamic>> updatePrivacy(Map<String, dynamic> p) async => p;
  @override
  Future<DateTime?> startProfileBoost({int durationHours = 24}) async => null;
  @override
  Future<Map<String, dynamic>> getNotificationPreferences() async => {};
  @override
  Future<Map<String, dynamic>> updateNotificationPreferences(Map<String, dynamic> p) async => p;
  @override
  Future<void> registerFcmToken(String t) async {}
  @override
  Future<void> deleteFcmToken() async {}
}

/// Throws on getMyProfile — simulates network error.
class _ErrorProfileRepo extends _NoProfileRepo {
  @override
  Future<UserProfile?> getMyProfile() async =>
      throw ApiException(500, 'INTERNAL_ERROR', 'Simulated failure');
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required ProfileRepository profileRepo,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(_StubAuth('usr_test')),
        profileRepositoryProvider.overrideWithValue(profileRepo),
        locationServiceProvider.overrideWithValue(_StubLocation()),
      ],
      child: const ShubhmilanApp(),
    ),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Regression: authenticated + no profile → mode-select (not home)',
    (tester) async {
      await _pumpApp(tester, profileRepo: _NoProfileRepo());
      await tester.pumpAndSettle(const Duration(seconds: 4));
      expect(find.byType(ModeSelectScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Regression: authenticated + profile error → mode-select (not home)',
    (tester) async {
      await _pumpApp(tester, profileRepo: _ErrorProfileRepo());
      await tester.pumpAndSettle(const Duration(seconds: 4));
      expect(find.byType(ModeSelectScreen), findsOneWidget);
    },
  );
}
