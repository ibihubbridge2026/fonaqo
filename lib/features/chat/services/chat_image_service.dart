import 'dart:io';
import 'package:fonaco/core/services/image_compression_service.dart';
import 'package:fonaco/core/utils/app_logger.dart';
import 'package:image_picker/image_picker.dart';

/// Service pour la compression et l'upload d'images dans le chat
class ChatImageService {
  static final ChatImageService _instance = ChatImageService._internal();
  factory ChatImageService() => _instance;
  ChatImageService._internal();

  final ImageCompressionService _compressionService = ImageCompressionService();
  final AppLogger _logger = AppLogger();
  final ImagePicker _imagePicker = ImagePicker();

  /// Taille maximale pour les images de chat (plus petite que les images de mission)
  static const int _maxWidthHeight = 800;
  static const int _chatQuality = 80;

  /// Sélectionne une image depuis la galerie
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxWidthHeight.toDouble(),
        maxHeight: _maxWidthHeight.toDouble(),
        imageQuality: _chatQuality,
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      _logger.e('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Prend une photo avec la caméra
  Future<File?> captureImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: _maxWidthHeight.toDouble(),
        maxHeight: _maxWidthHeight.toDouble(),
        imageQuality: _chatQuality,
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      _logger.e('Error capturing image: $e');
      return null;
    }
  }

  /// Compresse une image pour le chat
  Future<File?> compressImage(String filePath) async {
    try {
      final originalSize = await File(filePath).length();
      _logger.d(
          'Original image size: ${(originalSize / 1024).toStringAsFixed(2)} KB');

      final compressed = await _compressionService.compressImage(
        filePath: filePath,
        quality: _chatQuality,
        maxWidth: _maxWidthHeight,
      );

      if (compressed != null) {
        final compressedSize = await compressed.length();
        final reduction = ((1 - compressedSize / originalSize) * 100);
        _logger.i(
            'Compressed image: ${(compressedSize / 1024).toStringAsFixed(2)} KB (-${reduction.toStringAsFixed(1)}%)');
      }

      return compressed;
    } catch (e) {
      _logger.e('Error compressing image: $e');
      return File(filePath); // Fallback to original
    }
  }

  /// Valide une image avant upload
  Future<bool> validateImage(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _logger.w('Image file does not exist');
        return false;
      }

      final size = await file.length();
      final sizeMB = size / 1024 / 1024;

      // Limite de 5MB pour les images de chat
      if (sizeMB > 5) {
        _logger.w('Image too large: ${sizeMB.toStringAsFixed(2)} MB');
        return false;
      }

      return true;
    } catch (e) {
      _logger.e('Error validating image: $e');
      return false;
    }
  }

  /// Génère un nom de fichier unique
  String generateFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalName.split('.').last;
    return 'chat_image_$timestamp.$extension';
  }
}
