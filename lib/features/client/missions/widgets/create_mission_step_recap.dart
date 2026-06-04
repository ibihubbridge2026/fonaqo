import 'package:flutter/material.dart';

/// Étape 4 : récapitulatif type facture + confirmation.
class CreateMissionStepRecap extends StatefulWidget {
  final TextEditingController serviceAmountController;
  final TextEditingController purchaseAmountController;
  final bool isUrgent;
  final bool isConfidential;
  final String summaryTitle;
  final String summaryLines;
  final bool isSubmitting;
  final VoidCallback onConfirm;

  const CreateMissionStepRecap({
    super.key,
    required this.serviceAmountController,
    required this.purchaseAmountController,
    required this.isUrgent,
    required this.isConfidential,
    required this.summaryTitle,
    required this.summaryLines,
    required this.isSubmitting,
    required this.onConfirm,
  });

  @override
  State<CreateMissionStepRecap> createState() => _CreateMissionStepRecapState();
}

class _CreateMissionStepRecapState extends State<CreateMissionStepRecap> {
  static const double _optionCost = 500;

  @override
  void initState() {
    super.initState();
    widget.serviceAmountController.addListener(_onPrice);
    widget.purchaseAmountController.addListener(_onPrice);
  }

  @override
  void didUpdateWidget(covariant CreateMissionStepRecap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serviceAmountController != widget.serviceAmountController) {
      oldWidget.serviceAmountController.removeListener(_onPrice);
      widget.serviceAmountController.addListener(_onPrice);
    }
    if (oldWidget.purchaseAmountController != widget.purchaseAmountController) {
      oldWidget.purchaseAmountController.removeListener(_onPrice);
      widget.purchaseAmountController.addListener(_onPrice);
    }
  }

  @override
  void dispose() {
    widget.serviceAmountController.removeListener(_onPrice);
    widget.purchaseAmountController.removeListener(_onPrice);
    super.dispose();
  }

  void _onPrice() => setState(() {});

  double get _serviceAmount {
    final raw = widget.serviceAmountController.text.replaceAll(',', '.').trim();
    return double.tryParse(raw) ?? 0;
  }

  double get _purchaseAmount {
    final raw =
        widget.purchaseAmountController.text.replaceAll(',', '.').trim();
    return double.tryParse(raw) ?? 0;
  }

  double get _optionsCost =>
      (widget.isUrgent ? _optionCost : 0) +
      (widget.isConfidential ? _optionCost : 0);

  double get _fonnaqoFee => _serviceAmount * 0.10;

  double get _total =>
      _serviceAmount + _purchaseAmount + _optionsCost + _fonnaqoFee;

  String _fmt(double v) => v.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Récapitulatif',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vérifiez les détails avant de confirmer.',
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          icon: Icons.check_circle,
          message:
              'Votre mission sera publiée et visible par les agents disponibles.',
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.summaryTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
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
              _PriceInputCard(
                icon: Icons.attach_money,
                label: 'Montant de la prestation (FCFA)',
                controller: widget.serviceAmountController,
              ),
              const SizedBox(height: 16),
              _PriceInputCard(
                icon: Icons.shopping_cart,
                label: 'Montant des achats (FCFA)',
                controller: widget.purchaseAmountController,
              ),
              const SizedBox(height: 18),
              _invoiceRow('Prestation', '${_fmt(_serviceAmount)} FCFA',
                  bold: false),
              if (_purchaseAmount > 0) ...[
                const SizedBox(height: 8),
                _invoiceRow('Achats', '${_fmt(_purchaseAmount)} FCFA',
                    bold: false),
              ],
              if (_optionsCost > 0) ...[
                const SizedBox(height: 8),
                _invoiceRow('Options (Urgent/Confidentiel)',
                    '${_fmt(_optionsCost)} FCFA',
                    bold: false),
              ],
              const SizedBox(height: 8),
              _invoiceRow(
                'Frais FONACO (10 %)',
                '${_fmt(_fonnaqoFee)} FCFA',
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
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_serviceAmount > 0 && !widget.isSubmitting)
                ? widget.onConfirm
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD400),
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey[300],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: widget.isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Confirmer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
          ),
        ),
      ],
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InfoCard({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD400), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFFFFD400),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceInputCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;

  const _PriceInputCard({
    required this.icon,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFFB8860B),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Entrez le montant...',
              hintStyle: TextStyle(color: Color(0xFFBBBBBB)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
