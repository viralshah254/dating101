import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_typography.dart';
import 'safety_reasons.dart';

/// Shows a dialog to choose a block reason. Returns the selected reason code or null if cancelled.
Future<String?> showBlockReasonPicker(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  String? selected;
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          title: Text(l.whyBlocking),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: blockReasonCodes.map((code) {
                    final label = blockReasonLabels[code] ?? code;
                    final isSelected = selected == code;
                    return FilterChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (v) =>
                          setState(() => selected = v ? code : null),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.pop(ctx, selected),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l.continueLabel),
            ),
          ],
        );
      },
    ),
  );
}

/// Result of report reason picker: reason code and optional details.
class ReportReasonResult {
  const ReportReasonResult({required this.reason, this.details});
  final String reason;
  final String? details;
}

/// Shows a dialog to choose a report reason and optional details. Returns result or null if cancelled.
Future<ReportReasonResult?> showReportReasonPicker(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  String? selected;
  final detailsController = TextEditingController();
  final result = await showDialog<ReportReasonResult>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          title: Text(l.whyReporting),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: reportReasonCodes.map((code) {
                    final label = reportReasonLabels[code] ?? code;
                    final isSelected = selected == code;
                    return FilterChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (v) =>
                          setState(() => selected = v ? code : null),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  l.additionalDetailsOptional,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l.reportDetailsHint,
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () {
                      final details = detailsController.text.trim();
                      Navigator.pop(
                        ctx,
                        ReportReasonResult(
                          reason: selected!,
                          details: details.isEmpty ? null : details,
                        ),
                      );
                    },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l.continueLabel),
            ),
          ],
        );
      },
    ),
  );
  detailsController.dispose();
  return result;
}
