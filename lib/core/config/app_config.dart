import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration de l'application par environnement
/// Gère les variables d'environnement pour dev, staging et production
class AppConfig {
  // Singleton
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // Environment
  late final AppEnvironment _environment;
  late final String _appVersion;
  late final int _buildNumber;

  // API
  late final String _serverUrl;
  late final String _apiBaseUrl;
  late final Duration _connectTimeout;
  late final Duration _receiveTimeout;
  late final Duration _sendTimeout;

  // WebSocket
  late final String _wsUrl;

  // Firebase
  late final String _firebaseProjectId;
  late final String _firebaseAppIdAndroid;
  late final String _firebaseMessagingSenderId;
  late final String _firebaseApiKey;

  // Google Maps
  late final String _googleMapsApiKey;

  // Sécurité
  late final String _androidEncryptedPrefsName;
  late final String _iosAccessGroup;

  // Features flags
  late final bool _enableAiSearch;
  late final bool _enableChat;
  late final bool _enableWallet;
  late final bool _enableBoosts;
  late final bool _enableDisputes;

  // Debug
  late final bool _debugMode;
  late final bool _logHttpRequests;

  /// Initialise la configuration
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    final instance = AppConfig._instance;

    // Environment
    final env = dotenv.env['APP_ENV'] ?? 'development';
    instance._environment = AppEnvironment.fromString(env);
    instance._appVersion = dotenv.env['APP_VERSION'] ?? '1.0.0';
    instance._buildNumber =
        int.tryParse(dotenv.env['BUILD_NUMBER'] ?? '1') ?? 1;

    // API
    instance._serverUrl = dotenv.env['SERVER_URL'] ?? 'http://10.0.2.2:8000';
    instance._apiBaseUrl =
        dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api/v1/';
    instance._connectTimeout = Duration(
      seconds: int.tryParse(dotenv.env['API_CONNECT_TIMEOUT'] ?? '10') ?? 10,
    );
    instance._receiveTimeout = Duration(
      seconds: int.tryParse(dotenv.env['API_RECEIVE_TIMEOUT'] ?? '20') ?? 20,
    );
    instance._sendTimeout = Duration(
      seconds: int.tryParse(dotenv.env['API_SEND_TIMEOUT'] ?? '20') ?? 20,
    );

    // WebSocket
    instance._wsUrl = dotenv.env['WS_URL'] ?? 'ws://10.0.2.2:8000/ws';

    // Firebase
    instance._firebaseProjectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
    instance._firebaseAppIdAndroid =
        dotenv.env['FIREBASE_APP_ID_ANDROID'] ?? '';
    instance._firebaseMessagingSenderId =
        dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
    instance._firebaseApiKey = dotenv.env['FIREBASE_API_KEY'] ?? '';

    // Google Maps
    instance._googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

    // Sécurité
    instance._androidEncryptedPrefsName =
        dotenv.env['ANDROID_ENCRYPTED_PREFS_NAME'] ?? 'secure_storage_fonaqo';
    instance._iosAccessGroup =
        dotenv.env['IOS_ACCESS_GROUP'] ?? 'com.fonaqo.secure';

    // Features flags
    instance._enableAiSearch = dotenv.env['ENABLE_AI_SEARCH'] == 'true';
    instance._enableChat = dotenv.env['ENABLE_CHAT'] == 'true';
    instance._enableWallet = dotenv.env['ENABLE_WALLET'] == 'true';
    instance._enableBoosts = dotenv.env['ENABLE_BOOSTS'] == 'true';
    instance._enableDisputes = dotenv.env['ENABLE_DISPUTES'] == 'true';

    // Debug
    instance._debugMode = dotenv.env['DEBUG_MODE'] == 'true' || kDebugMode;
    instance._logHttpRequests = dotenv.env['LOG_HTTP_REQUESTS'] == 'true';

    // Log de l'initialisation
    instance._logInitialization();
  }

  void _logInitialization() {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🚀 FONAQO - Configuration Initialisée');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📦 Environment: ${_environment.name}');
    debugPrint('📱 Version: $_appVersion ($_buildNumber)');
    debugPrint('🌐 API: $_apiBaseUrl');
    debugPrint('🔌 WebSocket: $_wsUrl');
    debugPrint('🔥 Firebase: $_firebaseProjectId');
    debugPrint(
        '🗺️ Google Maps: ${_googleMapsApiKey.isNotEmpty ? "✓ Configuré" : "✗ Non configuré"}');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('⚙️ Features:');
    debugPrint('  - AI Search: ${_enableAiSearch ? "✓" : "✗"}');
    debugPrint('  - Chat: ${_enableChat ? "✓" : "✗"}');
    debugPrint('  - Wallet: ${_enableWallet ? "✓" : "✗"}');
    debugPrint('  - Boosts: ${_enableBoosts ? "✓" : "✗"}');
    debugPrint('  - Disputes: ${_enableDisputes ? "✓" : "✗"}');
    debugPrint('═══════════════════════════════════════════════════════════');
  }

  // Getters
  AppEnvironment get environment => _environment;
  String get appVersion => _appVersion;
  int get buildNumber => _buildNumber;
  String get serverUrl => _serverUrl;
  String get apiBaseUrl => _apiBaseUrl;
  Duration get connectTimeout => _connectTimeout;
  Duration get receiveTimeout => _receiveTimeout;
  Duration get sendTimeout => _sendTimeout;
  String get wsUrl => _wsUrl;
  String get firebaseProjectId => _firebaseProjectId;
  String get firebaseAppIdAndroid => _firebaseAppIdAndroid;
  String get firebaseMessagingSenderId => _firebaseMessagingSenderId;
  String get firebaseApiKey => _firebaseApiKey;
  String get googleMapsApiKey => _googleMapsApiKey;
  String get androidEncryptedPrefsName => _androidEncryptedPrefsName;
  String get iosAccessGroup => _iosAccessGroup;
  bool get enableAiSearch => _enableAiSearch;
  bool get enableChat => _enableChat;
  bool get enableWallet => _enableWallet;
  bool get enableBoosts => _enableBoosts;
  bool get enableDisputes => _enableDisputes;
  bool get debugMode => _debugMode;
  bool get logHttpRequests => _logHttpRequests;

  bool get isDevelopment => _environment == AppEnvironment.development;
  bool get isStaging => _environment == AppEnvironment.staging;
  bool get isProduction => _environment == AppEnvironment.production;
}

/// Enum des environnements
enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment fromString(String value) {
    switch (value.toLowerCase()) {
      case 'development':
      case 'dev':
        return AppEnvironment.development;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      default:
        return AppEnvironment.development;
    }
  }
}
