import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fonaco/features/chat/models/enums.dart';
import 'package:fonaco/features/chat/models/chat_room.dart';
import 'package:fonaco/core/utils/app_logger.dart';

/// Provider pour la gestion de la présence des utilisateurs
/// Gère le statut en ligne/hors ligne et le "vu récemment"
class PresenceProvider with ChangeNotifier {
  final AppLogger _logger = AppLogger();

  // Map userId -> PresenceStatus
  final Map<String, PresenceStatus> _userPresence = {};

  // Map userId -> DateTime (last seen)
  final Map<String, DateTime> _lastSeen = {};

  // Timer pour le cleanup des utilisateurs hors ligne
  Timer? _cleanupTimer;

  // Getters
  Map<String, PresenceStatus> get userPresence =>
      Map.unmodifiable(_userPresence);
  Map<String, DateTime> get lastSeen => Map.unmodifiable(_lastSeen);

  /// Met à jour la présence d'un utilisateur
  void updatePresence(String userId, PresenceStatus status,
      {DateTime? lastSeen}) {
    _userPresence[userId] = status;
    if (lastSeen != null) {
      _lastSeen[userId] = lastSeen;
    }

    _logger.d('User $userId presence: ${status.toJson()}');
    notifyListeners();
  }

  /// Met à jour le statut en ligne
  void setOnline(String userId) {
    updatePresence(userId, PresenceStatus.online);
  }

  /// Met à jour le statut hors ligne
  void setOffline(String userId) {
    updatePresence(userId, PresenceStatus.offline, lastSeen: DateTime.now());
  }

  /// Met à jour le statut "en train d'écrire"
  void setTyping(String userId, bool isTyping) {
    if (isTyping) {
      updatePresence(userId, PresenceStatus.busy);
    } else {
      // Retourner au statut précédent ou online
      _userPresence[userId] = PresenceStatus.online;
      notifyListeners();
    }
  }

  /// Obtient le statut de présence d'un utilisateur
  PresenceStatus getPresence(String userId) {
    return _userPresence[userId] ?? PresenceStatus.offline;
  }

  /// Obtient la date de dernière vue d'un utilisateur
  DateTime? getLastSeen(String userId) {
    return _lastSeen[userId];
  }

  /// Formate le "vu récemment" en texte lisible
  String formatLastSeen(String userId) {
    final lastSeen = _lastSeen[userId];
    if (lastSeen == null) return 'Hors ligne';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Vu il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Vu il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Vu il y a ${difference.inDays} j';
    } else {
      return 'Vu le ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }

  /// Vérifie si un utilisateur est en ligne
  bool isOnline(String userId) {
    return _userPresence[userId] == PresenceStatus.online;
  }

  /// Charge la présence depuis une liste de participants
  void loadFromParticipants(List<Participant> participants) {
    for (final participant in participants) {
      _userPresence[participant.userId] = participant.presence;
      if (participant.lastSeen != null) {
        _lastSeen[participant.userId] = participant.lastSeen!;
      }
    }
    notifyListeners();
  }

  /// Nettoie les utilisateurs hors ligne depuis longtemps
  void _cleanupOfflineUsers() {
    final now = DateTime.now();
    final toRemove = <String>[];

    for (final entry in _lastSeen.entries) {
      if (now.difference(entry.value).inDays > 7) {
        toRemove.add(entry.key);
      }
    }

    for (final userId in toRemove) {
      _userPresence.remove(userId);
      _lastSeen.remove(userId);
    }

    if (toRemove.isNotEmpty) {
      _logger.d('Cleaned up ${toRemove.length} offline users');
      notifyListeners();
    }
  }

  /// Démarre le cleanup automatique
  void startCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _cleanupOfflineUsers();
    });
  }

  /// Arrête le cleanup automatique
  void stopCleanup() {
    _cleanupTimer?.cancel();
  }

  @override
  void dispose() {
    stopCleanup();
    super.dispose();
  }
}
