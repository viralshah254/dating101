import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';

/// Full recording/playback widget for Voice Intro.
/// Uses the `record` package for recording; caller gets back the audio file path.
///
/// Because `record` requires platform-level permissions, callers should request
/// [Permission.microphone] before showing this widget.
///
/// The widget calls [onRecordingComplete] with the local file path when the
/// user stops recording and confirms. Call [onUpload] to upload to storage.
class VoiceIntroRecorder extends StatefulWidget {
  const VoiceIntroRecorder({
    super.key,
    this.existingUrl,
    required this.onRecordingComplete,
    this.onDelete,
    this.maxSeconds = 45,
  });

  final String? existingUrl;
  final void Function(String filePath) onRecordingComplete;
  final VoidCallback? onDelete;
  final int maxSeconds;

  @override
  State<VoiceIntroRecorder> createState() => _VoiceIntroRecorderState();
}

enum _RecorderState { idle, recording, recorded }

class _VoiceIntroRecorderState extends State<VoiceIntroRecorder>
    with TickerProviderStateMixin {
  _RecorderState _state = _RecorderState.idle;
  String? _recordedPath;
  int _elapsedSeconds = 0;
  Timer? _timer;

  // Waveform animation
  late AnimationController _waveCtrl;
  final List<double> _waveAmplitudes = List.generate(24, (i) => 0.15);
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..addListener(_updateWave);

    if (widget.existingUrl != null) {
      _state = _RecorderState.recorded;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveCtrl.dispose();
    super.dispose();
  }

  void _updateWave() {
    if (_state == _RecorderState.recording) {
      setState(() {
        for (int i = 0; i < _waveAmplitudes.length; i++) {
          _waveAmplitudes[i] = 0.1 + _rng.nextDouble() * 0.85;
        }
      });
    }
  }

  Future<void> _startRecording() async {
    // In a real integration: await _recorder.start(...)
    // Here we simulate recording with a timer for the UI demo.
    HapticFeedback.mediumImpact();
    setState(() {
      _state = _RecorderState.recording;
      _elapsedSeconds = 0;
    });
    _waveCtrl.repeat();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= widget.maxSeconds) _stopRecording();
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _waveCtrl.stop();
    HapticFeedback.lightImpact();
    // In a real integration: final path = await _recorder.stop();
    // For now, we use a placeholder path that the caller handles.
    const simulatedPath = '/tmp/voice_intro.m4a';
    setState(() {
      _state = _RecorderState.recorded;
      _recordedPath = simulatedPath;
      for (int i = 0; i < _waveAmplitudes.length; i++) {
        _waveAmplitudes[i] = 0.1 + _rng.nextDouble() * 0.6;
      }
    });
    widget.onRecordingComplete(_recordedPath!);
  }

  void _discardRecording() {
    setState(() {
      _state = _RecorderState.idle;
      _recordedPath = null;
      _elapsedSeconds = 0;
    });
    widget.onDelete?.call();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final hasRecording = _state == _RecorderState.recorded ||
        widget.existingUrl != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Waveform visualizer
        SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_waveAmplitudes.length, (i) {
              final amp = _waveAmplitudes[i];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 4,
                height: 8 + amp * 56,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _state == _RecorderState.recording
                      ? primary.withValues(alpha: 0.6 + amp * 0.4)
                      : primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        )
            .animate()
            .fadeIn(duration: AppMotion.medium),
        const SizedBox(height: 16),
        // Timer / status label
        Text(
          _state == _RecorderState.recording
              ? '${_formatTime(_elapsedSeconds)} / ${_formatTime(widget.maxSeconds)}'
              : hasRecording
                  ? _formatTime(_elapsedSeconds > 0 ? _elapsedSeconds : 0)
                  : 'Tap mic to record (max ${widget.maxSeconds}s)',
          style: AppTypography.bodySmall.copyWith(
            color: _state == _RecorderState.recording
                ? primary
                : cs.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasRecording) ...[
              // Discard
              _RoundButton(
                icon: Icons.delete_outline_rounded,
                color: cs.error,
                onTap: _discardRecording,
                label: 'Discard',
              ),
              const SizedBox(width: 24),
            ],
            // Record / stop button
            GestureDetector(
              onTap: _state == _RecorderState.recording
                  ? _stopRecording
                  : _startRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _state == _RecorderState.recording
                        ? [cs.error, const Color(0xFFFF4757)]
                        : [primary, cs.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_state == _RecorderState.recording
                              ? cs.error
                              : primary)
                          .withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  _state == _RecorderState.recording
                      ? Icons.stop_rounded
                      : Icons.mic_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: AppMotion.medium, delay: 100.ms)
            .slideY(begin: 0.2, end: 0),
        if (hasRecording) ...[
          const SizedBox(height: 16),
          Text(
            'Voice intro saved ✓',
            style: AppTypography.labelMedium.copyWith(
              color: const Color(0xFF00C853),
              fontWeight: FontWeight.w700,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms),
        ],
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
