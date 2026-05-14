import 'package:flutter/material.dart';

/// Étape 4 : récapitulatif type facture + confirmation.
class CreateMissionStepRecap extends StatefulWidget {
  final TextEditingController priceController;
  final String summaryTitle;
  final String summaryLines;
  final bool isSubmitting;
  final VoidCallback onConfirm;

  const CreateMissionStepRecap({
    super.key,
    required this.priceController,
    required this.summaryTitle,
    required this.summaryLines,
    required this.isSubmitting,
    required this.onConfirm,
  });

  @override
  State<CreateMissionStepRecap> createState() => _CreateMissionStepRecapState();
}

class _CreateMissionStepRecapState extends State<CreateMissionStepRecap> {
  @override
  void initState() {
    super.initState();
    widget.priceController.addListener(_onPrice);
  }

  @override
  void didUpdateWidget(covariant CreateMissionStepRecap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.priceController != widget.priceController) {
      oldWidget.priceController.removeListener(_onPrice);
      widget.priceController.addListener(_onPrice);
    }
  }

  @override
  void dispose() {
    widget.priceController.removeListener(_onPrice);
    super.dispose();
  }

  void _onPrice() => setState(() {});

  double get _price {
    final raw = widget.priceController.text.replaceAll(',', '.').trim();
    return double.tryParse(raw) ?? 0;
  }

  double get _fee => _price * 0.10;

  double get _total => _price + _fee;

  String _fmt(double v) => v.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Récapitulatif',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.summaryTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.summaryLines,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const Divider(height: 28),
                TextField(
                  controller: widget.priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Prix de la mission (FCFA)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 18),
                _invoiceRow('Prix mission', '${_fmt(_price)} FCFA', bold: false),
                const SizedBox(height: 8),
                _invoiceRow(
                  'Frais de service FONACO (10 %)',
                  '${_fmt(_fee)} FCFA',
                  bold: false,
                  muted: true,
                ),
                const SizedBox(height: 12),
                _invoiceRow(
                  'Total final',
                  '${_fmt(_total)} FCFA',
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Paiement FeexPay désactivé en démo : la mission sera enregistrée côté serveur si vous êtes connecté.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: (_price > 0 && !widget.isSubmitting)
                  ? widget.onConfirm
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: const Color(0xFFFFD400),
                disabledBackgroundColor: Colors.grey[400],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFFD400),
                      ),
                    )
                  : const Text(
                      'Confirmer',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceRow(String label, String value,
      {required bool bold, bool muted = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
      fontSize: bold ? 16 : 14,
      color: muted ? Colors.grey[700] : Colors.black87,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
