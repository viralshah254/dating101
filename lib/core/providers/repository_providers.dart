import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories_fake/fake_auth_repository.dart';
import '../../data/repositories_fake/fake_chat_repository.dart';
import '../../data/repositories_fake/fake_discovery_repository.dart';
import '../../data/repositories_fake/fake_interests_repository.dart';
import '../../data/repositories_fake/fake_profile_repository.dart';
import '../../data/repositories_fake/fake_shortlist_repository.dart';
import '../../data/repositories_fake/fake_subscription_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../../domain/repositories/interests_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/shortlist_repository.dart';
import '../../domain/repositories/subscription_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FakeAuthRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FakeProfileRepository();
});

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  final profileRepo = ref.watch(profileRepositoryProvider);
  return FakeDiscoveryRepository(profileRepo);
});

final interestsRepositoryProvider = Provider<InterestsRepository>((ref) {
  return FakeInterestsRepository();
});

final shortlistRepositoryProvider = Provider<ShortlistRepository>((ref) {
  return FakeShortlistRepository();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FakeChatRepository();
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return FakeSubscriptionRepository();
});
