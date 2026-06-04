import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fonaco/core/utils/app_logger.dart';

/// Service pour l'enregistrement de messages vocaux
class AudioRecorderService {
  static final AudioRecorderService _instance = AudioRecorderService._internal();
  factory AudioRecorderService() => _instance;
  AudioRecorderService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AppLogger _logger = AppLogger();

  String? _currentRecordingPath;
  bool _isRecording = false;
  bool _isPaused = false;
  Timer? _recordingTimer;
  int _recordingDuration = 0; // en secondes

  // Stream pour les mises à jour de durée
  final StreamController<int> _durationController = StreamController.broadcast();
  Stream<int> get durationStream => _durationController.stream;

  // Stream pour les mises à jour d'amplitude (visualisation)
  final StreamController<double> _amplitudeController = StreamController.broadcast();
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  /// Vérifie et demande les permissions
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _logger.i('Microphone permission granted');
      return true;
    }
    _logger.w('Microphone permission denied');
    return false;
  }

  /// Démarre l'enregistrement
  Future<String?> startRecording() async {
    if (_isRecording) {
      _logger.w('Recording already in progress');
      return _currentRecordingPath;
    }

    try {
      // Vérifier la permission
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return null;
      }

      // Vérifier si le recorder est disponible
      if (!await _recorder.hasPermission()) {
        _logger.w('Recorder permission not available');
        return null;
      }

      // Générer le chemin du fichier
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/chat_audio_$timestamp.m4a';

      _logger.i('Starting recording to: $_currentRecordingPath');

      // Configurer l'enregistrement
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _isPaused = false;
      _recordingDuration = 0;

      // Démarrer le timer de durée
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _recordingDuration++;
        _durationController.add(_recordingDuration);

        // Mettre à jour l'amplitude pour la visualisation
        _updateAmplitude();
      });

      _logger.i('Recording started');
      return _currentRecordingPath;
    } catch (e) {
      _logger.e('Error starting recording: $e');
      return null;
    }
  }

  /// Met en pause l'enregistrement
  Future<void> pauseRecording() async {
    if (!_isRecording || _isPaused) return;

    try {
      await _recorder.pause();
      _isPaused = true;
      _recordingTimer?.cancel();
      _logger.i('Recording paused');
    } catch (e) {
      _logger.e('Error pausing recording: $e');
    }
  }

  /// Reprend l'enregistrement
  Future<void> resumeRecording() async {
    if (!_isRecording || !_isPaused) return;

    try {
      await _recorder.resume();
      _isPaused = false;

      // Redémarrer le timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _recordingDuration++;
        _durationController.add(_recordingDuration);
        _updateAmplitude();
      });

      _logger.i('Recording resumed');
    } catch (e) {
      _logger.e('Error resuming recording: $e');
    }
  }

  /// Arrête l'enregistrement et retourne le fichier
  Future<File?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      _recordingTimer?.cancel();
      final path = await _recorder.stop();

      _isRecording = false;
      _isPaused = false;

      if (path != null && _currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        final size = await file.length();
        _logger.i('Recording stopped: ${_recordingDuration}s, ${(size / 1024).toStringAsFixed(2)} KB');
        return file;
      }

      return null;
    } catch (e) {
      _logger.e('Error stopping recording: $e');
      return null;
    }
  }

  /// Annule l'enregistrement et supprime le fichier
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      _recordingTimer?.cancel();
      await _recorder.stop();

      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          _logger.i('Recording cancelled and file deleted');
        }
      }

      _isRecording = false;
      _isPaused = false;
      _currentRecordingPath = null;
      _recordingDuration = 0;
    } catch (e) {
      _logger.e('Error cancelling recording: $e');
    }
  }

  /// Met à jour l'amplitude pour la visualisation
  Future<void> _updateAmplitude() async {
    try {
      final amplitude = await _recorder.getAmplitude();
      _amplitudeController.add(amplitude.current);
    } catch (e) {
      // Ignorer les erreurs d'amplitude
    }
  }

  /// Formate la durée en format lisible
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Nettoyage
  void dispose() {
    _recordingTimer?.cancel();
    _durationController.close();
    _amplitudeController.close();
    _recorder.dispose();
  }

  // Getters
  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  int get recordingDuration => _recordingDuration;
  String? get currentRecordingPath => _currentRecordingPath;
}
