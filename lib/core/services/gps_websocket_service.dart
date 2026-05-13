import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/base_client.dart';

/// WebSocket `ws://<hôte>/ws/gps/<mission_id>/?token=…` (Django Channels + JWT).
class GpsWebSocketService extends ChangeNotifier {
  GpsWebSocketService();

  final Logger _logger = Logger();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _agentLocationTimer;

  bool _connected = false;
  LatLng? _agentPosition;
  String? _liveStatus;
  double? _destinationLat;
  double? _destinationLng;
  String? _lastError;

  bool get isConnected => _connected;
  LatLng? get agentPosition => _agentPosition;
  String? get liveStatus => _liveStatus;
  double? get destinationLat => _destinationLat;
  double? get destinationLng => _destinationLng;
  String? get lastError => _lastError;

  static bool isValidMissionUuid(String missionId) {
    final re = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return re.hasMatch(missionId.trim());
  }

  Future<void> connect(String missionId) async {
    if (!isValidMissionUuid(missionId)) {
      _lastError = 'Identifiant de mission invalide.';
      notifyListeners();
      throw StateError(_lastError!);
    }

    await disconnect();

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      _lastError = 'Session expirée (token manquant).';
      notifyListeners();
      throw StateError(_lastError!);
    }

    final host = BaseClient.apiHostAndPort;
    final uri = Uri.parse('ws://$host/ws/gps/$missionId/')
        .replace(queryParameters: {'token': token});

    _logger.i('Connexion GPS WS: $uri');
    _channel = WebSocketChannel.connect(uri);

    _subscription = _channel!.stream.listen(
      _onMessage,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );

    _connected = true;
    _lastError = null;
    notifyListeners();
  }

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type']?.toString();

      if (type == 'gps_update') {
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          _agentPosition = LatLng(lat, lng);
        }
      } else if (type == 'mission_status') {
        _liveStatus = data['status']?.toString();
        final dLat = (data['destination_lat'] as num?)?.toDouble();
        final dLng = (data['destination_lng'] as num?)?.toDouble();
        if (dLat != null && dLng != null) {
          _destinationLat = dLat;
          _destinationLng = dLng;
        }
      } else if (type == 'error') {
        _lastError = data['message']?.toString();
      }
      notifyListeners();
    } catch (e, st) {
      _logger.e('GPS WS parse', error: e, stackTrace: st);
    }
  }

  void _onError(Object error) {
    _logger.e('GPS WS erreur: $error');
    _lastError = error.toString();
    _connected = false;
    notifyListeners();
  }

  void _onDone() {
    _connected = false;
    notifyListeners();
  }

  /// Envoie une position (agent, mission IN_PROGRESS côté serveur).
  Future<void> sendLocation(double lat, double lng) async {
    if (_channel == null) return;
    _channel!.sink.add(
      jsonEncode(<String, dynamic>{
        'type': 'location',
        'lat': lat,
        'lng': lng,
      }),
    );
  }

  /// Pousse la position courante toutes les 10 s tant que [shouldSend] est vrai.
  void startAgentLocationTicker(bool Function() shouldSend) {
    _agentLocationTimer?.cancel();
    _agentLocationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!_connected || !shouldSend()) return;
      try {
        final pos = await Geolocator.getCurrentPosition();
        await sendLocation(pos.latitude, pos.longitude);
      } catch (e) {
        _logger.w('GPS tick ignoré: $e');
      }
    });
  }

  void stopAgentLocationTicker() {
    _agentLocationTimer?.cancel();
    _agentLocationTimer = null;
  }

  Future<void> disconnect() async {
    stopAgentLocationTicker();
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _connected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopAgentLocationTicker();
    _subscription?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    super.dispose();
  }
}
