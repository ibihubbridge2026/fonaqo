import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fonaco/core/api/base_client.dart';
import 'package:fonaco/features/agent/domain/repositories/agent_profile_repository.dart';

class AgentProfileRepositoryImpl implements AgentProfileRepository {
  final BaseClient _baseClient;
  final Logger _logger;

  AgentProfileRepositoryImpl({
    BaseClient? baseClient,
    Logger? logger,
  })  : _baseClient = baseClient ?? BaseClient(),
        _logger = logger ?? Logger();

  @override
  Future<bool> updateStatus({required bool isOnline}) async {
    try {
      final response = await _baseClient.patch(
        'accounts/agent/status/',
        data: {'is_online': isOnline},
      );
      return response.statusCode == 200;
    } catch (e, st) {
      _logger.e('updateStatus', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _baseClient.get('accounts/profile/');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data'] as Map);
        }
      }
      return {};
    } catch (e, st) {
      _logger.e('getProfile', error: e, stackTrace: st);
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> updateProfile(dynamic data) async {
    try {
      final response = await _baseClient.patch(
        'accounts/profile/',
        data: data,
        options: data is FormData
            ? Options(contentType: 'multipart/form-data')
            : null,
      );
      if (response.statusCode == 200) {
        final body = response.data;
        if (body is Map) {
          if (body['data'] is Map) {
            return Map<String, dynamic>.from(body['data'] as Map);
          }
          if (body['id'] != null) {
            return Map<String, dynamic>.from(body);
          }
        }
      }
      return {};
    } catch (e, st) {
      _logger.e('updateProfile', error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await _baseClient.get('notifications/');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e, st) {
      _logger.e('getNotifications', error: e, stackTrace: st);
      return [];
    }
  }

  @override
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final response =
          await _baseClient.post('notifications/$notificationId/read/');
      return response.statusCode == 200;
    } catch (e, st) {
      _logger.e('markNotificationAsRead', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response =
          await _baseClient.delete('notifications/$notificationId/');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e, st) {
      _logger.e('deleteNotification', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<bool> markAllNotificationsAsRead() async {
    try {
      final response =
          await _baseClient.post('notifications/mark_all_read/');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, st) {
      _logger.e('markAllNotificationsAsRead', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<bool> purchaseBoost(
    String boostType,
    double amount, {
    String paymentMethod = 'wallet',
    String? transactionId,
  }) async {
    try {
      final response = await _baseClient.post(
        'boosts/my-boosts/purchase/',
        data: {
          'boost_type': boostType,
          'plan_id': boostType,
          'amount': amount,
          'payment_method': paymentMethod,
          if (transactionId != null) 'transaction_id': transactionId,
          'currency': 'XOF',
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, st) {
      _logger.e('purchaseBoost', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getBoostPlans() async {
    try {
      final response = await _baseClient.get('boosts/plans/');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        if (data is Map && data['results'] is List) {
          return List<Map<String, dynamic>>.from(data['results'] as List);
        }
      }
      return [];
    } catch (e, st) {
      _logger.e('getBoostPlans', error: e, stackTrace: st);
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getActiveBoost() async {
    try {
      final response = await _baseClient.get('boosts/my-boosts/active/');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['has_active_boost'] == false) return null;
        if (data is Map && data['id'] != null) {
          return Map<String, dynamic>.from(data);
        }
      }
      return null;
    } catch (e, st) {
      _logger.e('getActiveBoost', error: e, stackTrace: st);
      return null;
    }
  }

  @override
  Future<bool> submitKycDocuments(FormData formData) async {
    try {
      final response = await _baseClient.post(
        'accounts/kyc/submit/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, st) {
      _logger.e('submitKycDocuments', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getProBadgeStatus() async {
    try {
      final response = await _baseClient.get('accounts/agent/badge/');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body is Map && body['data'] is Map) {
          return Map<String, dynamic>.from(body['data'] as Map);
        }
      }
      return {};
    } catch (e, st) {
      _logger.e('getProBadgeStatus', error: e, stackTrace: st);
      return {};
    }
  }

  @override
  Future<bool> requestProBadge(FormData formData) async {
    try {
      final response = await _baseClient.post(
        'accounts/agent/badge/request/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, st) {
      _logger.e('requestProBadge', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<String?> downloadProBadge() async {
    try {
      final response = await _baseClient.get(
        'accounts/agent/badge/download/',
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode != 200) return null;
      final bytes = response.data;
      if (bytes == null) return null;
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/badge_fonaco.pdf';
      final file = File(path);
      await file.writeAsBytes(bytes as List<int>);
      return path;
    } catch (e, st) {
      _logger.e('downloadProBadge', error: e, stackTrace: st);
      return null;
    }
  }
}
