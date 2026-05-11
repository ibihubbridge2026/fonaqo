import 'package:flutter/material.dart';

class Step3PaymentSummary extends StatefulWidget {
  final String mode; // 'queue' ou 'service'
  final VoidCallback onPaid;
  final bool isUrgent;
  final bool isConfidential;

  const Step3PaymentSummary({
    super.key,
    required this.mode,
    required this.onPaid,
    this.isUrgent = false,
    this.isConfidential = false,
  });

  @override
  State<Step3PaymentSummary> createState() => _Step3PaymentSummaryState();
}

class _Step3PaymentSummaryState extends State<Step3PaymentSummary> {
  bool _paySupplierDirectly = false;
  final TextEditingController _purchaseBudgetController =
      TextEditingController();

  // TODO: Ces montants devront être récupérés via l'API GlobalSettings (Admin)
  static const double _baseServiceFee = 2000.0; // Frais de base
  static const double _urgencyFee = 500.0;
  static const double _confidentialFee = 500.0;
  static const double _defaultPurchaseBudget = 0.0;

  @override
  void initState() {
    super.initState();
    _purchaseBudgetController.addListener(() {
      setState(() {}); // Pour mettre à jour le total en temps réel
    });
  }

  @override
  void dispose() {
    _purchaseBudgetController.dispose();
    super.dispose();
  }

  double _calculateTotal() {
    double total = _baseServiceFee;

    // Ajout des frais d'urgence
    if (widget.isUrgent) total += _urgencyFee;

    // Ajout des frais de confidentialité (uniquement pour les services)
    if (widget.mode == 'service' && widget.isConfidential) {
      total += _confidentialFee;
    }

    // Ajout du budget achat si non payé directement
    if (!_paySupplierDirectly) {
      double purchaseBudget =
          double.tryParse(_purchaseBudgetController.text) ??
          _defaultPurchaseBudget;
      total += purchaseBudget;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Récapitulatif & Paiement",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),

          // --- CARTE RÉCAPITULATIVE ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  "Type de mission",
                  widget.mode == 'queue' ? "File d'attente" : "Service",
                ),
                _buildSummaryRow(
                  "Frais de service de base",
                  "${_baseServiceFee.toInt()} CFA",
                ),

                if (widget.isUrgent)
                  _buildSummaryRow(
                    "Option Urgence 🚨",
                    "+ ${_urgencyFee.toInt()} CFA",
                  ),

                if (widget.mode == 'service' && widget.isConfidential)
                  _buildSummaryRow(
                    "Option Confidentiel 🔐",
                    "+ ${_confidentialFee.toInt()} CFA",
                  ),

                if (!_paySupplierDirectly)
                  _buildSummaryRow(
                    "Budget Achats 🛒",
                    "${(double.tryParse(_purchaseBudgetController.text) ?? 0).toInt()} CFA",
                  ),

                const Divider(height: 30),
                _buildSummaryRow(
                  "Total à séquestrer",
                  "${(_calculateTotal()).toInt()} CFA",
                  isTotal: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // --- CONFIGURATION BUDGET ACHATS ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    "Je paie les achats moi-même",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("L'agent n'aura pas à avancer d'argent"),
                  value: _paySupplierDirectly,
                  activeColor: const Color(0xFFFFD400),
                  onChanged: (value) =>
                      setState(() => _paySupplierDirectly = value),
                ),
                if (!_paySupplierDirectly) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _purchaseBudgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Montant à confier à l'agent",
                      prefixText: "CFA ",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 25),
          const Text(
            "Moyen de paiement",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _buildPaymentMethod(
            "Mon Portefeuille FONACO",
            null,
            const Color(0xFFFFD400),
            iconData: Icons.account_balance_wallet,
          ),
          _buildPaymentMethod(
            "Mobile Money",
            null,
            Colors.orange,
            iconData: Icons.phone_android,
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
            child: Text(
              "CONFIRMER ET SÉQUESTRER ${(_calculateTotal()).toInt()} CFA",
              style: const TextStyle(
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
              color: isTotal ? Colors.black : Colors.grey[700],
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.w900,
              color: isTotal ? const Color(0xFFE6B800) : Colors.black,
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(iconData, color: color),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.radio_button_off, size: 20),
        onTap: () {},
      ),
    );
  }
}
