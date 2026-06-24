import 'package:fonaco/core/models/transaction_display_policy.dart';

/// Modèle pour les transactions du wallet
class WalletTransaction {
  final String id;
  final String userId;
  final TransactionType type;
  /// Type brut renvoyé par l'API Django (`DEPOSIT`, `ESCROW_RELEASE`, …).
  final String apiTransactionType;
  final double amount;
  final String currency;
  final String description;
  final TransactionStatus status;
  final String? reference;
  final String? missionId;
  final DateTime createdAt;
  final DateTime? processedAt;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.apiTransactionType,
    required this.amount,
    required this.currency,
    required this.description,
    required this.status,
    this.reference,
    this.missionId,
    required this.createdAt,
    this.processedAt,
  });

  bool get isInflow =>
      TransactionDisplayPolicy.isInflow(apiTransactionType, amount);

  /// Crée depuis JSON (tolérant — aligné sur TransactionSerializer Django).
  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final apiType = TransactionDisplayPolicy.normalizeType(
      json['transaction_type'] ?? json['type'] ?? 'DEPOSIT',
    );
    final amount = _readAmount(json['amount']);
    final createdRaw = json['created_at']?.toString();
    final createdAt = createdRaw != null
        ? (DateTime.tryParse(createdRaw) ?? DateTime.now())
        : DateTime.now();

    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      apiTransactionType: apiType,
      type: _mapLegacyType(apiType, amount),
      amount: amount,
      currency: json['currency']?.toString() ?? 'FCFA',
      description: json['description']?.toString() ?? '',
      status: TransactionStatusExtension.fromApi(json['status']),
      reference: json['reference']?.toString(),
      missionId: json['mission_id']?.toString(),
      createdAt: createdAt,
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'].toString())
          : null,
    );
  }

  static double _readAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  static TransactionType _mapLegacyType(String apiType, double amount) {
    if (!TransactionDisplayPolicy.isInflow(apiType, amount)) {
      return TransactionType.debit;
    }
    if (apiType == 'REFUND') return TransactionType.refund;
    if (apiType == 'REFERRAL_BONUS') return TransactionType.bonus;
    return TransactionType.credit;
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId.isNotEmpty) 'user_id': userId,
      'transaction_type': apiTransactionType,
      'type': type.toJson(),
      'amount': amount,
      if (currency.isNotEmpty) 'currency': currency,
      'description': description,
      'status': status.toApi(),
      'reference': reference,
      'mission_id': missionId,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }

  /// Montant formaté
  String get formattedAmount {
    final sign = isInflow ? '+' : '-';
    final abs = amount.abs().toStringAsFixed(0);
    return '$sign$abs ${currency.isNotEmpty ? currency : 'FCFA'}';
  }

  String get displayTitle => description.isNotEmpty
      ? description
      : TransactionDisplayPolicy.labelForType(apiTransactionType);
}

/// Type de transaction (vue simplifiée rétrocompatible).
enum TransactionType {
  credit,
  debit,
  refund,
  bonus,
}

extension TransactionTypeExtension on TransactionType {
  String toJson() => toString().split('.').last;
}

/// Statut de transaction
enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

extension TransactionStatusExtension on TransactionStatus {
  String toJson() => toString().split('.').last;

  String toApi() => toJson().toUpperCase();

  static TransactionStatus fromApi(dynamic raw) {
    final normalized = (raw?.toString() ?? 'PENDING').toUpperCase();
    switch (normalized) {
      case 'PENDING':
        return TransactionStatus.pending;
      case 'COMPLETED':
        return TransactionStatus.completed;
      case 'FAILED':
        return TransactionStatus.failed;
      case 'CANCELLED':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }
}

/// Solde du wallet — correspond au WalletSerializer backend (balance, escrow_balance).
class WalletBalance {
  final String id;
  final double availableBalance;
  final double escrowBalance;
  final DateTime updatedAt;

  WalletBalance({
    required this.id,
    required this.availableBalance,
    required this.escrowBalance,
    required this.updatedAt,
  });

  /// Crée depuis JSON (champs backend : balance, escrow_balance).
  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;
    return WalletBalance(
      id: (data['id'] ?? '').toString(),
      availableBalance: (data['balance'] as num? ?? 0).toDouble(),
      escrowBalance: (data['escrow_balance'] as num? ?? 0).toDouble(),
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balance': availableBalance,
      'escrow_balance': escrowBalance,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Solde total (disponible + séquestre)
  double get totalBalance => availableBalance + escrowBalance;
}

/// Filtres pour les transactions
class TransactionFilter {
  final TransactionType? type;
  final TransactionStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String? missionId;

  TransactionFilter({
    this.type,
    this.status,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.missionId,
  });

  /// Convertit en query parameters
  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (type != null) params['type'] = type!.toJson();
    if (status != null) params['status'] = status!.toApi();
    if (startDate != null) params['start_date'] = startDate!.toIso8601String();
    if (endDate != null) params['end_date'] = endDate!.toIso8601String();
    if (minAmount != null) params['min_amount'] = minAmount;
    if (maxAmount != null) params['max_amount'] = maxAmount;
    if (missionId != null) params['mission_id'] = missionId;
    return params;
  }
}
