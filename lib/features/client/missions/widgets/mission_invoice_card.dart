import 'package:flutter/material.dart';

import 'package:fonaco/core/models/mission_model.dart';

/// Bouton de téléchargement de facture (sans aperçu visuel).
class MissionInvoiceCard extends StatelessWidget {
  final MissionModel mission;
  final String? clientEmail;
  final String? agentEmail;
  final VoidCallback? onDownload;

  const MissionInvoiceCard({
    super.key,
    required this.mission,
    this.clientEmail,
    this.agentEmail,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    if (onDownload == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton.icon(
        onPressed: onDownload,
        icon: const Icon(Icons.file_download, size: 20),
        label: const Text(
          'Télécharger la facture',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade400),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
