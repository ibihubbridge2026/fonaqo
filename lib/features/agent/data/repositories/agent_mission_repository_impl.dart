import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fonaco/core/api/base_client.dart';
import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/services/cache_service.dart';
import 'package:fonaco/core/services/image_compression_service.dart';
import 'package:fonaco/core/services/location_service.dart';
import 'package:fonaco/features/agent/domain/repositories/agent_mission_repository.dart';

class AgentMissionRepositoryImpl implements AgentMissionRepository {
  final BaseClient _baseClient;
  final Logger _logger;
  final ImageCompressionService _compressionService;
  final CacheService _cacheService;

  AgentMissionRepositoryImpl({
    BaseClient? baseClient,
    Logger? logger,
    ImageCompressionService? compressionService,
    CacheService? cacheService,
  })  : _baseClient = baseClient ?? BaseClient(),
        _logger = logger ?? Logger(),
        _compressionService = compressionService ?? ImageCompressionService(),
        _cacheService = cacheService ?? CacheService();

  @override
  Future<List<MissionModel>> getAvailable({
    double? latitude,
    double? longitude,
    int? radius,
    bool filterByZone = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (latitude != null && longitude != null) {
        queryParams['latitude'] = latitude;
        queryParams['longitude'] = longitude;
        queryParams['radius'] = radius ?? 50000;
        await _cacheService.saveUserLocation(latitude, longitude);
      }
      if (filterByZone) {
        queryParams['filter_by_zone'] = 'true';
      }

      final response = await _baseClient.get(
        'missions/available/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final missions = _parseMissionList(response.data);
        final missionsJson = missions.map((m) => m.toJson()).toList();
        await _cacheService.cacheMissions(missionsJson);
        await _cacheService.setOnlineStatus(true);
        _logger.d('Missions disponibles: ${missions.length}');
        return missions;
      }

      return _missionsFromCache();
    } catch (e, st) {
      _logger.e('getAvailable', error: e, stackTrace: st);
      return _missionsFromCache();
    }
  }

  @override
  Future<List<MissionModel>> getAssigned({int limit = 50}) async {
    try {
      final response = await _baseClient.get(
        'missions/assigned/',
        queryParameters: {'limit': limit.toString()},
      );
      if (response.statusCode == 200) {
        return _parseMissionList(response.data);
      }
      return [];
    } catch (e, st) {
      _logger.e('getAssigned', error: e, stackTrace: st);
      return [];
    }
  }

  @override
  Future<bool> declineAssignment(String missionId) async {
    try {
      final response = await _baseClient.post(
        'missions/$missionId/decline_assignment/',
      );
      return response.statusCode == 200;
    } catch (e, st) {
      _logger.e('declineAssignment', error: e, stackTrace: st);
      return false;
    }
  }

  List<MissionModel> _missionsFromCache() {
    final cached = _cacheService.getCachedMissions();
    if (cached.isEmpty) return [];
    return cached.map((data) => MissionModel.fromJson(data)).toList();
  }

  List<MissionModel> _parseMissionList(dynamic raw) {
    List<dynamic> missionsData;
    if (raw is Map) {
      if (raw['results'] is List) {
        missionsData = raw['results'] as List<dynamic>;
      } else if (raw['data'] is Map &&
          (raw['data'] as Map)['results'] is List) {
        missionsData = (raw['data'] as Map)['results'] as List<dynamic>;
      } else if (raw['data'] is List) {
        missionsData = raw['data'] as List<dynamic>;
      } else {
        missionsData = [];
      }
    } else if (raw is List) {
      missionsData = raw;
    } else {
      missionsData = [];
    }
    return missionsData
        .map((data) => MissionModel.fromJson(data as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MissionModel>> getHistory({int limit = 20}) async {
    try {
      final response = await _baseClient.get(
        'missions/history/',
        queryParameters: {'limit': limit.toString()},
      );

      if (response.statusCode == 200) {
        return _parseMissionList(response.data);
      }
      return [];
    } catch (e, st) {
      _logger.e('getHistory', error: e, stackTrace: st);
      return [];
    }
  }

  @override
  Future<List<MissionModel>> getActive({int limit = 50}) async {
    try {
      final response = await _baseClient.get(
        'missions/active/',
        queryParameters: {'limit': limit.toString()},
      );

      if (response.statusCode == 200) {
        final missions = _parseMissionList(response.data);
        return missions
            .where((m) => MissionModel.isActiveLifecycle(m.status))
            .toList();
      }
      return [];
    } catch (e, st) {
      _logger.e('getActive', error: e, stackTrace: st);
      return [];
    }
  }

  MissionModel? _parseAcceptedMission(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        return MissionModel.fromJson(data);
      }
      return MissionModel.fromJson(raw);
    }
    return null;
  }

  @override
  Future<MissionAcceptResult> accept(String missionId) async {
    try {
      final response = await _baseClient.post(
        'missions/$missionId/accept/',
      );
      if (response.statusCode == 200) {
        return MissionAcceptResult(
          success: true,
          mission: _parseAcceptedMission(response.data),
        );
      }
      final message = response.data is Map
          ? (response.data['message']?.toString())
          : null;
      return MissionAcceptResult(
        success: false,
        message: message ?? 'Impossible d\'accepter la mission',
      );
    } on ApiException catch (e) {
      return MissionAcceptResult(
        success: false,
        conflict: e.type == ApiErrorType.conflict,
        message: e.message,
      );
    } catch (e, st) {
      _logger.e('accept', error: e, stackTrace: st);
      return const MissionAcceptResult(
        success: false,
        message: 'Une erreur inattendue est survenue',
      );
    }
  }

  @override
  Future<bool> startMission(String missionId) async {
    try {
      final response = await _baseClient.post(
        'missions/$missionId/start_mission/',
        data: {
          'status': 'IN_PROGRESS',
          'started_at': DateTime.now().toIso8601String(),
        },
      );
      return response.statusCode == 200;
    } catch (e, st) {
      _logger.e('startMission', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<bool> updateSteps(
    String missionId,
    String status, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      final position = LocationService().currentPosition;
      final stepData = <String, dynamic>{
        'status': status,
      };
      final lat = latitude ?? position?.latitude;
      final lng = longitude ?? position?.longitude;
      if (lat != null && lng != null) {
        stepData['latitude'] = lat;
        stepData['longitude'] = lng;
        if (position?.accuracy != null) {
          stepData['location_accuracy'] = position!.accuracy;
        }
      }

      final response = await _baseClient.post(
        'missions/$missionId/update_steps/',
        data: stepData,
      );
      return response.statusCode == 200;
    } catch (e, st) {
      _logger.e('updateSteps', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<bool> submitCompletion(String missionId, String photoPath) async {
    try {
      final originalFile = File(photoPath);
      if (!await originalFile.exists()) return false;

      final compressedFile = await _compressionService.compressUntilTargetSize(
        filePath: photoPath,
        targetSizeMB: 3.0,
        minQuality: 50,
      );
      if (compressedFile == null) return false;

      final fileName = compressedFile.path.split('/').last;
      final formData = FormData.fromMap({
        'completion_proof': await MultipartFile.fromFile(
          compressedFile.path,
          filename: fileName,
        ),
      });

      final position = LocationService().currentPosition;
      if (position != null) {
        formData.fields.add(MapEntry('latitude', '${position.latitude}'));
        formData.fields.add(MapEntry('longitude', '${position.longitude}'));
      }

      final response = await _baseClient.post(
        'missions/$missionId/submit_completion/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _cacheService.cacheMission(missionId, {
          'status': 'completed',
          'completion_date': DateTime.now().toIso8601String(),
        });
        return true;
      }
      return false;
    } catch (e, st) {
      _logger.e('submitCompletion', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<bool> rateClient({
    required String missionId,
    required String clientId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _baseClient.post(
        'missions/$missionId/rate_client/',
        data: {
          'client_id': clientId,
          'rating': rating,
          'comment': comment,
          'rated_at': DateTime.now().toIso8601String(),
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, st) {
      _logger.e('rateClient', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _baseClient.get('missions/statistics/');
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      return {};
    } catch (e, st) {
      _logger.e('getStatistics', error: e, stackTrace: st);
      return {};
    }
  }

  @override
  Future<List<MissionModel>> getDisputed({int limit = 50}) async {
    try {
      final response = await _baseClient.get(
        'missions/disputes/',
        queryParameters: {'limit': limit.toString()},
      );

      if (response.statusCode == 200) {
        return _parseMissionList(response.data);
      }
      return [];
    } catch (e, st) {
      _logger.e('getDisputed', error: e, stackTrace: st);
      return [];
    }
  }

  @override
  Future<String?> downloadMonthlyReport({int? month, int? year}) async {
    try {
      final now = DateTime.now();
      final m = month ?? now.month;
      final y = year ?? now.year;
      final monthKey = '$y-${m.toString().padLeft(2, '0')}';

      final response = await _baseClient.get(
        'missions/statistics/monthly_report/',
        queryParameters: {'month': monthKey},
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data;
        final bytes = raw is Uint8List
            ? raw
            : Uint8List.fromList(List<int>.from(raw as List));
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/releve_mensuel.pdf';
        final file = File(filePath);
        await file.writeAsBytes(bytes, flush: true);
        return filePath;
      }
      return null;
    } catch (e, st) {
      _logger.e('downloadMonthlyReport', error: e, stackTrace: st);
      return null;
    }
  }

  @override
  Future<bool> validateCompletion(String missionId, String qrCodeData) async {
    try {
      final response = await _baseClient.post(
        'missions/$missionId/validate_completion/',
        data: {
          'qr_code_data': qrCodeData,
          'validated_at': DateTime.now().toIso8601String(),
        },
      );
      return response.statusCode == 200;
    } catch (e, st) {
      _logger.e('validateCompletion', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<bool> submitReview(
    String missionId,
    int rating,
    String comment,
  ) async {
    try {
      final response = await _baseClient.post(
        'missions/$missionId/rate/',
        data: {
          'rating': rating,
          'comment': comment,
          'rated_at': DateTime.now().toIso8601String(),
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, st) {
      _logger.e('submitReview', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<bool> openDispute(
    String missionId,
    String reason,
    String description,
  ) async {
    try {
      final response = await _baseClient.post(
        'missions/$missionId/open_dispute/',
        data: {
          'reason': reason,
          'description': description,
          'disputed_at': DateTime.now().toIso8601String(),
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, st) {
      _logger.e('openDispute', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<bool> createDispute({
    required String missionId,
    required String title,
    required String description,
    String priority = 'medium',
  }) async {
    try {
      final response = await _baseClient.post(
        'disputes/',
        data: {
          'mission': missionId,
          'title': title,
          'description': description,
          'priority': priority,
        },
      );
      return response.statusCode == 201;
    } catch (e, st) {
      _logger.e('createDispute', error: e, stackTrace: st);
      return false;
    }
  }
}
