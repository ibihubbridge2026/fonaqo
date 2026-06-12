import 'package:flutter/foundation.dart';

/// Signal global pour rafraîchir le dashboard après création de mission.
class DashboardRefreshService extends ChangeNotifier {
  DashboardRefreshService._();
  static final DashboardRefreshService instance = DashboardRefreshService._();

  void requestRefresh() => notifyListeners();
}
