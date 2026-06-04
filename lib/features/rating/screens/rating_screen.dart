import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fonaco/features/rating/models/rating.dart';
import 'package:fonaco/features/rating/repositories/rating_repository.dart';
import 'package:fonaco/core/utils/app_logger.dart';

/// Écran de notation après mission
class RatingScreen extends StatefulWidget {
  final String missionId;
  final String ratedId;
  final String ratedName;
  final String? ratedAvatar;
  final RatingType type;

  const RatingScreen({
    super.key,
    required this.missionId,
    required this.ratedId,
    required this.ratedName,
    this.ratedAvatar,
    required this.type,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final RatingRepository _repository = RatingRepository();
  final AppLogger _logger = AppLogger();
  final TextEditingController _commentController = TextEditingController();

  int _selectedScore = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedScore == 0) {
      setState(() => _errorMessage = 'Veuillez sélectionner une note');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final rating = await _repository.submitRating(
        missionId: widget.missionId,
        ratedId: widget.ratedId,
        score: _selectedScore,
        type: widget.type,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      if (rating != null) {
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur lors de la soumission de la note';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      _logger.e('Error submitting rating: $e');
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.type == RatingType.clientToAgent
              ? 'Noter l\'agent'
              : 'Noter le client',
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),

            // Avatar et nom
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: widget.ratedAvatar != null
                  ? CachedNetworkImageProvider(widget.ratedAvatar!)
                  : null,
              child: widget.ratedAvatar == null
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.ratedName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.type == RatingType.clientToAgent
                  ? 'Comment s\'est passé votre mission ?'
                  : 'Comment était le client ?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Étoiles
            _buildStarRating(),
            const SizedBox(height: 16),

            // Message d'erreur
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Commentaire
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Laissez un commentaire (optionnel)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 32),

            // Bouton soumettre
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        'Envoyer la note',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() => _selectedScore = index + 1);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              index < _selectedScore ? Icons.star : Icons.star_border,
              size: 48,
              color: const Color(0xFFFFD400),
            ),
          ),
        );
      }),
    );
  }
}
