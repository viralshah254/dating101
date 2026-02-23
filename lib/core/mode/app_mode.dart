/// App-wide product mode: Dating vs Matrimony.
/// Influences navigation, copy, profile fields, and actions.
enum AppMode {
  dating,
  matrimony,
}

extension AppModeX on AppMode {
  bool get isDating => this == AppMode.dating;
  bool get isMatrimony => this == AppMode.matrimony;
}
