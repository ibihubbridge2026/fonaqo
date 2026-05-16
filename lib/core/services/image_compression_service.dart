import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
// sentry_flutter retiré

/// Service de compression d'images pour optimiser les uploads
/// Réduit la taille des fichiers avant envoi au backend
class ImageCompressionService {
  static final ImageCompressionService _instance =
      ImageCompressionService._internal();
  factory ImageCompressionService() => _instance;
  ImageCompressionService._internal();

  /// Qualité de compression (0-100)
  static const int defaultQuality = 75;

  /// Taille maximale en pixels (côté le plus long)
  static const int maxWidthHeight = 1920;

  /// Taille maximale du fichier en Mo
  static const double maxFileSizeMB = 3.0;

  /// Compresse une image depuis un chemin de fichier
  /// Retourne le chemin du fichier compressé
  Future<File?> compressImage({
    required String filePath,
    int quality = defaultQuality,
    int maxWidth = maxWidthHeight,
    bool keepExif = false,
  }) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        debugPrint('❌ Fichier inexistant: $filePath');
        return null;
      }

      final originalSize = await file.length();
      debugPrint(
          '📷 Image originale: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} Mo');

      // Compression avec flutter_image_compress
      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        getTempFilePath(filePath),
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxWidth,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        debugPrint('❌ Échec de la compression');
        return null;
      }

      final compressedSize = await result.length();
      final reduction = ((1 - compressedSize / originalSize) * 100);

      debugPrint(
          '✅ Image compressée: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} Mo (-${reduction.toStringAsFixed(1)}%)');

      return File(result.path);
    } catch (e) {
      debugPrint('❌ Erreur compression image: $e');
      // Erreur capturée localement
      // En cas d'erreur, retourner le fichier original
      return File(filePath);
    }
  }

  /// Compresse une image depuis un fichier XFile (image_picker)
  Future<File?> compressXFile({
    required dynamic xFile,
    int quality = defaultQuality,
    int maxWidth = maxWidthHeight,
  }) async {
    try {
      final path = xFile.path;
      if (path == null) {
        debugPrint('❌ Chemin XFile nul');
        return null;
      }
      return await compressImage(
        filePath: path,
        quality: quality,
        maxWidth: maxWidth,
      );
    } catch (e) {
      debugPrint('❌ Erreur compression XFile: $e');
      // Erreur capturée localement
      return null;
    }
  }

  /// Vérifie si une image dépasse la taille maximale
  Future<bool> isImageTooLarge(String filePath,
      {double maxSizeMB = maxFileSizeMB}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final size = await file.length();
      final sizeMB = size / 1024 / 1024;

      return sizeMB > maxSizeMB;
    } catch (e) {
      debugPrint('❌ Erreur vérification taille: $e');
      return false;
    }
  }

  /// Compresse jusqu'à atteindre une taille cible
  Future<File?> compressUntilTargetSize({
    required String filePath,
    double targetSizeMB = maxFileSizeMB,
    int minQuality = 40,
  }) async {
    try {
      File currentFile = File(filePath);
      int quality = defaultQuality;

      while (quality >= minQuality) {
        final compressed = await compressImage(
          filePath: currentFile.path,
          quality: quality,
        );

        if (compressed == null) break;

        final size = await compressed.length();
        final sizeMB = size / 1024 / 1024;

        if (sizeMB <= targetSizeMB) {
          debugPrint(
              '✅ Taille cible atteinte: ${sizeMB.toStringAsFixed(2)} Mo');
          return compressed;
        }

        // Supprimer le fichier temporaire précédent s'il est différent de l'original
        if (currentFile.path != filePath) {
          await currentFile.delete();
        }

        currentFile = compressed;
        quality -= 10;
      }

      debugPrint('⚠️ Taille minimale atteinte sans succès');
      return currentFile;
    } catch (e) {
      debugPrint('❌ Erreur compression progressive: $e');
      // Erreur capturée localement
      return File(filePath);
    }
  }

  /// Génère un chemin temporaire pour le fichier compressé
  String getTempFilePath(String originalPath) {
    final dir = Directory.systemTemp.path;
    final fileName = DateTime.now().millisecondsSinceEpoch;
    return '$dir/compressed_$fileName.jpg';
  }

  /// Obtient les informations d'une image (dimensions, taille)
  Future<Map<String, dynamic>> getImageInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return {'error': 'File not found'};
      }

      final size = await file.length();
      // Note: Pour obtenir les dimensions exactes, on pourrait utiliser
      // un package comme `image` ou `flutter_native_image`

      return {
        'path': filePath,
        'size_bytes': size,
        'size_mb': size / 1024 / 1024,
        'exists': true,
      };
    } catch (e) {
      debugPrint('❌ Erreur info image: $e');
      return {'error': e.toString()};
    }
  }

  /// Nettoie les fichiers temporaires de compression
  Future<void> cleanTempFiles() async {
    try {
      final tempDir = Directory.systemTemp;
      final entries = tempDir.listSync();

      int deletedCount = 0;
      for (var entry in entries) {
        if (entry is File &&
            entry.path.contains('compressed_') &&
            entry.path.endsWith('.jpg')) {
          // Supprimer les fichiers de plus de 1 heure
          final stat = await entry.stat();
          final age = DateTime.now().difference(stat.modified);

          if (age.inHours > 1) {
            await entry.delete();
            deletedCount++;
          }
        }
      }

      if (deletedCount > 0) {
        debugPrint('🧹 $deletedCount fichiers temporaires nettoyés');
      }
    } catch (e) {
      debugPrint('❌ Erreur nettoyage fichiers temporaires: $e');
      // Erreur capturée localement
    }
  }
}
