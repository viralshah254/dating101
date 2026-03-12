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
  /// **'Shubhmilan'**
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

  /// No description provided for @viewMore.
  ///
  /// In en, this message translates to:
  /// **'View more'**
  String get viewMore;

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
  /// **'Shubhmilan'**
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

  /// No description provided for @modeBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get modeBoth;

  /// No description provided for @modeBothSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use dating and matrimony. You\'ll see only profiles who are also on both. Switch between them anytime in Settings.'**
  String get modeBothSubtitle;

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

  /// No description provided for @navLikes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get navLikes;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @likesTabLikedYou.
  ///
  /// In en, this message translates to:
  /// **'Liked you'**
  String get likesTabLikedYou;

  /// No description provided for @likesTabVisitors.
  ///
  /// In en, this message translates to:
  /// **'Visitors'**
  String get likesTabVisitors;

  /// No description provided for @likesTabYouLiked.
  ///
  /// In en, this message translates to:
  /// **'You liked'**
  String get likesTabYouLiked;

  /// No description provided for @likesEmptyLikedYou.
  ///
  /// In en, this message translates to:
  /// **'No one has liked you yet'**
  String get likesEmptyLikedYou;

  /// No description provided for @likesEmptyLikedYouBody.
  ///
  /// In en, this message translates to:
  /// **'Keep exploring — when someone likes you, they\'ll show up here.'**
  String get likesEmptyLikedYouBody;

  /// No description provided for @likesEmptyVisitors.
  ///
  /// In en, this message translates to:
  /// **'No visitors yet'**
  String get likesEmptyVisitors;

  /// No description provided for @likesEmptyVisitorsBody.
  ///
  /// In en, this message translates to:
  /// **'When someone views your profile, they\'ll appear here.'**
  String get likesEmptyVisitorsBody;

  /// No description provided for @likesEmptyYouLiked.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t liked anyone yet'**
  String get likesEmptyYouLiked;

  /// No description provided for @likesEmptyYouLikedBody.
  ///
  /// In en, this message translates to:
  /// **'Profiles you like from Discover will show up here.'**
  String get likesEmptyYouLikedBody;

  /// No description provided for @sendReminder.
  ///
  /// In en, this message translates to:
  /// **'Send reminder'**
  String get sendReminder;

  /// No description provided for @reminderSentToast.
  ///
  /// In en, this message translates to:
  /// **'Reminder sent to {name}'**
  String reminderSentToast(String name);

  /// No description provided for @likedYouPremiumGateMessage.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to see everyone who liked you, or watch an ad to unlock one profile (2 per week).'**
  String get likedYouPremiumGateMessage;

  /// No description provided for @watchAdToUnlockOne.
  ///
  /// In en, this message translates to:
  /// **'Watch ad to unlock one ({remaining} left this week)'**
  String watchAdToUnlockOne(int remaining);

  /// No description provided for @likedYouUnlockedProfiles.
  ///
  /// In en, this message translates to:
  /// **'Unlocked profiles'**
  String get likedYouUnlockedProfiles;

  /// No description provided for @likedYouNoRequestToUnlock.
  ///
  /// In en, this message translates to:
  /// **'No request to unlock right now. Try again later.'**
  String get likedYouNoRequestToUnlock;

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

  /// No description provided for @navEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// No description provided for @navVisitors.
  ///
  /// In en, this message translates to:
  /// **'Visitors'**
  String get navVisitors;

  /// No description provided for @refine.
  ///
  /// In en, this message translates to:
  /// **'Refine'**
  String get refine;

  /// No description provided for @refineTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refine by age, city, religion, education and more'**
  String get refineTooltip;

  /// No description provided for @noRecommendationsYet.
  ///
  /// In en, this message translates to:
  /// **'No recommendations yet'**
  String get noRecommendationsYet;

  /// No description provided for @noRecommendationsYetBody.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile and preferences to get AI-powered matches.'**
  String get noRecommendationsYetBody;

  /// No description provided for @searchWidenedTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ve widened the search'**
  String get searchWidenedTitle;

  /// No description provided for @searchWidenedBody.
  ///
  /// In en, this message translates to:
  /// **'No results matched your current filters. We\'re showing more profiles by reducing some filters.'**
  String get searchWidenedBody;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @discoverNoMoreProfilesTitle.
  ///
  /// In en, this message translates to:
  /// **'No more profiles right now'**
  String get discoverNoMoreProfilesTitle;

  /// No description provided for @discoverNoMoreProfilesBody.
  ///
  /// In en, this message translates to:
  /// **'Check back later for new matches, or try changing your city or filters.'**
  String get discoverNoMoreProfilesBody;

  /// No description provided for @discoverNoProfilesInCityTitle.
  ///
  /// In en, this message translates to:
  /// **'No profiles in {city} yet'**
  String discoverNoProfilesInCityTitle(String city);

  /// No description provided for @discoverNoProfilesInCityBody.
  ///
  /// In en, this message translates to:
  /// **'Try \"Your area\" to see profiles near you, or pick a different city.'**
  String get discoverNoProfilesInCityBody;

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

  /// No description provided for @ctaSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get ctaSendMessage;

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

  /// No description provided for @ctaUpgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Shubhmilan Premium'**
  String get ctaUpgradeToPremium;

  /// No description provided for @premiumRequired.
  ///
  /// In en, this message translates to:
  /// **'Premium Feature'**
  String get premiumRequired;

  /// No description provided for @premiumMessageMale.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to send messages, see who likes you, and unlock contact details.'**
  String get premiumMessageMale;

  /// No description provided for @premiumMessageFemale.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for travel mode, profile boosts, and priority discovery.'**
  String get premiumMessageFemale;

  /// No description provided for @freeLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached'**
  String get freeLimitReached;

  /// No description provided for @freeLimitBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all your free interests today. Upgrade for unlimited.'**
  String get freeLimitBody;

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

  /// No description provided for @dailyMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily matches'**
  String get dailyMatchesTitle;

  /// No description provided for @dailyMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send a free interest to profiles you like'**
  String get dailyMatchesSubtitle;

  /// No description provided for @dailyMatchesSendFreeInterest.
  ///
  /// In en, this message translates to:
  /// **'Send free interest'**
  String get dailyMatchesSendFreeInterest;

  /// No description provided for @dailyMatchesSendFreeInterestToCount.
  ///
  /// In en, this message translates to:
  /// **'Send free interest to {count}'**
  String dailyMatchesSendFreeInterestToCount(int count);

  /// No description provided for @dailyMatchesMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get dailyMatchesMaybeLater;

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

  /// No description provided for @requestsSeeWhosInterested.
  ///
  /// In en, this message translates to:
  /// **'See who\'s interested'**
  String get requestsSeeWhosInterested;

  /// No description provided for @requestsUpgradeToView.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium to view and respond to your requests.'**
  String get requestsUpgradeToView;

  /// No description provided for @requestsUpgradeOrUnlock.
  ///
  /// In en, this message translates to:
  /// **'You have {count} request(s). Upgrade to view all, or watch an ad to unlock one.'**
  String requestsUpgradeOrUnlock(int count);

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

  /// No description provided for @shortlistedTab.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted'**
  String get shortlistedTab;

  /// No description provided for @shortlistedYouTab.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted you'**
  String get shortlistedYouTab;

  /// No description provided for @tabChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get tabChats;

  /// No description provided for @tabMessageRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get tabMessageRequests;

  /// No description provided for @circlesTab.
  ///
  /// In en, this message translates to:
  /// **'Circles'**
  String get circlesTab;

  /// No description provided for @eventsTab.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTab;

  /// No description provided for @upcomingTab.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingTab;

  /// No description provided for @myRsvpsTab.
  ///
  /// In en, this message translates to:
  /// **'My RSVPs'**
  String get myRsvpsTab;

  /// No description provided for @messageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageTooltip;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch ad'**
  String get watchAd;

  /// No description provided for @watchAdToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Watch ad to unlock'**
  String get watchAdToUnlock;

  /// No description provided for @loadingAd.
  ///
  /// In en, this message translates to:
  /// **'Loading ad…'**
  String get loadingAd;

  /// No description provided for @adCouldntBeLoaded.
  ///
  /// In en, this message translates to:
  /// **'Ad couldn\'t be loaded. Try again or upgrade to Premium.'**
  String get adCouldntBeLoaded;

  /// No description provided for @mutualMatchCelebrationMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re both interested in each other! Send a message or view their profile.'**
  String get mutualMatchCelebrationMessage;

  /// No description provided for @priorityInterestAdMessage.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to send your priority interest, or upgrade to Premium to send without ads.'**
  String get priorityInterestAdMessage;

  /// No description provided for @sendOrAcceptInterestFirst.
  ///
  /// In en, this message translates to:
  /// **'Send or accept an interest first'**
  String get sendOrAcceptInterestFirst;

  /// No description provided for @watchAdToMessageMessage.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to send a message, or upgrade to Premium to message without ads.'**
  String get watchAdToMessageMessage;

  /// No description provided for @datingMessageGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a message'**
  String get datingMessageGateTitle;

  /// No description provided for @datingMessageGateBody.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to send a message (up to 5 per day). Your message will go to their message requests. Upgrade to Premium for unlimited messaging.'**
  String get datingMessageGateBody;

  /// No description provided for @watchAdToSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Watch ad to send message'**
  String get watchAdToSendMessage;

  /// No description provided for @datingMessageAdLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used your 5 free message sends today. Upgrade to Premium for unlimited messaging.'**
  String get datingMessageAdLimitReached;

  /// No description provided for @likedOpenChatFromChats.
  ///
  /// In en, this message translates to:
  /// **'You\'ve liked them. Open Chats to start the conversation when they like you back.'**
  String get likedOpenChatFromChats;

  /// No description provided for @sayHiToName.
  ///
  /// In en, this message translates to:
  /// **'Say hi to {name}'**
  String sayHiToName(String name);

  /// No description provided for @sendPersonalNote.
  ///
  /// In en, this message translates to:
  /// **'Send a personal note'**
  String get sendPersonalNote;

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

  /// No description provided for @interestsAndHobbies.
  ///
  /// In en, this message translates to:
  /// **'Interests & Hobbies'**
  String get interestsAndHobbies;

  /// No description provided for @interestsAndHobbiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up to 6 — we\'ll use them for better matches.'**
  String get interestsAndHobbiesSubtitle;

  /// No description provided for @interestsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search interests & hobbies...'**
  String get interestsSearchHint;

  /// No description provided for @interestsMaxReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 6 interests. Remove one to add another.'**
  String get interestsMaxReached;

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

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

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

  /// No description provided for @subscriptionExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String subscriptionExpiresOn(String date);

  /// No description provided for @subscriptionRenewSoon.
  ///
  /// In en, this message translates to:
  /// **'Renew in the next 7 days to keep Premium'**
  String get subscriptionRenewSoon;

  /// No description provided for @subscriptionDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String subscriptionDaysLeft(int count);

  /// No description provided for @upgradeToPremiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock all features'**
  String get upgradeToPremiumSubtitle;

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

  /// No description provided for @aboutMeHint.
  ///
  /// In en, this message translates to:
  /// **'Share what matters to you — work, interests, and what you\'re looking for.'**
  String get aboutMeHint;

  /// No description provided for @profileSetupPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 photos. Profiles with clear face photos get more matches.'**
  String get profileSetupPhotosHint;

  /// No description provided for @profilePhotoTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tips for great photos'**
  String get profilePhotoTipsTitle;

  /// No description provided for @profilePhotoTipsBody.
  ///
  /// In en, this message translates to:
  /// **'Use clear, well-lit photos.\nInclude at least one clear face photo.\nAvoid group photos for your main picture.\nSmile — it helps others connect.'**
  String get profilePhotoTipsBody;

  /// No description provided for @primaryPhoto.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get primaryPhoto;

  /// No description provided for @conversationStarterHint.
  ///
  /// In en, this message translates to:
  /// **'Answer a prompt so matches have something to talk about.'**
  String get conversationStarterHint;

  /// No description provided for @conversationStarterFieldHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Best way to spend a Sunday? Chai and a book.'**
  String get conversationStarterFieldHint;

  /// No description provided for @voiceIntroDescription.
  ///
  /// In en, this message translates to:
  /// **'Record a short voice note (up to 30 seconds) so matches can hear your personality.'**
  String get voiceIntroDescription;

  /// No description provided for @voiceIntroSaved.
  ///
  /// In en, this message translates to:
  /// **'Voice intro saved. You can update it anytime.'**
  String get voiceIntroSaved;

  /// No description provided for @saveAndClose.
  ///
  /// In en, this message translates to:
  /// **'Save & close'**
  String get saveAndClose;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & continue'**
  String get saveAndContinue;

  /// No description provided for @bothModeSetupHint.
  ///
  /// In en, this message translates to:
  /// **'You selected both modes. We collect shared details first, then matrimony and dating specifics.'**
  String get bothModeSetupHint;

  /// No description provided for @stepOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOfTotal(int current, int total);

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

  /// No description provided for @onboardingDatingSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Depth-first connections'**
  String get onboardingDatingSlide1Title;

  /// No description provided for @onboardingDatingSlide1Body.
  ///
  /// In en, this message translates to:
  /// **'See full profiles and send thoughtful intros—no mindless swiping.'**
  String get onboardingDatingSlide1Body;

  /// No description provided for @onboardingDatingSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Explore by map'**
  String get onboardingDatingSlide2Title;

  /// No description provided for @onboardingDatingSlide2Body.
  ///
  /// In en, this message translates to:
  /// **'Discover people in your city or plan ahead when you travel.'**
  String get onboardingDatingSlide2Body;

  /// No description provided for @onboardingDatingSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Circles & events'**
  String get onboardingDatingSlide3Title;

  /// No description provided for @onboardingDatingSlide3Body.
  ///
  /// In en, this message translates to:
  /// **'Join communities and real-world meetups that match your life.'**
  String get onboardingDatingSlide3Body;

  /// No description provided for @onboardingMatrimonySlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Meaningful matches'**
  String get onboardingMatrimonySlide1Title;

  /// No description provided for @onboardingMatrimonySlide1Body.
  ///
  /// In en, this message translates to:
  /// **'See full profiles and partner preferences—serious about marriage.'**
  String get onboardingMatrimonySlide1Body;

  /// No description provided for @onboardingMatrimonySlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Families involved'**
  String get onboardingMatrimonySlide2Title;

  /// No description provided for @onboardingMatrimonySlide2Body.
  ///
  /// In en, this message translates to:
  /// **'Share profiles with family and align on preferences together.'**
  String get onboardingMatrimonySlide2Body;

  /// No description provided for @onboardingMatrimonySlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Verified & detailed'**
  String get onboardingMatrimonySlide3Title;

  /// No description provided for @onboardingMatrimonySlide3Body.
  ///
  /// In en, this message translates to:
  /// **'Focus on verified profiles and detailed preferences for a trusted match.'**
  String get onboardingMatrimonySlide3Body;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Priya Sharma, Arjun Kumar'**
  String get nameHint;

  /// No description provided for @nameValidationHint.
  ///
  /// In en, this message translates to:
  /// **'Use at least 2 words with capital letters, e.g. Priya Sharma'**
  String get nameValidationHint;

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
  /// **'Unlock more with Shubhmilan'**
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

  /// No description provided for @safetyScoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete verifications to increase your safety score and visibility.'**
  String get safetyScoreDescription;

  /// No description provided for @verificationIntro.
  ///
  /// In en, this message translates to:
  /// **'Verified profiles get more matches. Add one or more verifications below.'**
  String get verificationIntro;

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

  /// No description provided for @referNow.
  ///
  /// In en, this message translates to:
  /// **'Refer Now'**
  String get referNow;

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

  /// No description provided for @referralBenefitReferred.
  ///
  /// In en, this message translates to:
  /// **'30 days free Premium for everyone who signs up with your code.'**
  String get referralBenefitReferred;

  /// No description provided for @referralContestMessage.
  ///
  /// In en, this message translates to:
  /// **'Top referrer wins up to ₹1,00,000!'**
  String get referralContestMessage;

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

  /// No description provided for @referralCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Have a referral code?'**
  String get referralCodeHint;

  /// No description provided for @referralCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Referral code (optional)'**
  String get referralCodeOptional;

  /// No description provided for @referralPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'30 days free Premium!'**
  String get referralPremiumTitle;

  /// No description provided for @referralPremiumMessage.
  ///
  /// In en, this message translates to:
  /// **'Your referral code was applied. You have 30 days of free Premium. Enjoy!'**
  String get referralPremiumMessage;

  /// No description provided for @referralShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Try Shubhmilan — meaningful connections for the diaspora.\n\nDownload the app here: {link}\n\nWhen you sign up, enter my referral code: {code}\n\nYou get 30 days free Premium (India only). Plus, top referrers can win up to ₹1,00,000 every month!'**
  String referralShareMessage(String code, String link);

  /// No description provided for @referralTermsApply.
  ///
  /// In en, this message translates to:
  /// **'Terms & conditions apply'**
  String get referralTermsApply;

  /// No description provided for @referralTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Referral Programme Terms & Conditions'**
  String get referralTermsTitle;

  /// No description provided for @referralTermsAndConditionsBody.
  ///
  /// In en, this message translates to:
  /// **'1. Programme. The Shubhmilan Referral Programme (\"Programme\") lets you share a unique referral code or link. When an eligible new user signs up using your code/link in accordance with these terms, they may receive a referral benefit (e.g., 30 days of Premium), and you may be eligible for the monthly referrer contest (\"Contest\").\n\n2. Territory (India only). The Programme, referral benefits, and Contest are offered only in India. Participation is valid only for users who are physically located in India at the time of sign-up and participation, and who have an Indian mobile number. Shubhmilan may use reasonable methods (including phone number, device signals, IP/location indicators) to confirm eligibility. If you are outside India, you are not eligible for referral benefits or prizes.\n\n3. Age requirement (18+ only). You must be 18 years or older to participate. By participating, you confirm you are 18+. Any user found (or reasonably suspected) to be under 18 will be immediately disqualified from the Programme and Contest, may forfeit any benefits or prizes, and may have their account removed/suspended.\n\n4. Eligibility. To be eligible as a referrer, you must be a registered Shubhmilan user in good standing and comply with these terms and our main Terms of Service and Privacy Policy. Referred users must be new (first-time sign-up on Shubhmilan), must sign up using a valid referral code/link during registration, and must not have previously created an account (including via another phone number, email, device, or identity).\n\n5. Referral benefit (30-day Premium). If the referral code/link is successfully applied during registration and the referred user is eligible, the referred user receives 30 days of Premium (or other benefit as shown in-app). The referral benefit is limited to one per person and is not transferable, exchangeable, or redeemable for cash. Shubhmilan may reject invalid, duplicate, or fraudulent sign-ups.\n\n6. Contest period and monthly winner. Shubhmilan may run a monthly Contest where the top eligible referrer based on qualifying referrals may win a prize pool of up to ₹1,00,000 (\"Prize\"). Each month will have one (1) winner who may win the maximum prize pool for that month, subject to verification and these terms. Contest details, including the month and measurement rules, will be communicated in-app.\n\n7. Qualifying referrals. A \"qualifying referral\" is counted only when: (a) the referred user is eligible and new; (b) the referral code/link is applied at registration; (c) the account passes fraud/duplicate checks; and (d) Shubhmilan reasonably determines the sign-up is genuine. Shubhmilan may exclude referrals that appear to be incentivized improperly, spam-driven, or otherwise abusive.\n\n8. Prohibited conduct (anti-fraud). You may not use fake accounts, bots, scripts, click-farms, paid installs, spam, misleading claims, impersonation, mass messaging in violation of law/policies, or any fraudulent or abusive methods to earn referrals or Contest standing. You may not sell, trade, or publish referral codes/links on coupon/referral marketplaces. Any such activity may result in disqualification, forfeiture of benefits/prizes, and suspension/termination of your account.\n\n9. Verification, decision rights, and tie-breaks. Shubhmilan reserves the right to verify eligibility and compliance, including requesting proof of age and identity. If verification is not completed or fails, the user is disqualified. In case of a tie or suspected manipulation, Shubhmilan may use additional criteria (e.g., referral quality signals, time to qualify, integrity checks) or conduct a tie-break process at its sole discretion. Shubhmilan’s decision is final.\n\n10. Prize payment timeline and review date. Prize payouts (if any) will be processed only after the monthly competition ends and Shubhmilan completes verification and review. For the Contest cycle ending in August 2026, winner review will be completed by August 31, 2026, and payouts will be initiated after review is finalized. Shubhmilan may delay or withhold payouts where verification, compliance checks, or legal requirements are pending.\n\n11. Taxes, KYC, and payment method. Prizes may be subject to applicable Indian taxes, withholding (TDS), reporting, and KYC requirements. Winners must provide required details (e.g., PAN, bank account, ID) to receive the Prize. If a winner does not provide required information within the timeframe communicated, the Prize may be forfeited or awarded to an alternate eligible winner.\n\n12. Privacy and communications. We will handle personal data in accordance with our Privacy Policy. We may contact participants about eligibility, verification, and prize distribution.\n\n13. Changes, suspension, and termination. Shubhmilan may modify, suspend, or end the Programme/Contest or these terms at any time (including prize pool amounts and rules) where reasonably necessary (e.g., to prevent abuse, comply with law, or operational reasons). Continued participation after changes constitutes acceptance of the updated terms.\n\n14. Liability. To the maximum extent permitted by law, Shubhmilan is not liable for any loss arising from participation in the Programme/Contest, including technical issues, delayed or failed tracking, or disqualification decisions made in good faith.\n\n15. Governing law and disputes. These Referral Terms are governed by the laws of India. Courts of competent jurisdiction in India will have exclusive jurisdiction over disputes arising from the Programme/Contest.\n\n16. General. These Referral Terms are in addition to our main Terms of Service and Privacy Policy. If there is a conflict, these Referral Terms apply to the Programme/Contest only.'**
  String get referralTermsAndConditionsBody;

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
  /// **'Choose how you\'d like to use Shubhmilan. You can switch anytime from settings.'**
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

  /// No description provided for @confirmAge18Self.
  ///
  /// In en, this message translates to:
  /// **'I confirm I am 18 years or older'**
  String get confirmAge18Self;

  /// No description provided for @confirmAge18Other.
  ///
  /// In en, this message translates to:
  /// **'I confirm this person is 18 years or older'**
  String get confirmAge18Other;

  /// No description provided for @dobMustBe18.
  ///
  /// In en, this message translates to:
  /// **'Must be 18 or older'**
  String get dobMustBe18;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Where do you live?'**
  String get currentLocation;

  /// No description provided for @currentLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mumbai, New York'**
  String get currentLocationHint;

  /// No description provided for @hometown.
  ///
  /// In en, this message translates to:
  /// **'Where were you born?'**
  String get hometown;

  /// No description provided for @placeOfBirthHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Jaipur, Hyderabad'**
  String get placeOfBirthHint;

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

  /// No description provided for @profileStepEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get profileStepEducation;

  /// No description provided for @profileStepCareer.
  ///
  /// In en, this message translates to:
  /// **'Career'**
  String get profileStepCareer;

  /// No description provided for @profileStepDetails.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle & more'**
  String get profileStepDetails;

  /// No description provided for @profileStepPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profileStepPreferences;

  /// No description provided for @addEducation.
  ///
  /// In en, this message translates to:
  /// **'Add education'**
  String get addEducation;

  /// No description provided for @whatDidYouComplete.
  ///
  /// In en, this message translates to:
  /// **'What did you complete?'**
  String get whatDidYouComplete;

  /// No description provided for @whatDidYouCompleteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. High school, Bachelors, MBA'**
  String get whatDidYouCompleteHint;

  /// No description provided for @educationStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'First choose high school or college/university. For degrees, add your institution — it helps with matching.'**
  String get educationStepSubtitle;

  /// No description provided for @searchUniversity.
  ///
  /// In en, this message translates to:
  /// **'University / college'**
  String get searchUniversity;

  /// No description provided for @searchUniversityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. IIT Delhi, Christ University'**
  String get searchUniversityHint;

  /// No description provided for @universityImportantHint.
  ///
  /// In en, this message translates to:
  /// **'Choosing your institution helps with better matches.'**
  String get universityImportantHint;

  /// No description provided for @degreeLevel.
  ///
  /// In en, this message translates to:
  /// **'Degree / level'**
  String get degreeLevel;

  /// No description provided for @searchDegreeHint.
  ///
  /// In en, this message translates to:
  /// **'Search degree or level'**
  String get searchDegreeHint;

  /// No description provided for @graduationYear.
  ///
  /// In en, this message translates to:
  /// **'Year of graduation'**
  String get graduationYear;

  /// No description provided for @degreeGrade.
  ///
  /// In en, this message translates to:
  /// **'Degree grade / classification'**
  String get degreeGrade;

  /// No description provided for @degreeGradeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. UK 1st class honours, India First class'**
  String get degreeGradeHint;

  /// No description provided for @scoreCountry.
  ///
  /// In en, this message translates to:
  /// **'Grading system'**
  String get scoreCountry;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

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

  /// No description provided for @aboutCareer.
  ///
  /// In en, this message translates to:
  /// **'About your career'**
  String get aboutCareer;

  /// No description provided for @aboutCareerHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Role, years of experience, what you love about your work'**
  String get aboutCareerHint;

  /// No description provided for @aboutEducation.
  ///
  /// In en, this message translates to:
  /// **'About your education'**
  String get aboutEducation;

  /// No description provided for @aboutEducationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Degrees, institutions, certifications (CFA, etc.)'**
  String get aboutEducationHint;

  /// No description provided for @sectorQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sector'**
  String get sectorQuestion;

  /// No description provided for @sectorPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get sectorPrivate;

  /// No description provided for @sectorGovernment.
  ///
  /// In en, this message translates to:
  /// **'Government'**
  String get sectorGovernment;

  /// No description provided for @sectorPSU.
  ///
  /// In en, this message translates to:
  /// **'PSU'**
  String get sectorPSU;

  /// No description provided for @sectorBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business / Self-employed'**
  String get sectorBusiness;

  /// No description provided for @sectorOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get sectorOther;

  /// No description provided for @familyLocationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Family based out of'**
  String get familyLocationQuestion;

  /// No description provided for @familyLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bhilai, Mumbai'**
  String get familyLocationHint;

  /// No description provided for @householdIncomeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Household income'**
  String get householdIncomeQuestion;

  /// No description provided for @motherOccupationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s occupation'**
  String get motherOccupationQuestion;

  /// No description provided for @motherOccupationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Homemaker, Teacher'**
  String get motherOccupationHint;

  /// No description provided for @fatherOccupationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Father\'s occupation'**
  String get fatherOccupationQuestion;

  /// No description provided for @fatherOccupationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Govt. employee, Business'**
  String get fatherOccupationHint;

  /// No description provided for @motherAgeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s age'**
  String get motherAgeQuestion;

  /// No description provided for @fatherAgeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Father\'s age'**
  String get fatherAgeQuestion;

  /// No description provided for @siblingsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Siblings'**
  String get siblingsQuestion;

  /// No description provided for @siblingsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1 Brother (married), 1 Sister (unmarried)'**
  String get siblingsHint;

  /// No description provided for @siblingsBrothers.
  ///
  /// In en, this message translates to:
  /// **'Brothers'**
  String get siblingsBrothers;

  /// No description provided for @siblingsSisters.
  ///
  /// In en, this message translates to:
  /// **'Sisters'**
  String get siblingsSisters;

  /// No description provided for @birthTimeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Time of birth'**
  String get birthTimeQuestion;

  /// No description provided for @birthTimeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 11:00 AM (for horoscope)'**
  String get birthTimeHint;

  /// No description provided for @birthPlaceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Place of birth'**
  String get birthPlaceQuestion;

  /// No description provided for @birthPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bhilai, Chhattisgarh'**
  String get birthPlaceHint;

  /// No description provided for @prefCountryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Preferred country'**
  String get prefCountryQuestion;

  /// No description provided for @prefCountryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. India, UAE, UK, Any'**
  String get prefCountryHint;

  /// No description provided for @strictMatchLabel.
  ///
  /// In en, this message translates to:
  /// **'Strict (only show matches with this)'**
  String get strictMatchLabel;

  /// No description provided for @locationRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Location required'**
  String get locationRequiredTitle;

  /// No description provided for @locationRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Shubhmilan needs your location to keep the community safe and to record where your profile is created. We use it only for safety and support—never shared without your consent.'**
  String get locationRequiredMessage;

  /// No description provided for @locationAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get locationAllow;

  /// No description provided for @locationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get locationOpenSettings;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Please turn on location in your device settings to continue.'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access was denied. Enable it in settings to use the app.'**
  String get locationPermissionDenied;

  /// No description provided for @profileCreationLocationError.
  ///
  /// In en, this message translates to:
  /// **'We need your location to create your profile (for safety and support). Please allow location and try again.'**
  String get profileCreationLocationError;

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

  /// No description provided for @toastInterestSent.
  ///
  /// In en, this message translates to:
  /// **'Interest sent'**
  String get toastInterestSent;

  /// No description provided for @toastInterestSentTo.
  ///
  /// In en, this message translates to:
  /// **'Interest sent to {name}'**
  String toastInterestSentTo(Object name);

  /// No description provided for @toastAddedToShortlist.
  ///
  /// In en, this message translates to:
  /// **'Added to shortlist'**
  String get toastAddedToShortlist;

  /// No description provided for @toastRemovedFromShortlist.
  ///
  /// In en, this message translates to:
  /// **'Removed from shortlist'**
  String get toastRemovedFromShortlist;

  /// No description provided for @toastMatchWith.
  ///
  /// In en, this message translates to:
  /// **'It\'s a match with {name}!'**
  String toastMatchWith(Object name);

  /// No description provided for @toastBlocked.
  ///
  /// In en, this message translates to:
  /// **'{name} blocked'**
  String toastBlocked(Object name);

  /// No description provided for @toastReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you.'**
  String get toastReportSubmitted;

  /// No description provided for @toastErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get toastErrorGeneric;

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

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @chooseAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseAppLanguage;

  /// No description provided for @languageSelectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in settings.'**
  String get languageSelectSubtitle;

  /// No description provided for @languageSetTo.
  ///
  /// In en, this message translates to:
  /// **'Language set to {name}'**
  String languageSetTo(Object name);

  /// No description provided for @saathiMode.
  ///
  /// In en, this message translates to:
  /// **'Shubhmilan mode'**
  String get saathiMode;

  /// No description provided for @accountAndData.
  ///
  /// In en, this message translates to:
  /// **'Account & data'**
  String get accountAndData;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @discoverPass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get discoverPass;

  /// No description provided for @discoverLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get discoverLike;

  /// No description provided for @discoverSuperLike.
  ///
  /// In en, this message translates to:
  /// **'Super like'**
  String get discoverSuperLike;

  /// No description provided for @trustBadgeStrong.
  ///
  /// In en, this message translates to:
  /// **'High trust'**
  String get trustBadgeStrong;

  /// No description provided for @trustBadgeGood.
  ///
  /// In en, this message translates to:
  /// **'Verified trust'**
  String get trustBadgeGood;

  /// No description provided for @trustBadgeBasic.
  ///
  /// In en, this message translates to:
  /// **'Growing trust'**
  String get trustBadgeBasic;

  /// No description provided for @sharedInterestsReason.
  ///
  /// In en, this message translates to:
  /// **'Shared interests: {interests}'**
  String sharedInterestsReason(String interests);

  /// No description provided for @suggestedOpenersTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested openers'**
  String get suggestedOpenersTitle;

  /// No description provided for @suggestedOpenersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick one to start the conversation faster.'**
  String get suggestedOpenersSubtitle;

  /// No description provided for @openerHiName.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}, great to match with you!'**
  String openerHiName(String name);

  /// No description provided for @openerSharedInterest.
  ///
  /// In en, this message translates to:
  /// **'I noticed we both like {interest}. What got you into it?'**
  String openerSharedInterest(String interest);

  /// No description provided for @openerWeekendQuestion.
  ///
  /// In en, this message translates to:
  /// **'What does your ideal weekend look like?'**
  String get openerWeekendQuestion;

  /// No description provided for @openerCityQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do you like living in {city}?'**
  String openerCityQuestion(String city);

  /// No description provided for @chatEmojiTooltip.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get chatEmojiTooltip;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get chatMessageHint;

  /// No description provided for @discoverSwipePassHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe left to pass'**
  String get discoverSwipePassHint;

  /// No description provided for @discoverSwipeLikeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to like'**
  String get discoverSwipeLikeHint;

  /// No description provided for @discoverSwipeSuperLikeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe up for super like'**
  String get discoverSwipeSuperLikeHint;

  /// No description provided for @downloadMyData.
  ///
  /// In en, this message translates to:
  /// **'Download my data'**
  String get downloadMyData;

  /// No description provided for @requestDataCopy.
  ///
  /// In en, this message translates to:
  /// **'Request a copy of your data'**
  String get requestDataCopy;

  /// No description provided for @deactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate account'**
  String get deactivateAccount;

  /// No description provided for @deactivateAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Temporarily disable your account'**
  String get deactivateAccountSubtitle;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get deleteAccountSubtitle;

  /// No description provided for @boostProfile.
  ///
  /// In en, this message translates to:
  /// **'Boost profile'**
  String get boostProfile;

  /// No description provided for @appearMoreInDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Appear more in discovery'**
  String get appearMoreInDiscovery;

  /// No description provided for @verificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ID, photo, LinkedIn'**
  String get verificationSubtitle;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedUsers;

  /// No description provided for @blockedUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and unblock people you\'ve blocked'**
  String get blockedUsersSubtitle;

  /// No description provided for @showInVisitors.
  ///
  /// In en, this message translates to:
  /// **'Show in visitors'**
  String get showInVisitors;

  /// No description provided for @whoCanSeeMyProfile.
  ///
  /// In en, this message translates to:
  /// **'Who can see my profile'**
  String get whoCanSeeMyProfile;

  /// No description provided for @everyone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get everyone;

  /// No description provided for @onlyMyMatches.
  ///
  /// In en, this message translates to:
  /// **'Only my matches'**
  String get onlyMyMatches;

  /// No description provided for @onlyAfterInterest.
  ///
  /// In en, this message translates to:
  /// **'Only after interest'**
  String get onlyAfterInterest;

  /// No description provided for @hideFromDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Hide from discovery'**
  String get hideFromDiscovery;

  /// No description provided for @privacySettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings saved'**
  String get privacySettingsSaved;

  /// No description provided for @switchToMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to {mode}?'**
  String switchToMode(Object mode);

  /// No description provided for @switchToModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Switch to {mode}'**
  String switchToModeLabel(Object mode);

  /// No description provided for @switchButton.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchButton;

  /// No description provided for @addOtherModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {mode}?'**
  String addOtherModeTitle(Object mode);

  /// No description provided for @addOtherModeBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll now be on both Dating and Matrimony. Your profile info is shared—most details are already filled from your current mode. You can switch between them anytime in Settings.'**
  String get addOtherModeBody;

  /// No description provided for @addOtherModeCta.
  ///
  /// In en, this message translates to:
  /// **'Add {mode}'**
  String addOtherModeCta(Object mode);

  /// No description provided for @requestFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Request failed. Try again later.'**
  String get requestFailedTryAgain;

  /// No description provided for @deactivateAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deactivate account?'**
  String get deactivateAccountConfirm;

  /// No description provided for @deactivationFailed.
  ///
  /// In en, this message translates to:
  /// **'Deactivation failed. Try again.'**
  String get deactivationFailed;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete account permanently?'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. All your data will be permanently deleted.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountTypeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'To confirm, type DELETE below.'**
  String get deleteAccountTypeToConfirm;

  /// No description provided for @deleteAccountConfirmationPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteAccountConfirmationPlaceholder;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed. Try again.'**
  String get deleteFailed;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deletePermanently;

  /// No description provided for @notificationPreferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences saved'**
  String get notificationPreferencesSaved;

  /// No description provided for @noFcmToken.
  ///
  /// In en, this message translates to:
  /// **'No FCM token (check permission)'**
  String get noFcmToken;

  /// No description provided for @copyFcmToken.
  ///
  /// In en, this message translates to:
  /// **'Copy FCM token'**
  String get copyFcmToken;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile: {error}'**
  String errorLoadingProfile(Object error);

  /// No description provided for @noProfileYet.
  ///
  /// In en, this message translates to:
  /// **'No profile yet'**
  String get noProfileYet;

  /// No description provided for @createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get createProfile;

  /// No description provided for @basicDetails.
  ///
  /// In en, this message translates to:
  /// **'Basic details'**
  String get basicDetails;

  /// No description provided for @religionAndCommunity.
  ///
  /// In en, this message translates to:
  /// **'Religion & Community'**
  String get religionAndCommunity;

  /// No description provided for @physicalAttributes.
  ///
  /// In en, this message translates to:
  /// **'Physical Attributes'**
  String get physicalAttributes;

  /// No description provided for @educationAndCareer.
  ///
  /// In en, this message translates to:
  /// **'Education & Career'**
  String get educationAndCareer;

  /// No description provided for @lifestyleAndHabits.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle & Habits'**
  String get lifestyleAndHabits;

  /// No description provided for @interestsAndHobbiesSection.
  ///
  /// In en, this message translates to:
  /// **'Interests & Hobbies'**
  String get interestsAndHobbiesSection;

  /// No description provided for @familySection.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familySection;

  /// No description provided for @horoscopeSection.
  ///
  /// In en, this message translates to:
  /// **'Horoscope'**
  String get horoscopeSection;

  /// No description provided for @aboutMeSection.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get aboutMeSection;

  /// No description provided for @partnerPreferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Partner preferences'**
  String get partnerPreferencesSection;

  /// No description provided for @photosSection.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photosSection;

  /// No description provided for @languagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @originLabel.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get originLabel;

  /// No description provided for @degreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get degreeLabel;

  /// No description provided for @institutionLabel.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get institutionLabel;

  /// No description provided for @yearOfGraduation.
  ///
  /// In en, this message translates to:
  /// **'Year of graduation'**
  String get yearOfGraduation;

  /// No description provided for @gradeClassification.
  ///
  /// In en, this message translates to:
  /// **'Grade / classification'**
  String get gradeClassification;

  /// No description provided for @employer.
  ///
  /// In en, this message translates to:
  /// **'Employer'**
  String get employer;

  /// No description provided for @industry.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get industry;

  /// No description provided for @communityLabel.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityLabel;

  /// No description provided for @educationAndCareerTitle.
  ///
  /// In en, this message translates to:
  /// **'Education & career'**
  String get educationAndCareerTitle;

  /// No description provided for @familyTitle.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familyTitle;

  /// No description provided for @lifestyleTitleSection.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get lifestyleTitleSection;

  /// No description provided for @horoscopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Horoscope'**
  String get horoscopeTitle;

  /// No description provided for @lookingForTitle.
  ///
  /// In en, this message translates to:
  /// **'Looking for'**
  String get lookingForTitle;

  /// No description provided for @partnerPrefLocations.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get partnerPrefLocations;

  /// No description provided for @partnerPrefCountries.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get partnerPrefCountries;

  /// No description provided for @partnerPrefSettledAbroad.
  ///
  /// In en, this message translates to:
  /// **'Settled abroad'**
  String get partnerPrefSettledAbroad;

  /// No description provided for @partnerPrefHoroscopeMatch.
  ///
  /// In en, this message translates to:
  /// **'Horoscope match'**
  String get partnerPrefHoroscopeMatch;

  /// No description provided for @partnerPrefPreferred.
  ///
  /// In en, this message translates to:
  /// **'Preferred'**
  String get partnerPrefPreferred;

  /// No description provided for @partnerPrefStrictSuffix.
  ///
  /// In en, this message translates to:
  /// **' (Strict)'**
  String get partnerPrefStrictSuffix;

  /// No description provided for @requestAgain.
  ///
  /// In en, this message translates to:
  /// **'Request again'**
  String get requestAgain;

  /// No description provided for @requestContact.
  ///
  /// In en, this message translates to:
  /// **'Request contact'**
  String get requestContact;

  /// No description provided for @contactRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Contact request sent'**
  String get contactRequestSent;

  /// No description provided for @couldNotSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not send request: {error}'**
  String couldNotSendRequest(Object error);

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @contactShared.
  ///
  /// In en, this message translates to:
  /// **'Contact shared. They can now call or message you.'**
  String get contactShared;

  /// No description provided for @couldNotAccept.
  ///
  /// In en, this message translates to:
  /// **'Could not accept: {error}'**
  String couldNotAccept(Object error);

  /// No description provided for @requestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get requestDeclined;

  /// No description provided for @couldNotDecline.
  ///
  /// In en, this message translates to:
  /// **'Could not decline: {error}'**
  String couldNotDecline(Object error);

  /// No description provided for @interested.
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get interested;

  /// No description provided for @priorityInterest.
  ///
  /// In en, this message translates to:
  /// **'Priority interest'**
  String get priorityInterest;

  /// No description provided for @prioritySent.
  ///
  /// In en, this message translates to:
  /// **'Priority sent'**
  String get prioritySent;

  /// No description provided for @addPriority.
  ///
  /// In en, this message translates to:
  /// **'Add priority'**
  String get addPriority;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @withdrawInterest.
  ///
  /// In en, this message translates to:
  /// **'Withdraw interest'**
  String get withdrawInterest;

  /// No description provided for @declineRequest.
  ///
  /// In en, this message translates to:
  /// **'Decline request'**
  String get declineRequest;

  /// No description provided for @noContactRequests.
  ///
  /// In en, this message translates to:
  /// **'No contact requests'**
  String get noContactRequests;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @failedToSendTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to send. Try again.'**
  String get failedToSendTryAgain;

  /// No description provided for @blockUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block user?'**
  String get blockUserConfirm;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get reportUser;

  /// No description provided for @reportUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Report user?'**
  String get reportUserConfirm;

  /// No description provided for @reportUserMessage.
  ///
  /// In en, this message translates to:
  /// **'Report {name} for inappropriate behaviour?'**
  String reportUserMessage(Object name);

  /// No description provided for @reportSubmittedThankYou.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you.'**
  String get reportSubmittedThankYou;

  /// No description provided for @changeCity.
  ///
  /// In en, this message translates to:
  /// **'Change city'**
  String get changeCity;

  /// No description provided for @yourArea.
  ///
  /// In en, this message translates to:
  /// **'Your area'**
  String get yourArea;

  /// No description provided for @showProfilesNearYou.
  ///
  /// In en, this message translates to:
  /// **'Show profiles near you'**
  String get showProfilesNearYou;

  /// No description provided for @nearbyCities.
  ///
  /// In en, this message translates to:
  /// **'Nearby cities'**
  String get nearbyCities;

  /// No description provided for @browseByCountry.
  ///
  /// In en, this message translates to:
  /// **'Browse by country'**
  String get browseByCountry;

  /// No description provided for @activeUsersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String activeUsersCount(int count);

  /// No description provided for @unblocked.
  ///
  /// In en, this message translates to:
  /// **'{name} unblocked'**
  String unblocked(Object name);

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @whyBlocking.
  ///
  /// In en, this message translates to:
  /// **'Why are you blocking?'**
  String get whyBlocking;

  /// No description provided for @whyReporting.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting?'**
  String get whyReporting;

  /// No description provided for @blockedUsersScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedUsersScreenTitle;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @noChatRequests.
  ///
  /// In en, this message translates to:
  /// **'No chat requests'**
  String get noChatRequests;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @yrs.
  ///
  /// In en, this message translates to:
  /// **'{age} yrs'**
  String yrs(Object age);

  /// No description provided for @idVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a government ID. We match it to your photo.'**
  String get idVerificationSubtitle;

  /// No description provided for @faceMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Selfie matched to your ID photo.'**
  String get faceMatchSubtitle;

  /// No description provided for @linkedInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect your LinkedIn to verify work.'**
  String get linkedInSubtitle;

  /// No description provided for @educationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your university or college.'**
  String get educationSubtitle;

  /// No description provided for @verificationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{feature} verification coming soon'**
  String verificationComingSoon(Object feature);

  /// No description provided for @uploadUrlNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Upload URL not available'**
  String get uploadUrlNotAvailable;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {code}'**
  String uploadFailed(Object code);

  /// No description provided for @idSubmittedNotify.
  ///
  /// In en, this message translates to:
  /// **'ID submitted. We\'ll notify you when verification is complete.'**
  String get idSubmittedNotify;

  /// No description provided for @uploadFailedError.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String uploadFailedError(Object error);

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get chooseFile;

  /// No description provided for @photoVerification.
  ///
  /// In en, this message translates to:
  /// **'Photo verification'**
  String get photoVerification;

  /// No description provided for @startVerification.
  ///
  /// In en, this message translates to:
  /// **'Start verification'**
  String get startVerification;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @imReady.
  ///
  /// In en, this message translates to:
  /// **'I\'m ready'**
  String get imReady;

  /// No description provided for @simulateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Simulate success'**
  String get simulateSuccess;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @subscriptionActivated.
  ///
  /// In en, this message translates to:
  /// **'Subscription activated!'**
  String get subscriptionActivated;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed: {error}'**
  String purchaseFailed(Object error);

  /// No description provided for @purchasesRestored.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored!'**
  String get purchasesRestored;

  /// No description provided for @noActivePurchases.
  ///
  /// In en, this message translates to:
  /// **'No active purchases found.'**
  String get noActivePurchases;

  /// No description provided for @couldNotRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Could not restore purchases.'**
  String get couldNotRestorePurchases;

  /// No description provided for @boostPack.
  ///
  /// In en, this message translates to:
  /// **'Boost pack'**
  String get boostPack;

  /// No description provided for @mostRecent.
  ///
  /// In en, this message translates to:
  /// **'Most recent'**
  String get mostRecent;

  /// No description provided for @mostInterested.
  ///
  /// In en, this message translates to:
  /// **'Most interested'**
  String get mostInterested;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @noMatchesYet.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get noMatchesYet;

  /// No description provided for @sendYourNote.
  ///
  /// In en, this message translates to:
  /// **'Send your note'**
  String get sendYourNote;

  /// No description provided for @savedSearches.
  ///
  /// In en, this message translates to:
  /// **'Saved searches'**
  String get savedSearches;

  /// No description provided for @searchSaved.
  ///
  /// In en, this message translates to:
  /// **'Search saved'**
  String get searchSaved;

  /// No description provided for @couldNotSaveSearch.
  ///
  /// In en, this message translates to:
  /// **'Could not save search'**
  String get couldNotSaveSearch;

  /// No description provided for @saveSearch.
  ///
  /// In en, this message translates to:
  /// **'Save search'**
  String get saveSearch;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get preferredLanguage;

  /// No description provided for @preferredLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional — we\'ll use this for content and matches.'**
  String get preferredLanguageSubtitle;

  /// No description provided for @mapFilters.
  ///
  /// In en, this message translates to:
  /// **'Map filters'**
  String get mapFilters;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @rsvp.
  ///
  /// In en, this message translates to:
  /// **'RSVP'**
  String get rsvp;

  /// No description provided for @rsvpdTo.
  ///
  /// In en, this message translates to:
  /// **'RSVP\'d to {title}'**
  String rsvpdTo(Object title);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @shellRequiresProvider.
  ///
  /// In en, this message translates to:
  /// **'Shell requires Provider'**
  String get shellRequiresProvider;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @conversationStarter.
  ///
  /// In en, this message translates to:
  /// **'Conversation starter'**
  String get conversationStarter;

  /// No description provided for @switchToModeBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile info is shared. You can complete or update {mode}-specific details anytime.'**
  String switchToModeBody(Object mode);

  /// No description provided for @exportRequested.
  ///
  /// In en, this message translates to:
  /// **'Export requested. We\'ll email you when ready.'**
  String get exportRequested;

  /// No description provided for @deactivateAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile will be hidden and you won\'t receive matches or messages. You can reactivate later.'**
  String get deactivateAccountConfirmBody;

  /// No description provided for @reactivateAccountPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Account deactivated'**
  String get reactivateAccountPromptTitle;

  /// No description provided for @reactivateAccountPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is deactivated. Do you want to reactivate it?'**
  String get reactivateAccountPromptBody;

  /// No description provided for @reactivateAccountYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, reactivate'**
  String get reactivateAccountYes;

  /// No description provided for @reactivateAccountNo.
  ///
  /// In en, this message translates to:
  /// **'No, stay signed out'**
  String get reactivateAccountNo;

  /// No description provided for @showInVisitorsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When off, your visits are still recorded but you won\'t appear in others\' visitor lists'**
  String get showInVisitorsSubtitle;

  /// No description provided for @hideFromDiscoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Temporarily hide your profile from discovery and recommendations'**
  String get hideFromDiscoverySubtitle;

  /// No description provided for @hideMyPhotos.
  ///
  /// In en, this message translates to:
  /// **'Hide my photos'**
  String get hideMyPhotos;

  /// No description provided for @hideMyPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Others must request to view your photos; you approve or decline in Requests.'**
  String get hideMyPhotosSubtitle;

  /// No description provided for @requestToViewPhotos.
  ///
  /// In en, this message translates to:
  /// **'Request to view photos'**
  String get requestToViewPhotos;

  /// No description provided for @requestToViewPhotosSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get requestToViewPhotosSent;

  /// No description provided for @photoViewRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Request pending'**
  String get photoViewRequestPending;

  /// No description provided for @requestedToViewYourPhotos.
  ///
  /// In en, this message translates to:
  /// **'Requested to view your photos'**
  String get requestedToViewYourPhotos;

  /// No description provided for @noPhotoViewRequests.
  ///
  /// In en, this message translates to:
  /// **'No photo view requests'**
  String get noPhotoViewRequests;

  /// No description provided for @noPhotoViewRequestsBody.
  ///
  /// In en, this message translates to:
  /// **'When someone requests to view your photos, you can accept or decline here.'**
  String get noPhotoViewRequestsBody;

  /// No description provided for @photoViewRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'They can now view your photos.'**
  String get photoViewRequestAccepted;

  /// No description provided for @photoViewRequestsTab.
  ///
  /// In en, this message translates to:
  /// **'Photo view'**
  String get photoViewRequestsTab;

  /// No description provided for @photosLocked.
  ///
  /// In en, this message translates to:
  /// **'Photos are private'**
  String get photosLocked;

  /// No description provided for @photosLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Request access to view their photos'**
  String get photosLockedHint;

  /// No description provided for @blockUserMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} won\'t be able to see your profile or contact you.'**
  String blockUserMessage(Object name);

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get yourProfile;

  /// No description provided for @aboutYouShort.
  ///
  /// In en, this message translates to:
  /// **'A few lines about you'**
  String get aboutYouShort;

  /// No description provided for @recordYourIntro.
  ///
  /// In en, this message translates to:
  /// **'Record your intro'**
  String get recordYourIntro;

  /// No description provided for @heritageType.
  ///
  /// In en, this message translates to:
  /// **'Heritage / type of Indian'**
  String get heritageType;

  /// No description provided for @communityTagsOptional.
  ///
  /// In en, this message translates to:
  /// **'Community tags (optional)'**
  String get communityTagsOptional;

  /// No description provided for @communityTagsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select any that apply — helps with circles and events.'**
  String get communityTagsSubtitle;

  /// No description provided for @familyOrientation.
  ///
  /// In en, this message translates to:
  /// **'Family orientation'**
  String get familyOrientation;

  /// No description provided for @familyOrientationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Slide to reflect your preference — no wrong answer.'**
  String get familyOrientationSubtitle;

  /// No description provided for @traditionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Traditional'**
  String get traditionalLabel;

  /// No description provided for @progressiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Progressive'**
  String get progressiveLabel;

  /// No description provided for @dietLifestyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Diet / lifestyle'**
  String get dietLifestyleTitle;

  /// No description provided for @dietLifestyleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helps with date ideas and filters.'**
  String get dietLifestyleSubtitle;

  /// No description provided for @activeNowOnly.
  ///
  /// In en, this message translates to:
  /// **'Active now only'**
  String get activeNowOnly;

  /// No description provided for @activeNowOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show only people active in the last 24h'**
  String get activeNowOnlySubtitle;

  /// No description provided for @locationBlur.
  ///
  /// In en, this message translates to:
  /// **'Location blur'**
  String get locationBlur;

  /// No description provided for @locationBlurSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show approximate area instead of exact pin'**
  String get locationBlurSubtitle;

  /// No description provided for @verificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verificationTitle;

  /// No description provided for @feetUnit.
  ///
  /// In en, this message translates to:
  /// **'ft'**
  String get feetUnit;

  /// No description provided for @inchesUnit.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get inchesUnit;

  /// No description provided for @clearButton.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get clearButton;

  /// No description provided for @yearsFormat.
  ///
  /// In en, this message translates to:
  /// **'{age} years'**
  String yearsFormat(Object age);

  /// No description provided for @profileManagedByParent.
  ///
  /// In en, this message translates to:
  /// **'Profile managed by parent'**
  String get profileManagedByParent;

  /// No description provided for @profileManagedByGuardian.
  ///
  /// In en, this message translates to:
  /// **'Profile managed by guardian'**
  String get profileManagedByGuardian;

  /// No description provided for @profileManagedBySibling.
  ///
  /// In en, this message translates to:
  /// **'Profile managed by sibling'**
  String get profileManagedBySibling;

  /// No description provided for @profileManagedByFriend.
  ///
  /// In en, this message translates to:
  /// **'Profile managed by friend'**
  String get profileManagedByFriend;

  /// No description provided for @blockUserMessageChat.
  ///
  /// In en, this message translates to:
  /// **'They won\'t be able to contact you anymore.'**
  String get blockUserMessageChat;

  /// No description provided for @reportUserMessageChat.
  ///
  /// In en, this message translates to:
  /// **'We take safety seriously and will review this report.'**
  String get reportUserMessageChat;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockUser;

  /// No description provided for @matchToContinueOrUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Match to continue or upgrade'**
  String get matchToContinueOrUpgrade;

  /// No description provided for @noConversationsYetBody.
  ///
  /// In en, this message translates to:
  /// **'When you match with someone, your chats will appear here.'**
  String get noConversationsYetBody;

  /// No description provided for @noChatRequestsBody.
  ///
  /// In en, this message translates to:
  /// **'When someone sends you an interest, you can accept here to start chatting.'**
  String get noChatRequestsBody;

  /// No description provided for @inboundRequest.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get inboundRequest;

  /// No description provided for @outboundRequest.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get outboundRequest;

  /// No description provided for @noContactRequestsBody.
  ///
  /// In en, this message translates to:
  /// **'When someone requests your contact, you can accept or decline here.'**
  String get noContactRequestsBody;

  /// No description provided for @requestedYourContact.
  ///
  /// In en, this message translates to:
  /// **'Requested your contact'**
  String get requestedYourContact;

  /// No description provided for @withdrawPriority.
  ///
  /// In en, this message translates to:
  /// **'Withdraw priority'**
  String get withdrawPriority;

  /// No description provided for @withdrawPriorityAndInterest.
  ///
  /// In en, this message translates to:
  /// **'Withdraw priority (and interest)'**
  String get withdrawPriorityAndInterest;

  /// No description provided for @additionalDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)'**
  String get additionalDetailsOptional;

  /// No description provided for @reportDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Add any context that might help our team'**
  String get reportDetailsHint;

  /// No description provided for @translate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translate;

  /// No description provided for @translating.
  ///
  /// In en, this message translates to:
  /// **'Translating...'**
  String get translating;

  /// No description provided for @showOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show original'**
  String get showOriginal;

  /// No description provided for @showTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get showTranslation;

  /// No description provided for @translationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Translation unavailable'**
  String get translationUnavailable;

  /// No description provided for @noVisitorsYet.
  ///
  /// In en, this message translates to:
  /// **'No visitors yet'**
  String get noVisitorsYet;

  /// No description provided for @noVisitorsYetBody.
  ///
  /// In en, this message translates to:
  /// **'Profiles who viewed you will appear here. Complete your profile to get noticed.'**
  String get noVisitorsYetBody;

  /// No description provided for @visitorUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock this profile'**
  String get visitorUnlockTitle;

  /// No description provided for @visitorUnlockWatchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to unlock ({remaining} left this week)'**
  String visitorUnlockWatchAd(int remaining);

  /// No description provided for @visitorUnlockLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all 2 unlocks this week. Try again later or upgrade to Premium.'**
  String get visitorUnlockLimitReached;

  /// No description provided for @visitorUnlockUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get visitorUnlockUpgrade;

  /// No description provided for @visitorUnlockPremiumRequired.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium to see who visited you, or unlock 2 profiles per week by watching an ad.'**
  String get visitorUnlockPremiumRequired;

  /// No description provided for @noMatchesYetBody.
  ///
  /// In en, this message translates to:
  /// **'When you and someone else both express interest, you\'ll match and appear here.'**
  String get noMatchesYetBody;

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get noMatchesFound;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters for more results.'**
  String get tryAdjustingFilters;

  /// No description provided for @exploreProfiles.
  ///
  /// In en, this message translates to:
  /// **'Explore profiles'**
  String get exploreProfiles;

  /// No description provided for @exploreProfilesBody.
  ///
  /// In en, this message translates to:
  /// **'Use the filter icon above to search by age, city, religion, education and more.'**
  String get exploreProfilesBody;
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
