import 'package:flutter/material.dart';

import '../models/enums.dart';

const _kYellow = Color(0xFFFFD400);

/// Carte premium affichée au client pour une proposition tarifaire agent.
class NegotiationCard extends StatelessWidget {
  final double proposedAmount;
  final NegotiationStatus status;
  final bool isProcessing;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const NegotiationCard({
    super.key,
    required this.proposedAmount,
    required this.status,
    this.isProcessing = false,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (status == NegotiationStatus.accepted) {
      return _statusBanner(
        'Tarif accepté — ${proposedAmount.toStringAsFixed(0)} FCFA',
        Colors.green.shade50,
        Colors.green.shade800,
        Icons.check_circle_outline,
      );
    }
    if (status == NegotiationStatus.rejected) {
      return _statusBanner(
        'Proposition refusée',
        Colors.grey.shade100,
        Colors.grey.shade700,
        Icons.cancel_outlined,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kYellow, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kYellow.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payments_outlined, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Nouvelle proposition',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "L'agent propose un tarif de "
            '${proposedAmount.toStringAsFixed(0)} FCFA pour cette prestation.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isProcessing ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Refuser',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: isProcessing ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Accepter & Payer',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBanner(
    String text,
    Color bg,
    Color fg,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
