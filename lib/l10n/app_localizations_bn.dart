// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'saathi';

  @override
  String get appTagline => 'বিশ্বজুড়ে পরিশীলিত সংযোগ।';

  @override
  String get appTaglineDating => 'গভীরতা-প্রথম সংযোগ। অর্থহীন সোয়াইপিং নেই।';

  @override
  String get appTaglineMatrimony => 'বিয়েতে সিরিয়াস। অর্থপূর্ণ প্রোফাইল।';

  @override
  String get continueLabel => 'চালিয়ে যান';

  @override
  String get next => 'পরবর্তী';

  @override
  String get back => 'পিছনে';

  @override
  String get skip => 'এড়িয়ে যান';

  @override
  String get done => 'সম্পন্ন';

  @override
  String get save => 'সংরক্ষণ';

  @override
  String get cancel => 'বাতিল';

  @override
  String get getStarted => 'শুরু করুন';

  @override
  String get finish => 'শেষ';

  @override
  String get apply => 'প্রয়োগ';

  @override
  String get close => 'বন্ধ';

  @override
  String get submit => 'জমা দিন';

  @override
  String get verify => 'যাচাই করুন';

  @override
  String get resend => 'পুনরায় পাঠান';

  @override
  String get retry => 'পুনরায় চেষ্টা';

  @override
  String get enable => 'সক্রিয় করুন';

  @override
  String get notNow => 'এখন না';

  @override
  String get loginTitle => 'saathi';

  @override
  String get loginTagline => 'বিশ্বজুড়ে পরিশীলিত সংযোগ।';

  @override
  String get signUpWithPhone => 'ফোন নম্বর দিয়ে সাইন আপ করুন';

  @override
  String get phoneNumber => 'ফোন নম্বর';

  @override
  String get email => 'ইমেল';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get continueButton => 'চালিয়ে যান';

  @override
  String get continueWithGoogle => 'Google দিয়ে চালিয়ে যান';

  @override
  String get continueWithApple => 'Apple দিয়ে চালিয়ে যান';

  @override
  String get termsConsent =>
      'চালিয়ে যাওয়ার মাধ্যমে আপনি আমাদের শর্তাবলী ও গোপনীয়তা নীতি মেনে নিচ্ছেন।';

  @override
  String get verifyYourNumber => 'নম্বর যাচাই করুন';

  @override
  String get enterOtp => '৬ অঙ্কের কোড লিখুন';

  @override
  String otpSentTo(Object phone) {
    return 'আমরা $phone-এ যাচাই কোড পাঠিয়েছি। চালিয়ে যেতে নিচে লিখুন।';
  }

  @override
  String get resendCode => 'কোড পুনরায় পাঠান';

  @override
  String get verifyAndContinue => 'যাচাই করুন ও চালিয়ে যান';

  @override
  String get modeSelectTitle => 'আপনি এখানে কীসের জন্য?';

  @override
  String get modeDating => 'ডেটিং';

  @override
  String get modeDatingSubtitle =>
      'মানুষের সাথে দেখা করুন। গভীরতা-প্রথম প্রোফাইল, অনুসন্ধান ও অর্থপূর্ণ সংযোগ।';

  @override
  String get modeMatrimony => 'বিবাহ';

  @override
  String get modeMatrimonySubtitle =>
      'জীবনসঙ্গী খুঁজুন। বিস্তৃত প্রোফাইল, পার্টনার পছন্দ ও পরিবার-বান্ধব ম্যাচিং।';

  @override
  String get navDiscover => 'অন্বেষণ';

  @override
  String get navMap => 'ম্যাপ';

  @override
  String get navChats => 'চ্যাট';

  @override
  String get navCommunities => 'কমিউনিটি';

  @override
  String get navProfile => 'প্রোফাইল';

  @override
  String get navMatches => 'ম্যাচ';

  @override
  String get navRequests => 'অনুরোধ';

  @override
  String get navShortlist => 'শর্টলিস্ট';

  @override
  String get navEvents => 'ইভেন্ট';

  @override
  String get navVisitors => 'দর্শক';

  @override
  String get refine => 'পরিশোধন';

  @override
  String get refineTooltip =>
      'বয়স, শহর, ধর্ম, শিক্ষা এবং আরও দিয়ে পরিশোধন করুন';

  @override
  String get noRecommendationsYet => 'এখনও কোনো সুপারিশ নেই';

  @override
  String get noRecommendationsYetBody =>
      'AI-চালিত ম্যাচ পেতে আপনার প্রোফাইল এবং পছন্দ সম্পূর্ণ করুন।';

  @override
  String get searchWidenedTitle => 'আমরা খোঁজ প্রসারিত করেছি';

  @override
  String get searchWidenedBody =>
      'বর্তমান ফিল্টারে কোনো ফল মেলেনি। আমরা কিছু ফিল্টার কমানোর মাধ্যমে আরও প্রোফাইল দেখাচ্ছি।';

  @override
  String get discoverTitle => 'অন্বেষণ';

  @override
  String get dailyCuratedSet => 'দৈনিক বাছাই সেট';

  @override
  String exploreCity(Object city) {
    return '$city অন্বেষণ করুন';
  }

  @override
  String get travelModeHint => 'ট্রাভেল মোড: সেভ করা শহরগুলোতে প্রোফাইল দেখা';

  @override
  String get filters => 'ফিল্টার';

  @override
  String get filtersPlaceholder => 'বয়স, দূরত্ব, উদ্দেশ্য ইত্যাদি';

  @override
  String get ctaSendIntro => 'চিন্তাশীল ইন্ট্রো পাঠান';

  @override
  String get ctaSendInterest => 'আগ্রহ প্রকাশ করুন';

  @override
  String get ctaSendMessage => 'মেসেজ পাঠান';

  @override
  String get ctaShortlist => 'শর্টলিস্ট';

  @override
  String get ctaRequestContact => 'যোগাযোগ অনুরোধ';

  @override
  String get ctaUpgradeToPremium => 'saathi প্রিমিয়ামে আপগ্রেড করুন';

  @override
  String get premiumRequired => 'প্রিমিয়াম ফিচার';

  @override
  String get premiumMessageMale =>
      'মেসেজ পাঠাতে, কে লাইক করে দেখতে ও যোগাযোগ আনলক করতে আপগ্রেড করুন।';

  @override
  String get premiumMessageFemale =>
      'ট্রাভেল মোড, প্রোফাইল বুস্ট ও অগ্রাধিকার অনুসন্ধানের জন্য আপগ্রেড করুন।';

  @override
  String get freeLimitReached => 'দৈনিক লিমিট পূর্ণ';

  @override
  String get freeLimitBody =>
      'আজকের ফ্রি আগ্রহ সব ব্যবহার হয়েছে। সীমাহীনের জন্য আপগ্রেড করুন।';

  @override
  String get block => 'ব্লক';

  @override
  String get report => 'রিপোর্ট';

  @override
  String get viewFullProfile => 'সম্পূর্ণ প্রোফাইল দেখুন';

  @override
  String get matchesRecommended => 'সুপারিশকৃত';

  @override
  String get matchesSearch => 'খোঁজ';

  @override
  String get matchesNearby => 'কাছাকাছি';

  @override
  String get recommendedCopy => 'আপনার পছন্দ অনুযায়ী সুপারিশ';

  @override
  String get whyMatch => 'কেন এই ম্যাচ';

  @override
  String get requestsReceived => 'প্রাপ্ত';

  @override
  String get requestsSent => 'পাঠানো';

  @override
  String get accept => 'গ্রহণ';

  @override
  String get decline => 'প্রত্যাখ্যান';

  @override
  String get withdraw => 'প্রত্যাহার';

  @override
  String get requestsEmpty => 'এখনও কোনো অনুরোধ নেই';

  @override
  String get requestsEmptyHint => 'কেউ আগ্রহ পাঠালে এখানে দেখা যাবে।';

  @override
  String get shortlistTitle => 'শর্টলিস্ট';

  @override
  String get shortlistEmpty => 'শর্টলিস্টে প্রোফাইল নেই';

  @override
  String get shortlistEmptyHint => 'পরে দেখতে পছন্দের প্রোফাইল শর্টলিস্ট করুন।';

  @override
  String get profileTitle => 'প্রোফাইল';

  @override
  String get profileSettings => 'প্রোফাইল ও সেটিংস';

  @override
  String get myProfile => 'আমার প্রোফাইল';

  @override
  String get tapToEdit => 'এডিট করতে ট্যাপ করুন';

  @override
  String get about => 'সম্পর্কে';

  @override
  String get interests => 'আগ্রহ';

  @override
  String get interestsAndHobbies => 'আগ্রহ ও শখ';

  @override
  String get interestsAndHobbiesSubtitle =>
      '৬টি পর্যন্ত পছন্দ করুন — ভালো ম্যাচের জন্য ব্যবহার করব।';

  @override
  String get interestsSearchHint => 'আগ্রহ ও শখ খোঁজুন...';

  @override
  String get interestsMaxReached =>
      'সর্বোচ্চ ৬ আগ্রহ। আরেকটি যোগ করতে একটি সরান।';

  @override
  String get prompt => 'প্রম্পট';

  @override
  String get verification => 'যাচাই';

  @override
  String get trustCenter => 'ট্রাস্ট সেন্টার';

  @override
  String get notifications => 'নোটিফিকেশন';

  @override
  String get privacyAndSafety => 'গোপনীয়তা ও নিরাপত্তা';

  @override
  String get helpCentre => 'হেল্প সেন্টার';

  @override
  String get termsAndPrivacy => 'শর্ত ও গোপনীয়তা';

  @override
  String get signOut => 'সাইন আউট';

  @override
  String get account => 'অ্যাকাউন্ট';

  @override
  String get support => 'সহায়তা';

  @override
  String get language => 'ভাষা';

  @override
  String get chooseLanguage => 'ভাষা নির্বাচন করুন';

  @override
  String get subscription => 'সাবস্ক্রিপশন';

  @override
  String get legal => 'আইনি';

  @override
  String get profileBuilderPhotos => 'ফটো';

  @override
  String get profileBuilderAbout => 'আমার সম্পর্কে';

  @override
  String get profileBuilderBasic => 'মৌলিক বিবরণ';

  @override
  String get profileBuilderLifestyle => 'লাইফস্টাইল';

  @override
  String get profileBuilderPrompts => 'প্রম্পট ও ভয়েস';

  @override
  String get profileBuilderEducation => 'শিক্ষা ও কাজ';

  @override
  String get profileBuilderFamily => 'পরিবার';

  @override
  String get profileBuilderPartnerPrefs => 'পার্টনার পছন্দ';

  @override
  String completeProfile(Object percent) {
    return 'প্রোফাইল সম্পূর্ণ করুন — $percent%';
  }

  @override
  String get onboardingStepBasic => 'মৌলিক তথ্য';

  @override
  String get onboardingStepPreferences => 'পছন্দ';

  @override
  String get onboardingStepExtended => 'আপনার সম্পর্কে আরও';

  @override
  String get onboardingDatingSlide1Title => 'গভীরতা-প্রথম সংযোগ';

  @override
  String get onboardingDatingSlide1Body =>
      'পূর্ণ প্রোফাইল দেখুন ও চিন্তাশীল ইন্ট্রো পাঠান—অর্থহীন সোয়াইপিং নেই।';

  @override
  String get onboardingDatingSlide2Title => 'ম্যাপ দিয়ে অন্বেষণ';

  @override
  String get onboardingDatingSlide2Body =>
      'আপনার শহরে মানুষ খুঁজুন বা ভ্রমণে আগে প্ল্যান করুন।';

  @override
  String get onboardingDatingSlide3Title => 'সার্কেল ও ইভেন্ট';

  @override
  String get onboardingDatingSlide3Body =>
      'জীবনের সাথে মিলে এমন কমিউনিটি ও রিয়েল-ওয়ার্ল্ড মিটআপে যোগ দিন।';

  @override
  String get onboardingMatrimonySlide1Title => 'অর্থপূর্ণ ম্যাচ';

  @override
  String get onboardingMatrimonySlide1Body =>
      'পূর্ণ প্রোফাইল ও পার্টনার পছন্দ দেখুন—বিয়েতে সিরিয়াস।';

  @override
  String get onboardingMatrimonySlide2Title => 'পরিবার জড়িত';

  @override
  String get onboardingMatrimonySlide2Body =>
      'পরিবারের সাথে প্রোফাইল শেয়ার করুন ও পছন্দে একসাথে অ্যালাইন করুন।';

  @override
  String get onboardingMatrimonySlide3Title => 'যাচাইকৃত ও বিস্তারিত';

  @override
  String get onboardingMatrimonySlide3Body =>
      'বিশ্বস্ত ম্যাচের জন্য যাচাইকৃত প্রোফাইল ও বিস্তারিত পছন্দে ফোকাস।';

  @override
  String get yourName => 'আপনার নাম';

  @override
  String get nameHint => 'যেমন প্রিয়া, অর্জুন';

  @override
  String get nameValidationHint =>
      'কমপক্ষে ২ শব্দ বড় অক্ষরে, যেমন প্রিয়া শর্মা';

  @override
  String get aboutYou => 'আপনার সম্পর্কে কয়েক লাইন';

  @override
  String get aboutYouHint =>
      'যা গুরুত্বপূর্ণ শেয়ার করুন — কাজ, আগ্রহ, কী খুঁজছেন।';

  @override
  String get lookingForDating => 'আমি খুঁজছি';

  @override
  String get creatingProfileFor => 'এই প্রোফাইল কার জন্য বানাচ্ছি';

  @override
  String get self => 'নিজের';

  @override
  String get parent => 'অভিভাবক';

  @override
  String get guardian => 'অভিভাবক';

  @override
  String get sibling => 'ভাইবোন';

  @override
  String get friend => 'বন্ধু';

  @override
  String get lookingForBride => 'বধূ';

  @override
  String get lookingForGroom => 'বর';

  @override
  String get paywallTitle => 'saathi দিয়ে আরও আনলক করুন';

  @override
  String get paywallDatingSubtitle =>
      'গ্লোবাল অনুসন্ধান ও অগ্রাধিকারের জন্য আপগ্রেড করুন।';

  @override
  String get paywallMatrimonySubtitle =>
      'যোগাযোগের বিবরণ ও ফিচার্ড লিস্টিং আনলক করুন।';

  @override
  String get premium => 'প্রিমিয়াম';

  @override
  String get mostPopular => 'সবচেয়ে জনপ্রিয়';

  @override
  String get subscribe => 'সাবস্ক্রাইব করুন';

  @override
  String get restorePurchases => 'ক্রয় পুনরুদ্ধার';

  @override
  String get benefitUnlimitedIntros => 'সীমাহীন ইন্ট্রো';

  @override
  String get benefitSeeWhoLikes => 'কে লাইক করে দেখুন';

  @override
  String get benefitTravelMode => 'ট্রাভেল মোড: অন্য শহর অন্বেষণ';

  @override
  String get benefitPriorityDiscovery => 'অনুসন্ধানে অগ্রাধিকার';

  @override
  String get benefitReadReceipts => 'রিড রিসিপ্ট';

  @override
  String get benefitUnlimitedInterests => 'সীমাহীন আগ্রহ';

  @override
  String get benefitSeeWhoViewed => 'কে ভিউ করেছে দেখুন';

  @override
  String get benefitUnlockContact => 'যোগাযোগের বিবরণ আনলক';

  @override
  String get benefitFeaturedProfile => 'ফিচার্ড প্রোফাইল / অগ্রাধিকার লিস্টিং';

  @override
  String get benefitAdvancedFilters => 'এডভান্সড ফিল্টার';

  @override
  String get verifyPriority => 'অগ্রাধিকার পেতে যাচাই করুন';

  @override
  String get verifiedProfilesGetMore =>
      'যাচাইকৃত প্রোফাইল বেশি বিশ্বাস ও রেসপন্স পায়।';

  @override
  String get idVerification => 'আইডি যাচাই';

  @override
  String get faceMatch => 'ফেস ম্যাচ';

  @override
  String get linkedIn => 'LinkedIn';

  @override
  String get education => 'শিক্ষা';

  @override
  String get safetyScore => 'নিরাপত্তা স্কোর';

  @override
  String get uploadIdHint =>
      'পাসপোর্ট বা ড্রাইভিং লাইসেন্সের স্পষ্ট ফটো আপলোড করুন।';

  @override
  String get inviteFriends => 'বন্ধুদের আমন্ত্রণ';

  @override
  String get inviteCopy => 'বন্ধুদের সংযোগের ভালো উপায় দিন';

  @override
  String get inviteReward =>
      'ইনভাইট কোড বা লিংক শেয়ার করুন। জয়েন করলে দুজনে রিওয়ার্ড।';

  @override
  String get yourInviteCode => 'আপনার ইনভাইট কোড';

  @override
  String get copyCode => 'কোড কপি';

  @override
  String get shareVia => 'শেয়ার via';

  @override
  String get share => 'শেয়ার';

  @override
  String get copyLink => 'লিংক কপি';

  @override
  String get rewards => 'রিওয়ার্ড';

  @override
  String get codeCopied => 'কোড কপি হয়েছে';

  @override
  String get loginHeroTitle => 'আপনার\nমানুষ খুঁজুন';

  @override
  String get loginHeroSubtitle =>
      'ভারতীয় ডায়াস্পোরার জন্য অর্থপূর্ণ সংযোগ, বিশ্বজুড়ে।';

  @override
  String get orDivider => 'অথবা';

  @override
  String get ageConfirmation => 'আমি নিশ্চিত করছি আমি ১৮ বা তার বেশি';

  @override
  String get otpTitle => 'আপনার\nফোন যাচাই করুন';

  @override
  String get otpSubtitle => 'পাঠানো ৬ অঙ্কের কোড লিখুন';

  @override
  String get otpDidntReceive => 'পায়নি?';

  @override
  String otpResendIn(Object seconds) {
    return '$seconds সেকেন্ডে পুনরায় পাঠান';
  }

  @override
  String get modeSelectSubtitle =>
      'saathi কীভাবে ব্যবহার করবেন বেছে নিন। সেটিংস থেকে যেকোনো সময় সুইচ করতে পারবেন।';

  @override
  String get modeSwitchHint => 'সেটিংসে যেকোনো সময় সুইচ করতে পারবেন।';

  @override
  String get profileSetupTitle => 'চলুন আপনার\nপ্রোফাইল সেট আপ করি';

  @override
  String get profileSetupSubtitle =>
      'প্রায় ২ মিনিট। পরে যেকোনো সময় এডিট করতে পারবেন।';

  @override
  String get profileCreatingFor => 'এই প্রোফাইল কার জন্য';

  @override
  String get profileCreatingForSelf => 'নিজের';

  @override
  String get profileCreatingForSon => 'আমার ছেলে';

  @override
  String get profileCreatingForDaughter => 'আমার মেয়ে';

  @override
  String get profileCreatingForBrother => 'আমার ভাই';

  @override
  String get profileCreatingForSister => 'আমার বোন';

  @override
  String get profileCreatingForFriend => 'এক বন্ধু';

  @override
  String get profileCreatingForRelative => 'এক আত্মীয়';

  @override
  String get genderQuestion => 'লিঙ্গ';

  @override
  String get genderWoman => 'মহিলা';

  @override
  String get genderMan => 'পুরুষ';

  @override
  String get genderNonBinary => 'নন-বাইনারি';

  @override
  String get dateOfBirth => 'জন্ম তারিখ';

  @override
  String get confirmAge18Self => 'আমি নিশ্চিত করছি আমি ১৮ বা তার বেশি';

  @override
  String get confirmAge18Other => 'আমি নিশ্চিত করছি এই ব্যক্তি ১৮ বা তার বেশি';

  @override
  String get dobMustBe18 => '১৮ বা তার বেশি হতে হবে';

  @override
  String get selectDate => 'তারিখ নির্বাচন';

  @override
  String get ok => 'ঠিক আছে';

  @override
  String get currentLocation => 'আপনি কোথায় থাকেন?';

  @override
  String get currentLocationHint => 'যেমন মুম্বই, নিউ ইয়র্ক';

  @override
  String get hometown => 'আপনি কোথা থেকে?';

  @override
  String get placeOfBirthHint => 'যেমন জয়পুর, হায়দ্রাবাদ';

  @override
  String get lookingForPartner => 'খুঁজছি';

  @override
  String get profileStepIdentity => 'আইডেন্টিটি';

  @override
  String get profileStepPhotos => 'ফটো';

  @override
  String get profileStepEducation => 'শিক্ষা';

  @override
  String get profileStepCareer => 'কর্মজীবন';

  @override
  String get profileStepDetails => 'লাইফস্টাইল ও আরও';

  @override
  String get profileStepPreferences => 'পছন্দ';

  @override
  String get addEducation => 'শিক্ষা যোগ করুন';

  @override
  String get whatDidYouComplete => 'কী সম্পন্ন করেছেন?';

  @override
  String get whatDidYouCompleteHint => 'যেমন হাই স্কুল, ব্যাচেলর, MBA';

  @override
  String get educationStepSubtitle =>
      'প্রথম হাই স্কুল বা কলেজ/ইউনিভার্সিটি বেছে নিন। ডিগ্রির জন্য প্রতিষ্ঠান যোগ করুন — ম্যাচিংয়ে সাহায্য।';

  @override
  String get searchUniversity => 'ইউনিভার্সিটি / কলেজ';

  @override
  String get searchUniversityHint => 'যেমন IIT Delhi, Christ University';

  @override
  String get universityImportantHint =>
      'প্রতিষ্ঠান বেছে নিলে ভালো ম্যাচ পেতে সাহায্য।';

  @override
  String get degreeLevel => 'ডিগ্রি / লেভেল';

  @override
  String get searchDegreeHint => 'ডিগ্রি বা লেভেল খোঁজুন';

  @override
  String get graduationYear => 'পাসের বছর';

  @override
  String get degreeGrade => 'ডিগ্রি গ্রেড / ক্লাসিফিকেশন';

  @override
  String get degreeGradeHint => 'যেমন UK 1st class honours, India First class';

  @override
  String get scoreCountry => 'গ্রেডিং সিস্টেম';

  @override
  String get remove => 'সরান';

  @override
  String get datingIntentQuestion => 'আপনি কী খুঁজছেন?';

  @override
  String get datingIntentSerious => 'সিরিয়াস রিলেশনশিপ';

  @override
  String get datingIntentCasual => 'মজা / ক্যাজুয়াল';

  @override
  String get datingIntentMarriage => 'বিয়ে';

  @override
  String get datingIntentFriends => 'প্রথমে বন্ধু';

  @override
  String get datingIntentOpen => 'দেখতে খোলা';

  @override
  String get interestedIn => 'আগ্রহী';

  @override
  String get interestedInMen => 'পুরুষ';

  @override
  String get interestedInWomen => 'মহিলা';

  @override
  String get interestedInEveryone => 'সবাই';

  @override
  String get matrimonyReligionQuestion => 'ধর্ম';

  @override
  String get matrimonyCommunityQuestion => 'সম্প্রদায় / জাতি';

  @override
  String get matrimonyMotherTongueQuestion => 'মাতৃভাষা';

  @override
  String get matrimonyMaritalStatusQuestion => 'বৈবাহিক অবস্থা';

  @override
  String get matrimonyHeightQuestion => 'উচ্চতা';

  @override
  String get matrimonyEducationQuestion => 'সর্বোচ্চ শিক্ষা';

  @override
  String get matrimonyOccupationQuestion => 'পেশা';

  @override
  String get matrimonyIncomeQuestion => 'বার্ষিক আয় (ঐচ্ছিক)';

  @override
  String get matrimonyFamilyTypeQuestion => 'পরিবারের ধরন';

  @override
  String get matrimonyFamilyValuesQuestion => 'পারিবারিক মূল্যবোধ';

  @override
  String get neverMarried => 'কখনো বিয়ে হয়নি';

  @override
  String get divorced => 'তালাকপ্রাপ্ত';

  @override
  String get widowed => 'বিধবা/বিধুর';

  @override
  String get awaitingDivorce => 'তালাকের অপেক্ষায়';

  @override
  String get nuclear => 'নিউক্লিয়ার';

  @override
  String get joint => 'জয়েন্ট';

  @override
  String get traditional => 'প্রথাগত';

  @override
  String get moderate => 'মধ্যপন্থী';

  @override
  String get liberal => 'উদার';

  @override
  String dynSetupTitle(Object name) {
    return 'চলুন $name-এর প্রোফাইল সেট আপ করি';
  }

  @override
  String dynSetupSubtitle(Object name) {
    return '$name-এর বিবরণ পূরণ করুন। পরে যেকোনো সময় এডিট করতে পারবেন।';
  }

  @override
  String dynName(Object name) {
    return '$name-এর নাম';
  }

  @override
  String get dynNameHintSon => 'যেমন অর্জুন, রাহুল';

  @override
  String get dynNameHintDaughter => 'যেমন প্রিয়া, অনন্যা';

  @override
  String get dynNameHintGeneric => 'পূর্ণ নাম';

  @override
  String dynGender(Object name) {
    return '$name-এর লিঙ্গ';
  }

  @override
  String dynDob(Object name) {
    return '$name-এর জন্ম তারিখ';
  }

  @override
  String dynLocation(Object name) {
    return '$name কোথায় থাকেন?';
  }

  @override
  String dynHometown(Object name) {
    return '$name কোথা থেকে?';
  }

  @override
  String dynAboutTitle(Object name) {
    return '$name-এর সম্পর্কে';
  }

  @override
  String dynAboutHint(Object name) {
    return '$name-এর জন্য গুরুত্বপূর্ণ শেয়ার করুন — কাজ, আগ্রহ, কী খুঁজছেন।';
  }

  @override
  String dynDetailsTitle(Object name) {
    return '$name-এর\nপটভূমি';
  }

  @override
  String dynDetailsSubtitle(Object name) {
    return 'এগুলো $name-এর জন্য সামঞ্জস্যপূর্ণ ম্যাচ খুঁজতে সাহায্য করে।';
  }

  @override
  String dynPrefsTitle(Object name) {
    return '$name-এর জন্য\nপার্টনার পছন্দ';
  }

  @override
  String dynPrefsSubtitle(Object name) {
    return '$name-এর জন্য সঠিক ম্যাচ খুঁজতে সাহায্য করুন।';
  }

  @override
  String dynPhotosSubtitle(Object name) {
    return '$name-এর ফটো যোগ করুন। স্পষ্ট ফেস ফটো ৩x বেশি রেসপন্স পায়।';
  }

  @override
  String get lifestyleTitle => 'লাইফস্টাইল';

  @override
  String get dietQuestion => 'খাদ্যাভ্যাস';

  @override
  String get dietVeg => 'শাকাহারি';

  @override
  String get dietNonVeg => 'মাংশাহারি';

  @override
  String get dietVegan => 'ভেগান';

  @override
  String get dietEggetarian => 'এগেটেরিয়ান';

  @override
  String get dietJain => 'জৈন';

  @override
  String get dietFlexible => 'ফ্লেক্সিবল';

  @override
  String get drinkQuestion => 'মদপান';

  @override
  String get drinkNever => 'কখনো না';

  @override
  String get drinkSocially => 'সামাজিকভাবে';

  @override
  String get drinkRegularly => 'নিয়মিত';

  @override
  String get smokeQuestion => 'ধূমপান';

  @override
  String get smokeNever => 'কখনো না';

  @override
  String get smokeOccasionally => 'মাঝে মাঝে';

  @override
  String get smokeRegularly => 'নিয়মিত';

  @override
  String get exerciseQuestion => 'ব্যায়াম';

  @override
  String get exerciseDaily => 'দৈনিক';

  @override
  String get exerciseRegularly => 'নিয়মিত';

  @override
  String get exerciseSometimes => 'মাঝে মাঝে';

  @override
  String get exerciseRarely => 'বিরল';

  @override
  String get petsQuestion => 'পোষা প্রাণী';

  @override
  String get petsHaveDog => 'কুকুর আছে';

  @override
  String get petsHaveCat => 'বিড়াল আছে';

  @override
  String get petsLoveThem => 'ভালোবাসি';

  @override
  String get petsAllergic => 'অ্যালার্জি';

  @override
  String get petsNone => 'পোষা নেই';

  @override
  String get careerTitle => 'কর্মজীবন';

  @override
  String get companyQuestion => 'কোম্পানি / নিয়োগকর্তা';

  @override
  String get companyHint => 'যেমন Google, TCS, স্ব-নিয়োজিত';

  @override
  String get workLocationQuestion => 'কাজের স্থান';

  @override
  String get workLocationHint => 'যেমন মুম্বই, রিমোট, বিদেশ';

  @override
  String get settledAbroadQuestion => 'বিদেশে সেটেল্ড?';

  @override
  String get settledAbroadYes => 'হ্যাঁ';

  @override
  String get settledAbroadNo => 'না';

  @override
  String get settledAbroadPlanning => 'পরিকল্পনা করছি';

  @override
  String get willingToRelocate => 'রিলোকেট করতে রাজি?';

  @override
  String get relocateYes => 'হ্যাঁ';

  @override
  String get relocateNo => 'না';

  @override
  String get relocateMaybe => 'হয়তো';

  @override
  String get prefDietQuestion => 'খাদ্য পছন্দ';

  @override
  String get prefDrinkQuestion => 'মদ পছন্দ';

  @override
  String get prefSmokeQuestion => 'ধূমপান পছন্দ';

  @override
  String get prefCityQuestion => 'পছন্দের শহর';

  @override
  String get prefCityHint => 'যেমন মুম্বই, ব্যাঙ্গালোর, যেকোনো';

  @override
  String get prefHeightQuestion => 'উচ্চতা রেঞ্জ';

  @override
  String get prefSettledAbroadQuestion => 'বিদেশ সেটেল্ড পছন্দ';

  @override
  String get prefMotherTongueQuestion => 'মাতৃভাষা পছন্দ';

  @override
  String get anyOption => 'যেকোনো';

  @override
  String get modeSwitchCompleteTitle => 'প্রোফাইল সম্পূর্ণ করুন';

  @override
  String get modeSwitchCompleteSubtitle =>
      'ম্যাট্রিমনি মোডে ভালো ম্যাচের জন্য কয়েকটি বিবরণ বেশি লাগে।';

  @override
  String get mandatory => 'অবশ্যক';

  @override
  String get optional => 'ঐচ্ছিক';

  @override
  String get skipForNow => 'এখন বাদ দিন';

  @override
  String get fillLater => 'পরে প্রোফাইল থেকে পূরণ করতে পারবেন।';

  @override
  String get bodyTypeQuestion => 'বডি টাইপ';

  @override
  String get bodyTypeSlim => 'স্লিম';

  @override
  String get bodyTypeAthletic => 'অ্যাথলেটিক';

  @override
  String get bodyTypeAverage => 'গড়';

  @override
  String get bodyTypeHeavy => 'ভারী';

  @override
  String get bodyTypeCurvy => 'কার্ভি';

  @override
  String get heightQuestion => 'উচ্চতা';

  @override
  String get heightHint => 'যেমন 5\'8\" বা 173 cm';

  @override
  String get complexionQuestion => 'গাত্রবর্ণ';

  @override
  String get complexionFair => 'ফরসা';

  @override
  String get complexionWheatish => 'গম ভাতি';

  @override
  String get complexionDark => 'কালো';

  @override
  String get complexionPreferNot => 'বলতে চাই না';

  @override
  String get disabilityQuestion => 'কোনো প্রতিবন্ধকতা?';

  @override
  String get disabilityNone => '없ে';

  @override
  String get disabilityPhysical => 'শারীরিক';

  @override
  String get disabilityPreferNot => 'বলতে চাই না';

  @override
  String get languagesSpoken => 'বলা ভাষা';

  @override
  String get languagesHint => 'যেমন ইংরেজি, হিন্দি, তামিল';

  @override
  String get horoscopeQuestion => 'রাশিফল বিবরণ';

  @override
  String get manglikQuestion => 'মঙ্গলিক?';

  @override
  String get manglikYes => 'হ্যাঁ';

  @override
  String get manglikNo => 'না';

  @override
  String get manglikPartial => 'আংশিক (অংশিক)';

  @override
  String get manglikDontKnow => 'জানি না';

  @override
  String get rashiQuestion => 'রাশি (চন্দ্র রাশি)';

  @override
  String get nakshatraQuestion => 'নক্ষত্র (জন্ম তারা)';

  @override
  String get gotraQuestion => 'গোত্র';

  @override
  String get gotraHint => 'যেমন ভরদ্বাজ, কাশ্যপ';

  @override
  String get physicalTitle => 'শারীরিক';

  @override
  String get backgroundTitle => 'পটভূমি';

  @override
  String get aboutCareer => 'কর্মজীবন সম্পর্কে';

  @override
  String get aboutCareerHint => 'যেমন রোল, অভিজ্ঞতার বছর, কাজে কী ভালো লাগে';

  @override
  String get aboutEducation => 'শিক্ষা সম্পর্কে';

  @override
  String get aboutEducationHint =>
      'যেমন ডিগ্রি, প্রতিষ্ঠান, সার্টিফিকেশন (CFA ইত্যাদি)';

  @override
  String get sectorQuestion => 'সেক্টর';

  @override
  String get sectorPrivate => 'প্রাইভেট';

  @override
  String get sectorGovernment => 'সরকারি';

  @override
  String get sectorPSU => 'PSU';

  @override
  String get sectorBusiness => 'বিজনেস / স্ব-নিয়োজিত';

  @override
  String get sectorOther => 'অন্যান্য';

  @override
  String get familyLocationQuestion => 'পরিবার কোথায়';

  @override
  String get familyLocationHint => 'যেমন ভিলাই, মুম্বই';

  @override
  String get householdIncomeQuestion => 'গৃহস্থ আয়';

  @override
  String get motherOccupationQuestion => 'মায়ের পেশা';

  @override
  String get motherOccupationHint => 'যেমন গৃহিণী, শিক্ষিকা';

  @override
  String get fatherOccupationQuestion => 'বাবার পেশা';

  @override
  String get fatherOccupationHint => 'যেমন Govt. কর্মচারী, বিজনেস';

  @override
  String get motherAgeQuestion => 'মায়ের বয়স';

  @override
  String get fatherAgeQuestion => 'বাবার বয়স';

  @override
  String get siblingsQuestion => 'ভাইবোন';

  @override
  String get siblingsHint => 'যেমন ১ ভাই (বিবাহিত), ১ বোন (অবিবাহিত)';

  @override
  String get siblingsBrothers => 'ভাই';

  @override
  String get siblingsSisters => 'বোন';

  @override
  String get birthTimeQuestion => 'জন্ম সময়';

  @override
  String get birthTimeHint => 'যেমন 11:00 AM (রাশিফলের জন্য)';

  @override
  String get birthPlaceQuestion => 'জন্ম স্থান';

  @override
  String get birthPlaceHint => 'যেমন ভিলাই, ছত্তিশগড়';

  @override
  String get prefCountryQuestion => 'পছন্দের দেশ';

  @override
  String get prefCountryHint => 'যেমন ভারত, UAE, UK, যেকোনো';

  @override
  String get strictMatchLabel => 'স্ট্রিক্ট (শুধু এটির সাথে ম্যাচ দেখান)';

  @override
  String get locationRequiredTitle => 'লোকেশন দরকার';

  @override
  String get locationRequiredMessage =>
      'সম্প্রদায় নিরাপদ রাখতে ও প্রোফাইল কোথায় তৈরি রেকর্ড করতে saathi-র আপনার লোকেশন দরকার। শুধু নিরাপত্তা ও সাপোর্ট—আপনার সম্মতি ছাড়া শেয়ার না।';

  @override
  String get locationAllow => 'লোকেশন অনুমতি দিন';

  @override
  String get locationOpenSettings => 'সেটিংস খুলুন';

  @override
  String get locationServiceDisabled =>
      'চালিয়ে যেতে ডিভাইস সেটিংসে লোকেশন চালু করুন।';

  @override
  String get locationPermissionDenied =>
      'লোকেশন এক্সেস প্রত্যাখ্যান। অ্যাপ ব্যবহার করতে সেটিংসে চালু করুন।';

  @override
  String get profileCreationLocationError =>
      'প্রোফাইল তৈরি করতে (নিরাপত্তা ও সাপোর্ট) আপনার লোকেশন দরকার। লোকেশন অনুমতি দিয়ে আবার চেষ্টা করুন।';

  @override
  String get emptyStateGeneric => 'এখনও এখানে কিছু নেই';

  @override
  String get errorGeneric => 'কিছু ভুল হয়েছে';

  @override
  String get loading => 'লোড হচ্ছে';

  @override
  String get toastInterestSent => 'আগ্রহ পাঠানো হয়েছে';

  @override
  String toastInterestSentTo(Object name) {
    return 'আগ্রহ $name-কে পাঠানো হয়েছে';
  }

  @override
  String get toastAddedToShortlist => 'শর্টলিস্টে যোগ হয়েছে';

  @override
  String get toastRemovedFromShortlist => 'শর্টলিস্ট থেকে সরানো হয়েছে';

  @override
  String toastMatchWith(Object name) {
    return '$name-এর সাথে ম্যাচ!';
  }

  @override
  String toastBlocked(Object name) {
    return '$name ব্লক হয়েছে';
  }

  @override
  String get toastReportSubmitted => 'রিপোর্ট জমা। ধন্যবাদ।';

  @override
  String get toastErrorGeneric => 'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get activeNow => 'এখন সক্রিয়';

  @override
  String get verified => 'যাচাইকৃত';

  @override
  String managedBy(Object role) {
    return 'পরিচালক: $role';
  }

  @override
  String get lastActive => 'সর্বশেষ সক্রিয়';

  @override
  String kmAway(Object distance) {
    return '$distance কিমি দূরে';
  }

  @override
  String get ageRange => 'বয়সের পরিসর';

  @override
  String get distance => 'দূরত্ব';

  @override
  String get city => 'শহর';

  @override
  String get religion => 'ধর্ম';

  @override
  String get motherTongue => 'মাতৃভাষা';

  @override
  String get maritalStatus => 'বৈবাহিক অবস্থা';

  @override
  String get height => 'উচ্চতা';

  @override
  String get educationLevel => 'শিক্ষা';

  @override
  String get occupation => 'পেশা';

  @override
  String get income => 'আয়';

  @override
  String get diet => 'খাদ্যাভ্যাস';

  @override
  String get familyType => 'পরিবারের ধরন';

  @override
  String get familyValues => 'পারিবারিক মূল্যবোধ';

  @override
  String get appLanguage => 'অ্যাপ ভাষা';

  @override
  String get chooseAppLanguage => 'অ্যাপ ভাষা নির্বাচন করুন';

  @override
  String languageSetTo(Object name) {
    return 'ভাষা $name-এ সেট করা হয়েছে';
  }

  @override
  String get saathiMode => 'saathi মোড';

  @override
  String get accountAndData => 'অ্যাকাউন্ট ও ডেটা';

  @override
  String get viewProfile => 'প্রোফাইল দেখুন';

  @override
  String get downloadMyData => 'আমার ডেটা ডাউনলোড করুন';

  @override
  String get requestDataCopy => 'আপনার ডেটার কপি অনুরোধ করুন';

  @override
  String get deactivateAccount => 'অ্যাকাউন্ট নিষ্ক্রিয় করুন';

  @override
  String get deactivateAccountSubtitle =>
      'অস্থায়ীভাবে অ্যাকাউন্ট নিষ্ক্রিয় করুন';

  @override
  String get deleteAccount => 'অ্যাকাউন্ট মুছুন';

  @override
  String get deleteAccountSubtitle => 'অ্যাকাউন্ট স্থায়ীভাবে মুছুন';

  @override
  String get boostProfile => 'প্রোফাইল বুস্ট করুন';

  @override
  String get appearMoreInDiscovery => 'অন্বেষণে আরও দেখান';

  @override
  String get verificationSubtitle => 'আইডি, ফটো, লিংকডইন';

  @override
  String get blockedUsers => 'ব্লক করা ব্যবহারকারী';

  @override
  String get blockedUsersSubtitle => 'যাদের ব্লক করেছেন দেখুন ও আনব্লক করুন';

  @override
  String get showInVisitors => 'দর্শকদের মধ্যে দেখান';

  @override
  String get whoCanSeeMyProfile => 'কে আমার প্রোফাইল দেখতে পারবে';

  @override
  String get everyone => 'সবাই';

  @override
  String get onlyMyMatches => 'শুধু আমার ম্যাচ';

  @override
  String get onlyAfterInterest => 'শুধু আগ্রহের পর';

  @override
  String get hideFromDiscovery => 'অন্বেষণ থেকে লুকান';

  @override
  String get privacySettingsSaved => 'গোপনীয়তা সেটিংস সংরক্ষিত';

  @override
  String switchToMode(Object mode) {
    return '$mode-এ পরিবর্তন করবেন?';
  }

  @override
  String switchToModeLabel(Object mode) {
    return '$mode-এ পরিবর্তন করুন';
  }

  @override
  String get switchButton => 'পরিবর্তন';

  @override
  String get requestFailedTryAgain => 'অনুরোধ ব্যর্থ। পরে আবার চেষ্টা করুন।';

  @override
  String get deactivateAccountConfirm => 'অ্যাকাউন্ট নিষ্ক্রিয় করবেন?';

  @override
  String get deactivationFailed => 'নিষ্ক্রিয়করণ ব্যর্থ। আবার চেষ্টা করুন।';

  @override
  String get deactivate => 'নিষ্ক্রিয় করুন';

  @override
  String get deleteAccountConfirm => 'অ্যাকাউন্ট স্থায়ীভাবে মুছবেন?';

  @override
  String get deleteFailed => 'মুছে ফেলা ব্যর্থ। আবার চেষ্টা করুন।';

  @override
  String get deletePermanently => 'স্থায়ীভাবে মুছুন';

  @override
  String get notificationPreferencesSaved => 'বিজ্ঞপ্তি পছন্দ সংরক্ষিত';

  @override
  String get noFcmToken => 'FCM টোকেন নেই (অনুমতি পরীক্ষা করুন)';

  @override
  String get copyFcmToken => 'FCM টোকেন কপি করুন';

  @override
  String get linkCopied => 'লিংক কপি হয়েছে';

  @override
  String errorLoadingProfile(Object error) {
    return 'প্রোফাইল লোড করতে ত্রুটি: $error';
  }

  @override
  String get noProfileYet => 'এখনও প্রোফাইল নেই';

  @override
  String get createProfile => 'প্রোফাইল তৈরি করুন';

  @override
  String get basicDetails => 'মৌলিক বিবরণ';

  @override
  String get religionAndCommunity => 'ধর্ম ও সম্প্রদায়';

  @override
  String get physicalAttributes => 'শারীরিক বৈশিষ্ট্য';

  @override
  String get educationAndCareer => 'শিক্ষা ও কর্মজীবন';

  @override
  String get lifestyleAndHabits => 'লাইফস্টাইল ও অভ্যাস';

  @override
  String get interestsAndHobbiesSection => 'আগ্রহ ও শখ';

  @override
  String get familySection => 'পরিবার';

  @override
  String get horoscopeSection => 'রাশিফল';

  @override
  String get aboutMeSection => 'আমার সম্পর্কে';

  @override
  String get partnerPreferencesSection => 'পার্টনার পছন্দ';

  @override
  String get photosSection => 'ফটো';

  @override
  String get languagesLabel => 'ভাষা';

  @override
  String get locationLabel => 'অবস্থান';

  @override
  String get originLabel => 'উৎপত্তি';

  @override
  String get degreeLabel => 'ডিগ্রি';

  @override
  String get institutionLabel => 'প্রতিষ্ঠান';

  @override
  String get yearOfGraduation => 'স্নাতক বছর';

  @override
  String get gradeClassification => 'গ্রেড / শ্রেণিবিন্যাস';

  @override
  String get employer => 'নিয়োগকর্তা';

  @override
  String get industry => 'শিল্প';

  @override
  String get communityLabel => 'সম্প্রদায়';

  @override
  String get educationAndCareerTitle => 'শিক্ষা ও কর্মজীবন';

  @override
  String get familyTitle => 'পরিবার';

  @override
  String get lifestyleTitleSection => 'লাইফস্টাইল';

  @override
  String get horoscopeTitle => 'রাশিফল';

  @override
  String get lookingForTitle => 'খুঁজছি';

  @override
  String get requestAgain => 'আবার অনুরোধ করুন';

  @override
  String get requestContact => 'যোগাযোগ অনুরোধ করুন';

  @override
  String get contactRequestSent => 'যোগাযোগ অনুরোধ পাঠানো হয়েছে';

  @override
  String couldNotSendRequest(Object error) {
    return 'অনুরোধ পাঠানো যায়নি: $error';
  }

  @override
  String get call => 'কল';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get contactShared =>
      'যোগাযোগ শেয়ার করা হয়েছে। এখন তারা কল বা মেসেজ করতে পারবে।';

  @override
  String couldNotAccept(Object error) {
    return 'গ্রহণ করা যায়নি: $error';
  }

  @override
  String get requestDeclined => 'অনুরোধ প্রত্যাখ্যান';

  @override
  String couldNotDecline(Object error) {
    return 'প্রত্যাখ্যান করা যায়নি: $error';
  }

  @override
  String get interested => 'আগ্রহী';

  @override
  String get priorityInterest => 'অগ্রাধিকার আগ্রহ';

  @override
  String get withdrawInterest => 'আগ্রহ প্রত্যাহার';

  @override
  String get declineRequest => 'অনুরোধ প্রত্যাখ্যান করুন';

  @override
  String get noContactRequests => 'কোনো যোগাযোগ অনুরোধ নেই';

  @override
  String get upgrade => 'আপগ্রেড';

  @override
  String get failedToSendTryAgain => 'পাঠানো ব্যর্থ। আবার চেষ্টা করুন।';

  @override
  String get blockUserConfirm => 'ব্যবহারকারী ব্লক করবেন?';

  @override
  String get reportUser => 'ব্যবহারকারী রিপোর্ট করুন';

  @override
  String get reportUserConfirm => 'ব্যবহারকারী রিপোর্ট করবেন?';

  @override
  String reportUserMessage(Object name) {
    return '$name-কে অনুচিত আচরণের জন্য রিপোর্ট করবেন?';
  }

  @override
  String get reportSubmittedThankYou => 'রিপোর্ট জমা দেওয়া হয়েছে। ধন্যবাদ।';

  @override
  String get changeCity => 'শহর পরিবর্তন করুন';

  @override
  String get yourArea => 'আপনার অঞ্চল';

  @override
  String get showProfilesNearYou => 'কাছের প্রোফাইল দেখান';

  @override
  String unblocked(Object name) {
    return '$name আনব্লক হয়েছে';
  }

  @override
  String get somethingWentWrong => 'কিছু ভুল হয়েছে';

  @override
  String get whyBlocking => 'কেন ব্লক করছেন?';

  @override
  String get whyReporting => 'কেন রিপোর্ট করছেন?';

  @override
  String get blockedUsersScreenTitle => 'ব্লক করা ব্যবহারকারী';

  @override
  String get unblock => 'আনব্লক করুন';

  @override
  String get noConversationsYet => 'এখনও কোনো আলোচনা নেই';

  @override
  String get noChatRequests => 'কোনো চ্যাট অনুরোধ নেই';

  @override
  String get priority => 'অগ্রাধিকার';

  @override
  String yrs(Object age) {
    return '$age বছর';
  }

  @override
  String get idVerificationSubtitle =>
      'সরকারি আইডি আপলোড করুন। আমরা আপনার ফটোর সাথে মিলিয়ে দেব।';

  @override
  String get faceMatchSubtitle => 'সেলফি আপনার আইডি ফটোর সাথে মিলেছে।';

  @override
  String get linkedInSubtitle => 'কাজ যাচাই করতে LinkedIn সংযুক্ত করুন।';

  @override
  String get educationSubtitle => 'বিশ্ববিদ্যালয় বা কলেজ যাচাই করুন।';

  @override
  String verificationComingSoon(Object feature) {
    return '$feature যাচাই শীঘ্রই আসছে';
  }

  @override
  String get uploadUrlNotAvailable => 'আপলোড URL উপলব্ধ নেই';

  @override
  String uploadFailed(Object code) {
    return 'আপলোড ব্যর্থ: $code';
  }

  @override
  String get idSubmittedNotify => 'আইডি জমা হয়েছে। যাচাই সম্পূর্ণ হলে জানাব।';

  @override
  String uploadFailedError(Object error) {
    return 'ব্যর্থ: $error';
  }

  @override
  String get chooseFile => 'ফাইল নির্বাচন করুন';

  @override
  String get photoVerification => 'ফটো যাচাই';

  @override
  String get startVerification => 'যাচাই শুরু করুন';

  @override
  String get takePhoto => 'ফটো তোলুন';

  @override
  String get imReady => 'আমি প্রস্তুত';

  @override
  String get simulateSuccess => 'সাফল্য সিমুলেট করুন';

  @override
  String get tryAgain => 'আবার চেষ্টা করুন';

  @override
  String get subscriptionActivated => 'সাবস্ক্রিপশন সক্রিয়!';

  @override
  String purchaseFailed(Object error) {
    return 'ক্রয় ব্যর্থ: $error';
  }

  @override
  String get purchasesRestored => 'ক্রয় পুনরুদ্ধার হয়েছে!';

  @override
  String get noActivePurchases => 'কোনো সক্রিয় ক্রয় নেই।';

  @override
  String get couldNotRestorePurchases => 'ক্রয় পুনরুদ্ধার করা যায়নি।';

  @override
  String get boostPack => 'বুস্ট প্যাক';

  @override
  String get mostRecent => 'সর্বশেষ';

  @override
  String get mostInterested => 'সবচেয়ে আগ্রহী';

  @override
  String get note => 'নোট';

  @override
  String get noMatchesYet => 'এখনও কোনো ম্যাচ নেই';

  @override
  String get sendYourNote => 'আপনার নোট পাঠান';

  @override
  String get savedSearches => 'সংরক্ষিত খোঁজ';

  @override
  String get searchSaved => 'খোঁজ সংরক্ষিত';

  @override
  String get couldNotSaveSearch => 'খোঁজ সংরক্ষণ করা যায়নি';

  @override
  String get saveSearch => 'খোঁজ সংরক্ষণ করুন';

  @override
  String get preferredLanguage => 'পছন্দের ভাষা';

  @override
  String get preferredLanguageSubtitle =>
      'ঐচ্ছিক — কন্টেন্ট ও ম্যাচের জন্য ব্যবহার করা হবে।';

  @override
  String get mapFilters => 'ম্যাপ ফিল্টার';

  @override
  String get join => 'যোগ দিন';

  @override
  String get rsvp => 'RSVP';

  @override
  String rsvpdTo(Object title) {
    return '$title-এ RSVP করা হয়েছে';
  }

  @override
  String get confirm => 'নিশ্চিত করুন';

  @override
  String get reset => 'রিসেট';

  @override
  String get shellRequiresProvider => 'Shell-এর জন্য Provider প্রয়োজন';

  @override
  String get add => 'যোগ করুন';

  @override
  String get conversationStarter => 'কথোপকথন সূচক';

  @override
  String switchToModeBody(Object mode) {
    return 'আপনার প্রোফাইল তথ্য শেয়ার করা আছে। আপনি যেকোনো সময় $mode-সংক্রান্ত বিবরণ পূরণ বা আপডেট করতে পারবেন।';
  }

  @override
  String get exportRequested =>
      'রপ্তানির অনুরোধ করা হয়েছে। প্রস্তুত হলে ইমেল করব।';

  @override
  String get deactivateAccountConfirmBody =>
      'আপনার প্রোফাইল লুকানো থাকবে এবং ম্যাচ বা মেসেজ পাবেন না। পরে আবার সক্রিয় করতে পারবেন।';

  @override
  String get deleteAccountConfirmBody =>
      'এটি পূর্বাবস্থায় ফেরানো যাবে না। আপনার সব ডেটা স্থায়ীভাবে মুছে যাবে।';

  @override
  String get showInVisitorsSubtitle =>
      'বন্ধ থাকলেও আপনার ভিজিট রেকর্ড থাকবে কিন্তু অন্যদের তালিকায় দেখা যাবে না';

  @override
  String get hideFromDiscoverySubtitle =>
      'অন্বেষণ ও সুপারিশ থেকে অস্থায়ীভাবে প্রোফাইল লুকান';

  @override
  String get hideMyPhotos => 'আমার ফটো লুকান';

  @override
  String get hideMyPhotosSubtitle =>
      'অন্যরা আপনার ফটো দেখতে অনুরোধ করবে; আপনি অনুরোধে অনুমোদন বা প্রত্যাখ্যান করবেন।';

  @override
  String get requestToViewPhotos => 'ফটো দেখার অনুরোধ করুন';

  @override
  String get requestToViewPhotosSent => 'অনুরোধ পাঠানো হয়েছে';

  @override
  String get photoViewRequestPending => 'অনুরোধ মুলতুবি';

  @override
  String get requestedToViewYourPhotos => 'আপনার ফটো দেখার অনুরোধ করেছেন';

  @override
  String get noPhotoViewRequests => 'কোনো ফটো দেখার অনুরোধ নেই';

  @override
  String get noPhotoViewRequestsBody =>
      'কেউ আপনার ফটো দেখার অনুরোধ করলে আপনি এখানে অনুমোদন বা প্রত্যাখ্যান করতে পারবেন।';

  @override
  String get photoViewRequestAccepted => 'এখন তারা আপনার ফটো দেখতে পারবে।';

  @override
  String get photoViewRequestsTab => 'ফটো দেখার অনুরোধ';

  @override
  String get photosLocked => 'ফটো ব্যক্তিগত';

  @override
  String get photosLockedHint => 'তাদের ফটো দেখতে অ্যাক্সেসের অনুরোধ করুন';

  @override
  String blockUserMessage(Object name) {
    return '$name আপনার প্রোফাইল দেখতে বা যোগাযোগ করতে পারবে না।';
  }

  @override
  String get yourProfile => 'আপনার প্রোফাইল';

  @override
  String get aboutYouShort => 'আপনার সম্পর্কে কয়েক লাইন';

  @override
  String get recordYourIntro => 'আপনার পরিচয় রেকর্ড করুন';

  @override
  String get heritageType => 'ঐতিহ্য / ভারতীয় ধরন';

  @override
  String get communityTagsOptional => 'সম্প্রদায় ট্যাগ (ঐচ্ছিক)';

  @override
  String get communityTagsSubtitle =>
      'প্রযোজ্য যেকোনো নির্বাচন করুন — বৃত্ত ও ইভেন্টে সাহায্য করে।';

  @override
  String get familyOrientation => 'পরিবার অভিমুখিতা';

  @override
  String get familyOrientationSubtitle =>
      'আপনার পছন্দ জানাতে স্লাইড করুন — ভুল উত্তর নেই।';

  @override
  String get traditionalLabel => 'প্রথাগত';

  @override
  String get progressiveLabel => 'প্রগতিশীল';

  @override
  String get dietLifestyleTitle => 'খাদ্য / লাইফস্টাইল';

  @override
  String get dietLifestyleSubtitle => 'ডেট আইডিয়া ও ফিল্টারে সাহায্য করে।';

  @override
  String get activeNowOnly => 'শুধু এখন সক্রিয়';

  @override
  String get activeNowOnlySubtitle => 'গত ২৪ ঘণ্টায় সক্রিয় ব্যক্তিদেরই দেখান';

  @override
  String get locationBlur => 'অবস্থান ঝাপসা';

  @override
  String get locationBlurSubtitle => 'সঠিক পিনের বদলে আনুমানিক অঞ্চল দেখান';

  @override
  String get verificationTitle => 'যাচাই';

  @override
  String get feetUnit => 'ফুট';

  @override
  String get inchesUnit => 'ইঞ্চি';

  @override
  String get clearButton => '—';

  @override
  String yearsFormat(Object age) {
    return '$age বছর';
  }

  @override
  String get profileManagedByParent => 'প্রোফাইল অভিভাবক দ্বারা পরিচালিত';

  @override
  String get profileManagedByGuardian => 'প্রোফাইল অভিভাবক দ্বারা পরিচালিত';

  @override
  String get profileManagedBySibling => 'প্রোফাইল ভাইবোন দ্বারা পরিচালিত';

  @override
  String get profileManagedByFriend => 'প্রোফাইল বন্ধু দ্বারা পরিচালিত';

  @override
  String get blockUserMessageChat =>
      'তারা আর আপনার সাথে যোগাযোগ করতে পারবে না।';

  @override
  String get reportUserMessageChat =>
      'আমরা নিরাপত্তা গুরুত্ব সহকারে নিই এবং এই রিপোর্ট পর্যালোচনা করব।';

  @override
  String get blockUser => 'ব্যবহারকারী ব্লক করুন';

  @override
  String get matchToContinueOrUpgrade =>
      'চালিয়ে যেতে বা আপগ্রেড করতে ম্যাচ করুন';

  @override
  String get noConversationsYetBody =>
      'কাউকে ম্যাচ করলে আপনার চ্যাট এখানে দেখা যাবে।';

  @override
  String get noChatRequestsBody =>
      'কেউ আগ্রহ পাঠালে এখানে গ্রহণ করে চ্যাট শুরু করতে পারবেন।';

  @override
  String get noContactRequestsBody =>
      'কেউ আপনার যোগাযোগ চাইলে এখানে গ্রহণ বা প্রত্যাখ্যান করতে পারবেন।';

  @override
  String get requestedYourContact => 'আপনার যোগাযোগ চেয়েছে';

  @override
  String get withdrawPriority => 'অগ্রাধিকার প্রত্যাহার';

  @override
  String get withdrawPriorityAndInterest => 'অগ্রাধিকার (ও আগ্রহ) প্রত্যাহার';

  @override
  String get additionalDetailsOptional => 'অতিরিক্ত বিবরণ (ঐচ্ছিক)';

  @override
  String get reportDetailsHint =>
      'আমাদের টিমের সাহায্য হতে পারে এমন কোনো প্রসঙ্গ যোগ করুন';
}
