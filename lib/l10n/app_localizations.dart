import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('pa'),
    Locale('ta'),
    Locale('te'),
    Locale('ur'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DesiLink'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Sophisticated connections, globally.'**
  String get appTagline;

  /// No description provided for @appTaglineDating.
  ///
  /// In en, this message translates to:
  /// **'Depth-first connections. No mindless swiping.'**
  String get appTaglineDating;

  /// No description provided for @appTaglineMatrimony.
  ///
  /// In en, this message translates to:
  /// **'Serious about marriage. Meaningful profiles.'**
  String get appTaglineMatrimony;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'DesiLink'**
  String get loginTitle;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Sophisticated connections, globally.'**
  String get loginTagline;

  /// No description provided for @signUpWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Sign up with your phone number'**
  String get signUpWithPhone;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @termsConsent.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms and Privacy Policy.'**
  String get termsConsent;

  /// No description provided for @verifyYourNumber.
  ///
  /// In en, this message translates to:
  /// **'Verify your number'**
  String get verifyYourNumber;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get enterOtp;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification code to {phone}. Enter it below to continue.'**
  String otpSentTo(Object phone);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & continue'**
  String get verifyAndContinue;

  /// No description provided for @modeSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'What are you here for?'**
  String get modeSelectTitle;

  /// No description provided for @modeDating.
  ///
  /// In en, this message translates to:
  /// **'Dating'**
  String get modeDating;

  /// No description provided for @modeDatingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Meet people. Depth-first profiles, discovery, and meaningful connections.'**
  String get modeDatingSubtitle;

  /// No description provided for @modeMatrimony.
  ///
  /// In en, this message translates to:
  /// **'Matrimony'**
  String get modeMatrimony;

  /// No description provided for @modeMatrimonySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find a life partner. Extended profiles, partner preferences, and family-friendly matching.'**
  String get modeMatrimonySubtitle;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get navChats;

  /// No description provided for @navCommunities.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get navCommunities;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get navMatches;

  /// No description provided for @navRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get navRequests;

  /// No description provided for @navShortlist.
  ///
  /// In en, this message translates to:
  /// **'Shortlist'**
  String get navShortlist;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @dailyCuratedSet.
  ///
  /// In en, this message translates to:
  /// **'Daily curated set'**
  String get dailyCuratedSet;

  /// No description provided for @exploreCity.
  ///
  /// In en, this message translates to:
  /// **'Explore {city}'**
  String exploreCity(Object city);

  /// No description provided for @travelModeHint.
  ///
  /// In en, this message translates to:
  /// **'Travel mode: seeing profiles in your saved cities'**
  String get travelModeHint;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filtersPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Age range, distance, intent, etc.'**
  String get filtersPlaceholder;

  /// No description provided for @ctaSendIntro.
  ///
  /// In en, this message translates to:
  /// **'Send Thoughtful Intro'**
  String get ctaSendIntro;

  /// No description provided for @ctaSendInterest.
  ///
  /// In en, this message translates to:
  /// **'Express Interest'**
  String get ctaSendInterest;

  /// No description provided for @ctaShortlist.
  ///
  /// In en, this message translates to:
  /// **'Shortlist'**
  String get ctaShortlist;

  /// No description provided for @ctaRequestContact.
  ///
  /// In en, this message translates to:
  /// **'Request Contact'**
  String get ctaRequestContact;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @viewFullProfile.
  ///
  /// In en, this message translates to:
  /// **'View full profile'**
  String get viewFullProfile;

  /// No description provided for @matchesRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get matchesRecommended;

  /// No description provided for @matchesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get matchesSearch;

  /// No description provided for @matchesNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get matchesNearby;

  /// No description provided for @recommendedCopy.
  ///
  /// In en, this message translates to:
  /// **'Recommended based on your preferences'**
  String get recommendedCopy;

  /// No description provided for @whyMatch.
  ///
  /// In en, this message translates to:
  /// **'Why this match'**
  String get whyMatch;

  /// No description provided for @requestsReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get requestsReceived;

  /// No description provided for @requestsSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get requestsSent;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @requestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get requestsEmpty;

  /// No description provided for @requestsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'When someone sends you an interest, it will appear here.'**
  String get requestsEmptyHint;

  /// No description provided for @shortlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Shortlist'**
  String get shortlistTitle;

  /// No description provided for @shortlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'No profiles in shortlist'**
  String get shortlistEmpty;

  /// No description provided for @shortlistEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Shortlist profiles you like to review later.'**
  String get shortlistEmptyHint;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileSettings;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @tapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit'**
  String get tapToEdit;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @interests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interests;

  /// No description provided for @prompt.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get prompt;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @trustCenter.
  ///
  /// In en, this message translates to:
  /// **'Trust Center'**
  String get trustCenter;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @privacyAndSafety.
  ///
  /// In en, this message translates to:
  /// **'Privacy & safety'**
  String get privacyAndSafety;

  /// No description provided for @helpCentre.
  ///
  /// In en, this message translates to:
  /// **'Help centre'**
  String get helpCentre;

  /// No description provided for @termsAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy'**
  String get termsAndPrivacy;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @profileBuilderPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get profileBuilderPhotos;

  /// No description provided for @profileBuilderAbout.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get profileBuilderAbout;

  /// No description provided for @profileBuilderBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic details'**
  String get profileBuilderBasic;

  /// No description provided for @profileBuilderLifestyle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get profileBuilderLifestyle;

  /// No description provided for @profileBuilderPrompts.
  ///
  /// In en, this message translates to:
  /// **'Prompts & voice'**
  String get profileBuilderPrompts;

  /// No description provided for @profileBuilderEducation.
  ///
  /// In en, this message translates to:
  /// **'Education & work'**
  String get profileBuilderEducation;

  /// No description provided for @profileBuilderFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get profileBuilderFamily;

  /// No description provided for @profileBuilderPartnerPrefs.
  ///
  /// In en, this message translates to:
  /// **'Partner preferences'**
  String get profileBuilderPartnerPrefs;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile — {percent}%'**
  String completeProfile(Object percent);

  /// No description provided for @onboardingStepBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic info'**
  String get onboardingStepBasic;

  /// No description provided for @onboardingStepPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get onboardingStepPreferences;

  /// No description provided for @onboardingStepExtended.
  ///
  /// In en, this message translates to:
  /// **'More about you'**
  String get onboardingStepExtended;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Priya, Arjun'**
  String get nameHint;

  /// No description provided for @aboutYou.
  ///
  /// In en, this message translates to:
  /// **'A few lines about you'**
  String get aboutYou;

  /// No description provided for @aboutYouHint.
  ///
  /// In en, this message translates to:
  /// **'Share what matters to you — work, interests, what you\'re looking for.'**
  String get aboutYouHint;

  /// No description provided for @lookingForDating.
  ///
  /// In en, this message translates to:
  /// **'I\'m looking for'**
  String get lookingForDating;

  /// No description provided for @creatingProfileFor.
  ///
  /// In en, this message translates to:
  /// **'I\'m creating this profile for'**
  String get creatingProfileFor;

  /// No description provided for @self.
  ///
  /// In en, this message translates to:
  /// **'Self'**
  String get self;

  /// No description provided for @parent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parent;

  /// No description provided for @guardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get guardian;

  /// No description provided for @sibling.
  ///
  /// In en, this message translates to:
  /// **'Sibling'**
  String get sibling;

  /// No description provided for @friend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friend;

  /// No description provided for @lookingForBride.
  ///
  /// In en, this message translates to:
  /// **'Bride'**
  String get lookingForBride;

  /// No description provided for @lookingForGroom.
  ///
  /// In en, this message translates to:
  /// **'Groom'**
  String get lookingForGroom;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock more with DesiLink'**
  String get paywallTitle;

  /// No description provided for @paywallDatingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for global discovery and priority.'**
  String get paywallDatingSubtitle;

  /// No description provided for @paywallMatrimonySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock contact details and featured listing.'**
  String get paywallMatrimonySubtitle;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get mostPopular;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @benefitUnlimitedIntros.
  ///
  /// In en, this message translates to:
  /// **'Unlimited intros'**
  String get benefitUnlimitedIntros;

  /// No description provided for @benefitSeeWhoLikes.
  ///
  /// In en, this message translates to:
  /// **'See who likes you'**
  String get benefitSeeWhoLikes;

  /// No description provided for @benefitTravelMode.
  ///
  /// In en, this message translates to:
  /// **'Travel mode: explore other cities'**
  String get benefitTravelMode;

  /// No description provided for @benefitPriorityDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Priority in discovery'**
  String get benefitPriorityDiscovery;

  /// No description provided for @benefitReadReceipts.
  ///
  /// In en, this message translates to:
  /// **'Read receipts'**
  String get benefitReadReceipts;

  /// No description provided for @benefitUnlimitedInterests.
  ///
  /// In en, this message translates to:
  /// **'Unlimited interests'**
  String get benefitUnlimitedInterests;

  /// No description provided for @benefitSeeWhoViewed.
  ///
  /// In en, this message translates to:
  /// **'See who viewed you'**
  String get benefitSeeWhoViewed;

  /// No description provided for @benefitUnlockContact.
  ///
  /// In en, this message translates to:
  /// **'Unlock contact details'**
  String get benefitUnlockContact;

  /// No description provided for @benefitFeaturedProfile.
  ///
  /// In en, this message translates to:
  /// **'Featured profile / priority listing'**
  String get benefitFeaturedProfile;

  /// No description provided for @benefitAdvancedFilters.
  ///
  /// In en, this message translates to:
  /// **'Advanced filters'**
  String get benefitAdvancedFilters;

  /// No description provided for @verifyPriority.
  ///
  /// In en, this message translates to:
  /// **'Verify to Get Priority'**
  String get verifyPriority;

  /// No description provided for @verifiedProfilesGetMore.
  ///
  /// In en, this message translates to:
  /// **'Verified profiles get more trust and responses.'**
  String get verifiedProfilesGetMore;

  /// No description provided for @idVerification.
  ///
  /// In en, this message translates to:
  /// **'ID verification'**
  String get idVerification;

  /// No description provided for @faceMatch.
  ///
  /// In en, this message translates to:
  /// **'Face match'**
  String get faceMatch;

  /// No description provided for @linkedIn.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get linkedIn;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @safetyScore.
  ///
  /// In en, this message translates to:
  /// **'Safety score'**
  String get safetyScore;

  /// No description provided for @uploadIdHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear photo of your passport or driving licence.'**
  String get uploadIdHint;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get inviteFriends;

  /// No description provided for @inviteCopy.
  ///
  /// In en, this message translates to:
  /// **'Give friends a better way to connect'**
  String get inviteCopy;

  /// No description provided for @inviteReward.
  ///
  /// In en, this message translates to:
  /// **'Share your invite code or link. When they join, you both get a reward.'**
  String get inviteReward;

  /// No description provided for @yourInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Your invite code'**
  String get yourInviteCode;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @shareVia.
  ///
  /// In en, this message translates to:
  /// **'Share via'**
  String get shareVia;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @loginHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your\nperson'**
  String get loginHeroTitle;

  /// No description provided for @loginHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Meaningful connections for the Indian diaspora, worldwide.'**
  String get loginHeroSubtitle;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @ageConfirmation.
  ///
  /// In en, this message translates to:
  /// **'I confirm I am 18 years or older'**
  String get ageConfirmation;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your\nphone'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to'**
  String get otpSubtitle;

  /// No description provided for @otpDidntReceive.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive it?'**
  String get otpDidntReceive;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String otpResendIn(Object seconds);

  /// No description provided for @modeSelectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you\'d like to use DesiLink. You can switch anytime from settings.'**
  String get modeSelectSubtitle;

  /// No description provided for @modeSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'You can switch anytime in Settings.'**
  String get modeSwitchHint;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up\nyour profile'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Takes about 2 minutes. You can always edit later.'**
  String get profileSetupSubtitle;

  /// No description provided for @profileCreatingFor.
  ///
  /// In en, this message translates to:
  /// **'This profile is for'**
  String get profileCreatingFor;

  /// No description provided for @profileCreatingForSelf.
  ///
  /// In en, this message translates to:
  /// **'Myself'**
  String get profileCreatingForSelf;

  /// No description provided for @profileCreatingForSon.
  ///
  /// In en, this message translates to:
  /// **'My Son'**
  String get profileCreatingForSon;

  /// No description provided for @profileCreatingForDaughter.
  ///
  /// In en, this message translates to:
  /// **'My Daughter'**
  String get profileCreatingForDaughter;

  /// No description provided for @profileCreatingForBrother.
  ///
  /// In en, this message translates to:
  /// **'My Brother'**
  String get profileCreatingForBrother;

  /// No description provided for @profileCreatingForSister.
  ///
  /// In en, this message translates to:
  /// **'My Sister'**
  String get profileCreatingForSister;

  /// No description provided for @profileCreatingForFriend.
  ///
  /// In en, this message translates to:
  /// **'A Friend'**
  String get profileCreatingForFriend;

  /// No description provided for @profileCreatingForRelative.
  ///
  /// In en, this message translates to:
  /// **'A Relative'**
  String get profileCreatingForRelative;

  /// No description provided for @genderQuestion.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderQuestion;

  /// No description provided for @genderWoman.
  ///
  /// In en, this message translates to:
  /// **'Woman'**
  String get genderWoman;

  /// No description provided for @genderMan.
  ///
  /// In en, this message translates to:
  /// **'Man'**
  String get genderMan;

  /// No description provided for @genderNonBinary.
  ///
  /// In en, this message translates to:
  /// **'Non-binary'**
  String get genderNonBinary;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Where do you live?'**
  String get currentLocation;

  /// No description provided for @hometown.
  ///
  /// In en, this message translates to:
  /// **'Where are you from?'**
  String get hometown;

  /// No description provided for @lookingForPartner.
  ///
  /// In en, this message translates to:
  /// **'Looking for'**
  String get lookingForPartner;

  /// No description provided for @profileStepIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get profileStepIdentity;

  /// No description provided for @profileStepPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get profileStepPhotos;

  /// No description provided for @profileStepDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get profileStepDetails;

  /// No description provided for @profileStepPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profileStepPreferences;

  /// No description provided for @datingIntentQuestion.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for?'**
  String get datingIntentQuestion;

  /// No description provided for @datingIntentSerious.
  ///
  /// In en, this message translates to:
  /// **'Serious relationship'**
  String get datingIntentSerious;

  /// No description provided for @datingIntentCasual.
  ///
  /// In en, this message translates to:
  /// **'Fun / casual'**
  String get datingIntentCasual;

  /// No description provided for @datingIntentMarriage.
  ///
  /// In en, this message translates to:
  /// **'Marriage'**
  String get datingIntentMarriage;

  /// No description provided for @datingIntentFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends first'**
  String get datingIntentFriends;

  /// No description provided for @datingIntentOpen.
  ///
  /// In en, this message translates to:
  /// **'Open to see'**
  String get datingIntentOpen;

  /// No description provided for @interestedIn.
  ///
  /// In en, this message translates to:
  /// **'Interested in'**
  String get interestedIn;

  /// No description provided for @interestedInMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get interestedInMen;

  /// No description provided for @interestedInWomen.
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get interestedInWomen;

  /// No description provided for @interestedInEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get interestedInEveryone;

  /// No description provided for @matrimonyReligionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get matrimonyReligionQuestion;

  /// No description provided for @matrimonyCommunityQuestion.
  ///
  /// In en, this message translates to:
  /// **'Community / Caste'**
  String get matrimonyCommunityQuestion;

  /// No description provided for @matrimonyMotherTongueQuestion.
  ///
  /// In en, this message translates to:
  /// **'Mother tongue'**
  String get matrimonyMotherTongueQuestion;

  /// No description provided for @matrimonyMaritalStatusQuestion.
  ///
  /// In en, this message translates to:
  /// **'Marital status'**
  String get matrimonyMaritalStatusQuestion;

  /// No description provided for @matrimonyHeightQuestion.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get matrimonyHeightQuestion;

  /// No description provided for @matrimonyEducationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Highest education'**
  String get matrimonyEducationQuestion;

  /// No description provided for @matrimonyOccupationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get matrimonyOccupationQuestion;

  /// No description provided for @matrimonyIncomeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Annual income (optional)'**
  String get matrimonyIncomeQuestion;

  /// No description provided for @matrimonyFamilyTypeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Family type'**
  String get matrimonyFamilyTypeQuestion;

  /// No description provided for @matrimonyFamilyValuesQuestion.
  ///
  /// In en, this message translates to:
  /// **'Family values'**
  String get matrimonyFamilyValuesQuestion;

  /// No description provided for @neverMarried.
  ///
  /// In en, this message translates to:
  /// **'Never married'**
  String get neverMarried;

  /// No description provided for @divorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get divorced;

  /// No description provided for @widowed.
  ///
  /// In en, this message translates to:
  /// **'Widowed'**
  String get widowed;

  /// No description provided for @awaitingDivorce.
  ///
  /// In en, this message translates to:
  /// **'Awaiting divorce'**
  String get awaitingDivorce;

  /// No description provided for @nuclear.
  ///
  /// In en, this message translates to:
  /// **'Nuclear'**
  String get nuclear;

  /// No description provided for @joint.
  ///
  /// In en, this message translates to:
  /// **'Joint'**
  String get joint;

  /// No description provided for @traditional.
  ///
  /// In en, this message translates to:
  /// **'Traditional'**
  String get traditional;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @liberal.
  ///
  /// In en, this message translates to:
  /// **'Liberal'**
  String get liberal;

  /// No description provided for @dynSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up\n{name}\'s profile'**
  String dynSetupTitle(Object name);

  /// No description provided for @dynSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill in details about {name}. You can always edit later.'**
  String dynSetupSubtitle(Object name);

  /// No description provided for @dynName.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s name'**
  String dynName(Object name);

  /// No description provided for @dynNameHintSon.
  ///
  /// In en, this message translates to:
  /// **'e.g. Arjun, Rahul'**
  String get dynNameHintSon;

  /// No description provided for @dynNameHintDaughter.
  ///
  /// In en, this message translates to:
  /// **'e.g. Priya, Ananya'**
  String get dynNameHintDaughter;

  /// No description provided for @dynNameHintGeneric.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get dynNameHintGeneric;

  /// No description provided for @dynGender.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s gender'**
  String dynGender(Object name);

  /// No description provided for @dynDob.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s date of birth'**
  String dynDob(Object name);

  /// No description provided for @dynLocation.
  ///
  /// In en, this message translates to:
  /// **'Where does {name} live?'**
  String dynLocation(Object name);

  /// No description provided for @dynHometown.
  ///
  /// In en, this message translates to:
  /// **'Where is {name} from?'**
  String dynHometown(Object name);

  /// No description provided for @dynAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About {name}'**
  String dynAboutTitle(Object name);

  /// No description provided for @dynAboutHint.
  ///
  /// In en, this message translates to:
  /// **'Share what matters to {name} — work, interests, what they\'re looking for.'**
  String dynAboutHint(Object name);

  /// No description provided for @dynDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s\nbackground'**
  String dynDetailsTitle(Object name);

  /// No description provided for @dynDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These help us find compatible matches for {name}.'**
  String dynDetailsSubtitle(Object name);

  /// No description provided for @dynPrefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Partner preferences\nfor {name}'**
  String dynPrefsTitle(Object name);

  /// No description provided for @dynPrefsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us find the right match for {name}.'**
  String dynPrefsSubtitle(Object name);

  /// No description provided for @dynPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add photos of {name}. Clear face photos get 3x more responses.'**
  String dynPhotosSubtitle(Object name);

  /// No description provided for @lifestyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get lifestyleTitle;

  /// No description provided for @dietQuestion.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get dietQuestion;

  /// No description provided for @dietVeg.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get dietVeg;

  /// No description provided for @dietNonVeg.
  ///
  /// In en, this message translates to:
  /// **'Non-vegetarian'**
  String get dietNonVeg;

  /// No description provided for @dietVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get dietVegan;

  /// No description provided for @dietEggetarian.
  ///
  /// In en, this message translates to:
  /// **'Eggetarian'**
  String get dietEggetarian;

  /// No description provided for @dietJain.
  ///
  /// In en, this message translates to:
  /// **'Jain'**
  String get dietJain;

  /// No description provided for @dietFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get dietFlexible;

  /// No description provided for @drinkQuestion.
  ///
  /// In en, this message translates to:
  /// **'Drinking'**
  String get drinkQuestion;

  /// No description provided for @drinkNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get drinkNever;

  /// No description provided for @drinkSocially.
  ///
  /// In en, this message translates to:
  /// **'Socially'**
  String get drinkSocially;

  /// No description provided for @drinkRegularly.
  ///
  /// In en, this message translates to:
  /// **'Regularly'**
  String get drinkRegularly;

  /// No description provided for @smokeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get smokeQuestion;

  /// No description provided for @smokeNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get smokeNever;

  /// No description provided for @smokeOccasionally.
  ///
  /// In en, this message translates to:
  /// **'Occasionally'**
  String get smokeOccasionally;

  /// No description provided for @smokeRegularly.
  ///
  /// In en, this message translates to:
  /// **'Regularly'**
  String get smokeRegularly;

  /// No description provided for @exerciseQuestion.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exerciseQuestion;

  /// No description provided for @exerciseDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get exerciseDaily;

  /// No description provided for @exerciseRegularly.
  ///
  /// In en, this message translates to:
  /// **'Regularly'**
  String get exerciseRegularly;

  /// No description provided for @exerciseSometimes.
  ///
  /// In en, this message translates to:
  /// **'Sometimes'**
  String get exerciseSometimes;

  /// No description provided for @exerciseRarely.
  ///
  /// In en, this message translates to:
  /// **'Rarely'**
  String get exerciseRarely;

  /// No description provided for @petsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get petsQuestion;

  /// No description provided for @petsHaveDog.
  ///
  /// In en, this message translates to:
  /// **'Have a dog'**
  String get petsHaveDog;

  /// No description provided for @petsHaveCat.
  ///
  /// In en, this message translates to:
  /// **'Have a cat'**
  String get petsHaveCat;

  /// No description provided for @petsLoveThem.
  ///
  /// In en, this message translates to:
  /// **'Love them'**
  String get petsLoveThem;

  /// No description provided for @petsAllergic.
  ///
  /// In en, this message translates to:
  /// **'Allergic'**
  String get petsAllergic;

  /// No description provided for @petsNone.
  ///
  /// In en, this message translates to:
  /// **'No pets'**
  String get petsNone;

  /// No description provided for @careerTitle.
  ///
  /// In en, this message translates to:
  /// **'Career'**
  String get careerTitle;

  /// No description provided for @companyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Company / employer'**
  String get companyQuestion;

  /// No description provided for @companyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Google, TCS, Self-employed'**
  String get companyHint;

  /// No description provided for @workLocationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Work location'**
  String get workLocationQuestion;

  /// No description provided for @workLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mumbai, Remote, Abroad'**
  String get workLocationHint;

  /// No description provided for @settledAbroadQuestion.
  ///
  /// In en, this message translates to:
  /// **'Settled abroad?'**
  String get settledAbroadQuestion;

  /// No description provided for @settledAbroadYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get settledAbroadYes;

  /// No description provided for @settledAbroadNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get settledAbroadNo;

  /// No description provided for @settledAbroadPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning to'**
  String get settledAbroadPlanning;

  /// No description provided for @willingToRelocate.
  ///
  /// In en, this message translates to:
  /// **'Willing to relocate?'**
  String get willingToRelocate;

  /// No description provided for @relocateYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get relocateYes;

  /// No description provided for @relocateNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get relocateNo;

  /// No description provided for @relocateMaybe.
  ///
  /// In en, this message translates to:
  /// **'Maybe'**
  String get relocateMaybe;

  /// No description provided for @prefDietQuestion.
  ///
  /// In en, this message translates to:
  /// **'Diet preference'**
  String get prefDietQuestion;

  /// No description provided for @prefDrinkQuestion.
  ///
  /// In en, this message translates to:
  /// **'Drinking preference'**
  String get prefDrinkQuestion;

  /// No description provided for @prefSmokeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Smoking preference'**
  String get prefSmokeQuestion;

  /// No description provided for @prefCityQuestion.
  ///
  /// In en, this message translates to:
  /// **'Preferred city'**
  String get prefCityQuestion;

  /// No description provided for @prefCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mumbai, Bangalore, Any'**
  String get prefCityHint;

  /// No description provided for @prefHeightQuestion.
  ///
  /// In en, this message translates to:
  /// **'Height range'**
  String get prefHeightQuestion;

  /// No description provided for @prefSettledAbroadQuestion.
  ///
  /// In en, this message translates to:
  /// **'Settled abroad preference'**
  String get prefSettledAbroadQuestion;

  /// No description provided for @prefMotherTongueQuestion.
  ///
  /// In en, this message translates to:
  /// **'Mother tongue preference'**
  String get prefMotherTongueQuestion;

  /// No description provided for @anyOption.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get anyOption;

  /// No description provided for @modeSwitchCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get modeSwitchCompleteTitle;

  /// No description provided for @modeSwitchCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Matrimony mode requires a few more details for better matches.'**
  String get modeSwitchCompleteSubtitle;

  /// No description provided for @mandatory.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get mandatory;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @fillLater.
  ///
  /// In en, this message translates to:
  /// **'You can fill this later from your profile.'**
  String get fillLater;

  /// No description provided for @bodyTypeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Body type'**
  String get bodyTypeQuestion;

  /// No description provided for @bodyTypeSlim.
  ///
  /// In en, this message translates to:
  /// **'Slim'**
  String get bodyTypeSlim;

  /// No description provided for @bodyTypeAthletic.
  ///
  /// In en, this message translates to:
  /// **'Athletic'**
  String get bodyTypeAthletic;

  /// No description provided for @bodyTypeAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get bodyTypeAverage;

  /// No description provided for @bodyTypeHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get bodyTypeHeavy;

  /// No description provided for @bodyTypeCurvy.
  ///
  /// In en, this message translates to:
  /// **'Curvy'**
  String get bodyTypeCurvy;

  /// No description provided for @heightQuestion.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get heightQuestion;

  /// No description provided for @heightHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 5\'8\" or 173 cm'**
  String get heightHint;

  /// No description provided for @complexionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Complexion'**
  String get complexionQuestion;

  /// No description provided for @complexionFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get complexionFair;

  /// No description provided for @complexionWheatish.
  ///
  /// In en, this message translates to:
  /// **'Wheatish'**
  String get complexionWheatish;

  /// No description provided for @complexionDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get complexionDark;

  /// No description provided for @complexionPreferNot.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get complexionPreferNot;

  /// No description provided for @disabilityQuestion.
  ///
  /// In en, this message translates to:
  /// **'Any disability?'**
  String get disabilityQuestion;

  /// No description provided for @disabilityNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get disabilityNone;

  /// No description provided for @disabilityPhysical.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get disabilityPhysical;

  /// No description provided for @disabilityPreferNot.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get disabilityPreferNot;

  /// No description provided for @languagesSpoken.
  ///
  /// In en, this message translates to:
  /// **'Languages spoken'**
  String get languagesSpoken;

  /// No description provided for @languagesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. English, Hindi, Tamil'**
  String get languagesHint;

  /// No description provided for @horoscopeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Horoscope details'**
  String get horoscopeQuestion;

  /// No description provided for @manglikQuestion.
  ///
  /// In en, this message translates to:
  /// **'Manglik?'**
  String get manglikQuestion;

  /// No description provided for @manglikYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get manglikYes;

  /// No description provided for @manglikNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get manglikNo;

  /// No description provided for @manglikPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial (Anshik)'**
  String get manglikPartial;

  /// No description provided for @manglikDontKnow.
  ///
  /// In en, this message translates to:
  /// **'Don\'t know'**
  String get manglikDontKnow;

  /// No description provided for @rashiQuestion.
  ///
  /// In en, this message translates to:
  /// **'Rashi (Moon sign)'**
  String get rashiQuestion;

  /// No description provided for @nakshatraQuestion.
  ///
  /// In en, this message translates to:
  /// **'Nakshatra (Birth star)'**
  String get nakshatraQuestion;

  /// No description provided for @gotraQuestion.
  ///
  /// In en, this message translates to:
  /// **'Gotra'**
  String get gotraQuestion;

  /// No description provided for @gotraHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bharadwaj, Kashyap'**
  String get gotraHint;

  /// No description provided for @physicalTitle.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get physicalTitle;

  /// No description provided for @backgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get backgroundTitle;

  /// No description provided for @emptyStateGeneric.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyStateGeneric;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGeneric;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @activeNow.
  ///
  /// In en, this message translates to:
  /// **'Active now'**
  String get activeNow;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @managedBy.
  ///
  /// In en, this message translates to:
  /// **'Managed by: {role}'**
  String managedBy(Object role);

  /// No description provided for @lastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active'**
  String get lastActive;

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String kmAway(Object distance);

  /// No description provided for @ageRange.
  ///
  /// In en, this message translates to:
  /// **'Age range'**
  String get ageRange;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @religion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get religion;

  /// No description provided for @motherTongue.
  ///
  /// In en, this message translates to:
  /// **'Mother tongue'**
  String get motherTongue;

  /// No description provided for @maritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Marital status'**
  String get maritalStatus;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @educationLevel.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get educationLevel;

  /// No description provided for @occupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get occupation;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @diet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get diet;

  /// No description provided for @familyType.
  ///
  /// In en, this message translates to:
  /// **'Family type'**
  String get familyType;

  /// No description provided for @familyValues.
  ///
  /// In en, this message translates to:
  /// **'Family values'**
  String get familyValues;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bn',
    'en',
    'gu',
    'hi',
    'kn',
    'ml',
    'mr',
    'pa',
    'ta',
    'te',
    'ur',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'pa':
      return AppLocalizationsPa();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
