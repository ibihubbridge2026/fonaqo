/// Désenveloppe les réponses API Django (StandardizedJSONRenderer + JsonResponse).
class ApiResponseParser {
  ApiResponseParser._();

  static bool _isEnvelope(Map map) =>
      map.containsKey('status') &&
      map.containsKey('data') &&
      (map.containsKey('message') || map.containsKey('errors'));

  /// Retourne le payload utile (souvent `data`, parfois `data.data`).
  static dynamic unwrap(dynamic body) {
    if (body is! Map) return body;
    final map = Map<String, dynamic>.from(body);
    if (!_isEnvelope(map)) return body;

    var inner = map['data'];
    if (inner is Map &&
        inner.containsKey('data') &&
        !inner.containsKey('results') &&
        !inner.containsKey('access_token') &&
        !inner.containsKey('id') &&
        !inner.containsKey('user')) {
      inner = inner['data'];
    }
    return inner;
  }

  static String? envelopeMessage(dynamic body) {
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }
    return null;
  }

  static Map<String, dynamic>? envelopeErrors(dynamic body) {
    if (body is! Map) return null;
    final errors = body['errors'];
    if (errors is Map) return Map<String, dynamic>.from(errors);
    final data = body['data'];
    if (data is Map && body['status'] == 'error') {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }
}
