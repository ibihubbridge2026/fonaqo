import 'package:flutter/foundation.dart';

/// Mesure le temps entre le tap « Connexion » et le chargement complet des données.
class SessionBootstrapMonitor {
  SessionBootstrapMonitor._();
  static final SessionBootstrapMonitor instance = SessionBootstrapMonitor._();

  Stopwatch? _watch;
  final List<(String label, int ms)> _timeline = [];

  void beginLogin() {
    _watch = Stopwatch()..start();
    _timeline.clear();
    mark('login_button_pressed');
  }

  void mark(String label) {
    if (_watch == null) return;
    final ms = _watch!.elapsedMilliseconds;
    _timeline.add((label, ms));
    debugPrint('[Bootstrap] +${ms}ms — $label');
  }

  void finish() {
    if (_watch == null) return;
    mark('bootstrap_complete');
    final total = _watch!.elapsedMilliseconds;
    debugPrint('[Bootstrap] ▶ TOTAL ${total}ms');
    for (final (label, ms) in _timeline) {
      debugPrint('[Bootstrap]   $ms ms — $label');
    }
    _watch = null;
  }
}
