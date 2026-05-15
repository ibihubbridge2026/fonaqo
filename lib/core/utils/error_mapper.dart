import 'package:dio/dio.dart';

/// Mappe les erreurs techniques en messages simples pour les utilisateurs
class ErrorMapper {
  static String mapToUserFriendly(dynamic error) {
    // Parsing des erreurs JSON complexes du backend
    if (error is Map<String, dynamic>) {
      return _parseJsonError(error);
    }

    if (error is List) {
      return _parseListError(error);
    }

    // Codes HTTP
    if (error is DioException) {
      // Vérifier si la réponse contient des erreurs JSON
      if (error.response?.data is Map<String, dynamic>) {
        final jsonError =
            _parseJsonError(error.response!.data as Map<String, dynamic>);
        if (jsonError.isNotEmpty) return jsonError;
      }

      switch (error.response?.statusCode) {
        case 400:
          return "Infos non valides.";
        case 401:
          return "Session expirée. Reconnectez-vous.";
        case 403:
          return "Action non autorisée.";
        case 404:
          return "Ressource introuvable.";
        case 500:
          return "Service indisponible. Réessayez.";
        case 503:
          return "Service en maintenance.";
        default:
          return "Erreur réseau. Réessayez.";
      }
    }

    // Exceptions réseau
    if (error.toString().contains('SocketException')) {
      return "Problème de connexion.";
    }

    if (error.toString().contains('TimeoutException')) {
      return "Réponse trop lente.";
    }

    // Erreurs spécifiques FONACO
    final errorString = error.toString().toLowerCase();

    // Doublons
    if (errorString.contains('duplicate key') ||
        errorString.contains('already exists') ||
        errorString.contains('unique constraint')) {
      return "Numéro ou email déjà utilisé.";
    }

    // Login
    if (errorString.contains('invalid credentials') ||
        errorString.contains('authentication failed') ||
        errorString.contains('wrong password')) {
      return "Identifiants incorrects.";
    }

    // Permissions
    if (errorString.contains('permission denied') ||
        errorString.contains('access denied') ||
        errorString.contains('forbidden')) {
      return "Permission refusée.";
    }

    // Validation
    if (errorString.contains('validation') ||
        errorString.contains('required') ||
        errorString.contains('empty')) {
      return "Champs manquants.";
    }

    // Token
    if (errorString.contains('token') ||
        errorString.contains('unauthorized') ||
        errorString.contains('expired')) {
      return "Session expirée.";
    }

    // Serveur
    if (errorString.contains('500') ||
        errorString.contains('server error') ||
        errorString.contains('internal')) {
      return "Problème serveur.";
    }

    // Fallback simple
    return "Erreur inconnue. Réessayez.";
  }

  /// Parse les erreurs JSON complexes du backend
  static String _parseJsonError(Map<String, dynamic> json) {
    // Cas 1: {"phone_number": ["Le numéro doit comporter 8 chiffres"]}
    for (final entry in json.entries) {
      final value = entry.value;
      if (value is List && value.isNotEmpty) {
        final firstMessage = value.first.toString();
        if (firstMessage.isNotEmpty) {
          return firstMessage;
        }
      }
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    // Cas 2: {"error": "Message d'erreur"}
    if (json.containsKey('error')) {
      final error = json['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    }

    // Cas 3: {"message": "Message d'erreur"}
    if (json.containsKey('message')) {
      final message = json['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    // Cas 4: {"detail": "Message d'erreur"}
    if (json.containsKey('detail')) {
      final detail = json['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    }

    // Cas 5: Prendre la première valeur disponible
    for (final value in json.values) {
      if (value is String && value.isNotEmpty) {
        return value;
      }
      if (value is List && value.isNotEmpty) {
        final firstItem = value.first;
        if (firstItem is String && firstItem.isNotEmpty) {
          return firstItem;
        }
      }
    }

    return '';
  }

  /// Parse les erreurs de type List
  static String _parseListError(List list) {
    if (list.isNotEmpty) {
      final firstItem = list.first;
      if (firstItem is String && firstItem.isNotEmpty) {
        return firstItem;
      }
      if (firstItem is Map<String, dynamic>) {
        return _parseJsonError(firstItem);
      }
    }
    return '';
  }
}
