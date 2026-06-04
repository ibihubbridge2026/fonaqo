import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Gestionnaire de cache personnalisé pour l'application
/// Optimise le stockage des images et fichiers
class AppCacheManager {
  static const key = 'fonaqoCache';
  static const _maxCacheAge = Duration(days: 30);

  static final AppCacheManager _instance = AppCacheManager._internal();
  factory AppCacheManager() => _instance;
  AppCacheManager._internal();

  late final BaseCacheManager _cacheManager;

  /// Initialise le gestionnaire de cache
  Future<void> initialize() async {
    _cacheManager = CacheManager(
      Config(
        key,
        stalePeriod: _maxCacheAge,
        maxNrOfCacheObjects: 200,
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
        fileSystem: IOFileSystem(key),
      ),
    );
  }

  /// Obtient le gestionnaire de cache
  BaseCacheManager get cacheManager => _cacheManager;

  /// Nettoie le cache
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }

  /// Obtient la taille du cache
  Future<int> getCacheSize() async {
    final directory = await getTemporaryDirectory();
    final cacheDir = Directory('${directory.path}/$key');

    if (!cacheDir.existsSync()) return 0;

    int totalSize = 0;
    await for (final entity in cacheDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }

  /// Formate la taille du cache
  static String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }
}
