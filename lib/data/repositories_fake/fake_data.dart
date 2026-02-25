import '../../domain/models/family_details.dart';
import '../../domain/models/partner_preferences.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/verification_status.dart';
import '../../domain/models/dating_extensions.dart';
import '../../domain/models/discovery_preferences.dart';
import '../../domain/models/matrimony_extensions.dart';

class FakeData {
  FakeData._();

  static UserProfile get myProfile => UserProfile(
    id: 'me',
    name: 'Arjun Kumar',
    gender: 'Man',
    age: 29,
    dateOfBirth: '1996-08-14',
    currentCity: 'London',
    currentCountry: 'UK',
    originCity: 'Mumbai',
    originCountry: 'India',
    languagesSpoken: ['English', 'Hindi', 'Marathi'],
    motherTongue: 'Hindi',
    photoUrls: [],
    aboutMe:
        'Product person at a fintech startup. Love chai, good conversations, and weekend hikes. Family-oriented but independent.',
    interests: ['Tech', 'Travel', 'Food', 'Cricket', 'Reading'],
    verificationStatus: const VerificationStatus(
      photoVerified: true,
      phoneVerified: true,
      score: 0.6,
    ),
    profileCompleteness: 0.85,
    datingExtensions: DatingExtensions(
      datingIntent: 'Serious relationship',
      discoveryPreferences: DiscoveryPreferences(
        ageMin: 24,
        ageMax: 32,
        maxDistanceKm: 30,
        preferredCities: ['London', 'Mumbai'],
      ),
      prompts: [
        PromptAnswer(
          questionId: '1',
          questionText: 'A Sunday well spent',
          answer: 'Morning run, big brunch, then a bookshop crawl.',
        ),
      ],
    ),
    matrimonyExtensions: MatrimonyExtensions(
      religion: 'Hindu',
      casteOrCommunity: 'Maratha',
      motherTongue: 'Hindi',
      maritalStatus: 'Never Married',
      heightCm: 178,
      educationDegree: 'Master\'s',
      educationInstitution: 'IIM Ahmedabad',
      occupation: 'Product Manager',
      employer: 'Revolut',
      industry: 'Fintech',
      incomeRange: const IncomeRange(
        minLabel: '30L',
        maxLabel: '50L',
        currency: 'INR',
      ),
      diet: 'Non-Vegetarian',
      drinking: 'Socially',
      smoking: 'No',
      familyDetails: const FamilyDetails(
        familyType: 'Nuclear',
        familyValues: 'Moderate',
        fatherOccupation: 'Retired Banker',
        motherOccupation: 'Homemaker',
        siblingsCount: 1,
        siblingsMarried: 0,
      ),
      horoscope: const HoroscopeDetails(
        dateOfBirth: '1996-08-14',
        timeOfBirth: '06:15',
        birthPlace: 'Mumbai',
        manglik: 'No',
        nakshatra: 'Rohini',
      ),
    ),
    partnerPreferences: const PartnerPreferences(
      ageMin: 24,
      ageMax: 32,
      heightMinCm: 155,
      heightMaxCm: 175,
      preferredLocations: ['London', 'Mumbai', 'Delhi'],
      preferredReligions: ['Hindu'],
      educationPreference: 'Bachelor\'s',
      dietPreference: 'Any',
    ),
  );

  static PartnerPreferences get defaultPartnerPreferences =>
      const PartnerPreferences(
        ageMin: 24,
        ageMax: 32,
        preferredLocations: ['London', 'Mumbai'],
        preferredReligions: ['Hindu'],
        educationPreference: 'Bachelor\'s',
      );

  static Map<String, String> get matchReasons => {
    '1': 'Similar interests: design, travel',
    '2': 'Both love arts & chai',
    '3': 'Shared career ambitions',
    '4': 'Similar lifestyle: fitness, food',
    '5': 'Shared values: family, career',
  };

  static Map<String, UserProfile> get allProfiles => {
    '1': _priya,
    '2': _ananya,
    '3': _meera,
    '4': _riya,
    '5': _kavya,
  };

  // ─────────────────────────────────────────────────────────────────────

  static UserProfile get _priya => UserProfile(
    id: '1',
    name: 'Priya Sharma',
    gender: 'Woman',
    age: 28,
    dateOfBirth: '1997-03-22',
    currentCity: 'London',
    currentCountry: 'UK',
    originCity: 'Delhi',
    originCountry: 'India',
    languagesSpoken: ['English', 'Hindi', 'Punjabi'],
    motherTongue: 'Hindi',
    photoUrls: [
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400',
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
    ],
    aboutMe:
        'Product designer at a London startup. Chai over chaos. Love minimalism, good typography, and weekend markets. Looking for someone grounded who also dreams big.',
    interests: ['Design', 'Brunch', 'Travel', 'Art', 'Yoga', 'Reading'],
    verificationStatus: const VerificationStatus(
      photoVerified: true,
      idVerified: true,
      phoneVerified: true,
      score: 0.8,
    ),
    profileCompleteness: 0.92,
    datingExtensions: DatingExtensions(
      datingIntent: 'Serious relationship',
      discoveryPreferences: DiscoveryPreferences(
        ageMin: 27,
        ageMax: 34,
        maxDistanceKm: 25,
      ),
      prompts: [
        PromptAnswer(
          questionId: '1',
          questionText: 'Best way to spend a Sunday?',
          answer: 'Long walk through a market, then a big brunch with friends.',
        ),
        PromptAnswer(
          questionId: '2',
          questionText: 'My simple pleasure',
          answer: 'A perfectly pulled espresso and a new font release.',
        ),
      ],
    ),
    matrimonyExtensions: MatrimonyExtensions(
      religion: 'Hindu',
      casteOrCommunity: 'Khatri',
      motherTongue: 'Hindi',
      maritalStatus: 'Never Married',
      heightCm: 165,
      educationDegree: 'Master\'s',
      educationInstitution: 'Royal College of Art',
      occupation: 'Product Designer',
      employer: 'Monzo',
      industry: 'Fintech',
      incomeRange: const IncomeRange(
        minLabel: '£60K',
        maxLabel: '£80K',
        currency: 'GBP',
      ),
      diet: 'Vegetarian',
      drinking: 'Socially',
      smoking: 'No',
      familyDetails: const FamilyDetails(
        familyType: 'Nuclear',
        familyValues: 'Moderate',
        fatherOccupation: 'Retired Civil Servant',
        motherOccupation: 'Teacher',
        siblingsCount: 1,
        siblingsMarried: 1,
      ),
      horoscope: const HoroscopeDetails(
        dateOfBirth: '1997-03-22',
        timeOfBirth: '11:30',
        birthPlace: 'Delhi',
        manglik: 'No',
        nakshatra: 'Uttara Phalguni',
      ),
    ),
    partnerPreferences: const PartnerPreferences(
      ageMin: 27,
      ageMax: 34,
      heightMinCm: 170,
      heightMaxCm: 185,
      preferredLocations: ['London', 'Delhi'],
      preferredReligions: ['Hindu'],
      educationPreference: 'Master\'s',
      dietPreference: 'Vegetarian',
      horoscopeMatchPreferred: false,
    ),
  );

  // ─────────────────────────────────────────────────────────────────────

  static UserProfile get _ananya => UserProfile(
    id: '2',
    name: 'Ananya Iyer',
    gender: 'Woman',
    age: 26,
    dateOfBirth: '1999-07-10',
    currentCity: 'London',
    currentCountry: 'UK',
    originCity: 'Chennai',
    originCountry: 'India',
    languagesSpoken: ['English', 'Tamil', 'Hindi'],
    motherTongue: 'Tamil',
    photoUrls: [
      'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400',
      'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400',
      'https://images.unsplash.com/photo-1524250502761-1ac6f2e30d43?w=400',
      'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=400',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
    ],
    aboutMe:
        'Software engineer by day, bharatanatyam dancer by weekend. I write clean code and messy journals. Always up for chai and deep talks about life.',
    interests: [
      'Dance',
      'Tech',
      'Coffee',
      'Classical Music',
      'Running',
      'Podcasts',
    ],
    verificationStatus: const VerificationStatus(
      photoVerified: true,
      phoneVerified: true,
      score: 0.55,
    ),
    profileCompleteness: 0.88,
    datingExtensions: DatingExtensions(
      datingIntent: 'Serious relationship',
      discoveryPreferences: DiscoveryPreferences(
        ageMin: 26,
        ageMax: 33,
        maxDistanceKm: 20,
      ),
      prompts: [
        PromptAnswer(
          questionId: '1',
          questionText: 'My ideal weekend',
          answer:
              'Dance practice in the morning, then exploring a new café with a good book.',
        ),
        PromptAnswer(
          questionId: '3',
          questionText: 'A fact about me that surprises people',
          answer:
              'I can debug a production outage and perform a dance recital in the same day.',
        ),
      ],
    ),
    matrimonyExtensions: MatrimonyExtensions(
      religion: 'Hindu',
      casteOrCommunity: 'Iyer (Brahmin)',
      motherTongue: 'Tamil',
      maritalStatus: 'Never Married',
      heightCm: 162,
      educationDegree: 'Bachelor\'s',
      educationInstitution: 'IIT Madras',
      occupation: 'Software Engineer',
      employer: 'Google',
      industry: 'Technology',
      incomeRange: const IncomeRange(
        minLabel: '£70K',
        maxLabel: '£90K',
        currency: 'GBP',
      ),
      diet: 'Vegetarian',
      drinking: 'No',
      smoking: 'No',
      familyDetails: const FamilyDetails(
        familyType: 'Joint',
        familyValues: 'Traditional',
        fatherOccupation: 'Professor',
        motherOccupation: 'Doctor',
        siblingsCount: 2,
        siblingsMarried: 1,
      ),
      horoscope: const HoroscopeDetails(
        dateOfBirth: '1999-07-10',
        timeOfBirth: '05:45',
        birthPlace: 'Chennai',
        manglik: 'No',
        nakshatra: 'Punarvasu',
      ),
    ),
    partnerPreferences: const PartnerPreferences(
      ageMin: 26,
      ageMax: 33,
      heightMinCm: 170,
      heightMaxCm: 188,
      preferredLocations: ['London', 'Chennai', 'Bangalore'],
      preferredReligions: ['Hindu'],
      preferredCommunities: ['Brahmin', 'Iyer', 'Iyengar'],
      educationPreference: 'Bachelor\'s',
      dietPreference: 'Vegetarian',
      horoscopeMatchPreferred: true,
    ),
  );

  // ─────────────────────────────────────────────────────────────────────

  static UserProfile get _meera => UserProfile(
    id: '3',
    name: 'Meera Patel',
    gender: 'Woman',
    age: 30,
    dateOfBirth: '1995-11-05',
    currentCity: 'London',
    currentCountry: 'UK',
    originCity: 'Ahmedabad',
    originCountry: 'India',
    languagesSpoken: ['English', 'Gujarati', 'Hindi'],
    motherTongue: 'Gujarati',
    photoUrls: [
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
      'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=400',
    ],
    aboutMe:
        'Finance professional working in investment banking. Into yoga at dawn, hiking on weekends, and trying every cuisine London has to offer. Looking for a genuine, lasting connection.',
    interests: ['Yoga', 'Hiking', 'Food', 'Investing', 'Meditation', 'Travel'],
    verificationStatus: const VerificationStatus(
      photoVerified: true,
      idVerified: true,
      emailVerified: true,
      phoneVerified: true,
      score: 0.85,
    ),
    profileCompleteness: 0.95,
    datingExtensions: DatingExtensions(
      datingIntent: 'Marriage',
      discoveryPreferences: DiscoveryPreferences(
        ageMin: 28,
        ageMax: 36,
        maxDistanceKm: 40,
      ),
      prompts: [
        PromptAnswer(
          questionId: '1',
          questionText: 'Looking for',
          answer:
              'Someone who values honesty, can laugh at the small things, and isn\'t afraid of ambition.',
        ),
        PromptAnswer(
          questionId: '4',
          questionText: 'My non-negotiable',
          answer: 'Kindness. Everything else can be figured out.',
        ),
      ],
    ),
    matrimonyExtensions: MatrimonyExtensions(
      religion: 'Hindu',
      casteOrCommunity: 'Patel (Leuva)',
      motherTongue: 'Gujarati',
      maritalStatus: 'Never Married',
      heightCm: 168,
      educationDegree: 'Master\'s',
      educationInstitution: 'London School of Economics',
      occupation: 'Investment Banker',
      employer: 'Goldman Sachs',
      industry: 'Finance',
      incomeRange: const IncomeRange(
        minLabel: '£100K',
        maxLabel: '£150K',
        currency: 'GBP',
      ),
      diet: 'Vegetarian',
      drinking: 'Socially',
      smoking: 'No',
      familyDetails: const FamilyDetails(
        familyType: 'Nuclear',
        familyValues: 'Moderate',
        fatherOccupation: 'Businessman',
        motherOccupation: 'Chartered Accountant',
        siblingsCount: 1,
        siblingsMarried: 0,
      ),
      horoscope: const HoroscopeDetails(
        dateOfBirth: '1995-11-05',
        timeOfBirth: '09:20',
        birthPlace: 'Ahmedabad',
        manglik: 'Yes',
        nakshatra: 'Vishakha',
      ),
    ),
    partnerPreferences: const PartnerPreferences(
      ageMin: 28,
      ageMax: 36,
      heightMinCm: 172,
      heightMaxCm: 190,
      preferredLocations: ['London', 'Mumbai', 'Ahmedabad'],
      preferredReligions: ['Hindu', 'Jain'],
      preferredCommunities: ['Patel', 'Gujarati'],
      educationPreference: 'Master\'s',
      occupationPreference: 'Professional',
      dietPreference: 'Vegetarian',
      horoscopeMatchPreferred: true,
    ),
  );

  // ─────────────────────────────────────────────────────────────────────

  static UserProfile get _riya => UserProfile(
    id: '4',
    name: 'Riya Nair',
    gender: 'Woman',
    age: 25,
    dateOfBirth: '2000-01-18',
    currentCity: 'London',
    currentCountry: 'UK',
    originCity: 'Kochi',
    originCountry: 'India',
    languagesSpoken: ['English', 'Malayalam', 'Hindi'],
    motherTongue: 'Malayalam',
    photoUrls: [
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
      'https://images.unsplash.com/photo-1524250502761-1ac6f2e30d43?w=400',
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400',
    ],
    aboutMe:
        'Content creator and digital marketing strategist. Love brunch, long walks, and sunset views. South Indian at heart — appam and stew is my love language.',
    interests: [
      'Writing',
      'Photography',
      'Travel',
      'Cooking',
      'Films',
      'Social Media',
    ],
    verificationStatus: const VerificationStatus(
      photoVerified: true,
      phoneVerified: true,
      score: 0.5,
    ),
    profileCompleteness: 0.82,
    datingExtensions: DatingExtensions(
      datingIntent: 'Serious relationship',
      discoveryPreferences: DiscoveryPreferences(
        ageMin: 25,
        ageMax: 32,
        maxDistanceKm: 30,
      ),
      prompts: [
        PromptAnswer(
          questionId: '1',
          questionText: 'Best way to spend a Sunday?',
          answer:
              'Idli and filter coffee, then a park walk with a good playlist.',
        ),
        PromptAnswer(
          questionId: '5',
          questionText: 'The way to my heart',
          answer: 'Cook me a Kerala meal and I\'m yours forever.',
        ),
      ],
    ),
    matrimonyExtensions: MatrimonyExtensions(
      religion: 'Christian',
      casteOrCommunity: 'Syrian Christian',
      motherTongue: 'Malayalam',
      maritalStatus: 'Never Married',
      heightCm: 160,
      educationDegree: 'Bachelor\'s',
      educationInstitution: 'Christ University',
      occupation: 'Digital Marketing Manager',
      employer: 'Ogilvy',
      industry: 'Advertising',
      incomeRange: const IncomeRange(
        minLabel: '£40K',
        maxLabel: '£55K',
        currency: 'GBP',
      ),
      diet: 'Non-Vegetarian',
      drinking: 'Socially',
      smoking: 'No',
      familyDetails: const FamilyDetails(
        familyType: 'Nuclear',
        familyValues: 'Moderate',
        fatherOccupation: 'Engineer',
        motherOccupation: 'Nurse',
        siblingsCount: 2,
        siblingsMarried: 0,
      ),
      horoscope: null,
    ),
    partnerPreferences: const PartnerPreferences(
      ageMin: 25,
      ageMax: 33,
      heightMinCm: 168,
      heightMaxCm: 185,
      preferredLocations: ['London', 'Kochi', 'Bangalore'],
      preferredReligions: ['Christian'],
      educationPreference: 'Bachelor\'s',
      dietPreference: 'Any',
      horoscopeMatchPreferred: false,
    ),
  );

  // ─────────────────────────────────────────────────────────────────────

  static UserProfile get _kavya => UserProfile(
    id: '5',
    name: 'Kavya Reddy',
    gender: 'Woman',
    age: 27,
    dateOfBirth: '1998-05-30',
    currentCity: 'London',
    currentCountry: 'UK',
    originCity: 'Hyderabad',
    originCountry: 'India',
    languagesSpoken: ['English', 'Telugu', 'Hindi'],
    motherTongue: 'Telugu',
    photoUrls: [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400',
      'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400',
      'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400',
      'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=400',
    ],
    aboutMe:
        'Junior doctor training in paediatrics. Busy schedule but I always make time for family, friends, and really good biryani. Weekends are for cooking experiments and long phone calls with mum.',
    interests: [
      'Healthcare',
      'Cooking',
      'Reading',
      'Gardening',
      'Volunteering',
      'Badminton',
    ],
    verificationStatus: const VerificationStatus(
      photoVerified: true,
      idVerified: true,
      educationVerified: true,
      phoneVerified: true,
      score: 0.9,
    ),
    profileCompleteness: 0.96,
    datingExtensions: DatingExtensions(
      datingIntent: 'Marriage',
      discoveryPreferences: DiscoveryPreferences(
        ageMin: 27,
        ageMax: 35,
        maxDistanceKm: 35,
      ),
      prompts: [
        PromptAnswer(
          questionId: '1',
          questionText: 'Looking for',
          answer:
              'Someone who understands ambition but also knows when to slow down and just be.',
        ),
        PromptAnswer(
          questionId: '6',
          questionText: 'I guarantee I can',
          answer: 'Make the best biryani you\'ve ever had. Challenge accepted.',
        ),
      ],
    ),
    matrimonyExtensions: MatrimonyExtensions(
      religion: 'Hindu',
      casteOrCommunity: 'Reddy',
      motherTongue: 'Telugu',
      maritalStatus: 'Never Married',
      heightCm: 163,
      educationDegree: 'Doctorate',
      educationInstitution: 'King\'s College London',
      occupation: 'Doctor (Paediatrics)',
      employer: 'NHS',
      industry: 'Healthcare',
      incomeRange: const IncomeRange(
        minLabel: '£50K',
        maxLabel: '£70K',
        currency: 'GBP',
      ),
      diet: 'Non-Vegetarian',
      drinking: 'No',
      smoking: 'No',
      familyDetails: const FamilyDetails(
        familyType: 'Joint',
        familyValues: 'Traditional',
        fatherOccupation: 'Surgeon',
        motherOccupation: 'Pharmacist',
        siblingsCount: 1,
        siblingsMarried: 1,
      ),
      horoscope: const HoroscopeDetails(
        dateOfBirth: '1998-05-30',
        timeOfBirth: '14:00',
        birthPlace: 'Hyderabad',
        manglik: 'No',
        nakshatra: 'Mrigashira',
      ),
    ),
    partnerPreferences: const PartnerPreferences(
      ageMin: 27,
      ageMax: 35,
      heightMinCm: 170,
      heightMaxCm: 188,
      preferredLocations: ['London', 'Hyderabad'],
      preferredReligions: ['Hindu'],
      preferredCommunities: ['Reddy', 'Kamma', 'Telugu'],
      educationPreference: 'Master\'s',
      occupationPreference: 'Professional',
      maritalStatusPreference: ['Never Married'],
      dietPreference: 'Any',
      horoscopeMatchPreferred: true,
    ),
  );
}
