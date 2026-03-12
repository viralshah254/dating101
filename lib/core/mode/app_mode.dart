/// App-wide product mode: Dating vs Matrimony (and "both" for signup preference).
/// For UI/shell we use effective mode (dating or matrimony only); [both] is a signup preference.
enum AppMode {
  dating,
  matrimony,
  /// User is on both dating and matrimony; discovery/matches are shown per current view.
  both,
}

extension AppModeX on AppMode {
  bool get isDating => this == AppMode.dating;
  bool get isMatrimony => this == AppMode.matrimony;
  bool get isBoth => this == AppMode.both;
  /// True when this is a single feed mode (dating or matrimony), not "both".
  bool get isSingleMode => this == AppMode.dating || this == AppMode.matrimony;
}
