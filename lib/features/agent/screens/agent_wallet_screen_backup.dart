import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agent_provider.dart';
import '../widgets/wallet_transaction_tile.dart';

class AgentWalletScreen extends StatefulWidget {
  const AgentWalletScreen({super.key});

  @override
  State<AgentWalletScreen> createState() => _AgentWalletScreenState();
}

class _AgentWalletScreenState extends State<AgentWalletScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentProvider>().fetchWalletDetails();
    });
  }

  void _showWithdrawalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WithdrawalBottomSheet(
        availableBalance: context.read<AgentProvider>().balance,
        onWithdrawalRequested: (amount, provider) async {
          final success = await context
              .read<AgentProvider>()
              .requestWithdrawal(amount, provider);

          if (success && context.mounted) {
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Demande de retrait envoyée avec succès!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agentProvider = context.watch<AgentProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PORTEFEUILLE',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // CARD SOLDE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD400), Color(0xFFFFC107)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Solde disponible'),
                  const SizedBox(height: 12),
                  Text(
                    '${agentProvider.balance.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _showWithdrawalBottomSheet(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: const Color(0xFFFFD400),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Retirer mes gains'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text('Historique'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // QUICK ACTIONS
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    Icons.account_balance_wallet_outlined,
                    'Recharger',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickAction(Icons.swap_horiz, 'Transfert'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickAction(
                    Icons.receipt_long_outlined,
                    'Factures',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // STATS
            Row(
              children: [
                Expanded(
                  child: _buildStatsCard(
                    'Aujourd’hui',
                    '+18 000',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatsCard(
                    'Semaine',
                    '+72 500',
                    Icons.bar_chart,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // TRANSACTIONS
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transactions récentes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),

                  ...agentProvider.transactions.map((transaction) {
                    return WalletTransactionTile(
                      title: transaction['title'] ?? 'Transaction',
                      subtitle:
                          transaction['subtitle'] ?? 'Description',
                      amount: transaction['amount']?.toString() ?? '0',
                      icon: transaction['icon'] ?? Icons.swap_horiz,
                      iconColor:
                          transaction['iconColor'] ?? Colors.grey,
                      amountColor:
                          transaction['amountColor'] ?? Colors.black,
                      isIncome: transaction['isIncome'] ?? true,
                      onTap: () {},
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// ================= BOTTOM SHEET =================
//

class _WithdrawalBottomSheet extends StatefulWidget {
  final double availableBalance;
  final Function(double amount, String provider)
      onWithdrawalRequested;

  const _WithdrawalBottomSheet({
    required this.availableBalance,
    required this.onWithdrawalRequested,
  });

  @override
  State<_WithdrawalBottomSheet> createState() =>
      _WithdrawalBottomSheetState();
}

class _WithdrawalBottomSheetState
    extends State<_WithdrawalBottomSheet> {
  final TextEditingController _amountController =
      TextEditingController();

  String _selectedProvider = 'mtn_momo';
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) return;

    if (amount > widget.availableBalance) return;

    setState(() => _isProcessing = true);

    try {
      await widget.onWithdrawalRequested(
        amount,
        _selectedProvider,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Retirer mes gains',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Montant',
              prefixText: 'FCFA ',
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _selectedProvider = 'mtn'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: _selectedProvider == 'mtn'
                        ? Colors.yellow
                        : Colors.grey.shade200,
                    child: const Center(child: Text("MTN")),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _selectedProvider = 'moov'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: _selectedProvider == 'moov'
                        ? Colors.green
                        : Colors.grey.shade200,
                    child: const Center(child: Text("Moov")),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _submit,
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : const Text('Confirmer'),
            ),
          ),
        ],
      ),
    );
  }
}