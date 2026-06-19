import 'package:logger/logger.dart';
import 'package:flutter/material.dart';

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
    final type = (tx['transaction_type'] ?? tx['type'] ?? '').toString();
    final amount = _readAmount(tx['amount']);
    final isCredit = amount >= 0 ||
        type == 'DEPOSIT' ||
        type == 'ESCROW_RELEASE' ||
        type == 'REFERRAL_BONUS' ||
        type == 'REFUND';
    final absAmount = amount.abs();
    final sign = isCredit ? '+' : '-';
    return {
      'id': tx['id']?.toString() ?? '',
      'title': tx['description']?.toString() ?? _labelForType(type),
      'subtitle': _formatDate(tx['created_at']),
      'amount': '$sign${absAmount.toStringAsFixed(0)} FCFA',
      'rawAmount': amount,
      'type': type,
      'status': tx['status']?.toString() ?? '',
      'reference': tx['reference']?.toString(),
      'description': tx['description']?.toString() ?? '',
      'createdAt': tx['created_at']?.toString(),
      'icon': isCredit ? Icons.arrow_downward : Icons.arrow_upward,
      'iconColor': isCredit ? Colors.green : Colors.red,
      'amountColor': isCredit ? Colors.green.shade700 : Colors.red.shade700,
      'isIncome': isCredit,
    };
  }

  String _labelForType(String type) {
    switch (type) {
      case 'DEPOSIT':
        return 'Dépôt';
      case 'WITHDRAWAL':
        return 'Retrait';
      case 'MISSION_PAYMENT':
        return 'Paiement mission';
      case 'ESCROW_LOCK':
        return 'Blocage séquestre';
      case 'ESCROW_RELEASE':
        return 'Libération séquestre';
      case 'BOOST_PAYMENT':
        return 'Achat boost';
      default:
        return 'Transaction';
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return value.toString();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
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
