import 'package:fonaco/core/api/base_client.dart';
import 'package:fonaco/core/utils/app_logger.dart';
import 'package:fonaco/features/wallet/models/transaction.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Repository pour le wallet
class WalletRepository {
  final BaseClient _api = BaseClient();
  final AppLogger _logger = AppLogger();

  /// Récupère le solde du wallet
  Future<WalletBalance?> getBalance() async {
    try {
      final response = await _api.get('/wallet/balance/');

      if (response.statusCode == 200) {
        return WalletBalance.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      _logger.e('Error fetching wallet balance: $e');
      return null;
    }
  }

  /// Récupère l'historique des transactions
  Future<List<WalletTransaction>> getTransactions({
    TransactionFilter? filter,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (filter != null) {
        params.addAll(filter.toQueryParameters());
      }

      final response = await _api.get('/wallet/transactions/', queryParameters: params);

      if (response.statusCode == 200) {
        final data = response.data['results'] as List;
        return data.map((item) => WalletTransaction.fromJson(item as Map<String, dynamic>)).toList();
      }

      return [];
    } catch (e) {
      _logger.e('Error fetching transactions: $e');
      return [];
    }
  }

  /// Récupère une transaction par ID
  Future<WalletTransaction?> getTransaction(String transactionId) async {
    try {
      final response = await _api.get('/wallet/transactions/$transactionId/');

      if (response.statusCode == 200) {
        return WalletTransaction.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      _logger.e('Error fetching transaction: $e');
      return null;
    }
  }

  /// Demande un retrait
  Future<bool> requestWithdrawal({
    required double amount,
    required String paymentMethod,
    required String paymentDetails,
  }) async {
    try {
      final response = await _api.post(
        '/wallet/withdraw/',
        data: {
          'amount': amount,
          'payment_method': paymentMethod,
          'payment_details': paymentDetails,
        },
      );

      if (response.statusCode == 201) {
        _logger.i('Withdrawal request submitted');
        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Error requesting withdrawal: $e');
      return false;
    }
  }

  /// Exporte l'historique des transactions en PDF
  Future<File?> exportToPDF({
    TransactionFilter? filter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (filter != null) {
        params.addAll(filter.toQueryParameters());
      }
      if (startDate != null) {
        params['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        params['end_date'] = endDate.toIso8601String();
      }

      final response = await _api.get(
        '/wallet/export/pdf/',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        // Sauvegarder le fichier
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/wallet_export_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(response.data);
        _logger.i('PDF exported to ${file.path}');
        return file;
      }

      return null;
    } catch (e) {
      _logger.e('Error exporting PDF: $e');
      return null;
    }
  }

  /// Exporte l'historique des transactions en CSV
  Future<File?> exportToCSV({
    TransactionFilter? filter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (filter != null) {
        params.addAll(filter.toQueryParameters());
      }
      if (startDate != null) {
        params['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        params['end_date'] = endDate.toIso8601String();
      }

      final response = await _api.get(
        '/wallet/export/csv/',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        // Sauvegarder le fichier
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/wallet_export_${DateTime.now().millisecondsSinceEpoch}.csv');
        await file.writeAsString(response.data);
        _logger.i('CSV exported to ${file.path}');
        return file;
      }

      return null;
    } catch (e) {
      _logger.e('Error exporting CSV: $e');
      return null;
    }
  }

  /// Récupère les statistiques du wallet
  Future<Map<String, dynamic>?> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (startDate != null) {
        params['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        params['end_date'] = endDate.toIso8601String();
      }

      final response = await _api.get('/wallet/statistics/', queryParameters: params);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      _logger.e('Error fetching statistics: $e');
      return null;
    }
  }
}
