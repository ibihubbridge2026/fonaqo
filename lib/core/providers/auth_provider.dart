import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

import '../api/base_client.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import '../services/feedback_service.dart';

/// Provider pour gérer l'état d'authentification
class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'jwt_token';
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
    logout();
    _setError('Votre session a expiré. Veuillez vous reconnecter.');
  }

  // =========================
  // AUTH METHODS (LOGIN, REGISTER, GOOGLE)
  // =========================

  Future<bool> login(Map<String, dynamic> credentials) async {
    _clearError();
    _setLoading(true);

    try {
      final response =
          await _baseClient.post('accounts/login/', data: credentials);

      if (response.statusCode != 200) {
        _setError(response.data['message'] ?? 'Erreur de connexion');
        return false;
      }

      final data = response.data['data'];
      await _saveAuthData(data);
      return true;
    } catch (e) {
      _logger.e('Erreur LOGIN: $e');
      _setError('Erreur réseau: ${e.toString()}');
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

  // =========================
  // TOKEN MANAGEMENT
  // =========================

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final accessToken = data['access_token'];
    final refreshTokenValue = data['refresh_token'];
    final userData = data['user'];

    await _secureStorage.deleteAll();
    await _secureStorage.write(key: _tokenKey, value: accessToken);
    if (refreshTokenValue != null) {
      await _secureStorage.write(
          key: _refreshTokenKey, value: refreshTokenValue);
    }
    await _secureStorage.write(key: _userKey, value: jsonEncode(userData));

    _currentUser = UserModel.fromJson(userData);
    _isAuthenticated = true;

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
    _currentUser = null;
    _isAuthenticated = false;
    _setLoading(false);
  }

  Future<void> _loadUserData() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      final userDataString = await _secureStorage.read(key: _userKey);

      if (token != null && userDataString != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userDataString));
        _isAuthenticated = true;
      }
      notifyListeners();
    } catch (e) {
      _logger.e('Erreur chargement utilisateur: $e');
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
