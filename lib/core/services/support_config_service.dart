import 'package:fonaco/core/api/base_client.dart';

class SupportConfig {
  final String phone;
  final String email;
  final String hours;
  final List<({String question, String answer})> faqs;

  const SupportConfig({
    required this.phone,
    required this.email,
    required this.hours,
    required this.faqs,
  });
}

class SupportConfigService {
  final BaseClient _client;

  SupportConfigService({BaseClient? client}) : _client = client ?? BaseClient();

  Future<SupportConfig?> fetch({String? profile}) async {
    try {
      final response = await _client.get(
        'config/support/',
        queryParameters: profile != null ? {'profile': profile} : null,
      );
      if (response.statusCode != 200) return null;
      final raw = response.data;
      final data = raw is Map && raw['data'] is Map ? raw['data'] : raw;
      if (data is! Map) return null;
      final faqs = <({String question, String answer})>[];
      final list = data['faqs'];
      if (list is List) {
        for (final item in list) {
          if (item is Map) {
            faqs.add((
              question: item['question']?.toString() ?? '',
              answer: item['answer']?.toString() ?? '',
            ));
          }
        }
      }
      return SupportConfig(
        phone: data['phone']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        hours: data['hours']?.toString() ?? '',
        faqs: faqs,
      );
    } catch (_) {
      return null;
    }
  }
}
