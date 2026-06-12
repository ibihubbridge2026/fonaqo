import 'package:flutter/material.dart';

import '../widgets/fon_dialog.dart';

/// Placeholder FeexPay — intégration réelle à venir.
/// Pour l'instant, simule un paiement réussi après confirmation utilisateur.
class FeexPayService {
  FeexPayService._();
  static final FeexPayService instance = FeexPayService._();

  /// Affiche un dialogue FeexPay et retourne `true` si l'utilisateur confirme.
  Future<bool> requestPayment({
    required BuildContext context,
    required double amount,
    required String description,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => FonDialog.alert(
        title: const Text('Paiement FeexPay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: Text(
                '${amount.toStringAsFixed(0)} FCFA',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'FeexPay sera intégré prochainement. Le paiement est accepté '
              'automatiquement pour le moment.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: FonDialog.secondaryActionStyle(),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: FonDialog.primaryActionStyle(),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Payer avec FeexPay'),
          ),
        ],
      ),
    );

    return confirmed == true;
  }
}
