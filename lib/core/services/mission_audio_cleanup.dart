import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Supprime les enregistrements audio temporaires du téléphone.
class MissionAudioCleanup {
  MissionAudioCleanup._();

  static Future<void> purgeTemporaryRecordings() async {
    try {
      final dir = await getTemporaryDirectory();
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (name.startsWith('mission_voice_') ||
            name.startsWith('voice_') ||
            name.startsWith('audio_')) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
