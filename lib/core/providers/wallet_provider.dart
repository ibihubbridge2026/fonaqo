import 'package:flutter/foundation.dart';
import 'package:fonaco/features/wallet/repositories/wallet_repository.dart';

/// Solde portefeuille — connecté à l'API réelle via WalletRepository.
class WalletProvider extends ChangeNotifier {
  double _balanceCfa = 0;
  double _escrowBalanceCfa = 0;
  bool _isLoading = false;
  bool _hasLoaded = false;

  final WalletRepository _repository = WalletRepository();

  double get balanceCfa => _balanceCfa;
  double get escrowBalanceCfa => _escrowBalanceCfa;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  bool canAfford(double amountCfa) => amountCfa > 0 && _balanceCfa >= amountCfa;

  /// Charge le solde réel depuis l'API.
  Future<void> fetchBalance() async {
    _isLoading = true;
    notifyListeners();
    try {
      final balance = await _repository.getBalance();
      if (balance != null) {
        _balanceCfa = balance.availableBalance;
        _escrowBalanceCfa = balance.escrowBalance;
        _hasLoaded = true;
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetForDebug([double amount = 100000]) {
    _balanceCfa = amount;
    notifyListeners();
  }
}
