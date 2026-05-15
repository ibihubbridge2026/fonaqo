import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import '../../../core/api/base_client.dart';
import '../../../core/models/mission_model.dart';
import '../../../core/services/location_service.dart';

/// Repository pour les appels API spécifiques à l'Agent
class AgentRepository {
  final Logger _logger = Logger();
  final BaseClient _baseClient = BaseClient();

  /// Récupère le solde de l'agent
  Future<double> getAgentBalance() async {
    try {
      final response = await _baseClient.get('agent/balance/');

      if (response.statusCode == 200) {
        final balance = response.data['data']['balance']?.toDouble() ?? 0.0;
        _logger.d('Solde agent récupéré: $balance');
        return balance;
      } else {
        _logger.e('Erreur récupération solde: ${response.statusCode}');
        return 0.0;
      }
    } catch (e) {
      _logger.e('Erreur getAgentBalance: $e');
      return 0.0;
    }
  }

  /// Récupère les missions disponibles pour l'agent avec coordonnées GPS
  Future<List<MissionModel>> getAvailableMissions({
    double? latitude,
    double? longitude,
    int? radius, // rayon de recherche en mètres
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};

      // Ajouter les coordonnées GPS si disponibles
      if (latitude != null && longitude != null) {
        queryParams['latitude'] = latitude;
        queryParams['longitude'] = longitude;

        // Rayon par défaut si non spécifié (50km pour le Bénin)
        queryParams['radius'] = radius ?? 50000; // 50km en mètres
      }

      final response = await _baseClient.get(
        'agent/missions/available/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> missionsData =
            response.data['data']['missions'] ?? [];
        final missions =
            missionsData.map((data) => MissionModel.fromJson(data)).toList();
        _logger.d(
            'Missions disponibles récupérées: ${missions.length} avec localisation');
        return missions;
      } else {
        _logger.e('Erreur récupération missions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.e('Erreur getAvailableMissions: $e');
      return [];
    }
  }

  /// Met à jour le statut en ligne de l'agent
  Future<bool> updateOnlineStatus(bool isOnline) async {
    try {
      final response = await _baseClient.patch(
        'agent/status/',
        data: {
          'is_online': isOnline,
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Statut online mis à jour: $isOnline');
        return true;
      } else {
        _logger.e('Erreur mise à jour statut: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Erreur updateOnlineStatus: $e');
      return false;
    }
  }

  /// Accepte une mission
  Future<bool> acceptMission(String missionId) async {
    try {
      final response = await _baseClient.post(
        'agent/missions/$missionId/accept/',
        data: {
          'status': 'ACCEPTED',
          'accepted_at': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Mission acceptée: $missionId');
        return true;
      } else {
        _logger.e('Erreur acceptation mission: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Erreur acceptMission: $e');
      return false;
    }
  }

  /// Démarre une mission
  Future<bool> startMission(String missionId) async {
    try {
      final response = await _baseClient.post(
        'agent/missions/$missionId/start/',
        data: {
          'status': 'IN_PROGRESS',
          'started_at': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Mission démarrée: $missionId');
        return true;
      } else {
        _logger.e('Erreur démarrage mission: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Erreur startMission: $e');
      return false;
    }
  }

  /// Met à jour l'étape d'une mission avec coordonnées GPS
  Future<bool> updateMissionStep(String missionId, String status) async {
    try {
      // Récupérer les coordonnées GPS actuelles
      final locationService = LocationService();
      final position = locationService.currentPosition;

      final Map<String, dynamic> stepData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Ajouter les coordonnées GPS si disponibles
      if (position != null) {
        stepData['latitude'] = position.latitude;
        stepData['longitude'] = position.longitude;
        stepData['location_accuracy'] = position.accuracy;
      }

      final response = await _baseClient.post(
        'missions/$missionId/update_steps/',
        data: stepData,
      );

      if (response.statusCode == 200) {
        _logger.d('Étape mission mise à jour: $missionId - $status');
        return true;
      } else {
        _logger.e('Erreur mise à jour étape: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Erreur updateMissionStep: $e');
      return false;
    }
  }

  /// Soumet la preuve de complétion (photo) avec upload réel via FormData
  Future<bool> submitCompletion(String missionId, String photoPath) async {
    try {
      final file = File(photoPath);
      if (!await file.exists()) {
        _logger.e('Fichier photo inexistant: $photoPath');
        return false;
      }

      final fileName = photoPath.split('/').last;
      final fileSize = await file.length();

      _logger.d('Upload preuve de complétion: $fileName (${fileSize} bytes)');

      // Créer FormData pour l'upload
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          photoPath,
          filename: fileName,
        ),
        'mission_id': missionId,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      final response = await _baseClient.post(
        'missions/$missionId/submit_completion/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: (sent, total) {
          final progress = sent / total;
          _logger.d('Upload progression: ${(progress * 100).toInt()}%');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.d('Preuve de complétion soumise avec succès: $missionId');
        return true;
      } else {
        _logger.e('Erreur soumission preuve: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Erreur submitCompletion: $e');
      return false;
    }
  }

  /// Valide la complétion via QR Code client
  Future<bool> validateCompletion(String missionId, String qrCodeData) async {
    try {
      final response = await _baseClient.post(
        'missions/$missionId/validate_completion/',
        data: {
          'qr_code_data': qrCodeData,
          'validated_at': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Complétion validée: $missionId');
        return true;
      } else {
        _logger.e('Erreur validation complétion: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Erreur validateCompletion: $e');
      return false;
    }
  }

  /// Rafraîchit le solde du portefeuille
  Future<double> refreshWalletBalance() async {
    try {
      final response = await _baseClient.get('wallets/me/');

      if (response.statusCode == 200) {
        final balance = response.data['data']['balance'] ?? 0.0;
        _logger.d('Solde rafraîchi: $balance');
        return balance.toDouble();
      } else {
        _logger.e('Erreur rafraîchissement solde: ${response.statusCode}');
        return 0.0;
      }
    } catch (e) {
      _logger.e('Erreur refreshWalletBalance: $e');
      return 0.0;
    }
  }

  /// Demande l'ouverture d'un litige pour une mission
  Future<bool> openDispute(
      String missionId, String reason, String description) async {
    try {
      final response = await _baseClient.post(
        'missions/$missionId/open_dispute/',
        data: {
          'reason': reason,
          'description': description,
          'disputed_at': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.d('Litige ouvert pour mission $missionId: $reason');
        return true;
      } else {
        _logger.e('Erreur ouverture litige: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Erreur openDispute: $e');
      return false;
    }
  }

  /// Récupère le solde du portefeuille
  Future<double> getWalletBalance() async {
    try {
      final response = await _baseClient.get('wallets/me/');

      if (response.statusCode == 200) {
        final balance = response.data['data']['balance'] ?? 0.0;
        _logger.d('Solde récupéré: $balance');
        return balance.toDouble();
      } else {
        _logger.e('Erreur récupération solde: ${response.statusCode}');
        return 0.0;
      }
    } catch (e) {
      _logger.e('Erreur getWalletBalance: $e');
      return 0.0;
    }
  }

  /// Récupère l'historique des transactions
  Future<List<Map<String, dynamic>>> getWalletTransactions() async {
    try {
      final response = await _baseClient.get('wallets/transactions/');

      if (response.statusCode == 200) {
        final transactions = List<Map<String, dynamic>>.from(
          response.data['data'] ?? [],
        );
        _logger.d('Transactions récupérées: ${transactions.length}');
        return transactions;
      } else {
        _logger.e('Erreur récupération transactions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.e('Erreur getWalletTransactions: $e');
      return [];
    }
  }

  /// Demande un retrait de fonds
  Future<bool> requestWithdrawal(double amount, String provider) async {
    try {
      final response = await _baseClient.post(
        'payments/withdraw/',
        data: {
          'amount': amount,
          'provider': provider, // 'mtn_momo' ou 'moov_flooz'
          'currency': 'XOF',
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Demande de retrait envoyée: $amount $provider');
        return true;
      } else {
        _logger.e('Erreur demande retrait: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Erreur requestWithdrawal: $e');
      return false;
    }
  }

  /// Soumet une évaluation de mission
  Future<bool> submitReview(
      String missionId, int rating, String comment) async {
    try {
      final response = await _baseClient.post(
        'missions/$missionId/rate/',
        data: {
          'rating': rating,
          'comment': comment,
          'rated_at': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger
            .d('Évaluation soumise pour mission $missionId: $rating étoiles');
        return true;
      } else {
        _logger.e('Erreur soumission évaluation: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Erreur submitReview: $e');
      return false;
    }
  }

  /// Récupère les évaluations de l'agent
  Future<Map<String, dynamic>> getAgentRatings() async {
    try {
      final response = await _baseClient.get('agent/ratings/');

      if (response.statusCode == 200) {
        final ratings = response.data['data'] ?? {};
        _logger.d('Évaluations agent récupérées');
        return ratings;
      } else {
        _logger.e('Erreur récupération évaluations: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      _logger.e('Erreur getAgentRatings: $e');
      return {};
    }
  }

  /// Récupère les statistiques de l'agent
  Future<Map<String, dynamic>> getAgentStats() async {
    try {
      final response = await _baseClient.get('agent/stats/');

      if (response.statusCode == 200) {
        final stats = response.data['data'] ?? {};
        _logger.d('Statistiques agent récupérées');
        return stats;
      } else {
        _logger.e('Erreur récupération statistiques: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      _logger.e('Erreur getAgentStats: $e');
      return {};
    }
  }

  /// Upload un fichier pour le chat
  Future<Map<String, dynamic>?> uploadChatFile(
    File file,
    String missionId, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();

      _logger.d('Upload fichier: $fileName (${fileSize} bytes)');

      // Créer FormData pour l'upload
      final formData = {
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'mission_id': missionId,
        'file_size': fileSize,
      };

      final response = await _baseClient.post(
        'chat/upload/',
        data: formData,
        onSendProgress: (sent, total) {
          final progress = sent / total;
          _logger.d('Upload progress: ${(progress * 100).toInt()}%');
          onProgress?.call(progress);
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final uploadData = response.data['data'] ?? {};
        _logger.d('Fichier uploadé avec succès: ${uploadData['url']}');
        return uploadData;
      } else {
        _logger.e('Erreur upload fichier: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Erreur uploadChatFile: $e');
      return null;
    }
  }

  /// Achète un boost pour l'agent
  Future<bool> purchaseBoost(String boostType, double amount) async {
    try {
      final response = await _baseClient.post(
        'agent/purchase-boost/',
        data: {
          'boost_type': boostType,
          'amount': amount,
          'currency': 'XOF',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.d('Boost acheté: $boostType pour $amount XOF');
        return true;
      } else {
        _logger.e('Erreur achat boost: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Erreur purchaseBoost: $e');
      return false;
    }
  }

  /// Récupère l'historique des missions de l'agent
  Future<List<MissionModel>> getAgentMissionHistory({int limit = 20}) async {
    try {
      final response = await _baseClient.get(
        'agent/missions/history/',
        queryParameters: {'limit': limit.toString()},
      );

      if (response.statusCode == 200) {
        final List<dynamic> missionsData =
            response.data['data']['missions'] ?? [];
        final missions =
            missionsData.map((data) => MissionModel.fromJson(data)).toList();
        _logger.d('Historique missions récupéré: ${missions.length}');
        return missions;
      } else {
        _logger.e('Erreur récupération historique: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.e('Erreur getAgentMissionHistory: $e');
      return [];
    }
  }
}
