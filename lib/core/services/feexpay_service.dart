import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../api/base_client.dart';
import '../widgets/fon_dialog.dart';

/// Intégration FeexPay — init API backend + confirmation sandbox.
class FeexPayService {
  FeexPayService._();
  static final FeexPayService instance = FeexPayService._();

  final BaseClient _client = BaseClient();

  /// Initialise un paiement FeexPay et retourne la référence externe si succès.
  Future<FeexPayPaymentResult?> initPayment({
    required double amount,
    required String purpose,
    Map<String, dynamic>? metadata,
    String paymentMethod = 'MTN',
  }) async {
    final amountInt = amount.round();
    if (amountInt <= 0) return null;

    try {
      final response = await _client.post(
        'payments/feexpay/init/',
        data: {
          'amount': amountInt,
          'purpose': purpose,
          'payment_method': paymentMethod,
          if (metadata != null) 'metadata': metadata,
        },
      );
      final body = response.data;
      if (body is! Map) return null;
      return FeexPayPaymentResult(
        paymentId: body['payment_id']?.toString() ?? '',
        externalReference: body['external_reference']?.toString() ?? '',
        amount: amountInt,
      );
    } on DioException {
      return null;
    }
  }

  /// Confirme le paiement (sandbox) et crédite le wallet côté serveur.
  Future<int?> confirmPayment({
    required String paymentId,
    required String externalReference,
  }) async {
    try {
      final response = await _client.post(
        'payments/feexpay/confirm/',
        data: {
          'payment_id': paymentId,
          'external_reference': externalReference,
        },
      );
      if (response.statusCode != 200) return null;
      final body = response.data;
      if (body is Map && body['new_balance'] != null) {
        return (body['new_balance'] as num).round();
      }
      return 0;
    } on DioException {
      return null;
    }
  }

  /// Affiche le dialogue FeexPay, initie et confirme le paiement.
  Future<FeexPayPaymentResult?> requestPayment({
    required BuildContext context,
    required double amount,
    required String description,
    String purpose = 'wallet_deposit',
    Map<String, dynamic>? metadata,
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
                '${amount.round()} FCFA',
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
              'Mobile Money Bénin — MTN, Moov, Wave, Celtiis',
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

    if (confirmed != true) return null;

    final init = await initPayment(
      amount: amount,
      purpose: purpose,
      metadata: metadata,
    );
    if (init == null) return null;

    final newBalance = await confirmPayment(
      paymentId: init.paymentId,
      externalReference: init.externalReference,
    );
    return newBalance != null ? init : null;
  }
}

class FeexPayPaymentResult {
  final String paymentId;
  final String externalReference;
  final int amount;

  const FeexPayPaymentResult({
    required this.paymentId,
    required this.externalReference,
    required this.amount,
  });
}
