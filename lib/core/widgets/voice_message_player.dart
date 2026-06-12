import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Lecteur vocal style WhatsApp avec sélecteur de vitesse (1x / 1.5x / 2x).
class VoiceMessagePlayer extends StatefulWidget {
  final String audioPath;
  final int? durationSeconds;
  final bool isMe;
  final AudioPlayer player;

  const VoiceMessagePlayer({
    super.key,
    required this.audioPath,
    required this.player,
    this.durationSeconds,
    this.isMe = false,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  static const _speeds = [1.0, 1.5, 2.0];
  static const _speedLabels = ['1x', '1.5x', '2x'];

  int _speedIndex = 0;
  bool _isPlaying = false;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    _completeSub = widget.player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    super.dispose();
  }

  double get _currentSpeed => _speeds[_speedIndex];

  String get _currentSpeedLabel => _speedLabels[_speedIndex];

  Future<void> _togglePlay() async {
    final path = widget.audioPath;
    if (path.isEmpty) return;

    if (_isPlaying) {
      await widget.player.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    await widget.player.setPlaybackRate(_currentSpeed);
    if (path.startsWith('/') && File(path).existsSync()) {
      await widget.player.play(DeviceFileSource(path));
    } else if (path.startsWith('http')) {
      await widget.player.play(UrlSource(path));
    }
    if (mounted) setState(() => _isPlaying = true);
  }

  Future<void> _cycleSpeed() async {
    setState(() => _speedIndex = (_speedIndex + 1) % _speeds.length);
    if (_isPlaying) {
      await widget.player.setPlaybackRate(_currentSpeed);
    }
  }

  String _durationLabel() {
    final d = widget.durationSeconds;
    if (d == null || d <= 0) return 'Vocal';
    final m = d ~/ 60;
    final s = d % 60;
    if (m > 0) return '${m}:${s.toString().padLeft(2, '0')}';
    return '0:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isMe ? const Color(0xFF075E54) : const Color(0xFF54656F);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _togglePlay,
          borderRadius: BorderRadius.circular(20),
          child: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: iconColor,
            size: 32,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _durationLabel(),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: _cycleSpeed,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                _currentSpeedLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
