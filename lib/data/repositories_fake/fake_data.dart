import '../../domain/models/partner_preferences.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/verification_status.dart';
import '../../domain/models/dating_extensions.dart';
import '../../domain/models/discovery_preferences.dart';

/// Centralized fake data for all fake repositories.
class FakeData {
  FakeData._();

  static UserProfile get myProfile => UserProfile(
        id: 'me',
        name: 'Me',
        gender: 'Man',
        age: 29,
        currentCity: 'London',
        currentCountry: 'UK',
        originCity: 'Mumbai',
        originCountry: 'India',
        languagesSpoken: ['English', 'Hindi'],
        motherTongue: 'Hindi',
        photoUrls: [],
        aboutMe: 'Product person. Love chai and good conversations.',
        interests: ['Tech', 'Travel', 'Food'],
        verificationStatus: const VerificationStatus(photoVerified: true, score: 0.4),
        profileCompleteness: 0.65,
        datingExtensions: DatingExtensions(
          datingIntent: 'Serious relationship',
          discoveryPreferences: DiscoveryPreferences(ageMin: 24, ageMax: 35, maxDistanceKm: 30),
        ),
      );

  static PartnerPreferences get defaultPartnerPreferences => const PartnerPreferences(
        ageMin: 24,
        ageMax: 35,
        preferredLocations: ['London', 'Mumbai'],
      );

  static Map<String, String> get matchReasons => {
        '2': 'Similar interests: design, brunch',
        '3': 'Both love arts & tech',
        '4': 'Similar lifestyle: fitness, food',
        '5': 'Both in creative fields',
        '6': 'Shared values: family, career',
      };

  static Map<String, UserProfile> get allProfiles => {
        '1': _priya,
        '2': _ananya,
        '3': _meera,
        '4': _riya,
        '5': _kavya,
      };

  static UserProfile get _priya => UserProfile(
        id: '1',
        name: 'Priya',
        gender: 'Woman',
        age: 28,
        currentCity: 'London',
        currentCountry: 'UK',
        photoUrls: [],
        aboutMe:
            'Product designer. Chai over chaos. Love minimalism and good typography.',
        interests: ['Design', 'Brunch', 'Travel'],
        verificationStatus: const VerificationStatus(photoVerified: true, score: 0.6),
        profileCompleteness: 0.8,
        datingExtensions: DatingExtensions(
          prompts: [
            PromptAnswer(
              questionId: '1',
              questionText: 'Best way to spend a Sunday?',
              answer: 'Long walk, then a big brunch.',
            ),
          ],
        ),
      );

  static UserProfile get _ananya => UserProfile(
        id: '2',
        name: 'Ananya',
        gender: 'Woman',
        age: 26,
        currentCity: 'London',
        currentCountry: 'UK',
        photoUrls: [],
        aboutMe:
            'Software engineer by day, bharatanatyam dancer by weekend. Always up for chai and deep talks.',
        interests: ['Dance', 'Tech', 'Coffee'],
        verificationStatus: const VerificationStatus(photoVerified: false, score: 0.2),
        profileCompleteness: 0.7,
        datingExtensions: DatingExtensions(
          prompts: [
            PromptAnswer(
              questionId: '1',
              questionText: 'My ideal weekend',
              answer: 'Dance practice and exploring a new café.',
            ),
          ],
        ),
      );

  static UserProfile get _meera => UserProfile(
        id: '3',
        name: 'Meera',
        gender: 'Woman',
        age: 30,
        currentCity: 'London',
        currentCountry: 'UK',
        photoUrls: [],
        aboutMe:
            'Finance professional. Into yoga, hiking, and trying new cuisines. Looking for genuine connection.',
        interests: ['Yoga', 'Hiking', 'Food'],
        verificationStatus: const VerificationStatus(photoVerified: true, score: 0.5),
        profileCompleteness: 0.75,
        datingExtensions: DatingExtensions(
          prompts: [
            PromptAnswer(
              questionId: '1',
              questionText: 'Looking for',
              answer: 'Someone who values honesty and can laugh at the small things.',
            ),
          ],
        ),
      );

  static UserProfile get _riya => UserProfile(
        id: '4',
        name: 'Riya',
        gender: 'Woman',
        age: 25,
        currentCity: 'London',
        currentCountry: 'UK',
        photoUrls: [],
        aboutMe:
            'Content creator. Love brunch, long walks, and sunset views. South Indian at heart.',
        interests: ['Writing', 'Photography', 'Travel'],
        verificationStatus: const VerificationStatus(photoVerified: false, score: 0.3),
        profileCompleteness: 0.7,
        datingExtensions: DatingExtensions(
          prompts: [
            PromptAnswer(
              questionId: '1',
              questionText: 'Best way to spend a Sunday?',
              answer: 'Idli and filter coffee, then a park walk.',
            ),
          ],
        ),
      );

  static UserProfile get _kavya => UserProfile(
        id: '5',
        name: 'Kavya',
        gender: 'Woman',
        age: 27,
        currentCity: 'London',
        currentCountry: 'UK',
        photoUrls: [],
        aboutMe:
            'Doctor. Busy schedule but I make time for family, friends, and good food.',
        interests: ['Healthcare', 'Cooking', 'Reading'],
        verificationStatus: const VerificationStatus(photoVerified: true, score: 0.55),
        profileCompleteness: 0.85,
        datingExtensions: DatingExtensions(
          prompts: [
            PromptAnswer(
              questionId: '1',
              questionText: 'Looking for',
              answer: 'Someone who understands ambition but also knows when to slow down.',
            ),
          ],
        ),
      );
}
