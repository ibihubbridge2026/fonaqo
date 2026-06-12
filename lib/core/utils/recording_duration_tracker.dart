import 'dart:async';

/// Compteur de durée d'enregistrement (secondes) avec Timer périodique.
class RecordingDurationTracker {
  Timer? _timer;
  int _seconds = 0;

  int get seconds => _seconds;
  bool get isRunning => _timer != null;

  void Function(int seconds)? onTick;

  void start() {
    stop();
    _seconds = 0;
    onTick?.call(_seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _seconds++;
      onTick?.call(_seconds);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    onTick = null;
  }

  static String formatMmSs(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
