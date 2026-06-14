/// Résultat d'une demande de retrait.
class WithdrawResult {
  final bool success;
  final String? message;

  const WithdrawResult({required this.success, this.message});
}

/// Contrat portefeuille agent.
abstract class AgentWalletRepository {
  Future<double> getBalance();

  Future<List<Map<String, dynamic>>> getTransactions();

  Future<WithdrawResult> withdraw({
    required double amount,
    required String paymentMethod,
    required String phoneNumber,
  });

  Future<bool> deposit({
    required double amount,
    String paymentMethod,
    String? paymentReference,
  });
}
