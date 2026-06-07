import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

/// Service pour l'intégration avec l'API Mistral AI
/// Responsabilités: Appel HTTP, gestion timeout, retry, parsing réponse
class MistralAiService {
  final Dio _dio;
  final Logger _logger = Logger();

  // Configuration
  static const String _baseUrl = 'https://api.mistral.ai/v1';
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 2;

  MistralAiService({required String apiKey})
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: _timeout,
          receiveTimeout: _timeout,
          sendTimeout: _timeout,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ));

  /// Analyse une requête en langage naturel et extrait les informations structurées
  ///
  /// [query] - La requête de l'utilisateur en langage naturel
  /// [categories] - Liste des catégories de services disponibles pour validation
  ///
  /// Retourne un Map<String, dynamic> avec les données extraites par l'IA
  Future<Map<String, dynamic>> analyzeQuery({
    required String query,
    required List<String> categories,
  }) async {
    int retryCount = 0;

    while (retryCount <= _maxRetries) {
      try {
        _logger.i(
            '🤖 Appel Mistral AI (tentative ${retryCount + 1}/${_maxRetries + 1})');

        final response = await _dio.post(
          '/chat/completions',
          data: _buildRequestBody(query, categories),
        );

        if (response.statusCode == 200) {
          final result = _parseResponse(response.data);
          _logger.i('✅ Réponse Mistral reçue avec succès');
          return result;
        } else {
          throw Exception(
              'HTTP ${response.statusCode}: ${response.statusMessage}');
        }
      } on DioException catch (e) {
        retryCount++;

        if (retryCount > _maxRetries) {
          _logger.e('❌ Échec après $_maxRetries tentatives: $e');
          throw _handleDioError(e);
        }

        _logger.w('⚠️ Erreur Dio, retry $retryCount/$_maxRetries: $e');
        await Future.delayed(
            Duration(seconds: retryCount)); // Backoff exponentiel
      } catch (e) {
        _logger.e('❌ Erreur inattendue: $e');
        rethrow;
      }
    }

    throw Exception('Nombre maximum de tentatives dépassé');
  }

  /// Construit le corps de la requête pour l'API Mistral
  Map<String, dynamic> _buildRequestBody(
      String query, List<String> categories) {
    final categoriesList = categories.map((c) => '"$c"').join(', ');

    return {
      'model': 'mistral-small-latest', // Modèle léger et rapide
      'messages': [
        {
          'role': 'system',
          'content': _buildSystemPrompt(categories),
        },
        {
          'role': 'user',
          'content': query,
        },
      ],
      'temperature': 0.3, // Faible température pour plus de précision
      'max_tokens': 500,
      'response_format': {'type': 'json_object'}, // Force la réponse JSON
    };
  }

  /// Construit le prompt système pour Mistral
  String _buildSystemPrompt(List<String> categories) {
    return '''
Tu es un assistant IA pour Fonaqo, une plateforme de services à la demande en Afrique de l'Ouest.

Ta tâche est d'analyser la requête d'un utilisateur et d'extraire les informations structurées suivantes au format JSON strict:

{
  "intent": "catégorie exacte parmi: [$categories]",
  "location": "ville ou quartier mentionné (ex: Cocody, Marcory, Plateau)",
  "time": "moment mentionné (ex: demain matin, ce soir, cette semaine)",
  "urgency": "true si urgent, false sinon",
  "description": "résumé court du besoin en français",
  "keywords": ["mot1", "mot2", "mot3"]
}

RÈGLES IMPORTANTES:
1. Le champ "intent" DOIT correspondre EXACTEMENT à l'une des catégories fournies: [$categories]
2. Si aucune catégorie ne correspond, utilise "service_général"
3. Retourne UNIQUEMENT le JSON, sans texte supplémentaire
4. Les champs "location" et "time" peuvent être null si non mentionnés
5. "urgency" doit être un booléen (true/false)
6. "keywords" est une liste de 3-5 mots-clés pertinents

Exemple de requête: "J'ai besoin de quelqu'un pour faire la queue à la banque demain matin à Cocody"
Réponse attendue: {
  "intent": "banque",
  "location": "Cocody",
  "time": "demain matin",
  "urgency": false,
  "description": "Besoin d'agent pour faire la queue à la banque",
  "keywords": ["banque", "queue", "Cocody"]
}
''';
  }

  /// Parse la réponse de l'API Mistral
  Map<String, dynamic> _parseResponse(dynamic responseData) {
    try {
      final choices = responseData['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw Exception('Réponse sans choices');
      }

      final firstChoice = choices[0] as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>?;
      if (message == null) {
        throw Exception('Réponse sans message');
      }

      final content = message['content'] as String?;
      if (content == null || content.isEmpty) {
        throw Exception('Réponse sans content');
      }

      // Parser le JSON contenu dans la réponse
      final parsedJson = jsonDecode(content) as Map<String, dynamic>;

      // Validation basique des champs requis
      if (!parsedJson.containsKey('intent')) {
        throw Exception('Réponse JSON sans champ "intent"');
      }

      return parsedJson;
    } catch (e) {
      _logger.e('Erreur parsing réponse Mistral: $e');
      throw Exception('Échec du parsing de la réponse IA: $e');
    }
  }

  /// Gère les erreurs Dio de manière appropriée
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Délai d\'attente dépassé. Vérifiez votre connexion.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return Exception(
              'Clé API Mistral invalide. Vérifiez votre configuration.');
        } else if (statusCode == 429) {
          return Exception('Quota API Mistral dépassé. Réessayez plus tard.');
        } else if (statusCode == 400) {
          return Exception('Requête invalide envoyée à l\'API Mistral.');
        } else {
          return Exception('Erreur API Mistral: HTTP $statusCode');
        }

      case DioExceptionType.cancel:
        return Exception('Requête annulée');

      case DioExceptionType.connectionError:
        return Exception('Erreur de connexion. Vérifiez votre réseau.');

      case DioExceptionType.unknown:
        return Exception('Erreur inconnue: ${error.message}');

      default:
        return Exception('Erreur inattendue: ${error.type}');
    }
  }

  /// Dispose des ressources
  void dispose() {
    _dio.close();
  }
}
