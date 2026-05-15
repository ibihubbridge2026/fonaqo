import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Service pour gérer les sons de notification
class SoundNotificationService {
  static final SoundNotificationService _instance =
      SoundNotificationService._internal();
  factory SoundNotificationService() => _instance;
  SoundNotificationService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  /// Initialise le service et charge les sons
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configurer le lecteur pour jouer par le haut-parleur
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      _isInitialized = true;
    } catch (e) {
      print('Erreur initialisation SoundNotificationService: $e');
    }
  }

  /// Joue un son de notification pour nouveau message
  Future<void> playNewMessageSound() async {
    await initialize();

    try {
      // Essayer de jouer le son personnalisé d'abord
      final customSound = await _getCustomSoundPath('notification.mp3');
      if (await File(customSound).exists()) {
        await _audioPlayer.play(DeviceFileSource(customSound));
      } else {
        // Son par défaut système
        await _playSystemNotificationSound();
      }
    } catch (e) {
      print('Erreur lecture son message: $e');
      // Fallback vers son système
      await _playSystemNotificationSound();
    }
  }

  /// Joue un son pour mission acceptée
  Future<void> playMissionAcceptedSound() async {
    await initialize();

    try {
      final customSound = await _getCustomSoundPath('mission_accepted.mp3');
      if (await File(customSound).exists()) {
        await _audioPlayer.play(DeviceFileSource(customSound));
      } else {
        // Son système de notification
        await _playSystemNotificationSound();
      }
    } catch (e) {
      print('Erreur lecture son mission acceptée: $e');
      await _playSystemNotificationSound();
    }
  }

  /// Joue un son pour succès financier
  Future<void> playFinancialSuccessSound() async {
    await initialize();

    try {
      final customSound = await _getCustomSoundPath('success.mp3');
      if (await File(customSound).exists()) {
        await _audioPlayer.play(DeviceFileSource(customSound));
      } else {
        // Son système de succès
        await _playSystemSuccessSound();
      }
    } catch (e) {
      print('Erreur lecture son succès financier: $e');
      await _playSystemSuccessSound();
    }
  }

  /// Joue un son pour erreur
  Future<void> playErrorSound() async {
    await initialize();

    try {
      final customSound = await _getCustomSoundPath('error.mp3');
      if (await File(customSound).exists()) {
        await _audioPlayer.play(DeviceFileSource(customSound));
      } else {
        // Son système d'erreur
        await _playSystemErrorSound();
      }
    } catch (e) {
      print('Erreur lecture son erreur: $e');
      await _playSystemErrorSound();
    }
  }

  /// Joue un son pour mission terminée
  Future<void> playMissionCompletedSound() async {
    await initialize();

    try {
      final customSound = await _getCustomSoundPath('mission_completed.mp3');
      if (await File(customSound).exists()) {
        await _audioPlayer.play(DeviceFileSource(customSound));
      } else {
        await _playSystemSuccessSound(); // Réutiliser le son de succès
      }
    } catch (e) {
      print('Erreur lecture son mission terminée: $e');
      await _playSystemSuccessSound();
    }
  }

  /// Joue le son de notification système
  Future<void> _playSystemNotificationSound() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      print('Erreur son système notification: $e');
    }
  }

  /// Joue le son de succès système
  Future<void> _playSystemSuccessSound() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      print('Erreur son système succès: $e');
      // Fallback vers notification
      await _playSystemNotificationSound();
    }
  }

  /// Joue le son d'erreur système
  Future<void> _playSystemErrorSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      print('Erreur son système erreur: $e');
    }
  }

  /// Retourne le chemin d'un son personnalisé dans les assets
  Future<String> _getCustomSoundPath(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/sounds/$fileName';
    } catch (e) {
      print('Erreur obtention chemin son: $e');
      rethrow;
    }
  }

  /// Arrête la lecture en cours
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Erreur arrêt son: $e');
    }
  }

  /// Définit le volume (0.0 à 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
    } catch (e) {
      print('Erreur définition volume: $e');
    }
  }

  /// Dispose les ressources
  void dispose() {
    _audioPlayer.dispose();
    _isInitialized = false;
  }
}
