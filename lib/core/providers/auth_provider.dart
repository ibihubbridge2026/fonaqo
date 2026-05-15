import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fonaco/core/services/feedback_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

import '../api/base_client.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

/// Provider pour gérer l'état d'authentification
class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';
  static const String _userKey = 'user_data';

  final Logger _logger = Logger();
  final BaseClient _baseClient = BaseClient();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  // =========================
  // GETTERS
  // =========================

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isAgent => _currentUser?.isAgent ?? false;
  bool get isClient => _currentUser?.isClient ?? false;
  bool get isVerified => _currentUser?.isVerified ?? false;

  // =========================
  // CONSTRUCTOR
  // =========================

  AuthProvider() {
    _loadUserData();
    _baseClient.setOnTokenExpiredCallback(handleTokenExpired);
  }

  // =========================
  // PRIVATE HELPERS
  // =========================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void showErrorSnackBar(BuildContext context, String message) {
    FeedbackService.showError(context, message);
  }

  void showSuccessSnackBar(BuildContext context, String message) {
    FeedbackService.showSuccess(context, message);
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void handleTokenExpired() {
    _logger.w('Déconnexion automatique : token expiré');
    _clearUserDataAndNotify();
    _setError('Votre session a expiré. Veuillez vous reconnecter.');
  }

  /// Nettoie les données utilisateur et notifie les listeners
  void _clearUserDataAndNotify() {
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Vérifie si un token JWT est expiré en parsant le payload
  bool _isTokenExpired(String token) {
    try {
      // Format JWT: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) return true; // Format invalide = expiré

      final payload = parts[1];
      // Padding pour base64 si nécessaire
      final paddedPayload =
          payload.padRight((payload.length + 3) ~/ 4 * 4, '=');

      final decoded = String.fromCharCodes(base64
          .decode(paddedPayload.replaceAll('-', '+').replaceAll('_', '/')));

      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = payloadMap['exp'] as int?;

      if (exp == null)
        return true; // Pas de date d'expiration = expiré par sécurité

      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();

      // Ajouter une marge de 30 secondes pour éviter les courses aux conditions
      final isExpired =
          now.isAfter(expirationTime.subtract(const Duration(seconds: 30)));

      if (isExpired) {
        _logger.d('Token expiré: expiration=$expirationTime, now=$now');
      }

      return isExpired;
    } catch (e) {
      _logger.e('Erreur parsing token JWT: $e');
      return true; // En cas d'erreur, considérer comme expiré
    }
  }

  // =========================
  // AUTH METHODS (LOGIN, REGISTER, GOOGLE)
  // =========================

  Future<bool> login(Map<String, dynamic> credentials) async {
    _clearError();
    _setLoading(true);

    try {
      // Nettoyer les champs de connexion pour éviter les espaces invisibles
      final cleanedCredentials = Map<String, dynamic>.from(credentials);
      if (cleanedCredentials.containsKey('email')) {
        cleanedCredentials['email'] =
            cleanedCredentials['email']?.toString().trim();
      }
      if (cleanedCredentials.containsKey('phone_number')) {
        cleanedCredentials['phone_number'] =
            cleanedCredentials['phone_number']?.toString().trim();
      }
      if (cleanedCredentials.containsKey('password')) {
        cleanedCredentials['password'] =
            cleanedCredentials['password']?.toString().trim();
      }

      final response =
          await _baseClient.post('accounts/login/', data: cleanedCredentials);

      if (response.statusCode != 200) {
        // Gestion spécifique des erreurs 400 (identifiants incorrects)
        String errorMessage = 'Erreur de connexion';
        if (response.statusCode == 400) {
          // Erreur 400 : afficher le message exact du backend
          errorMessage = response.data['message'] ??
              response.data['error'] ??
              response.data['detail'] ??
              'Identifiants incorrects';
          _logger.e('🔴 Erreur 400 login: $errorMessage');
        } else if (response.statusCode == 401) {
          errorMessage = 'Identifiants incorrects';
          _logger.e('🔴 Erreur 401 login: $errorMessage');
        } else {
          errorMessage = response.data['message'] ??
              response.data['error'] ??
              'Erreur de connexion (code: ${response.statusCode})';
          _logger.e('🔴 Erreur login ${response.statusCode}: $errorMessage');
        }

        _setError(errorMessage);
        return false;
      }

      final data = response.data['data'];
      await _saveAuthData(data);
      return true;
    } on DioException catch (e) {
      _logger.e(
          '🔴 Erreur Dio LOGIN: ${e.response?.statusCode} - ${e.response?.data}');

      // Gestion spécifique des erreurs Dio
      String errorMessage = 'Erreur de connexion';
      if (e.response?.statusCode == 400) {
        errorMessage = e.response?.data['message'] ??
            e.response?.data['error'] ??
            e.response?.data['detail'] ??
            'Identifiants incorrects';
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'Identifiants incorrects';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Serveur indisponible. Vérifiez votre connexion internet.';
      } else if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Délai d\'attente dépassé. Réessayez dans un instant.';
      } else {
        errorMessage = 'Erreur réseau: ${e.message}';
      }

      _setError(errorMessage);
      return false;
    } catch (e) {
      _logger.e('🔴 Erreur inattendue LOGIN: $e');
      _setError('Erreur inattendue: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _clearError();
    _setLoading(true);

    try {
      final response =
          await _baseClient.post('accounts/register/', data: userData);

      if (response.statusCode != 201 && response.statusCode != 200) {
        _setError(response.data['message'] ?? 'Erreur d\'inscription');
        return false;
      }

      final data = response.data['data'];
      await _saveAuthData(data);
      return true;
    } catch (e) {
      _logger.e('Erreur REGISTER: $e');
      _setError('Erreur d\'inscription: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _clearError();
    _setLoading(true);

    try {
      final GoogleSignIn googleSignIn =
          GoogleSignIn(scopes: ['email', 'profile']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final response = await _baseClient.post(
        'accounts/google-auth/',
        data: {
          'email': googleUser.email,
          'name': googleUser.displayName ?? '',
          'google_id': googleUser.id,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        await _saveAuthData(data);

        // Charger immédiatement les données utilisateur pour mettre à jour l'UI
        await _loadUserData();

        return true;
      }
      return false;
    } catch (e) {
      _logger.e('Erreur Google Auth: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePhoneNumber(String phoneNumber) async {
    _clearError();
    _setLoading(true);

    try {
      final response = await _baseClient.patch(
        'accounts/update-phone/',
        data: {
          'phone_number': phoneNumber,
        },
      );

      if (response.statusCode == 200) {
        final userData = response.data['data']['user'];

        // Mettre à jour les données utilisateur localement
        await _secureStorage.write(key: _userKey, value: jsonEncode(userData));

        // Recharger les données utilisateur pour mettre à jour l'état
        await _loadUserData();

        _logger.i('📱 Numéro de téléphone mis à jour avec succès');
        return true;
      } else {
        _setError('Erreur lors de la mise à jour du numéro de téléphone');
        return false;
      }
    } catch (e) {
      _logger.e('Erreur updatePhoneNumber: $e');
      _setError('Une erreur est survenue: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // TOKEN MANAGEMENT
  // =========================

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final accessToken = data['access_token'];
    final refreshTokenValue = data['refresh_token'];
    final userData = data['user'];

    _logger.i('💾 Sauvegarde des données d\'authentification...');

    await _secureStorage.deleteAll();
    _logger.d('🗑️ Stockage nettoyé');

    await _secureStorage.write(key: _tokenKey, value: accessToken);
    _logger.d('🔑 Access token sauvegardé: ${_tokenKey}');

    if (refreshTokenValue != null) {
      await _secureStorage.write(
          key: _refreshTokenKey, value: refreshTokenValue);
      _logger.d('🔄 Refresh token sauvegardé: ${_refreshTokenKey}');
    }

    await _secureStorage.write(key: _userKey, value: jsonEncode(userData));
    _logger.d('👤 Données utilisateur sauvegardées: ${_userKey}');

    // Vérification que tout est bien sauvegardé
    final savedToken = await _secureStorage.read(key: _tokenKey);
    final savedUser = await _secureStorage.read(key: _userKey);

    if (savedToken != null && savedUser != null) {
      _logger.i('✅ Données d\'authentification sauvegardées avec succès');
      _currentUser = UserModel.fromJson(userData);
      _isAuthenticated = true;
    } else {
      _logger.e('❌ Erreur lors de la sauvegarde des données');
      throw Exception('Échec de la sauvegarde des données d\'authentification');
    }

    await NotificationService().sendTokenToBackend(accessToken);
    notifyListeners();
  }

  Future<bool> refreshToken() async {
    try {
      final storedRefreshToken =
          await _secureStorage.read(key: _refreshTokenKey);

      if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
        _logger.w('Refresh token manquant');
        return false;
      }

      final response = await _baseClient.post(
        'accounts/token/refresh/',
        data: {'refresh': storedRefreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'];
        if (newAccessToken != null) {
          await _secureStorage.write(key: _tokenKey, value: newAccessToken);
          _logger.i('✅ Access token rafraîchi avec succès');
          return true;
        }
      }
      return false;
    } catch (e) {
      _logger.e('Erreur rafraîchissement token: $e');
      return false;
    }
  }

  // =========================
  // LOGOUT & UTILS
  // =========================

  Future<void> logout() async {
    _setLoading(true);
    await _secureStorage.deleteAll();
    _clearUserDataAndNotify();
    _setLoading(false);
  }

  Future<void> _loadUserData() async {
    try {
      // LOGS DÉTAILLÉS DU SECURE STORAGE AU DÉMARRAGE
      _logger.i('🔍 Vérification du SecureStorage au démarrage...');

      final token = await _secureStorage.read(key: _tokenKey);
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      final userDataString = await _secureStorage.read(key: _userKey);

      _logger.i('📋 Contenu SecureStorage:');
      _logger.i(
          '  🎫 Token: ${token != null ? "Présent (${token.length} chars)" : "ABSENT"}');
      _logger.i(
          '  🔄 Refresh Token: ${refreshToken != null ? "Présent (${refreshToken.length} chars)" : "ABSENT"}');
      _logger.i(
          '  👤 User Data: ${userDataString != null ? "Présent (${userDataString.length} chars)" : "ABSENT"}');

      // Vérification basique de l'expiration du token (format JWT)
      if (token != null && _isTokenExpired(token)) {
        _logger.w(
            '🚨 Token JWT expiré détecté au démarrage, nettoyage automatique');
        await _secureStorage.deleteAll();
        _clearUserDataAndNotify();
        _setError('Votre session a expiré. Veuillez vous reconnecter.');
        return;
      }

      if (token != null && userDataString != null) {
        // Charger l'utilisateur depuis le cache SANS tenter de refresh
        try {
          _currentUser = UserModel.fromJson(jsonDecode(userDataString));
          _isAuthenticated = true;
          _logger.i(
              '✅ Utilisateur chargé depuis le cache: ${_currentUser?.email}');
          _logger.i('📍 Session restaurée (refresh automatique désactivé)');
          _logger
              .i('🛡️ handleTokenExpired ne sera JAMAIS appelé au démarrage');
          _logger.i(
              '📍 Seule une vraie erreur 401 API déclenchera la déconnexion');
        } catch (e) {
          _logger.e('❌ Erreur parsing utilisateur depuis cache: $e');
          await _secureStorage.deleteAll();
          _currentUser = null;
          _isAuthenticated = false;
          notifyListeners();
          return;
        }

        // REFRESH AUTOMATIQUE DÉSACTIVÉ - Laisser l'intercepteur gérer les 401 réelles
        _logger.i(
            '📍 Refresh automatique désactivé - l\'intercepteur gérera les 401 si nécessaire');
      } else {
        _logger.w('⚠️ Session incomplète - certains tokens manquent');
        _logger.w('📍 Aucune action de déconnexion automatique au démarrage');
      }
      notifyListeners();
    } catch (e) {
      _logger.e('❌ Erreur critique chargement utilisateur: $e');
      // Seulement en cas d'erreur critique, on nettoie tout
      await _secureStorage.deleteAll();
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<String?> getToken() async => await _secureStorage.read(key: _tokenKey);

  // =========================
  // PROFILE & SETTINGS
  // =========================

  Future<bool> updateProfile(dynamic profileData) async {
    _clearError();
    _setLoading(true);
    try {
      final response = await _baseClient.patch(
        'accounts/profile/',
        data: profileData,
        options: profileData is FormData
            ? Options(contentType: 'multipart/form-data')
            : null,
      );

      if (response.statusCode == 200) {
        final userData = response.data['data'];
        _currentUser = UserModel.fromJson(userData);
        await _secureStorage.write(key: _userKey, value: jsonEncode(userData));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Erreur lors de la mise à jour : $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Vérifie si l'utilisateur est authentifié
  Future<void> checkAuth() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      final userData = await _secureStorage.read(key: _userKey);

      if (token != null && userData != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userData));
        _isAuthenticated = true;
        notifyListeners();
      } else {
        _isAuthenticated = false;
        _currentUser = null;
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Erreur lors de la vérification de l\'authentification: $e');
      _isAuthenticated = false;
      _currentUser = null;
      notifyListeners();
    }
  }

  /// Mot de passe oublié
  Future<bool> forgotPassword(Map<String, String> data) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _baseClient.post(
        'accounts/forgot-password/',
        data: data,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        _setError('Erreur lors de l\'envoi de l\'email de réinitialisation');
        return false;
      }
    } catch (e) {
      _setError('Erreur: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Changer le mot de passe
  Future<bool> changePassword(Map<String, String> data) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _baseClient.post(
        'accounts/change-password/',
        data: data,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        _setError('Erreur lors du changement de mot de passe');
        return false;
      }
    } catch (e) {
      _setError('Erreur: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Formate les messages d'erreur
  String formatErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    } else if (error is String) {
      return error;
    } else {
      return 'Une erreur est survenue';
    }
  }
}
