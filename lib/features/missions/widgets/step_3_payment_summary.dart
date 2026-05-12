import 'package:flutter/material.dart';

/// Montants validés à l’étape paiement (avant appel API + portefeuille simulé).
class MissionPaymentTotals {
  final double totalCfa;
  final double serviceFeeCfa;
  final double purchaseBudgetCfa;
  final bool paySupplierDirectly;
  final String? targetAgentUsername;

  const MissionPaymentTotals({
    required this.totalCfa,
    required this.serviceFeeCfa,
    required this.purchaseBudgetCfa,
    required this.paySupplierDirectly,
    this.targetAgentUsername,
  });
}

class Step3PaymentSummary extends StatefulWidget {
  final String mode;
  final Future<void> Function(MissionPaymentTotals totals) onPayAndValidate;

  const Step3PaymentSummary({
    super.key,
    required this.mode,
    required this.onPayAndValidate,
  });

  @override
  State<Step3PaymentSummary> createState() => _Step3PaymentSummaryState();
}

class _Step3PaymentSummaryState extends State<Step3PaymentSummary> {
  bool _paySupplierDirectly = false;
  final TextEditingController _purchaseBudgetController =
      TextEditingController();
  final TextEditingController _targetAgentController = TextEditingController();

  static const double _serviceFee = 500.0;
  static const double _defaultBudget = 2500.0;
  bool _submitting = false;

  @override
  void dispose() {
    _purchaseBudgetController.dispose();
    _targetAgentController.dispose();
    super.dispose();
  }

  double _purchaseBudgetValue() {
    if (_paySupplierDirectly) return 0;
    final t = _purchaseBudgetController.text.trim();
    if (t.isEmpty) return _defaultBudget;
    return double.tryParse(t) ?? _defaultBudget;
  }

  double _calculateTotal() {
    var total = _serviceFee;
    if (!_paySupplierDirectly) {
      total += _purchaseBudgetValue();
    }
    return total;
  }

  double _calculateServiceFee(double missionPrice) {
    return missionPrice * 0.10; // 10% de frais de service
  }

  Future<void> _onPayPressed() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      // Calcul des frais de service dynamiques
      final missionPrice = _purchaseBudgetValue();
      final calculatedServiceFee = _calculateServiceFee(missionPrice);
      final targetAgent = _targetAgentController.text.trim();

      final totals = MissionPaymentTotals(
        totalCfa: missionPrice + calculatedServiceFee,
        serviceFeeCfa: calculatedServiceFee,
        purchaseBudgetCfa: missionPrice,
        paySupplierDirectly: _paySupplierDirectly,
        targetAgentUsername: targetAgent.isNotEmpty ? targetAgent : null,
      );
      await widget.onPayAndValidate(totals);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paiement sécurisé',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Type de mission',
                  widget.mode == 'queue' ? "File d'attente" : 'Service libre',
                ),
                _buildSummaryRow(
                  'Frais de service',
                  '${_serviceFee.toInt()} CFA',
                ),
                if (!_paySupplierDirectly) ...[
                  _buildSummaryRow(
                    'Budget achats',
                    '${_purchaseBudgetValue().toInt()} CFA',
                  ),
                ],
                const Divider(height: 30),
                _buildSummaryRow(
                  'Total à payer',
                  '${_calculateTotal().toInt()} CFA',
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFFFFD400),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Je paie les frais d'achat directement au fournisseur",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Le séquestre ne concernera que les frais de service',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Checkbox(
                  value: _paySupplierDirectly,
                  onChanged: (value) =>
                      setState(() => _paySupplierDirectly = value ?? false),
                  activeColor: const Color(0xFFFFD400),
                ),
                if (!_paySupplierDirectly) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _purchaseBudgetController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Budget d\'achat',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Champ pour assigner à un agent spécifique
                TextField(
                  controller: _targetAgentController,
                  decoration: const InputDecoration(
                    labelText:
                        'Assigner à un agent spécifique (Username) - Optionnel',
                    hintText: 'Entrez le username de l\'agent',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_search),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // AFFICHAGE DÉTAILLÉ DES COÛTS
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Détail des coûts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _buildSummaryRow('Prix mission',
                    '${_purchaseBudgetValue().toStringAsFixed(2)} CFA'),
                _buildSummaryRow('Frais de service (10%)',
                    '${_calculateServiceFee(_purchaseBudgetValue()).toStringAsFixed(2)} CFA'),
                const Divider(),
                _buildSummaryRow(
                  'TOTAL',
                  '${(_purchaseBudgetValue() + _calculateServiceFee(_purchaseBudgetValue())).toStringAsFixed(2)} CFA',
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Choisir un moyen de paiement',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 15),
          _buildPaymentMethod(
            'Orange Money',
            'assets/icons/orange.png',
            Colors.orange,
          ),
          _buildPaymentMethod(
            'Moov Money',
            'assets/icons/moov.png',
            Colors.blue,
          ),
          _buildPaymentMethod(
            'Wave',
            'assets/icons/wave.png',
            Colors.lightBlueAccent,
          ),
          _buildPaymentMethod(
            'Carte bancaire',
            null,
            Colors.black,
            iconData: Icons.credit_card,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _submitting ? null : _onPayPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1C1C),
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'PAYER ET VALIDER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.black : Colors.grey,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(
    String name,
    String? assetPath,
    Color color, {
    IconData? iconData,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: assetPath != null
                ? Image.asset(assetPath, width: 24, height: 24)
                : Icon(iconData, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}
