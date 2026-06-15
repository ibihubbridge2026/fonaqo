import 'package:flutter_test/flutter_test.dart';

import 'package:fonaco/core/config/api_config.dart';

void main() {
  test('ApiConfig expose ws host alias apiHostAndPort', () {
    expect(ApiConfig.apiHostAndPort, isNotEmpty);
    expect(ApiConfig.apiHostAndPort, ApiConfig.wsHost);
  });

  test('ApiConfig.wsUrl construit gps path avec token', () {
    final url = ApiConfig.wsUrl(
      '/ws/gps/test-mission-id/',
      query: {'token': 'abc'},
    );
    expect(url, contains('/ws/gps/test-mission-id/'));
    expect(url, contains('token=abc'));
    expect(url.startsWith('ws://') || url.startsWith('wss://'), isTrue);
  });
}
