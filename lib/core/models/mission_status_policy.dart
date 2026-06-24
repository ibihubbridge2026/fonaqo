import 'mission_model.dart';

/// Source unique de vérité pour le cycle de vie des missions (miroir Django).
class MissionStatusPolicy {
  MissionStatusPolicy._();

  /// Missions actives côté agent (endpoint `missions/active/`).
  static const Set<MissionStatus> agentActive = {
    MissionStatus.ACCEPTED,
    MissionStatus.ON_THE_WAY,
    MissionStatus.ARRIVED,
    MissionStatus.IN_PROGRESS,
    MissionStatus.IN_PROGRESS_REVIEW,
  };

  /// Missions visibles dans l'onglet client « En cours » (Home + liste).
  static const Set<MissionStatus> clientOngoing = {
    MissionStatus.PENDING,
    MissionStatus.ACCEPTED,
    MissionStatus.ON_THE_WAY,
    MissionStatus.ARRIVED,
    MissionStatus.IN_PROGRESS,
    MissionStatus.IN_PROGRESS_REVIEW,
  };

  /// États terminaux — mission fermée définitivement.
  static const Set<MissionStatus> terminal = {
    MissionStatus.COMPLETED,
    MissionStatus.CANCELLED,
  };

  static bool isAgentActive(MissionStatus status) =>
      agentActive.contains(status);

  static bool isClientOngoing(MissionStatus status) =>
      clientOngoing.contains(status);

  static bool isTerminal(MissionStatus status) => terminal.contains(status);

  static bool isAwaitingClientValidation(MissionStatus status) =>
      status == MissionStatus.IN_PROGRESS_REVIEW;

  static bool isDisputed(MissionStatus status) =>
      status == MissionStatus.DISPUTED;
}
