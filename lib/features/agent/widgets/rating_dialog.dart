import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../providers/agent_provider.dart';
import '../repository/agent_repository.dart';

/// Dialogue de notation pour évaluer une mission terminée
class RatingDialog extends StatefulWidget {
  final String missionId;
  final Function(int rating, String comment) onRatingSubmitted;

  const RatingDialog({
    super.key,
    required this.missionId,
    required this.onRatingSubmitted,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD400).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Color(0xFFFFD400),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mission terminée !',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Comment s\'est passée la mission ?',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF757575), // grey[600]
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Barre de notation
            Column(
              children: [
                RatingBar.builder(
                  initialRating: 5,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Color(0xFFFFD400),
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating.toInt();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _getRatingText(_rating),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getRatingColor(_rating),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Champ commentaire
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Partagez votre expérience (optionnel)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFD400)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Plus tard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD400),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Envoyer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Soumet la note
  Future<void> _submitRating() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final agentProvider = Provider.of<AgentProvider>(context, listen: false);
      final success = await agentProvider.submitReview(
        widget.missionId,
        _rating,
        _commentController.text.trim(),
      );

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci pour votre avis!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Échec de la soumission');
      }
      await widget.onRatingSubmitted(_rating, _commentController.text.trim());
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Retourne le texte de la note
  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Très insatisfait';
      case 2:
        return 'Insatisfait';
      case 3:
        return 'Neutre';
      case 4:
        return 'Satisfait';
      case 5:
        return 'Très satisfait';
      default:
        return 'Neutre';
    }
  }

  /// Retourne la couleur de la note
  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.grey;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
