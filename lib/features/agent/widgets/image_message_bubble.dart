import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bulle pour afficher les messages images avec aperçu et plein écran
class ImageMessageBubble extends StatefulWidget {
  final String imageUrl;
  final String? caption;
  final bool isMe;
  final VoidCallback? onTap;
  final bool isUploading;
  final double uploadProgress;

  const ImageMessageBubble({
    super.key,
    required this.imageUrl,
    this.caption,
    required this.isMe,
    this.onTap,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  @override
  State<ImageMessageBubble> createState() => _ImageMessageBubbleState();
}

class _ImageMessageBubbleState extends State<ImageMessageBubble> {
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
            onTap: widget.onTap ?? () => _showFullScreenImage(context),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
                minWidth: 150,
                maxHeight: 300,
              ),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Image
                    if (widget.isUploading)
                      _buildUploadingPlaceholder()
                    else
                      _buildImage(),
                    
                    // Overlay de progression
                    if (widget.isUploading)
                      _buildProgressOverlay(),
                  ],
                ),
              ),
            ),
          ),
          
          // Caption optionnel
          if (widget.caption != null && widget.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.caption!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Image.network(
      widget.imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return Container(
          color: Colors.grey.shade100,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.isMe ? Colors.black : const Color(0xFFFFD400),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                color: Colors.grey.shade400,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'Image non disponible',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadingPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            color: Colors.grey.shade400,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            'Envoi en cours...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CircularProgressIndicator(
                value: widget.uploadProgress,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isMe ? Colors.black : const Color(0xFFFFD400),
                ),
                strokeWidth: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _FullScreenImageView(imageUrl: widget.imageUrl),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
}

class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageView({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 50,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Image non disponible',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
