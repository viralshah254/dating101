import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The value selected on the "Who is this profile for?" screen.
/// `null` = Myself. Non-null = a family role string (e.g. `'daughter'`).
/// Persists in memory for the duration of the sign-up flow so
/// [ProfileSetupScreen] can pre-seed [ProfileFormData.creatingFor] and skip
/// the in-wizard [StepCreatingFor].
final creatingForProvider = StateProvider<String?>((ref) => null);

/// Becomes `true` once the user confirms on [ProfileForScreen].
/// Distinguishes "user chose Myself (null)" from "screen not yet visited (null)".
final creatingForAnsweredProvider = StateProvider<bool>((ref) => false);
