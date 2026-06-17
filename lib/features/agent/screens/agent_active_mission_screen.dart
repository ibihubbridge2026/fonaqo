import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../presentation/mission/widgets/mission_step_timeline.dart';
import '../presentation/mission/widgets/completion_proof_sheet.dart';
import '../widgets/dispute_bottom_sheet.dart';
import '../providers/agent_provider.dart';
import '../services/mission_timeline_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/location_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/mission_model.dart';
import 'dart:convert';

class AgentActiveMissionScreen extends StatefulWidget {
  final MissionModel mission;

  const AgentActiveMissionScreen({
    super.key,
    required this.mission,
  });

  @override
  State<AgentActiveMissionScreen> createState() =>
      _AgentActiveMissionScreenState();
}

class _AgentActiveMissionScreenState extends State<AgentActiveMissionScreen> {
  final Logger _logger = Logger();
  final LocationService _locationService = LocationService();
  final MissionTimelineService _timelineService = MissionTimelineService();

  // GPS Tracking
  StreamSubscription<Position>? _gpsSubscription;
  WebSocketChannel? _gpsWebSocket;
  bool _isGpsTracking = false;
  bool _isProcessing = false;
  bool _isDisputed = false;
  late MissionModel _mission;
  late final String _missionId;

  // GPS WebSocket Resilience
  Timer? _gpsReconnectTimer;
  Timer? _gpsHeartbeatTimer;
  int _gpsReconnectAttempts = 0;
  final List<int> _gpsReconnectDelays = [
    2,
    5,
    10,
    30
  ]; // Exponential backoff in seconds
  final List<Map<String, dynamic>> _gpsQueue = []; // Queue for offline GPS data
  DateTime? _lastGpsPongTime;
  String? _gpsToken;
  String? _gpsAgentId;

  String? get _primaryActionLabel {
    switch (_mission.status) {
      case MissionStatus.ACCEPTED:
        return 'Démarrer le trajet';
      case MissionStatus.ON_THE_WAY:
        return 'Je suis arrivé sur place';
      case MissionStatus.ARRIVED:
        return 'Commencer la mission';
      case MissionStatus.IN_PROGRESS:
        return 'Clôturer et envoyer la preuve';
      default:
        return null;
    }
  }

  String? get _nextStatusApi {
    switch (_mission.status) {
      case MissionStatus.ACCEPTED:
        return 'ON_THE_WAY';
      case MissionStatus.ON_THE_WAY:
        return 'ARRIVED';
      case MissionStatus.ARRIVED:
        return 'IN_PROGRESS';
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _mission = widget.mission;
    _missionId = _mission.id;
    _startGpsTracking();
    _initializeTimeline();
  }

  @override
  Widget build(BuildContext context) {
    final status = _mission.status;
    final showAction = _mission.status != MissionStatus.IN_PROGRESS_REVIEW &&
        _mission.status != MissionStatus.COMPLETED &&
        _primaryActionLabel != null &&
        !_isDisputed;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // Bandeau de statut coloré
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: status.badgeBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _mission.formattedStatus,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: status.badgeColor,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: status.badgeColor),
                        onSelected: (value) {
                          if (value == 'dispute') _showDisputeBottomSheet();
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'dispute',
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Signaler un problème'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_mission.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _mission.description,
                      style: const TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bannière de litige si applicable
            if (_isDisputed)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mission suspendue - Un administrateur FONAQO examine votre cas',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Bannière de reconnexion GPS si applicable
            if (_gpsReconnectTimer != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Reconnexion GPS en cours...',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CARTE CLIENT
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: widget.mission.avatarUrl != null
                                ? CachedNetworkImageProvider(
                                    widget.mission.avatarUrl!) as ImageProvider
                                : null,
                            backgroundColor: const Color(0xFFFFD54F),
                            child: widget.mission.avatarUrl == null
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.black,
                                    size: 30,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.mission.clientName ?? 'Client',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.mission.isUrgent == true
                                      ? 'Client vérifié • Livraison urgente'
                                      : 'Client vérifié',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              // TODO: Replace with actual client phone number from mission model
                              final phoneNumber = '+22900000000'; // Placeholder
                              final Uri phoneUri =
                                  Uri(scheme: 'tel', path: phoneNumber);
                              if (await canLaunchUrl(phoneUri)) {
                                await launchUrl(phoneUri);
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Impossible de lancer l\'appel')),
                                  );
                                }
                              }
                            },
                            child: Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.call,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // CARTE TRAJET
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Column(
                                children: [
                                  Container(
                                    height: 14,
                                    width: 14,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 50,
                                    color: Colors.grey.shade300,
                                  ),
                                  Container(
                                    height: 14,
                                    width: 14,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Départ",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.mission.address ?? 'Non spécifié',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Color(0xFF000000),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    const Text(
                                      "Destination",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.mission.destinationAddress ??
                                          widget.mission.address ??
                                          'Non spécifié',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Color(0xFF000000),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMiniStat(
                                "Gain",
                                "${widget.mission.price?.toStringAsFixed(0) ?? '0'} FCFA",
                                Icons.payments,
                              ),
                              _buildMiniStat(
                                "Catégorie",
                                widget.mission.category ?? 'Livraison',
                                Icons.category,
                              ),
                              _buildMiniStat(
                                "Urgence",
                                widget.mission.isUrgent == true ? "Oui" : "Non",
                                Icons.priority_high,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ÉTAPES
                    const Text(
                      "Progression",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 18),

                    MissionStepTimeline(currentStatus: _mission.status),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Barre d'actions en bas
            if (_mission.status == MissionStatus.IN_PROGRESS_REVIEW)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text(
                    'En attente de validation client',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
              )
            else if (showAction)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handlePrimaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD400),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            _primaryActionLabel!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              )
            else if (_isDisputed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: const Text(
                  'Mission suspendue (litige ouvert)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(
    String title,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6D8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFC79A00),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Future<void> _handlePrimaryAction() async {
    if (_mission.status == MissionStatus.IN_PROGRESS) {
      await CompletionProofSheet.show(context, missionId: _missionId);
      return;
    }

    final nextStatus = _nextStatusApi;
    if (nextStatus != null) {
      await _updateMissionStep(nextStatus);
    }
  }

  /// Met à jour l'étape de la mission via la machine à états.
  Future<void> _updateMissionStep(String status) async {
    HapticFeedback.lightImpact();
    setState(() => _isProcessing = true);

    try {
      await _locationService.getCurrentLocation();
      final position = _locationService.currentPosition;

      final success = await context
          .read<AgentProvider>()
          .missionRepository
          .updateSteps(
            _missionId,
            status,
            latitude: position?.latitude,
            longitude: position?.longitude,
          );

      if (!mounted) return;

      if (success) {
        setState(() {
          _mission = _mission.copyWith(
            status: MissionModel.parseMissionStatus(status.toLowerCase()),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Étape enregistrée : $status'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour de l\'étape'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Démarre le tracking GPS
  Future<void> _startGpsTracking() async {
    if (_isGpsTracking) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.getToken();
      final agentId = authProvider.currentUser?.id;

      if (agentId == null || token == null) {
        _logger.e('Erreur: Agent ID ou token non disponible');
        return;
      }

      // Store for reconnection
      _gpsToken = token;
      _gpsAgentId = agentId;

      // Connecter au WebSocket GPS avec authentification
      final wsUrl = ApiConfig.wsUrl(
        '/ws/gps/$_missionId/',
        query: {'token': token},
      );
      _gpsWebSocket = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen for WebSocket messages (pong, errors, disconnection)
      _gpsWebSocket?.stream.listen(
        (message) {
          try {
            final data = json.decode(message) as Map<String, dynamic>;
            if (data['type'] == 'pong') {
              _lastGpsPongTime = DateTime.now();
              _logger.d('GPS Pong received');
            }
          } catch (e) {
            _logger.e('Error parsing GPS WebSocket message: $e');
          }
        },
        onError: (error) {
          _logger.e('GPS WebSocket error: $error');
          _handleGpsDisconnection();
        },
        onDone: () {
          _logger.w('GPS WebSocket disconnected');
          _handleGpsDisconnection();
        },
        cancelOnError: true,
      );

      // Start heartbeat
      _startGpsHeartbeat();

      // Reset reconnection attempts on successful connection
      _gpsReconnectAttempts = 0;
      _lastGpsPongTime = DateTime.now();

      // Démarrer le stream GPS
      _gpsSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Mettre à jour tous les 10m
        ),
      ).listen(
        (Position position) {
          if (_gpsWebSocket != null) {
            _sendGpsCoordinates(position, agentId);
          } else {
            // Queue GPS data for later
            _gpsQueue.add({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'accuracy': position.accuracy,
              'timestamp': DateTime.now().toIso8601String(),
              'speed': position.speed,
              'heading': position.heading,
            });
          }
        },
        onError: (error) {
          _logger.e('Erreur GPS: $error');
        },
      );

      setState(() {
        _isGpsTracking = true;
      });

      _logger.d(
          'GPS tracking démarré pour mission $_missionId avec agent $agentId');
    } catch (e) {
      _logger.e('Erreur démarrage GPS: $e');
      _handleGpsDisconnection();
    }
  }

  /// Start GPS heartbeat ping/pong
  void _startGpsHeartbeat() {
    _gpsHeartbeatTimer?.cancel();
    _gpsHeartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_gpsWebSocket != null) {
        _gpsWebSocket?.sink.add(json.encode({'type': 'ping'}));
        _logger.d('GPS Heartbeat ping sent');

        // Check if we received a pong in the last 60 seconds
        if (_lastGpsPongTime != null &&
            DateTime.now().difference(_lastGpsPongTime!).inSeconds > 60) {
          _logger
              .w('No GPS pong received for 60 seconds, connection may be dead');
          _handleGpsDisconnection();
        }
      }
    });
  }

  /// Handle GPS WebSocket disconnection and trigger reconnection
  void _handleGpsDisconnection() {
    if (_gpsWebSocket != null) {
      _gpsWebSocket?.sink.close();
      _gpsWebSocket = null;
    }

    _isGpsTracking = false;

    // Schedule reconnection with exponential backoff
    _scheduleGpsReconnect();
  }

  /// Schedule GPS WebSocket reconnection with exponential backoff
  void _scheduleGpsReconnect() {
    if (_gpsToken == null || _gpsAgentId == null) {
      _logger.w('Cannot reconnect GPS: no token/agent context');
      return;
    }

    _gpsReconnectTimer?.cancel();

    final delayIndex = _gpsReconnectAttempts < _gpsReconnectDelays.length
        ? _gpsReconnectAttempts
        : _gpsReconnectDelays.length - 1;
    final delaySeconds = _gpsReconnectDelays[delayIndex];

    _logger.d(
        'Scheduling GPS reconnection in ${delaySeconds}s (attempt ${_gpsReconnectAttempts + 1})');

    _gpsReconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      _gpsReconnectAttempts++;
      try {
        _logger.d('Attempting GPS reconnection...');
        _startGpsTracking();

        // If successful, send queued GPS data
        if (_isGpsTracking && _gpsQueue.isNotEmpty) {
          _logger.d('Sending ${_gpsQueue.length} queued GPS points');
          for (final gpsData in List.from(_gpsQueue)) {
            try {
              _gpsWebSocket?.sink.add(json.encode({
                'type': 'gps_update',
                'mission_id': _missionId,
                'agent_id': _gpsAgentId,
                ...gpsData,
              }));
              _gpsQueue.remove(gpsData);
            } catch (e) {
              _logger.e('Failed to send queued GPS data: $e');
            }
          }
        }
      } catch (e) {
        _logger.e('GPS reconnection failed: $e');
        _scheduleGpsReconnect();
      }
    });
  }

  /// Arrête le tracking GPS
  void _stopGpsTracking() {
    if (!_isGpsTracking) return;

    _gpsReconnectTimer?.cancel();
    _gpsHeartbeatTimer?.cancel();
    _gpsReconnectTimer = null;
    _gpsHeartbeatTimer = null;
    _gpsReconnectAttempts = 0;

    _gpsSubscription?.cancel();
    _gpsWebSocket?.sink.close();
    _gpsSubscription = null;
    _gpsWebSocket = null;
    _gpsQueue.clear();

    setState(() {
      _isGpsTracking = false;
    });

    _logger.d('GPS tracking arrêté');
  }

  /// Envoie les coordonnées GPS via WebSocket
  void _sendGpsCoordinates(Position position, String agentId) {
    if (_gpsWebSocket == null) return;

    final gpsData = {
      'type': 'gps_update',
      'mission_id': _missionId,
      'agent_id': agentId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'timestamp': DateTime.now().toIso8601String(),
      'speed': position.speed,
      'heading': position.heading,
    };

    try {
      _gpsWebSocket!.sink.add(json.encode(gpsData));
      _logger.d(
          'Coordonnées GPS envoyées: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      _logger.e('Erreur envoi GPS: $e');
    }
  }

  /// Initialise la timeline WebSocket (tracking temps réel).
  void _initializeTimeline() {
    _timelineService.connectToTimeline(_missionId, (stepData) {
      _logger.d('Timeline update: $stepData');
    });
  }

  /// Affiche le BottomSheet de litige.
  void _showDisputeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DisputeBottomSheet(
        missionId: _missionId,
        onDisputeOpened: () {
          setState(() {
            _isDisputed = true;
          });
        },
      ),
    );
  }


  @override
  void dispose() {
    _stopGpsTracking();
    _gpsReconnectTimer?.cancel();
    _gpsHeartbeatTimer?.cancel();
    super.dispose();
  }
}
