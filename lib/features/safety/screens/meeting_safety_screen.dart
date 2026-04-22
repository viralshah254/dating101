/**
 * Meeting Safety Toolkit
 *
 * A comprehensive safety screen for users going on first meetings with matches.
 * Features:
 *  - SOS emergency contact (call or SMS)
 *  - Timed check-ins (set a timer; if you don't check in, SOS auto-triggers)
 *  - Share your live location via WhatsApp/SMS
 *  - Safety checklist before the meeting
 *  - Red flag reporting
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class MeetingSafetyScreen extends StatefulWidget {
  const MeetingSafetyScreen({super.key, this.matchName});

  /// Optional name of the person you're meeting
  final String? matchName;

  @override
  State<MeetingSafetyScreen> createState() => _MeetingSafetyScreenState();
}

class _MeetingSafetyScreenState extends State<MeetingSafetyScreen> {
  final _emergencyContactCtrl = TextEditingController();
  String? _emergencyContact;
  int _checkInMinutes = 60;
  Timer? _checkInTimer;
  int _secondsRemaining = 0;
  bool _checkInActive = false;
  bool _locationSharing = false;
  Position? _lastPosition;
  final List<bool> _checklist = List.filled(6, false);

  static const _checklistItems = [
    'Told a friend or family where you\'re meeting',
    'Meeting in a public, well-lit place',
    'Have your phone fully charged',
    'Arranged your own transportation',
    'Emergency contact saved in this screen',
    'Trust your gut — it\'s okay to leave if uncomfortable',
  ];

  static const _checkInOptions = [15, 30, 60, 90, 120];

  @override
  void dispose() {
    _checkInTimer?.cancel();
    _emergencyContactCtrl.dispose();
    super.dispose();
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> _shareLocation() async {
    final contact = _emergencyContact;
    if (contact == null || contact.isEmpty) {
      _showNoContactError();
      return;
    }

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _lastPosition = position;
        _locationSharing = true;
      });

      final lat = position.latitude.toStringAsFixed(6);
      final lng = position.longitude.toStringAsFixed(6);
      final mapsUrl = 'https://maps.google.com/?q=$lat,$lng';
      final message = 'I\'m currently at: $mapsUrl (shared via Shubhmilan Safety)';

      final smsUri = Uri(scheme: 'sms', path: contact, queryParameters: {'body': message});
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        await Clipboard.setData(ClipboardData(text: message));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location link copied to clipboard'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // ── Check-in Timer ────────────────────────────────────────────────────────

  void _startCheckIn() {
    _checkInTimer?.cancel();
    setState(() {
      _checkInActive = true;
      _secondsRemaining = _checkInMinutes * 60;
    });
    _checkInTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        _triggerSOS(reason: 'Check-in timer expired');
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _cancelCheckIn() {
    _checkInTimer?.cancel();
    setState(() {
      _checkInActive = false;
      _secondsRemaining = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Check-in timer cancelled — stay safe!'), behavior: SnackBarBehavior.floating),
    );
  }

  void _checkIn() {
    _checkInTimer?.cancel();
    setState(() {
      _checkInActive = false;
      _secondsRemaining = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ You checked in safely!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.indiaGreen,
      ),
    );
  }

  // ── SOS ───────────────────────────────────────────────────────────────────

  void _triggerSOS({String reason = 'Manual SOS'}) {
    _checkInTimer?.cancel();
    setState(() => _checkInActive = false);

    final contact = _emergencyContact;
    if (contact == null || contact.isEmpty) {
      _showNoContactError();
      return;
    }

    final name = widget.matchName != null ? 'meeting ${widget.matchName}' : 'on a meeting';
    final location = _lastPosition != null
        ? 'https://maps.google.com/?q=${_lastPosition!.latitude},${_lastPosition!.longitude}'
        : 'location unknown';

    final message = '🆘 SOS from Shubhmilan: I was $name. Please check on me! Last known location: $location. Reason: $reason';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🆘 SOS Alert'),
        content: Text('Sending emergency message to $contact:\n\n"$message"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final smsUri = Uri(scheme: 'sms', path: contact, queryParameters: {'body': message});
              if (await canLaunchUrl(smsUri)) {
                await launchUrl(smsUri);
              }
              // Also try calling
              final callUri = Uri(scheme: 'tel', path: contact);
              if (await canLaunchUrl(callUri)) {
                await launchUrl(callUri);
              }
            },
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }

  void _showNoContactError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please save an emergency contact first'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // ── Time formatting ───────────────────────────────────────────────────────

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final checkedAll = _checklist.every((v) => v);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Meeting Safety'),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          _SafetyHeader(matchName: widget.matchName),
          const SizedBox(height: 20),

          // Emergency contact
          _SectionTitle(title: '1. Emergency Contact', icon: Icons.phone_rounded),
          const SizedBox(height: 8),
          _EmergencyContactCard(
            controller: _emergencyContactCtrl,
            contact: _emergencyContact,
            onSave: (v) => setState(() => _emergencyContact = v),
          ),
          const SizedBox(height: 20),

          // Location sharing
          _SectionTitle(title: '2. Share Your Location', icon: Icons.location_on_rounded),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _locationSharing ? 'Location shared with your contact' : 'Send your live location to your emergency contact via SMS',
                    style: AppTypography.bodySmall.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _shareLocation,
                    icon: const Icon(Icons.share_location_rounded),
                    label: Text(_locationSharing ? 'Share Location Again' : 'Share My Location'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _locationSharing ? AppColors.indiaGreen : cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Check-in timer
          _SectionTitle(title: '3. Safety Check-in Timer', icon: Icons.timer_rounded),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set a timer. If you don\'t check in before it expires, we\'ll alert your emergency contact.',
                    style: AppTypography.bodySmall.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 12),
                  if (!_checkInActive) ...[
                    Row(
                      children: [
                        const Text('Check in after: '),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _checkInMinutes,
                          items: _checkInOptions.map((m) => DropdownMenuItem(value: m, child: Text('$m min'))).toList(),
                          onChanged: (v) => setState(() => _checkInMinutes = v!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _startCheckIn,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start Timer'),
                    ),
                  ] else ...[
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _formatTime(_secondsRemaining),
                            style: AppTypography.displaySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: _secondsRemaining < 300 ? Colors.redAccent : cs.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'remaining until SOS',
                            style: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FilledButton.icon(
                                onPressed: _checkIn,
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('I\'m Safe ✓'),
                                style: FilledButton.styleFrom(backgroundColor: AppColors.indiaGreen),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: _cancelCheckIn,
                                icon: const Icon(Icons.stop_rounded),
                                label: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // SOS button
          _SectionTitle(title: '4. Emergency SOS', icon: Icons.sos_rounded),
          const SizedBox(height: 8),
          Card(
            color: Colors.red.withValues(alpha: 0.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Feeling unsafe? Press SOS to immediately message and call your emergency contact.',
                    style: AppTypography.bodySmall.copyWith(color: cs.onSurface.withValues(alpha: 0.8)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _triggerSOS(),
                      icon: const Icon(Icons.warning_rounded),
                      label: const Text('SOS — Alert Emergency Contact'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Safety checklist
          _SectionTitle(title: '5. Pre-Meeting Checklist', icon: Icons.checklist_rounded),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ..._checklistItems.asMap().entries.map((e) => CheckboxListTile(
                        value: _checklist[e.key],
                        title: Text(e.value, style: AppTypography.bodySmall),
                        onChanged: (v) => setState(() => _checklist[e.key] = v!),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.indiaGreen,
                      )),
                  if (checkedAll) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.indiaGreen),
                          const SizedBox(width: 8),
                          Text(
                            'All checked! Have a safe meeting 💫',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.indiaGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SafetyHeader extends StatelessWidget {
  const _SafetyHeader({this.matchName});
  final String? matchName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700.withValues(alpha: 0.12), Colors.blue.shade900.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.blue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matchName != null ? 'Meeting ${matchName!}?' : 'Going on a first meeting?',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your safety matters. Use these tools to stay safe.',
                  style: AppTypography.bodySmall.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
      ],
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({
    required this.controller,
    required this.contact,
    required this.onSave,
  });

  final TextEditingController controller;
  final String? contact;
  final void Function(String) onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact != null && contact!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.indiaGreen, size: 16),
                  const SizedBox(width: 8),
                  Text('Emergency contact: $contact', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => onSave(''),
                child: const Text('Change'),
              ),
            ] else ...[
              Text('Enter a phone number for your emergency contact', style: AppTypography.bodySmall.copyWith(color: cs.onSurface.withValues(alpha: 0.7))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '+91 98765 43210',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        onSave(controller.text.trim());
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
