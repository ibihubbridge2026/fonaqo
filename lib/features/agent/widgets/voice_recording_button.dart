import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/audio_service.dart';

/// Bouton d'enregistrement vocal avec logique "Hold to Record"
class VoiceRecordingButton extends StatefulWidget {
  final Function(String audioPath) onRecordingComplete;
  final VoidCallback? onCancel;

  const VoiceRecordingButton({
    super.key,
    required this.onRecordingComplete,
    this.onCancel,
  });

  @override
  State<VoiceRecordingButton> createState() => _VoiceRecordingButtonState();
}

class _VoiceRecordingButtonState extends State<VoiceRecordingButton> {
  final AudioService _audioService = AudioService();
  
  bool _isRecording = false;
  bool _isDragging = false;
  double _dragOffset = 0.0;
  Timer? _recordingTimer;
  
  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _startRecording() async {
    final success = await _audioService.startRecording();
    if (success != null) {
      setState(() {
        _isRecording = true;
        _dragOffset = 0.0;
      });
      
      // Timer pour mettre à jour l'UI
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (mounted) {
          setState(() {}); // Mettre à jour l'affichage de la durée
        }
      });
    }
  }
  
  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    
    final path = await _audioService.stopRecording();
    if (path != null && widget.onRecordingComplete != null) {
      widget.onRecordingComplete!(path);
    }
    
    setState(() {
      _isRecording = false;
      _dragOffset = 0.0;
    });
  }
  
  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await _audioService.cancelRecording();
    
    if (widget.onCancel != null) {
      widget.onCancel!();
    }
    
    setState(() {
      _isRecording = false;
      _dragOffset = 0.0;
    });
  }
  
  void _onPanStart(DragStartDetails details) {
    if (!_isRecording) {
      _startRecording();
    }
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    if (_isRecording) {
      setState(() {
        _dragOffset += details.delta.dx;
      });
      
      // Vérifier si l'utilisateur a glissé assez loin pour annuler
      if (_dragOffset < -100) { // 100px vers la gauche
        _cancelRecording();
      }
    }
  }
  
  void _onPanEnd(DragEndDetails details) {
    if (_isRecording) {
      if (_dragOffset > -100) {
        _stopRecording();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isRecording) {
      return _buildRecordingInterface();
    } else {
      return _buildMicrophoneButton();
    }
  }
  
  Widget _buildMicrophoneButton() {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD400),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD400).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.mic,
          color: Colors.black,
          size: 24,
        ),
      ),
    );
  }
  
  Widget _buildRecordingInterface() {
    return Transform.translate(
      offset: Offset(_dragOffset, 0),
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Icône d'annulation
            if (_dragOffset < -50)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 20,
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            
            const SizedBox(width: 16),
            
            // Timer et ondes sonores
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _audioService.formatDuration(_audioService.recordingDuration),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dragOffset < -50 ? 'Glisser pour annuler' : 'Enregistrement...',
                    style: TextStyle(
                      fontSize: 12,
                      color: _dragOffset < -50 ? Colors.red : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Ondes sonores animées
                  Row(
                    children: List.generate(5, (index) {
                      final height = 20.0 + (_audioService.recordingDuration.inMilliseconds % 1000) / 100 * (index % 2 == 0 ? 10 : -10);
                      return Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 3,
                          height: height.clamp(8.0, 30.0),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            
            // Indicateur de glissement
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _dragOffset < -50 ? Icons.arrow_back : Icons.arrow_forward,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
