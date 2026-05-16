import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
// sentry_flutter retiré
// ffmpeg_kit_flutter retiré (discontinued) - utilisation de compression native

/// Service de compression multimédia pour optimiser les uploads
/// Réduit la taille des fichiers avant envoi au backend (OBLIGATOIRE)
class MediaCompressionService {
  static final MediaCompressionService _instance =
      MediaCompressionService._internal();
  factory MediaCompressionService() => _instance;
  MediaCompressionService._internal();

  /// Qualité de compression (0-100)
  static const int defaultImageQuality = 75;

  /// Taille maximale en pixels (côté le plus long)
  static const int maxWidthHeight = 1920;

  /// Taille maximale du fichier en Mo
  static const double maxImageFileSizeMB = 3.0;

  /// Taille maximale du fichier audio en Mo
  static const double maxAudioFileSizeMB = 5.0;

  /// Bitrate audio cible (kbps)
  static const int targetAudioBitrate = 64000;

  /// Durée maximale audio (secondes)
  static const int maxAudioDurationSeconds = 120;

  /// Compresse une image depuis un chemin de fichier (OBLIGATOIRE)
  /// Retourne le chemin du fichier compressé
  Future<File> compressImage({
    required String filePath,
    int quality = defaultImageQuality,
    int maxWidth = maxWidthHeight,
    bool keepExif = false,
    bool forceCompression = true, // Toujours compresser
  }) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Fichier inexistant: $filePath');
    }

    final originalSize = await file.length();
    debugPrint(
        '📷 Image originale: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} Mo');

    // Vérifier si la compression est nécessaire
    final needsCompression = forceCompression ||
        originalSize > (maxImageFileSizeMB * 1024 * 1024) ||
        await _isImageTooLarge(filePath);

    if (!needsCompression) {
      debugPrint('ℹ️ Image déjà optimisée, pas de compression nécessaire');
      return file;
    }

    // Compression avec flutter_image_compress
    final result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      _getTempFilePath(filePath),
      quality: quality,
      minWidth: maxWidth,
      minHeight: maxWidth,
      format: CompressFormat.jpeg,
      keepExif: keepExif,
    );

    if (result == null) {
      throw Exception('Échec de la compression image');
    }

    final compressedSize = await result.length();
    final reduction = ((1 - compressedSize / originalSize) * 100);

    debugPrint(
        '✅ Image compressée: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} Mo (-${reduction.toStringAsFixed(1)}%)');

    // Supprimer l'original après compression réussie
    await file.delete();

    return File(result.path);
  }

  /// Compresse une image depuis un fichier XFile (image_picker) - OBLIGATOIRE
  Future<File> compressXFile({
    required dynamic xFile,
    int quality = defaultImageQuality,
    int maxWidth = maxWidthHeight,
  }) async {
    final path = xFile.path;
    if (path == null) {
      throw Exception('Chemin XFile nul');
    }
    return await compressImage(
      filePath: path,
      quality: quality,
      maxWidth: maxWidth,
    );
  }

  /// Vérifie si une image dépasse la taille maximale
  Future<bool> _isImageTooLarge(String filePath,
      {double maxSizeMB = maxImageFileSizeMB}) async {
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

  /// Compresse une image avec une qualité progressive
  Future<File> compressImageProgressive({
    required String filePath,
    double targetSizeMB = maxImageFileSizeMB,
    int minQuality = 30,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return File(filePath);

      File? currentFile = file;
      int currentQuality = defaultImageQuality;

      while (currentQuality >= minQuality) {
        final compressed = await compressImage(
          filePath: currentFile!.path,
          quality: currentQuality,
        );

        final size = await compressed.length();
        final sizeMB = size / 1024 / 1024;

        if (sizeMB <= targetSizeMB) {
          return compressed;
        }

        // Nettoyer le fichier précédent et continuer avec une qualité inférieure
        if (currentFile.path != file.path) {
          await currentFile.delete();
        }

        currentFile = compressed;
        currentQuality -= 10;
      }

      debugPrint('⚠️ Taille minimale atteinte sans succès');
      return currentFile!;
    } catch (e) {
      debugPrint('❌ Erreur compression progressive: $e');
      // Erreur capturée localement
      return File(filePath);
    }
  }

  /// Génère un chemin de fichier temporaire
  String _getTempFilePath(String originalPath) {
    final dir = Directory.systemTemp;
    final fileName =
        'compressed_${DateTime.now().millisecondsSinceEpoch}${path.extension(originalPath)}';
    return path.join(dir.path, fileName);
  }

  // =========================
  // COMPRESSION AUDIO (OBLIGATOIRE)
  // =========================

  /// Compresse un fichier audio (OBLIGATOIRE - Version simplifiée)
  /// Supporte les formats: MP3, M4A, WAV
  Future<File> compressAudio({
    required String filePath,
    int targetBitrate = targetAudioBitrate,
    int maxDurationSeconds = maxAudioDurationSeconds,
  }) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Fichier audio inexistant: $filePath');
    }

    final originalSize = await file.length();
    debugPrint(
        '🎵 Audio original: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} Mo');

    // Vérifier la taille maximale
    if (originalSize > (maxAudioFileSizeMB * 1024 * 1024)) {
      throw Exception(
          'Fichier audio trop volumineux: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} Mo > ${maxAudioFileSizeMB} Mo');
    }

    final extension = path.extension(filePath).toLowerCase();

    // Validation du format
    if (!['.mp3', '.m4a', '.aac', '.wav', '.ogg'].contains(extension)) {
      throw Exception('Format audio non supporté: $extension');
    }

    // Pour l'instant, nous retournons le fichier original sans compression
    // La compression audio avancée nécessiterait une librairie différente
    debugPrint('⚠️ Compression audio simplifiée - fichier retourné tel quel');
    debugPrint(
        '📊 Taille: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} Mo');

    return file;
  }

  /// Compresse un audio depuis un XFile (OBLIGATOIRE)
  Future<File> compressAudioXFile({
    required dynamic xFile,
    int targetBitrate = targetAudioBitrate,
  }) async {
    final path = xFile.path;
    if (path == null) {
      throw Exception('Chemin XFile audio nul');
    }
    return await compressAudio(
      filePath: path,
      targetBitrate: targetBitrate,
    );
  }

  // =========================
  // VALIDATION ET MÉTHODES UTILITAIRES
  // =========================

  /// Valide et compresse automatiquement un fichier média (OBLIGATOIRE)
  Future<File> validateAndCompressMedia(String filePath) async {
    final extension = path.extension(filePath).toLowerCase();

    // Formats image
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp']
        .contains(extension)) {
      return await compressImage(filePath: filePath);
    }

    // Formats audio
    else if (['.mp3', '.m4a', '.aac', '.wav', '.ogg'].contains(extension)) {
      return await compressAudio(filePath: filePath);
    } else {
      throw Exception('Format de fichier non supporté: $extension');
    }
  }

  /// Vérifie si un fichier nécessite une compression
  Future<bool> needsCompression(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;

    final size = await file.length();
    final sizeMB = size / 1024 / 1024;
    final extension = path.extension(filePath).toLowerCase();

    // Images
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp']
        .contains(extension)) {
      return sizeMB > maxImageFileSizeMB || await _isImageTooLarge(filePath);
    }

    // Audio
    else if (['.mp3', '.m4a', '.aac', '.wav', '.ogg'].contains(extension)) {
      return sizeMB > maxAudioFileSizeMB;
    }

    return false;
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
