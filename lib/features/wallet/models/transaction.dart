/// Modèle pour les transactions du wallet
class WalletTransaction {
  final String id;
  final String userId;
  final TransactionType type;
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
    required this.amount,
    required this.currency,
    required this.description,
    required this.status,
    this.reference,
    this.missionId,
    required this.createdAt,
    this.processedAt,
  });

  /// Crée depuis JSON
  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: TransactionTypeExtension.fromJson(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      description: json['description'] as String,
      status: TransactionStatusExtension.fromJson(json['status'] as String),
      reference: json['reference'] as String?,
      missionId: json['mission_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.toJson(),
      'amount': amount,
      'currency': currency,
      'description': description,
      'status': status.toJson(),
      'reference': reference,
      'mission_id': missionId,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }

  /// Montant formaté
  String get formattedAmount {
    final sign = type == TransactionType.credit ? '+' : '-';
    return '$sign${amount.toStringAsFixed(2)} $currency';
  }
}

/// Type de transaction
enum TransactionType {
  credit, // Crédit (gain)
  debit, // Débit (dépense)
  refund, // Remboursement
  bonus, // Bonus
}

extension TransactionTypeExtension on TransactionType {
  String toJson() => toString().split('.').last;

  static TransactionType fromJson(String value) {
    switch (value) {
      case 'credit':
        return TransactionType.credit;
      case 'debit':
        return TransactionType.debit;
      case 'refund':
        return TransactionType.refund;
      case 'bonus':
        return TransactionType.bonus;
      default:
        return TransactionType.credit;
    }
  }
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

  static TransactionStatus fromJson(String value) {
    switch (value) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      case 'cancelled':
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
    if (status != null) params['status'] = status!.toJson();
    if (startDate != null) params['start_date'] = startDate!.toIso8601String();
    if (endDate != null) params['end_date'] = endDate!.toIso8601String();
    if (minAmount != null) params['min_amount'] = minAmount;
    if (maxAmount != null) params['max_amount'] = maxAmount;
    if (missionId != null) params['mission_id'] = missionId;
    return params;
  }
}
