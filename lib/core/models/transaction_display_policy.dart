import 'package:flutter/material.dart';

/// Politique centralisée d'affichage des mouvements wallet (alignée API Django).
class TransactionDisplayPolicy {
  TransactionDisplayPolicy._();

  static const Color inflowColor = Color(0xFF2E7D32);
  static const Color outflowColor = Color(0xFFC62828);

  static const Set<String> _inflowTypes = {
    'DEPOSIT',
    'ESCROW_RELEASE',
    'REFERRAL_BONUS',
    'REFUND',
  };

  static const Set<String> _outflowTypes = {
    'WITHDRAWAL',
    'MISSION_PAYMENT',
    'ESCROW_LOCK',
    'BOOST_PAYMENT',
    'INSURANCE_FEE',
    'BADGE_FEE',
  };

  static String normalizeType(dynamic raw) =>
      (raw?.toString() ?? 'DEPOSIT').toUpperCase();

  static bool isInflow(String transactionType, double amount) {
    final type = normalizeType(transactionType);
    if (type == 'TRANSFER') return amount >= 0;
    if (_inflowTypes.contains(type)) return true;
    if (_outflowTypes.contains(type)) return false;
    return amount >= 0;
  }

  static IconData flowIcon(bool inflow) =>
      inflow ? Icons.north_east_rounded : Icons.south_east_rounded;

  static Color flowColor(bool inflow) => inflow ? inflowColor : outflowColor;

  static String labelForType(String transactionType) {
    switch (normalizeType(transactionType)) {
      case 'DEPOSIT':
        return 'Dépôt';
      case 'WITHDRAWAL':
        return 'Retrait';
      case 'MISSION_PAYMENT':
        return 'Paiement mission';
      case 'ESCROW_LOCK':
        return 'Blocage séquestre';
      case 'ESCROW_RELEASE':
        return 'Libération des fonds';
      case 'BOOST_PAYMENT':
        return 'Achat boost';
      case 'REFERRAL_BONUS':
        return 'Bonus parrainage';
      case 'INSURANCE_FEE':
        return 'Frais assurance';
      case 'BADGE_FEE':
        return 'Badge professionnel';
      case 'TRANSFER':
        return 'Transfert';
      case 'REFUND':
        return 'Remboursement';
      default:
        return 'Transaction';
    }
  }
}
