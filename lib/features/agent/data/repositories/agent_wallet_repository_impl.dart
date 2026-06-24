import 'package:logger/logger.dart';

import 'package:fonaco/core/models/transaction_display_policy.dart';
import 'package:fonaco/core/api/base_client.dart';
import 'package:fonaco/features/agent/domain/repositories/agent_wallet_repository.dart';

class AgentWalletRepositoryImpl implements AgentWalletRepository {
  final BaseClient _baseClient;
  final Logger _logger;

  AgentWalletRepositoryImpl({
    BaseClient? baseClient,
    Logger? logger,
  })  : _baseClient = baseClient ?? BaseClient(),
        _logger = logger ?? Logger();

  double _readAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  double _parseBalance(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map && data['balance'] != null) {
        return _readAmount(data['balance']);
      }
      if (raw['balance'] != null) {
        return _readAmount(raw['balance']);
      }
    }
    return 0.0;
  }

  @override
  Future<double> getBalance() async {
    try {
      final response = await _baseClient.get('wallets/balance/');
      if (response.statusCode == 200) {
        final balance = _parseBalance(response.data);
        _logger.d('Solde agent: $balance');
        return balance;
      }
      return 0.0;
    } catch (e, st) {
      _logger.e('getBalance', error: e, stackTrace: st);
      return 0.0;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final response = await _baseClient.get('wallets/transactions/');
      if (response.statusCode == 200) {
        final raw = response.data;
        List<dynamic> items = [];
        if (raw is Map && raw['results'] is List) {
          items = raw['results'] as List;
        } else if (raw is Map && raw['data'] is List) {
          items = raw['data'] as List;
        } else if (raw is List) {
          items = raw;
        }
        return items
            .whereType<Map>()
            .map((tx) => _mapTransaction(Map<String, dynamic>.from(tx)))
            .toList();
      }
      return [];
    } catch (e, st) {
      _logger.e('getTransactions', error: e, stackTrace: st);
      return [];
    }
  }

  Map<String, dynamic> _mapTransaction(Map<String, dynamic> tx) {
    final type = TransactionDisplayPolicy.normalizeType(
      tx['transaction_type'] ?? tx['type'],
    );
    final amount = _readAmount(tx['amount']);
    final isInflow = TransactionDisplayPolicy.isInflow(type, amount);
    final absAmount = amount.abs();
    final sign = isInflow ? '+' : '-';
    final rawDescription = tx['description']?.toString() ?? '';
    final missionId = _extractMissionId(tx, rawDescription);
    final missionTitle = _extractMissionTitle(rawDescription);
    final friendlyTitle = missionTitle.isNotEmpty
        ? missionTitle
        : TransactionDisplayPolicy.labelForType(type);
    final friendlyDate = _formatFullDate(tx['created_at']);

    return {
      'id': tx['id']?.toString() ?? '',
      'title': friendlyTitle,
      'subtitle': _formatDate(tx['created_at']),
      'amount': '$sign${absAmount.toStringAsFixed(0)} FCFA',
      'rawAmount': amount,
      'type': type,
      'typeLabel': TransactionDisplayPolicy.labelForType(type),
      'status': tx['status']?.toString() ?? '',
      'statusLabel': _labelForStatus(tx['status']?.toString() ?? ''),
      'reference': tx['reference']?.toString(),
      'description': rawDescription,
      'missionId': missionId,
      'missionIdShort': missionId != null && missionId.length >= 8
          ? missionId.substring(0, 8)
          : missionId,
      'missionTitle': missionTitle,
      'fullDate': friendlyDate,
      'createdAt': tx['created_at']?.toString(),
      'icon': TransactionDisplayPolicy.flowIcon(isInflow),
      'iconColor': TransactionDisplayPolicy.flowColor(isInflow),
      'amountColor': isInflow
          ? TransactionDisplayPolicy.inflowColor
          : TransactionDisplayPolicy.outflowColor,
      'isIncome': isInflow,
    };
  }

  String? _extractMissionId(Map<String, dynamic> tx, String description) {
    final fromField = tx['mission_id']?.toString() ??
        tx['mission']?.toString();
    if (fromField != null && fromField.isNotEmpty) return fromField;

    final uuidPattern = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    );
    final match = uuidPattern.firstMatch(description);
    return match?.group(0);
  }

  String _extractMissionTitle(String description) {
    if (description.isEmpty) return '';
    final cleaned = description
        .replaceAll(
          RegExp(
            r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
          ),
          '',
        )
        .replaceAll(RegExp(r'\b(ESCROW_RELEASE|COMPLETED|PENDING)\b'), '')
        .trim();
    if (cleaned.isEmpty) return '';
    final parts = cleaned.split('—');
    if (parts.length > 1) return parts.last.trim();
    return cleaned.length > 80 ? '${cleaned.substring(0, 77)}…' : cleaned;
  }

  String _labelForStatus(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return 'Réussi';
      case 'PENDING':
        return 'En attente';
      case 'FAILED':
        return 'Échoué';
      case 'CANCELLED':
        return 'Annulé';
      default:
        return status.isEmpty ? '—' : status;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return value.toString();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatFullDate(dynamic value) {
    if (value == null) return '';
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return value.toString();
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    final month = months[dt.month - 1];
    return '${dt.day} $month ${dt.year} à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      final error = data['error'];
      if (error is String && error.isNotEmpty) return error;
    }
    return null;
  }

  @override
  Future<WithdrawResult> withdraw({
    required double amount,
    required String paymentMethod,
    required String phoneNumber,
  }) async {
    try {
      final response = await _baseClient.post(
        'wallets/withdraw/',
        data: {
          'amount': amount,
          'payment_method': paymentMethod,
          'phone_number': phoneNumber,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return const WithdrawResult(success: true);
      }
      return WithdrawResult(
        success: false,
        message: _extractErrorMessage(response.data) ??
            'Erreur lors de la demande de retrait',
      );
    } on ApiException catch (e) {
      return WithdrawResult(success: false, message: e.message);
    } catch (e, st) {
      _logger.e('withdraw', error: e, stackTrace: st);
      return const WithdrawResult(
        success: false,
        message: 'Une erreur inattendue est survenue',
      );
    }
  }

  @override
  Future<bool> deposit({
    required double amount,
    String paymentMethod = 'mobile_money',
    String? paymentReference,
  }) async {
    try {
      final response = await _baseClient.post(
        'wallets/deposit/',
        data: {
          'amount': amount,
          'payment_method': paymentMethod,
          'payment_reference': paymentReference ?? '',
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, st) {
      _logger.e('deposit', error: e, stackTrace: st);
      return false;
    }
  }
}
