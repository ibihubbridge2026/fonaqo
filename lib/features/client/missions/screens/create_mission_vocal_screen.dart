import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fonaco/core/api/base_client.dart';
import 'package:fonaco/features/client/missions/screens/vocal_validation_screen.dart';

/// Écran de création de mission par vocal - Flux "Zéro Clavier"
class CreateMissionVocalScreen extends StatefulWidget {
  const CreateMissionVocalScreen({super.key});

  @override
  State<CreateMissionVocalScreen> createState() =>
      _CreateMissionVocalScreenState();
}

class _CreateMissionVocalScreenState extends State<CreateMissionVocalScreen>
    with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final BaseClient _api = BaseClient();

  // États de l'écran
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _hasRecorded = false;
  bool _isStopping = false;
  String? _audioPath;
  String? _transcription;

  // Données extraites du backend
  Map<String, dynamic>? _extractedData;
  List<Map<String, dynamic>>? _missingFields;
  int _currentFieldIndex = 0;

  // Animation pour l'onde sonore
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _waveAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<bool> _requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission microphone requise'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/mission_vocal_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _audioRecorder
          .start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() {
        _isRecording = true;
        _audioPath = path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur enregistrement: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _isStopping) return;
    _isStopping = true;
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _hasRecorded = true;
        _audioPath = path;
        _isStopping = false;
      });
      await _sendAudioToBackend();
    } catch (e) {
      setState(() => _isStopping = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur arrêt enregistrement: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendAudioToBackend() async {
    if (_audioPath == null) return;

    setState(() => _isProcessing = true);

    try {
      final file = File(_audioPath!);
      if (!await file.exists()) {
        throw Exception('Fichier audio introuvable');
      }

      final formData = FormData.fromMap({
        'audio':
            await MultipartFile.fromFile(_audioPath!, filename: 'audio.m4a'),
      });

      final response = await _api.post(
        'missions/parse-vocal/',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        setState(() {
          _extractedData = data['extracted_data'] as Map<String, dynamic>?;
          _missingFields = (data['missing_fields'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList();
          _transcription = data['transcription'] as String?;
          _isProcessing = false;
        });
        if ((_missingFields == null || _missingFields!.isEmpty) && mounted) {
          _navigateToValidation();
        }
      } else {
        final errorMsg = () {
          final body = response.data;
          if (body is Map)
            return body['error']?.toString() ?? body['message']?.toString();
          return null;
        }();
        final code = response.statusCode;
        String userMessage;
        if (code == 422) {
          userMessage = errorMsg ??
              'Audio incompréhensible, parlez plus clairement et réessayez.';
        } else if (code == 503) {
          userMessage = errorMsg ??
              'Service de transcription indisponible. Réessayez plus tard.';
        } else {
          userMessage = errorMsg ?? 'Erreur serveur ($code). Réessayez.';
        }
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur traitement vocal: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _selectOption(String field, dynamic value) {
    setState(() {
      if (_extractedData == null) {
        _extractedData = {};
      }
      _extractedData![field] = value;
      _currentFieldIndex++;
    });

    // Vérifier si tous les champs sont remplis → naviguer vers l'écran de validation
    if (_currentFieldIndex >= (_missingFields?.length ?? 0)) {
      _navigateToValidation();
    }
  }

  void _navigateToValidation() {
    if (_extractedData == null) return;
    final data = Map<String, dynamic>.from(_extractedData!);
    if ((data['description'] as String?)?.isEmpty ?? true) {
      data['description'] = _transcription ?? '';
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VocalValidationScreen(extractedData: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Création vocale',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Moki
              _buildMokiHeader(),
              const SizedBox(height: 40),

              // Contenu principal selon l'état
              if (_isProcessing)
                _buildProcessingState()
              else if (_missingFields != null && _missingFields!.isNotEmpty)
                _buildMissingFieldsUI()
              else
                _buildRecordingUI(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMokiHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar Moki
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD400),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              size: 32,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 16),
          // Message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bonjour !',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _hasRecorded
                      ? 'J\'analyse votre demande...'
                      : 'De quel service avez-vous besoin aujourd\'hui ? Restez appuyé sur le micro et décrivez votre problème.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingUI() {
    return Column(
      children: [
        // Bouton d'enregistrement
        GestureDetector(
          onLongPressStart: (_) => _startRecording(),
          onLongPressEnd: (_) => _stopRecording(),
          child: AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? const Color(0xFFFFD400).withValues(alpha: 0.3)
                      : const Color(0xFFFFD400),
                  boxShadow: _isRecording
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFFFFD400).withValues(alpha: 0.5),
                            blurRadius: 30 * _waveAnimation.value,
                            spreadRadius: 10,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color:
                                const Color(0xFFFFD400).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                ),
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none_rounded,
                  size: 80,
                  color: Colors.black,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isRecording ? 'Enregistrement en cours...' : 'Maintenir pour parler',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        if (_hasRecorded && !_isRecording) ...[
          const SizedBox(height: 16),
          Text(
            'Relâchez pour envoyer',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProcessingState() {
    return Column(
      children: [
        const SizedBox(height: 60),
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD400)),
        ),
        const SizedBox(height: 24),
        Text(
          'Traitement en cours...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Moki analyse votre demande',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildMissingFieldsUI() {
    if (_currentFieldIndex >= (_missingFields?.length ?? 0)) {
      return _buildFinalValidation();
    }

    final currentField = _missingFields![_currentFieldIndex];
    final question = currentField['question'] as String? ?? 'Question';
    final options = currentField['options'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Options boutons
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: options.map((option) {
            final label = option['label'] as String? ?? '';
            final value = option['value'];
            return _buildOptionButton(
                label, value, currentField['field'] as String?);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOptionButton(String label, dynamic value, String? field) {
    return GestureDetector(
      onTap: () => _selectOption(field ?? '', value),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD400), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinalValidation() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.check_circle,
                size: 48,
                color: Colors.green,
              ),
              SizedBox(height: 16),
              Text(
                'Toutes les informations sont prêtes !',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _navigateToValidation,
          icon: const Icon(Icons.rocket_launch, size: 24),
          label: const Text(
            '🚀 Lancer la recherche d\'un artisan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD400),
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: const Color(0xFFFFD400).withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
