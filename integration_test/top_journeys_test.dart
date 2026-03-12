import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saathi/app.dart';
import 'package:saathi/core/location/app_location_service.dart';
import 'package:saathi/core/location/location_service_provider.dart';
import 'package:saathi/core/mode/mode_provider.dart';
import 'package:saathi/core/providers/repository_providers.dart';
import 'package:saathi/data/repositories_fake/fake_profile_repository.dart';
import 'package:saathi/domain/repositories/auth_repository.dart';
import 'package:saathi/features/location/screens/location_required_screen.dart';
import 'package:saathi/features/mode_select/screens/mode_select_screen.dart';
import 'package:saathi/features/auth/screens/language_select_screen.dart';

class _TestAuthRepository implements AuthRepository {
  _TestAuthRepository(this._userId);

  final String? _userId;

  @override
  String? get currentUserId => _userId;

  @override
  Stream<String?> get authStateChanges => Stream.value(_userId);

  @override
  Future<SendOtpResult> sendOtp({
    required String countryCode,
    required String phone,
  }) async => const SendOtpSuccess(verificationId: 'test');

  @override
  Future<AuthResult> verifyOtp({
    required String verificationId,
    required String code,
    String? referralCode,
  }) async => AuthSuccess(userId: _userId, isNewUser: false);

  @override
  Future<AuthResult> signInWithGoogle() async =>
      AuthSuccess(userId: _userId, isNewUser: false);

  @override
  Future<AuthResult> signInWithApple() async =>
      AuthSuccess(userId: _userId, isNewUser: false);

  @override
  Future<void> signOut() async {}
}

class _TestLocationService implements LocationService {
  _TestLocationService(this.access);

  final LocationAccess access;

  @override
  Future<LocationAccess> checkAccess() async => access;

  @override
  Future<LocationAccess> requestPermission() async => access;

  @override
  Future<ProfileCreationLocation?> getCurrentCreationLocation() async =>
      ProfileCreationLocation(
        latitude: 12.9716,
        longitude: 77.5946,
        capturedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  @override
  Future<bool> openAppSettings() async => true;
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required String? userId,
  required LocationAccess access,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(_TestAuthRepository(userId)),
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        locationServiceProvider.overrideWithValue(_TestLocationService(access)),
      ],
      child: const ShubhmilanApp(),
    ),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Journey: unauthenticated + granted => language select', (tester) async {
    await _pumpApp(
      tester,
      userId: null,
      access: LocationAccess.granted,
    );
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.byType(LanguageSelectScreen), findsOneWidget);
  });

  testWidgets('Journey: authenticated + granted => home shell', (tester) async {
    await _pumpApp(
      tester,
      userId: 'me',
      access: LocationAccess.granted,
    );
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.byType(ModeSelectScreen), findsOneWidget);
  });

  testWidgets('Journey: location denied => location required', (tester) async {
    await _pumpApp(
      tester,
      userId: null,
      access: LocationAccess.denied,
    );
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.byType(LocationRequiredScreen), findsOneWidget);
  });
}
