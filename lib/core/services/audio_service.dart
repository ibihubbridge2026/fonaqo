import 'dart:io';
import 'dart:async';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

/// Service pour gérer l'enregistrement et la lecture des messages vocaux
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final Logger _logger = Logger();

  String? _currentRecordingPath;
  bool _isRecording = false;
  bool _isPlaying = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  Duration get recordingDuration => _recordingDuration;
  String? get currentRecordingPath => _currentRecordingPath;

  /// Vérifie et demande les permissions microphone
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      _logger.d('Permission microphone: $status');
      return status.isGranted;
    } catch (e) {
      _logger.e('Erreur permission microphone: $e');
      return false;
    }
  }

  /// Démarre l'enregistrement audio
  Future<String?> startRecording() async {
    if (_isRecording) return null;

    // Vérifier les permissions
    final hasPermission = await requestMicrophonePermission();
    if (!hasPermission) {
      _logger.e('Permission microphone refusée');
      return null;
    }

    try {
      // Créer le répertoire temporaire si nécessaire
      final directory = await getTemporaryDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      // Générer un nom de fichier unique
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'voice_$timestamp.m4a';
      final filePath = '${recordingsDir.path}/$fileName';

      // Configurer l'enregistrement
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      _isRecording = true;
      _currentRecordingPath = filePath;
      _recordingDuration = Duration.zero;

      // Démarrer le timer pour suivre la durée
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration =
            Duration(seconds: _recordingDuration.inSeconds + 1);
      });

      _logger.d('Enregistrement démarré: $filePath');
      return filePath;
    } catch (e) {
      _logger.e('Erreur démarrage enregistrement: $e');
      return null;
    }
  }

  /// Arrête l'enregistrement et retourne le chemin du fichier
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      _recordingTimer?.cancel();

      final path = await _recorder.stop();
      _isRecording = false;
      _recordingDuration = Duration.zero;

      _logger.d('Enregistrement arrêté: $path');
      return path;
    } catch (e) {
      _logger.e('Erreur arrêt enregistrement: $e');
      return null;
    }
  }

  /// Annule l'enregistrement et supprime le fichier
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      _recordingTimer?.cancel();
      await _recorder.cancel();

      // Supprimer le fichier temporaire
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _isRecording = false;
      _currentRecordingPath = null;
      _recordingDuration = Duration.zero;

      _logger.d('Enregistrement annulé');
    } catch (e) {
      _logger.e('Erreur annulation enregistrement: $e');
    }
  }

  /// Joue un fichier audio
  Future<bool> playAudio(String filePath) async {
    try {
      if (_isPlaying) {
        await _player.stop();
      }

      // Configurer pour jouer par le haut-parleur
      await _player.setPlayerMode(PlayerMode.mediaPlayer);

      await _player.play(DeviceFileSource(filePath));
      _isPlaying = true;

      // Écouter la fin de lecture
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
      });

      _logger.d('Lecture audio démarrée: $filePath');
      return true;
    } catch (e) {
      _logger.e('Erreur lecture audio: $e');
      return false;
    }
  }

  /// Met en pause la lecture audio
  Future<void> pauseAudio() async {
    try {
      await _player.pause();
      _isPlaying = false;
      _logger.d('Lecture audio mise en pause');
    } catch (e) {
      _logger.e('Erreur pause audio: $e');
    }
  }

  /// Arrête la lecture audio
  Future<void> stopAudio() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _logger.d('Lecture audio arrêtée');
    } catch (e) {
      _logger.e('Erreur arrêt audio: $e');
    }
  }

  /// Convertit la durée en format texte (MM:SS)
  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Dispose les ressources
  void dispose() {
    _recordingTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
  }
}
