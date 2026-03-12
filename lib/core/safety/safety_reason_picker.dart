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
  return showDialog<ReportReasonResult>(
    context: context,
    builder: (ctx) => _ReportReasonPickerDialog(),
  );
}

/// Stateful dialog content so [TextEditingController] is owned and disposed with the dialog.
class _ReportReasonPickerDialog extends StatefulWidget {
  @override
  State<_ReportReasonPickerDialog> createState() =>
      _ReportReasonPickerDialogState();
}

class _ReportReasonPickerDialogState extends State<_ReportReasonPickerDialog> {
  String? _selected;
  late final TextEditingController _detailsController;

  @override
  void initState() {
    super.initState();
    _detailsController = TextEditingController();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
                final isSelected = _selected == code;
                return FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (v) =>
                      setState(() => _selected = v ? code : null),
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
              controller: _detailsController,
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
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () {
                  final details = _detailsController.text.trim();
                  Navigator.pop(
                    context,
                    ReportReasonResult(
                      reason: _selected!,
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
  }
}
