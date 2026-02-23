/// Shared profile model for discovery, map pins, and full profile screen.
class DiscoveryProfile {
  DiscoveryProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.city,
    required this.bio,
    required this.promptAnswer,
    required this.imageUrl,
    this.distanceKm,
    this.verified = false,
    this.matchReason,
    this.interests = const [],
  });
  final String id;
  final String name;
  final int age;
  final String city;
  final String bio;
  final String promptAnswer;
  final String? imageUrl;
  final double? distanceKm;
  final bool verified;
  final String? matchReason;
  final List<String> interests;
}

/// Dummy Indian women profiles for discovery, map, and chat.
final List<DiscoveryProfile> mockDiscoveryProfiles = [
  DiscoveryProfile(
    id: '1',
    name: 'Priya',
    age: 28,
    city: 'London',
    bio: 'Product designer. Chai over chaos. Love minimalism and good typography.',
    promptAnswer: 'Best way to spend a Sunday? Long walk, then a big brunch.',
    imageUrl: null,
    distanceKm: 2.1,
    verified: true,
    matchReason: 'Similar interests: design, brunch',
    interests: ['Design', 'Brunch', 'Travel'],
  ),
  DiscoveryProfile(
    id: '2',
    name: 'Ananya',
    age: 26,
    city: 'London',
    bio: 'Software engineer by day, bharatanatyam dancer by weekend. Always up for chai and deep talks.',
    promptAnswer: 'My ideal weekend is a mix of dance practice and exploring a new café.',
    imageUrl: null,
    distanceKm: 4.2,
    verified: false,
    matchReason: 'Both love arts & tech',
    interests: ['Dance', 'Tech', 'Coffee'],
  ),
  DiscoveryProfile(
    id: '3',
    name: 'Meera',
    age: 30,
    city: 'London',
    bio: 'Finance professional. Into yoga, hiking, and trying new cuisines. Looking for genuine connection.',
    promptAnswer: 'Looking for someone who values honesty and can laugh at the small things.',
    imageUrl: null,
    distanceKm: 5.0,
    verified: true,
    matchReason: 'Similar lifestyle: fitness, food',
    interests: ['Yoga', 'Hiking', 'Food'],
  ),
  DiscoveryProfile(
    id: '4',
    name: 'Riya',
    age: 25,
    city: 'London',
    bio: 'Content creator. Love brunch, long walks, and sunset views. South Indian at heart.',
    promptAnswer: 'Best way to spend a Sunday? Idli and filter coffee, then a park walk.',
    imageUrl: null,
    distanceKm: 3.2,
    verified: false,
    matchReason: 'Both in creative fields',
    interests: ['Writing', 'Photography', 'Travel'],
  ),
  DiscoveryProfile(
    id: '5',
    name: 'Kavya',
    age: 27,
    city: 'London',
    bio: 'Doctor. Busy schedule but I make time for family, friends, and good food.',
    promptAnswer: 'I\'m looking for someone who understands ambition but also knows when to slow down.',
    imageUrl: null,
    distanceKm: 6.1,
    verified: true,
    matchReason: 'Shared values: family, career',
    interests: ['Healthcare', 'Cooking', 'Reading'],
  ),
];

DiscoveryProfile? getDiscoveryProfileById(String id) {
  try {
    return mockDiscoveryProfiles.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
}
