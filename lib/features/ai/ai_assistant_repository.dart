import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'package:fonaco/core/api/base_client.dart';
import 'package:fonaco/features/client/missions/mission_repository.dart';
import 'models/assistant_response.dart';

/// Repository Moki : chat IA backend + recherche agents dynamique.
class AiAssistantRepository {
  final BaseClient _client;
  final MissionRepository _missionRepository;
  final Logger _logger = Logger();

  AiAssistantRepository({
    BaseClient? client,
    MissionRepository? missionRepository,
  })  : _client = client ?? BaseClient(),
        _missionRepository = missionRepository ?? MissionRepository();

  Future<AssistantResponse> ask({
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final response = await _client.post(
        'ai/assistant/',
        data: {
          'message': message,
          'history': history,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final body = response.data as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          return AssistantResponse.fromJson(data);
        }
      }
    } on DioException catch (e, st) {
      _logger.w('ask assistant API', error: e, stackTrace: st);
    } catch (e, st) {
      _logger.w('ask assistant', error: e, stackTrace: st);
    }

    return _localFallback(message);
  }

  Future<List<Map<String, dynamic>>> searchAgents({
    required AgentSearchHints hints,
    double? latitude,
    double? longitude,
    int limit = 5,
  }) async {
    final types = hints.missionTypes.isNotEmpty
        ? hints.missionTypes
        : _inferMissionTypes(hints.keywords);

    return _missionRepository.fetchNearbyAgents(
      latitude: latitude,
      longitude: longitude,
      verifiedOnly: true,
      missionTypes: types.isNotEmpty ? types : null,
      limit: limit,
    );
  }

  AssistantResponse _localFallback(String message) {
    final q = message.toLowerCase();
    final suggest = q.contains('agent') ||
        q.contains('livraison') ||
        q.contains('course') ||
        q.contains('queue') ||
        q.contains('trouver') ||
        q.contains('chercher') ||
        q.contains('disponible');

    final types = <String>[];
    if (q.contains('livraison') || q.contains('colis')) types.add('livraison');
    if (q.contains('course')) types.add('courses');
    if (q.contains('queue') || q.contains('banque')) types.add('queue');
    if (types.isEmpty && suggest) types.add('autre');

    String reply;
    if (q.contains('mission') || q.contains('créer') || q.contains('creer')) {
      reply =
          'Pour créer une mission : onglet Missions → CRÉER. Choisissez la catégorie, '
          'décrivez votre besoin (texte ou micro), puis indiquez la destination.';
    } else if (q.contains('paiement') || q.contains('wallet') || q.contains('feex')) {
      reply =
          'Vous pouvez payer via FeexPay ou votre portefeuille FONACO. '
          'Le montant minimal de prestation est de 500 FCFA.';
    } else if (q.contains('annul')) {
      reply =
          "Une mission acceptée ou en cours peut être annulée avec un "
          "dédommagement obligatoire de 20 % pour l'agent.";
    } else if (q.contains('litige')) {
      reply =
          'Ouvrez un litige depuis le détail d\'une mission en cours. '
          'Notre équipe revient vers vous sous 24 h ouvrées maximum.';
    } else if (suggest) {
      reply =
          'Voici des agents susceptibles de correspondre à votre recherche. '
          'Consultez leur profil ou créez une mission pour les contacter.';
    } else {
      reply =
          'Je suis Moki, votre assistant FONACO. Posez-moi une question sur '
          'les missions, les paiements, les agents ou les litiges.';
    }

    return AssistantResponse(
      reply: reply,
      suggestAgents: suggest,
      agentSearch: AgentSearchHints(
        missionTypes: types,
        keywords: q.split(RegExp(r'\s+')).where((w) => w.length > 2).take(5).toList(),
      ),
    );
  }

  List<String> _inferMissionTypes(List<String> keywords) {
    final joined = keywords.join(' ').toLowerCase();
    final types = <String>[];
    if (joined.contains('livraison') || joined.contains('colis')) {
      types.add('livraison');
    }
    if (joined.contains('course')) types.add('courses');
    if (joined.contains('queue') || joined.contains('banque')) {
      types.add('queue');
    }
    return types;
  }
}
