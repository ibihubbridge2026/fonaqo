import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bulle pour afficher les messages fichiers (PDF, documents, etc.)
class FileMessageBubble extends StatefulWidget {
  final String fileName;
  final String? fileUrl;
  final int? fileSize;
  final String? fileType;
  final bool isMe;
  final VoidCallback? onTap;
  final bool isUploading;
  final double uploadProgress;

  const FileMessageBubble({
    super.key,
    required this.fileName,
    this.fileUrl,
    this.fileSize,
    this.fileType,
    required this.isMe,
    this.onTap,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  @override
  State<FileMessageBubble> createState() => _FileMessageBubbleState();
}

class _FileMessageBubbleState extends State<FileMessageBubble> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: widget.isMe ? 48 : 0,
        right: widget.isMe ? 0 : 48,
        bottom: 8,
        top: 8,
      ),
      child: Column(
        crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bulle principale
          GestureDetector(
            onTap: widget.onTap ?? (widget.isUploading ? null : _openFile),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
                minWidth: 200,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isMe ? const Color(0xFFFFD400) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: widget.isUploading 
                  ? _buildUploadingContent()
                  : _buildFileContent(),
            ),
          ),
          
          // Taille du fichier
          if (widget.fileSize != null && !widget.isUploading)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatFileSize(widget.fileSize!),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileContent() {
    return Row(
      children: [
        // Icône du fichier
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getFileIconColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getFileIcon(),
            color: _getFileIconColor(),
            size: 24,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Informations du fichier
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.fileName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _getFileTypeLabel(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        
        // Icône de téléchargement
        if (!widget.isUploading)
          Icon(
            Icons.download,
            color: widget.isMe ? Colors.black : Colors.grey.shade600,
            size: 20,
          ),
      ],
    );
  }

  Widget _buildUploadingContent() {
    return Row(
      children: [
        // Icône avec progression
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  _getFileIcon(),
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ),
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: widget.uploadProgress,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isMe ? Colors.black : const Color(0xFFFFD400),
                  ),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Informations d'upload
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.fileName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Envoi en cours... ${(widget.uploadProgress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon() {
    final extension = widget.fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor() {
    final extension = widget.fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'txt':
        return Colors.grey;
      case 'zip':
      case 'rar':
        return Colors.purple;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getFileTypeLabel() {
    final extension = widget.fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return 'Document PDF';
      case 'doc':
      case 'docx':
        return 'Document Word';
      case 'xls':
      case 'xlsx':
        return 'Feuille Excel';
      case 'ppt':
      case 'pptx':
        return 'Présentation';
      case 'txt':
        return 'Fichier texte';
      case 'zip':
      case 'rar':
        return 'Archive compressée';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'Image';
      default:
        return 'Fichier ${extension.toUpperCase()}';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  void _openFile() {
    if (widget.fileUrl == null) return;
    
    // TODO: Implémenter l'ouverture du fichier
    // Pour l'instant, montrer un message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture de ${widget.fileName}...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
