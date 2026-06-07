import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fonaco/core/services/feedback_service.dart';
import 'package:fonaco/core/services/memory_auth_cache.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

import '../api/base_client.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

/// Provider pour gérer l'état d'authentification
class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final MemoryAuthCache _memoryCache = MemoryAuthCache();

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
  String? get accessToken => _memoryCache.accessToken;
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
    _memoryCache.clear();
    _setError('Votre session a expiré. Veuillez vous reconnecter.');
  }

  /// Nettoie les données utilisateur et notifie les listeners
  void _clearUserDataAndNotify() {
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Vérifie si un token JWT est expiré
  bool _isTokenExpired(String token) {
    try {
      // JWT structure: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      final decoded =
          utf8.decode(base64Url.decode(base64Url.normalize(payload)));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;

      final exp = payloadMap['exp'] as int?;
      if (exp == null) return false;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final isExpired = DateTime.now().isAfter(expiryDate);

      if (isExpired) {
        _logger.w(
            '⚠️ Token JWT expiré (exp: $expiryDate, now: ${DateTime.now()})');
      }

      return isExpired;
    } catch (e) {
      _logger.e('Erreur vérification expiration token: $e');
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
          // Erreur 400 : extraire les erreurs par champ depuis response.data
          errorMessage = _extractApiErrors(response.data);
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
        errorMessage = _extractApiErrors(e.response?.data ?? {});
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
        final errorMessage = _extractApiErrors(response.data);
        _setError(errorMessage);
        return false;
      }

      final data = response.data['data'];
      await _saveAuthData(data);
      return true;
    } on DioException catch (e) {
      _logger.e(
          'Erreur REGISTER: ${e.response?.statusCode} - ${e.response?.data}');

      String errorMessage = 'Erreur d\'inscription';
      if (e.response?.statusCode == 400) {
        errorMessage = _extractApiErrors(e.response?.data ?? {});
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Serveur indisponible. Vérifiez votre connexion internet.';
      } else if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Délai d\'attente dépassé. Réessayez dans un instant.';
      }

      _setError(errorMessage);
      return false;
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
    var accessToken = data['access_token'];
    final refreshTokenValue = data['refresh_token'];
    final userData = data['user'];

    _logger.i('💾 Sauvegarde des données d\'authentification...');

    await _secureStorage.deleteAll();
    _logger.d('🗑️ Stockage nettoyé');

    // Nettoyer le token pour éviter les caractères parasites (#, espaces, etc.)
    if (accessToken is String) {
      accessToken =
          accessToken.trim().replaceAll('#', '').replaceAll(RegExp(r'\s'), '');
    }

    // Sauvegarder dans MemoryAuthCache ET SecureStorage
    await _memoryCache.saveTokens(accessToken, refreshTokenValue);
    await _memoryCache.saveUserData(jsonEncode(userData));

    _logger.d('🔑 Access token sauvegardé: $_tokenKey');
    _logger.d('🔄 Refresh token sauvegardé: $_refreshTokenKey');
    _logger.d('👤 Données utilisateur sauvegardées: $_userKey');

    _currentUser = UserModel.fromJson(userData);
    _isAuthenticated = true;

    await NotificationService().sendTokenToBackend(accessToken);
    notifyListeners();
  }

  Future<bool> refreshToken() async {
    try {
      final storedRefreshToken = _memoryCache.refreshToken;

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
          // Mettre à jour MemoryAuthCache ET SecureStorage
          await _memoryCache.updateAccessToken(newAccessToken);
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
    await _memoryCache.clear();
    await _secureStorage.deleteAll();
    _clearUserDataAndNotify();
    _setLoading(false);
  }

  Future<void> _loadUserData() async {
    try {
      // Charger depuis MemoryAuthCache d'abord
      await _memoryCache.loadFromStorage();

      final token = _memoryCache.accessToken;
      final userDataString = _memoryCache.userData;

      _logger.i('🔍 Vérification de l\'authentification au démarrage...');

      if (token != null && userDataString != null) {
        // VÉRIFIER L'EXPIRATION DU TOKEN
        if (_isTokenExpired(token)) {
          _logger.w('⚠️ Token expiré détecté au démarrage');

          // Tenter de rafraîchir le token
          final refreshed = await refreshToken();

          if (refreshed) {
            _logger.i('✅ Token rafraîchi avec succès');
            // Recharger depuis le cache après refresh
            await _memoryCache.loadFromStorage();
            final newToken = _memoryCache.accessToken;

            if (newToken != null && !_isTokenExpired(newToken)) {
              try {
                _currentUser = UserModel.fromJson(jsonDecode(userDataString));
                _isAuthenticated = true;
                _logger.i(
                    '✅ Utilisateur authentifié après refresh: ${_currentUser?.email}');
                notifyListeners();
                return;
              } catch (e) {
                _logger.e('❌ Erreur parsing utilisateur: $e');
              }
            }
          }

          // Si refresh échoue ou token toujours expiré, logout complet
          _logger
              .w('🚨 Refresh échoué ou token toujours expiré - logout complet');
          await _memoryCache.clear();
          await _secureStorage.deleteAll();
          _currentUser = null;
          _isAuthenticated = false;
          notifyListeners();
          return;
        }

        // Token valide, charger l'utilisateur
        try {
          _currentUser = UserModel.fromJson(jsonDecode(userDataString));
          _isAuthenticated = true;
          _logger.i('✅ Utilisateur chargé: ${_currentUser?.email}');
          _logger.i('📍 Session valide (token non expiré)');
        } catch (e) {
          _logger.e('❌ Erreur parsing utilisateur: $e');
          await _memoryCache.clear();
          _currentUser = null;
          _isAuthenticated = false;
        }
      } else {
        _logger.w('⚠️ Aucun token ou user data trouvé');
        _isAuthenticated = false;
        _currentUser = null;
      }

      notifyListeners();
    } catch (e) {
      _logger.e('❌ Erreur critique chargement utilisateur: $e');
      await _memoryCache.clear();
      await _secureStorage.deleteAll();
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<String?> getToken() async => _memoryCache.accessToken;

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

  /// Vérifie si l'utilisateur est authentifié (vérifie l'expiration du token)
  Future<void> checkAuth() async {
    await _loadUserData();
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
        'accounts/password/change/',
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
    }
    return 'Erreur inconnue';
  }

  /// Extrait et formate les erreurs de validation depuis la réponse API
  String _extractApiErrors(dynamic responseData) {
    if (responseData is! Map) return 'Erreur de validation';

    // Structure standardisée: { "status": "error", "message": "...", "data": { "field": ["error"] } }
    final data = responseData['data'];
    final message = responseData['message'] as String?;

    if (data is Map && data.isNotEmpty) {
      final errors = <String>[];

      // Extraire les erreurs par champ
      data.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          final fieldErrors = value.whereType<String>().join(', ');
          errors.add('$key: $fieldErrors');
        } else if (value is String) {
          errors.add('$key: $value');
        }
      });

      if (errors.isNotEmpty) {
        return errors.join('\n');
      }
    }

    // Fallback sur le message général
    return message ?? 'Erreur de validation';
  }
}
