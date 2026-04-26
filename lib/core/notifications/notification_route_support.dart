import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Push/deep links often use [GoRouter.go], which leaves no stack entry to [pop].
/// Call this from a back affordance: pop when possible, otherwise run [onCannotPop]
/// (typically `context.go('/')` or a shell tab).
void handleNotificationAwarePop(
  BuildContext context, {
  required VoidCallback onCannotPop,
}) {
  if (Navigator.of(context).canPop()) {
    context.pop();
  } else {
    onCannotPop();
  }
}

/// Standard AppBar back control for screens that may open as the only route.
Widget notificationAwareBackButton(
  BuildContext context, {
  required VoidCallback onCannotPop,
}) {
  return IconButton(
    icon: const Icon(Icons.arrow_back_rounded),
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: () => handleNotificationAwarePop(context, onCannotPop: onCannotPop),
  );
}
