import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fonaco/core/services/feedback_service.dart';
import 'package:fonaco/core/services/memory_auth_cache.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

import '../api/base_client.dart';
import '../api/token_refresh_result.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

export '../api/base_client.dart' show ApiException, ApiErrorType;

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
  bool _accountSuspended = false;
  String? _errorMessage;
  UserModel? _currentUser;

  // =========================
  // GETTERS
  // =========================

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get accountSuspended => _accountSuspended;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  String? get accessToken => _memoryCache.accessToken;
  bool get isAgent => _currentUser?.isAgent ?? false;
  bool get isClient => _currentUser?.isClient ?? false;
  bool get isVerified => _currentUser?.isVerified ?? false;
  bool get needsPhoneCompletion {
    final phone = _currentUser?.phoneNumber;
    return phone == null || phone.trim().isEmpty;
  }

  // =========================
  // CONSTRUCTOR
  // =========================

  AuthProvider() {
    _loadUserData();
    // Pas de déconnexion auto : session conservée jusqu'au logout explicite.
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

  /// Session invalidée (flush DB, refresh rejeté) — déconnexion complète.
  Future<void> handleTokenExpired() async {
    _logger.w('Session invalidée — déconnexion forcée');
    await logout();
  }

  /// Nettoie les données utilisateur et notifie les listeners
  void _clearUserDataAndNotify() {
    _currentUser = null;
    _isAuthenticated = false;
    _accountSuspended = false;
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
        String errorMessage = 'Erreur de connexion';
        if (response.statusCode == 403) {
          final data = response.data;
          final code = data is Map ? data['code']?.toString() : null;
          if (code == 'ACCOUNT_SUSPENDED') {
            errorMessage = (data is Map ? data['message'] : null)?.toString() ??
                'Votre compte a été suspendu. Contactez le support.';
            _setError(errorMessage);
            _accountSuspended = true;
            notifyListeners();
            return false;
          }
        }
        if (response.statusCode == 400) {
          // Erreur 400 : extraire les erreurs par champ depuis response.data
          errorMessage = _extractApiErrors(
            response.extra['api_envelope'] ?? response.data,
          );
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

      final data = response.data;
      if (data is! Map || data['access_token'] == null) {
        _setError('Réponse connexion invalide');
        return false;
      }
      await _saveAuthData(Map<String, dynamic>.from(data));
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } on DioException catch (e) {
      _setError(_messageFromDio(e));
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
      // Jamais de code promo saisi manuellement — parrainage = deep link uniquement.
      userData.remove('promo_code');

      final response =
          await _baseClient.post('accounts/register/', data: userData);

      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorMessage = _extractApiErrors(response.data);
        _setError(errorMessage);
        return false;
      }

      final raw = response.data;
      Map<String, dynamic>? authPayload;
      if (raw is Map && raw['access_token'] != null) {
        authPayload = Map<String, dynamic>.from(raw);
      }
      if (authPayload == null) {
        _setError('Réponse inscription invalide');
        return false;
      }
      await _saveAuthData(authPayload);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } on DioException catch (e) {
      _setError(_messageFromDio(e, fallback: 'Erreur d\'inscription'));
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
        final data = response.data;
        if (data is Map && data['access_token'] != null) {
          await _saveAuthData(Map<String, dynamic>.from(data));
          await _loadUserData();
          return true;
        }
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
        final data = response.data['data'];
        Map<String, dynamic>? userData;
        if (data is Map && data['user'] is Map) {
          userData = Map<String, dynamic>.from(data['user'] as Map);
        } else if (data is Map && data['phone_number'] != null) {
          final current = _currentUser?.toJson() ?? <String, dynamic>{};
          current['phone_number'] = data['phone_number'];
          userData = current;
        }

        if (userData != null) {
          await _memoryCache.saveUserData(jsonEncode(userData));
          await _secureStorage.write(
            key: _userKey,
            value: jsonEncode(userData),
          );
          _currentUser = UserModel.fromJson(userData);
          notifyListeners();
        }

        _logger.i('📱 Numéro de téléphone mis à jour avec succès');
        return true;
      } else {
        _setError(_extractApiErrors(response.data));
        return false;
      }
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
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

    await NotificationService().initialize();
    if (accessToken is String && accessToken.isNotEmpty) {
      await NotificationService().sendTokenToBackend(accessToken);
    }
    notifyListeners();
  }

  Future<bool> refreshToken() async {
    final result = await _refreshTokenWithResult();
    if (result == TokenRefreshResult.sessionRevoked) {
      await handleTokenExpired();
    }
    return result == TokenRefreshResult.success;
  }

  Future<TokenRefreshResult> _refreshTokenWithResult() async {
    try {
      await _memoryCache.ensureLoaded();
      final storedRefreshToken = _memoryCache.refreshToken;

      if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
        _logger.w('Refresh token manquant');
        return TokenRefreshResult.sessionRevoked;
      }

      final response = await _baseClient.post(
        'accounts/token/refresh/',
        data: {'refresh': storedRefreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'];
        if (newAccessToken != null) {
          await _memoryCache.updateAccessToken(newAccessToken);
          _logger.i('✅ Access token rafraîchi avec succès');
          return TokenRefreshResult.success;
        }
      }
      if (response.statusCode == 401) {
        return TokenRefreshResult.sessionRevoked;
      }
      return TokenRefreshResult.failed;
    } on DioException catch (e) {
      if (BaseClient.isNetworkErrorPublic(e)) {
        _logger.w('Refresh token — panne réseau, session conservée');
        return TokenRefreshResult.networkError;
      }
      if (e.response?.statusCode == 401) {
        return TokenRefreshResult.sessionRevoked;
      }
      _logger.e('Erreur rafraîchissement token: $e');
      return TokenRefreshResult.failed;
    } catch (e) {
      _logger.e('Erreur rafraîchissement token: $e');
      return TokenRefreshResult.failed;
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
        try {
          _currentUser = UserModel.fromJson(jsonDecode(userDataString));
          _isAuthenticated = true;
          _logger.i('✅ Session restaurée: ${_currentUser?.email}');
        } catch (e) {
          _logger.e('❌ Erreur parsing utilisateur: $e');
          _isAuthenticated = false;
          _currentUser = null;
        }

        if (_isTokenExpired(token)) {
          _logger.w('⚠️ Access token expiré — refresh silencieux');
          unawaited(refreshToken());
        }
      } else {
        _logger.w('⚠️ Aucun token ou user data trouvé');
        _isAuthenticated = false;
        _currentUser = null;
      }

      notifyListeners();
    } catch (e) {
      _logger.e('❌ Erreur chargement utilisateur: $e');
      _isAuthenticated = _memoryCache.accessToken != null;
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
        final userData = response.data;
        if (userData is Map) {
          final map = Map<String, dynamic>.from(userData);
          if (map.containsKey('data') && map['data'] is Map) {
            final inner = Map<String, dynamic>.from(map['data'] as Map);
            _currentUser = UserModel.fromJson(inner);
          } else {
            _currentUser = UserModel.fromJson(map);
          }
          final encoded = jsonEncode(_currentUser != null
              ? {
                  'id': _currentUser!.id,
                  'email': _currentUser!.email,
                  'username': _currentUser!.djangoUsername,
                  'first_name': _currentUser!.firstName,
                  'last_name': _currentUser!.lastName,
                  'role': _currentUser!.role,
                  'avatar_url': _currentUser!.avatarUrl,
                }
              : map);
          await _secureStorage.write(key: _userKey, value: encoded);
          await _memoryCache.saveUserData(encoded);
          notifyListeners();
          return true;
        }
      }
      _setError(_extractApiErrors(response.extra['api_envelope'] ?? response.data));
      return false;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } on DioException catch (e) {
      _setError(_messageFromDio(e, fallback: 'Erreur mise à jour profil'));
      return false;
    } catch (e) {
      _setError('Erreur lors de la mise à jour : $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Vérifie si l'utilisateur est authentifié (expiration JWT + validation serveur).
  Future<void> checkAuth() async {
    await _loadUserData();
    if (!_isAuthenticated) return;

    try {
      final response = await _baseClient.get('accounts/profile/');
      if (response.statusCode == 200 && response.data is Map) {
        final map = Map<String, dynamic>.from(response.data as Map);
        _currentUser = UserModel.fromJson(map);
        final encoded = jsonEncode(map);
        await _secureStorage.write(key: _userKey, value: encoded);
        await _memoryCache.saveUserData(encoded);
        notifyListeners();
      }
    } on ApiException catch (e) {
      if (e.type == ApiErrorType.unauthorized) {
        final ok = await refreshToken();
        if (!ok) await handleTokenExpired();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final ok = await refreshToken();
        if (!ok) await handleTokenExpired();
      } else {
        _logger.w('Vérification profil serveur ignorée: $e');
      }
    } catch (e) {
      _logger.w('Vérification profil serveur ignorée: $e');
    }

    if (!_isAuthenticated) return;

    await NotificationService().initialize();
    final token = accessToken;
    if (token != null) {
      await NotificationService().sendTokenToBackend(token);
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
        'accounts/password/change/',
        data: data,
      );

      if (response.statusCode == 200) {
        return true;
      }
      _setError(_extractApiErrors(response.data));
      return false;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
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

    final map = Map<String, dynamic>.from(responseData);

    // Enveloppe complète
    if (map.containsKey('status') && map['status'] == 'error') {
      final data = map['data'];
      if (data is Map && data.isNotEmpty) {
        return _formatFieldErrors(data);
      }
      return map['message']?.toString() ?? 'Erreur de validation';
    }

    // Payload déjà désenveloppé (erreurs par champ)
    if (!map.containsKey('access_token') && !map.containsKey('id')) {
      final fieldErr = _formatFieldErrors(map);
      if (fieldErr.isNotEmpty) return fieldErr;
    }

    return map['message']?.toString() ?? 'Erreur de validation';
  }

  String _formatFieldErrors(Map data) {
    const fieldLabels = {
      'phone_number': 'Téléphone',
      'password': 'Mot de passe',
      'email': 'Email',
      'username': 'Nom d\'utilisateur',
      'promo_code': 'Code promo',
      'referral_code_cache': 'Code parrainage',
      'role': 'Rôle',
      'non_field_errors': 'Erreur',
    };

    final errors = <String>[];
    data.forEach((key, value) {
      final label = fieldLabels[key] ?? key.toString();
      if (value is List && value.isNotEmpty) {
        errors.add('$label : ${value.whereType<String>().join(', ')}');
      } else if (value is String && value.isNotEmpty) {
        errors.add('$label : $value');
      }
    });
    return errors.join('\n');
  }

  String _messageFromDio(DioException e, {String fallback = 'Erreur de connexion'}) {
    if (e.response?.statusCode == 400) {
      return _extractApiErrors(e.response?.data ?? {});
    }
    if (e.response?.statusCode == 401) {
      return 'Identifiants incorrects';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Serveur indisponible. Vérifiez votre connexion internet.';
    }
    if (e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Délai d\'attente dépassé. Réessayez dans un instant.';
    }
    return e.message ?? fallback;
  }
}
