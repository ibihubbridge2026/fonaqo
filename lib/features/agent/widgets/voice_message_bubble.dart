import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/services/audio_service.dart';

/// Bulle pour afficher et jouer les messages vocaux
class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final Duration duration;
  final bool isMe;
  final VoidCallback? onDelete;

  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.duration,
    required this.isMe,
    this.onDelete,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  final AudioService _audioService = AudioService();

  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();

    // Écouter les changements de position
    _player.onPositionChanged.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });

    // Écouter la fin de lecture
    _player.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
      _positionTimer?.cancel();
    });
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
      _positionTimer?.cancel();
    } else {
      // Configurer pour jouer par le haut-parleur
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.play(UrlSource(widget.audioUrl));

      // Démarrer le timer pour suivre la progression
      _positionTimer =
          Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_currentPosition < widget.duration) {
          // La position sera mise à jour via onPositionChanged
        } else {
          timer.cancel();
        }
      });
    }

    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  double get _progress => widget.duration.inMilliseconds > 0
      ? _currentPosition.inMilliseconds / widget.duration.inMilliseconds
      : 0.0;

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
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bulle principale
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Onde sonore et contrôles
                Row(
                  children: [
                    // Bouton play/pause
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.isMe
                              ? Colors.black
                              : const Color(0xFFFFD400),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: widget.isMe
                              ? const Color(0xFFFFD400)
                              : Colors.black,
                          size: 24,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Onde sonore animée
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Barre de progression
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: widget.isMe
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: widget.isMe
                                      ? Colors.black
                                      : const Color(0xFFFFD400),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Durées
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _audioService.formatDuration(_currentPosition),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isMe
                                      ? Colors.black.withOpacity(0.7)
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _audioService.formatDuration(widget.duration),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isMe
                                      ? Colors.black.withOpacity(0.7)
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Ondes sonores visuelles
                    const SizedBox(width: 8),
                    _buildSoundWaves(),
                  ],
                ),
              ],
            ),
          ),

          // Timestamp
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _audioService.formatDuration(widget.duration),
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

  Widget _buildSoundWaves() {
    return Column(
      children: List.generate(3, (index) {
        final height = _isPlaying
            ? [20.0, 12.0, 16.0][index] +
                (_currentPosition.inMilliseconds % 1000) / 100 * 8
            : [20.0, 12.0, 16.0][index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 3,
            height: height.clamp(8.0, 28.0),
            decoration: BoxDecoration(
              color: widget.isMe
                  ? Colors.black.withOpacity(0.4)
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        );
      }),
    );
  }
}
