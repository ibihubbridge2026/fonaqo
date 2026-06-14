import 'package:logger/logger.dart';

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
        if (raw is Map && raw['results'] is List) {
          return List<Map<String, dynamic>>.from(raw['results'] as List);
        }
        if (raw is Map && raw['data'] is List) {
          return List<Map<String, dynamic>>.from(raw['data'] as List);
        }
      }
      return [];
    } catch (e, st) {
      _logger.e('getTransactions', error: e, stackTrace: st);
      return [];
    }
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
