import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Supprime les enregistrements vocaux temporaires créés lors de la création de mission.
class MissionAudioCleanup {
  MissionAudioCleanup._();

  static Future<void> purgeTemporaryRecordings() async {
    try {
      final dir = await getTemporaryDirectory();
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (name.startsWith('mission_voice_') && name.endsWith('.m4a')) {
          await entity.delete();
        }
      }
    } catch (_) {
      // Nettoyage best-effort — ne bloque pas le flux utilisateur.
    }
  }
}
