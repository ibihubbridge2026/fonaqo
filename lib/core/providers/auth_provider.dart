import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';

import '../api/base_client.dart';
import '../models/user_model.dart';

/// Provider pour gérer l'état d'authentification
class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'jwt_token';
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

  /// Affiche une SnackBar moderne avec le message d'erreur
  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade50,
        elevation: 0,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Affiche une SnackBar de succès moderne
  void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade50,
        elevation: 0,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Gère la déconnexion automatique lors de l'expiration du token
  void handleTokenExpired() {
    print('DEBUG - Déconnexion automatique due à token expiré');
    logout();

    // Afficher un message d'erreur propre
    _setError('Votre session a expiré. Veuillez vous reconnecter.');
  }

  // =========================
  // LOGIN
  // =========================

  Future<bool> login(Map<String, dynamic> credentials) async {
    _clearError();
    _setLoading(true);

    try {
      final response = await _baseClient.post(
        '/accounts/login/',
        data: credentials,
      );

      _logger.d('LOGIN STATUS CODE: ${response.statusCode}');

      _logger.i('LOGIN RESPONSE DATA: ${response.data}');

      if (response.statusCode != 200) {
        final errorMessage = response.data is Map
            ? response.data['message'] ?? 'Erreur de connexion'
            : 'Erreur de connexion';

        _setError(errorMessage);

        return false;
      }

      final responseData = response.data as Map<String, dynamic>;

      final data = responseData['data'] as Map<String, dynamic>?;

      final accessToken = data?['access_token'] as String?;

      final userData = data?['user'] as Map<String, dynamic>?;

      if (accessToken == null) {
        _setError('Token manquant dans la réponse');

        return false;
      }

      if (userData == null) {
        _setError('Données utilisateur manquantes');

        return false;
      }

      // Forcer le nettoyage des anciens tokens
      await _secureStorage.deleteAll();

      // Debug: Afficher les heures
      print('DEBUG - Heure téléphone: ${DateTime.now().toIso8601String()}');
      print('DEBUG - Token reçu: $accessToken');

      // Sauvegarder le token
      await _secureStorage.write(key: _tokenKey, value: accessToken);

      // Sauvegarder les données utilisateur
      await _secureStorage.write(key: _userKey, value: jsonEncode(userData));

      // Créer le user model
      final user = UserModel.fromJson(userData);

      _currentUser = user;

      _isAuthenticated = true;

      notifyListeners();

      return true;
    } catch (e) {
      _logger.e('Erreur LOGIN: ${e.toString()}');

      _setError('Erreur réseau: ${e.toString()}');

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // REGISTER
  // =========================

  Future<bool> register(Map<String, dynamic> userData) async {
    _clearError();

    _setLoading(true);

    try {
      // Debug du payload envoyé à Django
      print('DEBUG REGISTER PAYLOAD: $userData');

      final response = await _baseClient.post(
        '/accounts/register/',
        data: userData,
      );

      _logger.d('REGISTER STATUS CODE: ${response.statusCode}');

      _logger.i('REGISTER RESPONSE DATA: ${response.data}');

      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorMessage = response.data is Map
            ? response.data['message'] ?? 'Erreur d\'inscription'
            : 'Erreur d\'inscription';

        _setError(errorMessage);

        return false;
      }

      // Connexion automatique après inscription
      final loginData = {
        'phone_number': userData['phone_number'],
        'password': userData['password'],
      };

      final loginSuccess = await login(loginData);

      return loginSuccess;
    } catch (e) {
      _logger.e('Erreur REGISTER: ${e.toString()}');

      _setError('Erreur d\'inscription: ${e.toString()}');

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // FORGOT PASSWORD
  // =========================

  Future<bool> forgotPassword(Map<String, dynamic> data) async {
    _clearError();

    _setLoading(true);

    try {
      final response = await _baseClient.post(
        '/accounts/forgot-password/',
        data: data,
      );

      _logger.d('FORGOT PASSWORD STATUS: ${response.statusCode}');

      _logger.i('FORGOT PASSWORD DATA: ${response.data}');

      if (response.statusCode != 200) {
        final errorMessage = response.data is Map
            ? response.data['message'] ?? 'Erreur lors de l\'envoi du code'
            : 'Erreur lors de l\'envoi du code';

        _setError(errorMessage);

        return false;
      }

      return true;
    } catch (e) {
      _logger.e('Erreur FORGOT PASSWORD: ${e.toString()}');

      _setError('Erreur lors de l\'envoi du code: ${e.toString()}');

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // GOOGLE AUTH
  // =========================

  /// Méthode d'authentification Google
  Future<bool> signInWithGoogle() async {
    _clearError();
    _setLoading(true);

    try {
      // TODO: Implémenter l'authentification Google avec Firebase Auth
      // Pour l'instant, nous allons simuler le processus

      // Étape 1: Authentifier avec Firebase (à implémenter)
      // final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      // final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
      // final credential = GoogleAuthProvider.credential(
      //   accessToken: googleAuth?.accessToken,
      //   idToken: googleAuth?.idToken,
      // );
      // final userCredential = await _firebaseAuth.signInWithCredential(credential);

      // Simulation pour le développement
      await Future.delayed(const Duration(seconds: 2));

      // Étape 2: Envoyer les informations à notre backend Django
      final response = await _baseClient.post(
        '/accounts/google-auth/',
        data: {
          'email': 'test@example.com', // TODO: Remplacer par l'email Google
          'name': 'Test User', // TODO: Remplacer par le nom Google
          'google_id': 'google_id_123', // TODO: Remplacer par l'ID Google
        },
      );

      // Logger détaillé pour debug
      _logger.d('Status Code Google Auth: ${response.statusCode}');
      _logger.i('Data reçue Google Auth: ${response.data}');

      // Vérifier si la réponse contient les données attendues
      if (response.statusCode != 200) {
        final errorMessage = response.data is Map
            ? response.data['message'] ??
                  'Erreur lors de l\'authentification Google'
            : 'Erreur lors de l\'authentification Google';
        _setError(errorMessage);
        return false;
      }

      // Étape 3: Gérer la réponse du backend (connexion existante ou nouveau compte)
      final responseData = response.data;
      if (responseData['status'] == 'success') {
        final userData = responseData['data']['user'];
        final accessToken = responseData['data']['access_token'];

        // Sauvegarder le token et les données utilisateur
        await _secureStorage.write(key: _tokenKey, value: accessToken);
        await _secureStorage.write(key: _userKey, value: jsonEncode(userData));

        _logger.i('Authentification Google réussie: ${userData['email']}');
        return true;
      } else {
        _setError(
          responseData['message'] ??
              'Erreur lors de l\'authentification Google',
        );
        return false;
      }
    } catch (e) {
      // Gérer les erreurs d'annulation Google
      if (e.toString().contains('cancelled') ||
          e.toString().contains('canceled')) {
        _logger.i('Authentification Google annulée par l\'utilisateur');
        return false;
      }

      _setError('Erreur lors de l\'authentification Google: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    _setLoading(true);

    try {
      await _secureStorage.delete(key: _tokenKey);

      await _secureStorage.delete(key: _userKey);

      _currentUser = null;

      _isAuthenticated = false;

      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la déconnexion');
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // LOAD USER DATA
  // =========================

  Future<void> _loadUserData() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);

      final userDataString = await _secureStorage.read(key: _userKey);

      if (token != null && userDataString != null) {
        final Map<String, dynamic> userData = jsonDecode(userDataString);

        _currentUser = UserModel.fromJson(userData);

        _isAuthenticated = true;
      } else {
        _currentUser = null;

        _isAuthenticated = false;
      }

      notifyListeners();
    } catch (e) {
      _logger.e('Erreur chargement utilisateur: $e');
    }
  }

  // =========================
  // MISSIONS DISPONIBLES
  // =========================

  Future<List<Map<String, dynamic>>> fetchAvailableMissions({
    double? lat,
    double? lng,
  }) async {
    _setLoading(true);

    _clearError();

    try {
      final token = await _secureStorage.read(key: _tokenKey);

      _logger.i('TOKEN ACTUEL: $token');

      Map<String, dynamic> queryParams = {};

      if (lat != null && lng != null) {
        queryParams['lat'] = lat.toString();

        queryParams['lng'] = lng.toString();
      }

      final response = await _baseClient.get(
        '/missions/available/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        final missionsData = responseData['data'] as List<dynamic>? ?? [];

        return missionsData.cast<Map<String, dynamic>>();
      } else {
        _setError('Erreur lors de la récupération des missions');

        return [];
      }
    } catch (e) {
      _logger.e('Erreur missions: ${e.toString()}');

      return [];
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // REFRESH TOKEN
  // =========================

  Future<bool> refreshToken() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      return true;
    } catch (e) {
      _setError('Erreur rafraîchissement token');

      return false;
    }
  }

  // =========================
  // CHECK AUTH
  // =========================

  Future<void> checkAuth() async {
    await _loadUserData();
  }

  // =========================
  // GET TOKEN
  // =========================

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }
}
