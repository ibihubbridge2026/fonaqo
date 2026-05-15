import 'package:flutter/foundation.dart';

/// Solde portefeuille simulé côté client (tests bout en bout avant intégration wallets API).
class WalletProvider extends ChangeNotifier {
  double _balanceCfa = 100000;

  double get balanceCfa => _balanceCfa;

  bool canAfford(double amountCfa) => amountCfa > 0 && _balanceCfa >= amountCfa;

  /// Retourne false si solde insuffisant.
  bool deduct(double amountCfa) {
    if (!canAfford(amountCfa)) return false;
    _balanceCfa -= amountCfa;
    notifyListeners();
    return true;
  }

  void resetForDebug([double amount = 100000]) {
    _balanceCfa = amount;
    notifyListeners();
  }
}
