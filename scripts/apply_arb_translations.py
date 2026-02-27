#!/usr/bin/env python3
"""Apply translated key-value pairs to ARB files from toastErrorGeneric through navEvents."""
import json
import os

# Keys in order (toastErrorGeneric through navEvents)
KEYS = [
    "toastErrorGeneric", "activeNow", "verified", "managedBy", "lastActive", "kmAway",
    "ageRange", "distance", "city", "religion", "motherTongue", "maritalStatus", "height",
    "educationLevel", "occupation", "income", "diet", "familyType", "familyValues",
    "appLanguage", "chooseAppLanguage", "languageSetTo", "saathiMode", "accountAndData",
    "viewProfile", "downloadMyData", "requestDataCopy", "deactivateAccount",
    "deactivateAccountSubtitle", "deleteAccount", "deleteAccountSubtitle", "boostProfile",
    "appearMoreInDiscovery", "verificationSubtitle", "blockedUsers", "blockedUsersSubtitle",
    "showInVisitors", "whoCanSeeMyProfile", "everyone", "onlyMyMatches", "onlyAfterInterest",
    "hideFromDiscovery", "privacySettingsSaved", "switchToMode", "switchToModeLabel",
    "switchButton", "requestFailedTryAgain", "deactivateAccountConfirm", "deactivationFailed",
    "deactivate", "deleteAccountConfirm", "deleteFailed", "deletePermanently",
    "notificationPreferencesSaved", "noFcmToken", "copyFcmToken", "linkCopied",
    "errorLoadingProfile", "noProfileYet", "createProfile", "basicDetails", "religionAndCommunity",
    "physicalAttributes", "educationAndCareer", "lifestyleAndHabits", "interestsAndHobbiesSection",
    "familySection", "horoscopeSection", "aboutMeSection", "partnerPreferencesSection",
    "photosSection", "languagesLabel", "locationLabel", "originLabel", "degreeLabel",
    "institutionLabel", "yearOfGraduation", "gradeClassification", "employer", "industry",
    "communityLabel", "educationAndCareerTitle", "familyTitle", "lifestyleTitleSection",
    "horoscopeTitle", "lookingForTitle", "requestAgain", "requestContact", "contactRequestSent",
    "couldNotSendRequest", "call", "whatsApp", "contactShared", "couldNotAccept",
    "requestDeclined", "couldNotDecline", "interested", "priorityInterest", "withdrawInterest",
    "declineRequest", "noContactRequests", "upgrade", "failedToSendTryAgain", "blockUserConfirm",
    "reportUser", "reportUserConfirm", "reportUserMessage", "reportSubmittedThankYou",
    "changeCity", "yourArea", "showProfilesNearYou", "unblocked", "somethingWentWrong",
    "whyBlocking", "whyReporting", "blockedUsersScreenTitle", "unblock", "noConversationsYet",
    "noChatRequests", "priority", "yrs", "idVerificationSubtitle", "faceMatchSubtitle",
    "linkedInSubtitle", "educationSubtitle", "verificationComingSoon", "uploadUrlNotAvailable",
    "uploadFailed", "idSubmittedNotify", "uploadFailedError", "chooseFile", "photoVerification",
    "startVerification", "takePhoto", "imReady", "simulateSuccess", "tryAgain",
    "subscriptionActivated", "purchaseFailed", "purchasesRestored", "noActivePurchases",
    "couldNotRestorePurchases", "boostPack", "mostRecent", "mostInterested", "note",
    "noMatchesYet", "sendYourNote", "skipForNow", "savedSearches", "searchSaved",
    "couldNotSaveSearch", "saveSearch", "preferredLanguage", "preferredLanguageSubtitle",
    "mapFilters", "join", "rsvp", "rsvpdTo", "confirm", "reset", "shellRequiresProvider",
    "add", "conversationStarter", "switchToModeBody", "exportRequested",
    "deactivateAccountConfirmBody", "deleteAccountConfirmBody", "showInVisitorsSubtitle",
    "hideFromDiscoverySubtitle", "blockUserMessage", "yourProfile", "yourName", "aboutYouShort",
    "recordYourIntro", "heritageType", "communityTagsOptional", "communityTagsSubtitle",
    "familyOrientation", "familyOrientationSubtitle", "traditionalLabel", "progressiveLabel",
    "dietLifestyleTitle", "dietLifestyleSubtitle", "activeNowOnly", "activeNowOnlySubtitle",
    "locationBlur", "locationBlurSubtitle", "verificationTitle", "feetUnit", "inchesUnit",
    "clearButton", "yearsFormat", "profileManagedByParent", "profileManagedByGuardian",
    "profileManagedBySibling", "profileManagedByFriend", "blockUserMessageChat",
    "reportUserMessageChat", "blockUser", "matchToContinueOrUpgrade", "noConversationsYetBody",
    "noChatRequestsBody", "noContactRequestsBody", "withdrawPriority", "withdrawPriorityAndInterest",
    "additionalDetailsOptional", "reportDetailsHint", "navEvents",
]

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
L10N_DIR = os.path.join(SCRIPT_DIR, "..", "lib", "l10n")


def apply_translations(locale: str, translations: dict) -> None:
    arb_path = os.path.join(L10N_DIR, f"app_{locale}.arb")
    with open(arb_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    for k in KEYS:
        if k in translations:
            data[k] = translations[k]
    with open(arb_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"Updated app_{locale}.arb")


def main():
    from translations_data_ml import ML
    from translations_data_mr import MR
    from translations_data_pa import PA
    from translations_data_ta import TA
    from translations_data_te import TE
    from translations_data_ur import UR

    for locale, trans in [("ml", ML), ("mr", MR), ("pa", PA), ("ta", TA), ("te", TE), ("ur", UR)]:
        apply_translations(locale, trans)


if __name__ == "__main__":
    main()
