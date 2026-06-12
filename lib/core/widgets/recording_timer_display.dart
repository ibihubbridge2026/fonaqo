import 'package:flutter/material.dart';

import '../utils/recording_duration_tracker.dart';

/// Indicateur d'enregistrement : point rouge clignotant + compteur MM:SS.
class RecordingTimerDisplay extends StatefulWidget {
  final int seconds;
  final TextStyle? textStyle;

  const RecordingTimerDisplay({
    super.key,
    required this.seconds,
    this.textStyle,
  });

  @override
  State<RecordingTimerDisplay> createState() => _RecordingTimerDisplayState();
}

class _RecordingTimerDisplayState extends State<RecordingTimerDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.textStyle ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.red,
          letterSpacing: 0.5,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.25, end: 1).animate(
              CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
            ),
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            RecordingDurationTracker.formatMmSs(widget.seconds),
            style: style,
          ),
        ],
      ),
    );
  }
}
