import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../models/agent_model.dart';
import '../models/ai_analysis_result.dart';
import '../../../core/services/mistral_ai_service.dart';
import '../../../core/services/cache_service.dart';
import '../missions/mission_repository.dart';

/// Provider pour la Recherche Assistée par IA (Côté CLIENT)
/// Utilise Mistral AI pour analyser les requêtes naturelles et scorer les agents
class AiSearchProvider extends ChangeNotifier {
  final MissionRepository _missionRepository = MissionRepository();
  final CacheService _cacheService = CacheService();
  MistralAiService? _mistralService;

  // Configuration Mistral API Key via variable d'environnement (.env)
  static String get _mistralApiKey => dotenv.env['MISTRAL_API_KEY'] ?? '';

  List<AgentModel> _suggestedAgents = [];
  AiAnalysisResult? _analysisResult;
  bool _isLoading = false;
  String? _error;

  List<AgentModel> get suggestedAgents => _suggestedAgents;
  AiAnalysisResult? get analysisResult => _analysisResult;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Analyse le texte et trouve des agents avec scoring intelligent
  Future<void> searchAgents(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Vérifier le cache (TTL 10 minutes)
      final cacheKey = 'ai_search_${query.hashCode}';
      final cached = await _getCachedResult(cacheKey);
      if (cached != null) {
        _analysisResult = cached['analysis'] as AiAnalysisResult;
        _suggestedAgents = cached['agents'] as List<AgentModel>;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2. Initialiser le service Mistral
      if (_mistralApiKey.isEmpty) {
        Logger().w(
            '⚠️ Clé API Mistral non configurée (MISTRAL_API_KEY non définie)');
        _error = 'Service IA non configuré. Contactez l\'administrateur.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      _mistralService = MistralAiService(apiKey: _mistralApiKey);

      // 3. Récupérer les catégories de services disponibles
      final categories = await _missionRepository.fetchServiceCategories();
      final categoryNames = categories
          .map((c) => (c['name'] ?? c['id'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();

      // 4. Analyser la requête avec Mistral
      final mistralResponse = await _mistralService!.analyzeQuery(
        query: query,
        categories: categoryNames,
      );
      _analysisResult = AiAnalysisResult.fromJson(mistralResponse);

      // 5. Récupérer les agents disponibles
      final agentsData = await _missionRepository.fetchNearbyAgents(
        limit: 50, // Plus d'agents pour meilleur scoring
      );

      // 6. Convertir en AgentModel et scorer
      final agents = agentsData.map((data) {
        return AgentModel(
          id: data['id']?.toString() ?? '',
          name: data['name'] ?? data['username'] ?? 'Agent',
          avatarUrl: data['avatar_url'] ?? '',
          rating: (data['rating'] ?? 4.0).toDouble(),
          specialty: data['specialty'] ??
              data['specialties']?.toString() ??
              'Service général',
          completedMissions: data['completed_missions'] ?? 0,
          estimatedPrice: data['estimated_price']?.toString() ?? '0 FCFA',
          isTopChoice: data['is_top_choice'] ?? false,
        );
      }).toList();

      // 7. Filtrer et scorer les agents
      _suggestedAgents = _scoreAndFilterAgents(agents, _analysisResult!);

      // 8. Mettre en cache (10 minutes TTL)
      await _cacheResult(cacheKey, {
        'analysis': _analysisResult,
        'agents': _suggestedAgents,
      });
    } catch (e) {
      _error = "Erreur lors de la recherche: $e";
      Logger().e("Erreur AiSearchProvider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _suggestedAgents = [];
    _analysisResult = null;
    _error = null;
    notifyListeners();
  }

  /// Algorithme de scoring des agents (0-100)
  List<AgentModel> _scoreAndFilterAgents(
    List<AgentModel> agents,
    AiAnalysisResult analysis,
  ) {
    final scoredAgents = agents.map((agent) {
      double score = 0;

      // 1. Correspondance des compétences/spécialités (Poids: 40)
      final specialtyMatch =
          _calculateSpecialtyMatch(agent.specialty, analysis);
      score += specialtyMatch * 40;

      // 2. Fiabilité / Note (Poids: 30)
      final ratingScore = (agent.rating / 5.0) * 30;
      score += ratingScore;

      // 3. Volume d'activité (Poids: 20)
      final activityScore = _calculateActivityScore(agent.completedMissions);
      score += activityScore * 20;

      // 4. Bonus Top Choice (Poids: 10)
      if (agent.isTopChoice) {
        score += 10;
      }

      // 5. Filtrage par localisation textuelle
      if (analysis.location != null && analysis.location!.isNotEmpty) {
        final locationMatch = _calculateLocationMatch(
          agent,
          analysis.location!,
        );
        if (locationMatch == 0) {
          score *= 0.5; // Pénalité si localisation ne correspond pas
        } else {
          score += locationMatch * 10; // Bonus si correspondance
        }
      }

      return MapEntry(agent, score);
    }).toList();

    // Trier par score décroissant
    scoredAgents.sort((a, b) => b.value.compareTo(a.value));

    // Retourner les agents triés (top 10)
    return scoredAgents.take(10).map((e) => e.key).toList();
  }

  /// Calcule la correspondance des spécialités (0-1)
  double _calculateSpecialtyMatch(
      String agentSpecialty, AiAnalysisResult analysis) {
    final specialtyLower = agentSpecialty.toLowerCase();
    final intentLower = analysis.intent.toLowerCase();

    // Correspondance exacte
    if (specialtyLower.contains(intentLower) ||
        intentLower.contains(specialtyLower)) {
      return 1.0;
    }

    // Correspondance par mots-clés
    int keywordMatches = 0;
    for (final keyword in analysis.keywords) {
      if (specialtyLower.contains(keyword.toLowerCase())) {
        keywordMatches++;
      }
    }

    return keywordMatches / analysis.keywords.length.clamp(1, 5);
  }

  /// Calcule le score d'activité basé sur le nombre de missions (0-1)
  double _calculateActivityScore(int completedMissions) {
    if (completedMissions == 0) return 0.2; // Minimum pour nouveaux agents
    if (completedMissions < 10) return 0.4;
    if (completedMissions < 50) return 0.7;
    if (completedMissions < 100) return 0.9;
    return 1.0;
  }

  /// Calcule la correspondance de localisation textuelle (0-1)
  double _calculateLocationMatch(AgentModel agent, String userLocation) {
    final userLower = userLocation.toLowerCase();

    // Vérifier correspondance avec district (priorité haute)
    if (agent.district != null && agent.district!.isNotEmpty) {
      final districtLower = agent.district!.toLowerCase();
      if (districtLower.contains(userLower) ||
          userLower.contains(districtLower)) {
        return 1.0;
      }
    }

    // Vérifier correspondance avec city (priorité moyenne)
    if (agent.city != null && agent.city!.isNotEmpty) {
      final cityLower = agent.city!.toLowerCase();
      if (cityLower.contains(userLower) || userLower.contains(cityLower)) {
        return 0.8;
      }
    }

    // Vérifier correspondance avec address (priorité basse)
    if (agent.address != null && agent.address!.isNotEmpty) {
      final addressLower = agent.address!.toLowerCase();
      if (addressLower.contains(userLower) ||
          userLower.contains(addressLower)) {
        return 0.6;
      }
    }

    // Fallback: vérifier specialty (ancien comportement)
    final specialtyLower = agent.specialty.toLowerCase();
    if (specialtyLower.contains(userLower) ||
        userLower.contains(specialtyLower)) {
      return 0.4;
    }

    return 0.0;
  }

  /// Récupère un résultat depuis le cache (TTL 10 minutes)
  Future<Map<String, dynamic>?> _getCachedResult(String key) async {
    try {
      if (!_cacheService.isInitialized) {
        await _cacheService.init();
      }

      final cachedString = _cacheService.getCachedJsonResponse(key);
      if (cachedString == null) return null;

      final cached = jsonDecode(cachedString) as Map<String, dynamic>;

      final timestamp = cached['timestamp'] as int?;
      if (timestamp == null) return null;

      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age > 10 * 60 * 1000) {
        // 10 minutes en ms
        return null; // Cache expiré
      }

      // Parser l'analysis
      final analysisJson = cached['analysis'] as Map<String, dynamic>?;
      if (analysisJson == null) return null;

      final agentsJson = cached['agents'] as List<dynamic>?;
      if (agentsJson == null) return null;

      return {
        'analysis': AiAnalysisResult.fromJson(analysisJson),
        'agents': agentsJson
            .map((j) => AgentModel.fromJson(j as Map<String, dynamic>))
            .toList(),
      };
    } catch (e) {
      Logger().e('Erreur cache: $e');
      return null;
    }
  }

  /// Met en cache un résultat avec timestamp
  Future<void> _cacheResult(String key, Map<String, dynamic> data) async {
    try {
      if (!_cacheService.isInitialized) {
        await _cacheService.init();
      }

      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'analysis': (data['analysis'] as AiAnalysisResult).toJson(),
        'agents': (data['agents'] as List<AgentModel>)
            .map((a) => a.toJson())
            .toList(),
      };

      await _cacheService.cacheJsonResponse(key, jsonEncode(cacheData));
    } catch (e) {
      Logger().e('Erreur cache: $e');
    }
  }
}
