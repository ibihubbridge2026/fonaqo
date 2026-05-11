import 'package:flutter/material.dart';

class Step3PaymentSummary extends StatefulWidget {
  final String mode;
  final VoidCallback onPaid;
  const Step3PaymentSummary({
    super.key,
    required this.mode,
    required this.onPaid,
  });

  @override
  State<Step3PaymentSummary> createState() => _Step3PaymentSummaryState();
}

class _Step3PaymentSummaryState extends State<Step3PaymentSummary> {
  bool _paySupplierDirectly = false;
  final TextEditingController _purchaseBudgetController =
      TextEditingController();

  // Dynamic amounts (TODO: Make API-driven)
  static const double _serviceFee = 500.0;
  static const double _defaultBudget = 2500.0;

  @override
  void dispose() {
    _purchaseBudgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Paiement sécurisé",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 20),

        // Carte Récapitulative (Design paiement.html)
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
                "Type de mission",
                widget.mode == 'queue' ? "File d'attente" : "Service libre",
              ),
              _buildSummaryRow(
                "Frais de service",
                "${_serviceFee.toInt()} CFA",
              ),

              // Budget Achats (conditionnel)
              if (!_paySupplierDirectly) ...[
                _buildSummaryRow(
                  "Budget Achats",
                  "${_purchaseBudgetController.text.isEmpty ? _defaultBudget.toInt() : int.parse(_purchaseBudgetController.text)} CFA",
                ),
              ],

              const Divider(height: 30),
              _buildSummaryRow(
                "Total à payer",
                "${(_calculateTotal()).toInt()} CFA",
                isTotal: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // QUESTION PAIEMENT DIRECT FOURNISSEUR
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
                  Icon(
                    Icons.account_balance_wallet,
                    color: const Color(0xFFFFD400),
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
                          "Le séquestre ne concernera que les frais de service",
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

              // CHAMP BUDGET ACHATS (conditionnel)
              if (!_paySupplierDirectly) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _purchaseBudgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Budget Achats",
                    hintText: "Entrez le montant pour les achats",
                    prefixText: "CFA ",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFD400)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 30),
        const Text(
          "Choisir un moyen de paiement",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 15),

        // Liste des moyens de paiement
        _buildPaymentMethod(
          "Orange Money",
          "assets/icons/orange.png",
          Colors.orange,
        ),
        _buildPaymentMethod("Moov Money", "assets/icons/moov.png", Colors.blue),
        _buildPaymentMethod(
          "Wave",
          "assets/icons/wave.png",
          Colors.lightBlueAccent,
        ),
        _buildPaymentMethod(
          "Carte Bancaire",
          null,
          Colors.black,
          iconData: Icons.credit_card,
        ),

        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: widget.onPaid,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1C1C),
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            "PAYER ET VALIDER",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  double _calculateTotal() {
    double total = _serviceFee;
    if (!_paySupplierDirectly) {
      double purchaseBudget = _purchaseBudgetController.text.isEmpty
          ? _defaultBudget
          : (double.tryParse(_purchaseBudgetController.text) ?? 0);
      total += purchaseBudget;
    }
    return total;
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
