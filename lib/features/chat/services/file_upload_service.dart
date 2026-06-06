import 'dart:io';
import 'package:dio/dio.dart';
import 'package:fonaco/core/api/base_client.dart';
import 'package:fonaco/core/utils/app_logger.dart';
import 'package:path/path.dart' as path;

/// Service pour l'upload sécurisé de fichiers dans le chat
class ChatFileUploadService {
  static final ChatFileUploadService _instance =
      ChatFileUploadService._internal();
  factory ChatFileUploadService() => _instance;
  ChatFileUploadService._internal();

  final BaseClient _api = BaseClient();
  final AppLogger _logger = AppLogger();

  /// Types de fichiers autorisés
  static const List<String> _allowedImageTypes = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp'
  ];
  static const List<String> _allowedDocumentTypes = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx'
  ];
  static const List<String> _allowedAudioTypes = [
    'mp3',
    'wav',
    'm4a',
    'aac',
    'ogg'
  ];
  static const List<String> _allowedVideoTypes = ['mp4', 'mov', 'avi', 'mkv'];

  /// Taille maximale par type (en octets)
  static const int _maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int _maxDocumentSize = 10 * 1024 * 1024; // 10MB
  static const int _maxAudioSize = 10 * 1024 * 1024; // 10MB
  static const int _maxVideoSize = 50 * 1024 * 1024; // 50MB

  /// Upload un fichier
  Future<UploadResult?> uploadFile({
    required File file,
    required String conversationId,
    required String messageType,
    ProgressCallback? onProgress,
  }) async {
    try {
      final fileName = path.basename(file.path);
      final extension =
          path.extension(fileName).replaceFirst('.', '').toLowerCase();

      // Valider le type de fichier
      if (!_isFileTypeAllowed(extension, messageType)) {
        _logger.w('File type not allowed: $extension');
        return UploadResult.error('Type de fichier non autorisé');
      }

      // Valider la taille
      final fileSize = await file.length();
      if (!_isFileSizeAllowed(fileSize, messageType)) {
        _logger.w('File size exceeds limit: ${fileSize / 1024 / 1024} MB');
        return UploadResult.error('Fichier trop volumineux');
      }

      // Préparer le multipart
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'conversation_id': conversationId,
        'message_type': messageType,
      });

      _logger.i(
          'Uploading file: $fileName (${(fileSize / 1024).toStringAsFixed(2)} KB)');

      final response = await _api.dio.post(
        '/chat/upload/',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        _logger.i('File uploaded successfully: ${data['file_url']}');
        return UploadResult.success(
          fileUrl: data['file_url'] as String,
          fileName: data['file_name'] as String? ?? fileName,
          fileSize: data['file_size'] as int? ?? fileSize,
          mimeType: data['mime_type'] as String?,
        );
      }

      return UploadResult.error('Échec de l\'upload');
    } catch (e) {
      _logger.e('Error uploading file: $e');
      return UploadResult.error('Erreur lors de l\'upload: $e');
    }
  }

  /// Vérifie si le type de fichier est autorisé
  bool _isFileTypeAllowed(String extension, String messageType) {
    switch (messageType) {
      case 'image':
        return _allowedImageTypes.contains(extension);
      case 'file':
        return _allowedDocumentTypes.contains(extension);
      case 'audio':
        return _allowedAudioTypes.contains(extension);
      case 'video':
        return _allowedVideoTypes.contains(extension);
      default:
        return false;
    }
  }

  /// Vérifie si la taille du fichier est autorisée
  bool _isFileSizeAllowed(int size, String messageType) {
    switch (messageType) {
      case 'image':
        return size <= _maxImageSize;
      case 'file':
        return size <= _maxDocumentSize;
      case 'audio':
        return size <= _maxAudioSize;
      case 'video':
        return size <= _maxVideoSize;
      default:
        return false;
    }
  }

  /// Obtient la taille maximale autorisée pour un type
  int getMaxSizeForType(String messageType) {
    switch (messageType) {
      case 'image':
        return _maxImageSize;
      case 'file':
        return _maxDocumentSize;
      case 'audio':
        return _maxAudioSize;
      case 'video':
        return _maxVideoSize;
      default:
        return _maxDocumentSize;
    }
  }

  /// Formate la taille en format lisible
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }
}

/// Résultat d'upload
class UploadResult {
  final bool success;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final String? error;

  UploadResult.success({
    required this.fileUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
  })  : success = true,
        error = null;

  UploadResult.error(this.error)
      : success = false,
        fileUrl = null,
        fileName = null,
        fileSize = null,
        mimeType = null;
}
