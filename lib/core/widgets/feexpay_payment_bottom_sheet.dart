import 'package:flutter/material.dart';

const _kYellow = Color(0xFFFFD400);

/// Bottom sheet FeexPay — MTN, Moov, Wave, Celtiis.
class FeexPayPaymentBottomSheet extends StatefulWidget {
  final double amount;
  final String description;

  const FeexPayPaymentBottomSheet({
    super.key,
    required this.amount,
    required this.description,
  });

  static Future<bool> show(
    BuildContext context, {
    required double amount,
    required String description,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FeexPayPaymentBottomSheet(
        amount: amount,
        description: description,
      ),
    ).then((v) => v == true);
  }

  @override
  State<FeexPayPaymentBottomSheet> createState() =>
      _FeexPayPaymentBottomSheetState();
}

class _FeexPayPaymentBottomSheetState extends State<FeexPayPaymentBottomSheet> {
  String? _selected;

  static const _operators = [
    ('mtn', 'MTN Mobile Money', Icons.phone_android),
    ('moov', 'Moov Money', Icons.smartphone),
    ('wave', 'Wave', Icons.account_balance_wallet_outlined),
    ('celtiis', 'Celtiis', Icons.credit_card),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Paiement FeexPay',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kYellow),
              ),
              child: Text(
                '${widget.amount.toStringAsFixed(0)} FCFA',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._operators.map((op) {
              final selected = _selected == op.$1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selected = op.$1),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? _kYellow.withValues(alpha: 0.2)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _kYellow : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(op.$3, color: Colors.black87),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            op.$2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              child: const Text('Annuler'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _selected == null
                  ? null
                  : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kYellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: const Text(
                'Payer maintenant',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
