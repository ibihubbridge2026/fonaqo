import 'package:flutter_test/flutter_test.dart';

import 'package:fonaco/core/services/gps_websocket_service.dart';

void main() {
  group('GpsWebSocketService', () {
    test('isValidMissionUuid accepte un UUID v4', () {
      expect(
        GpsWebSocketService.isValidMissionUuid(
          '550e8400-e29b-41d4-a716-446655440000',
        ),
        isTrue,
      );
    });

    test('isValidMissionUuid rejette un identifiant invalide', () {
      expect(GpsWebSocketService.isValidMissionUuid('mission-123'), isFalse);
      expect(GpsWebSocketService.isValidMissionUuid(''), isFalse);
    });
  });
}
