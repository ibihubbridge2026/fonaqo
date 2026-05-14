import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/providers/auth_provider.dart';

/// Provider pour gérer l'état de l'interface Agent
class AgentProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  
  bool _isAgentMode = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  bool get isAgentMode => _isAgentMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Bascule vers le mode agent si l'utilisateur a les droits nécessaires
  /// Retourne true si le basculement a réussi, false sinon
  Future<bool> toggleAgentMode(AuthProvider authProvider) async {
    if (_isLoading) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      // Vérifier si l'utilisateur est authentifié
      if (!authProvider.isAuthenticated) {
        _setError('Vous devez être connecté pour accéder au mode agent');
        return false;
      }
      
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        _setError('Utilisateur non trouvé');
        return false;
      }
      
      // Vérifier si l'utilisateur a le droit d'être agent
      if (!currentUser.isAgent && !currentUser.isClient) {
        _setError('Votre compte n\'est pas configuré pour être agent');
        return false;
      }
      
      // Si l'utilisateur est déjà agent, basculer le mode
      if (currentUser.isAgent) {
        _isAgentMode = !_isAgentMode;
        _logger.d('Mode agent basculé: $_isAgentMode pour utilisateur ${currentUser.id}');
        return true;
      }
      
      // Si l'utilisateur est client mais veut devenir agent
      if (currentUser.isClient) {
        _setError('Votre compte est de type Client. Pour devenir Agent, veuillez contacter le support.');
        return false;
      }
      
      return false;
    } catch (e, st) {
      _logger.e('Erreur lors du basculement mode agent', error: e, stackTrace: st);
      _setError('Une erreur est survenue: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Vérifie si l'utilisateur peut accéder au mode agent
  bool canAccessAgentMode(AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) return false;
    
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return false;
    
    return currentUser.isAgent;
  }
  
  /// Force l'activation du mode agent (pour les tests ou admin)
  void forceAgentMode(bool enabled) {
    _isAgentMode = enabled;
    _logger.d('Mode agent forcé: $enabled');
    notifyListeners();
  }
  
  /// Réinitialise le provider
  void reset() {
    _isAgentMode = false;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
  
  // Méthodes privées pour la gestion d'état
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
