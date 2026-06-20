import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/core/services/gps_websocket_service.dart';
import 'package:fonaco/features/chat/chat_repository.dart';
import 'package:fonaco/features/client/missions/mission_repository.dart';
import 'package:fonaco/features/client/missions/widgets/mission_rating_dialog.dart';
import 'package:fonaco/features/rating/models/rating.dart';
import 'package:fonaco/features/rating/repositories/rating_repository.dart';
import 'package:fonaco/widgets/custom_app_bar.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

/// Suivi GPS live + barre de statut (ACCEPTED → IN_PROGRESS → COMPLETED).
class MissionTrackingScreen extends StatefulWidget {
  final String missionId;

  const MissionTrackingScreen({super.key, required this.missionId});

  @override
  State<MissionTrackingScreen> createState() => _MissionTrackingScreenState();
}

class _MissionTrackingScreenState extends State<MissionTrackingScreen> {
  final MissionRepository _repo = MissionRepository();
  final GpsWebSocketService _gps = GpsWebSocketService();
  final MapController _mapController = MapController();
  final ChatRepository _chatRepo = ChatRepository();
  final Logger _logger = Logger();

  MissionModel? _mission;
  bool _loading = true;
  String? _error;
  bool _actionBusy = false;
  bool _isChatLoading = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final m = await _repo.fetchMissionDetails(widget.missionId);
      if (!mounted) return;
      setState(() {
        _mission = m;
        _loading = false;
      });
      try {
        await _gps.connect(widget.missionId);
        _gps.addListener(_onGpsUpdate);
        _maybeStartAgentTicker();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('WebSocket GPS : $e')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onGpsUpdate() {
    if (!mounted) return;
    if (_gps.agentPosition != null) {
      try {
        _mapController.move(_gps.agentPosition!, _mapController.camera.zoom);
      } catch (e) {
        _logger.w('Erreur déplacement caméra GPS', error: e);
      }
    }
    setState(() {});
  }

  void _maybeStartAgentTicker() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAgent || _mission == null) return;
    if (_mission!.status != MissionStatus.IN_PROGRESS) return;
    _gps.startAgentLocationTicker(() {
      if (!mounted) return false;
      return _mission?.status == MissionStatus.IN_PROGRESS;
    });
  }

  MissionStatus get _effectiveStatus {
    final raw = _gps.liveStatus ?? _mission?.status.name;
    return MissionModel.parseMissionStatus(raw);
  }

  LatLng? get _destination {
    final lat = _gps.destinationLat ?? _mission?.latitude;
    final lng = _gps.destinationLng ?? _mission?.longitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  LatLng? get _agentMarker => _gps.agentPosition;

  int get _progressStep {
    final s = _effectiveStatus;
    if (s == MissionStatus.COMPLETED) return 2;
    if (s == MissionStatus.IN_PROGRESS) return 1;
    if (s == MissionStatus.ACCEPTED ||
        s == MissionStatus.ON_THE_WAY ||
        s == MissionStatus.ARRIVED) {
      return 0;
    }
    return 0;
  }

  Future<void> _startMission() async {
    setState(() => _actionBusy = true);
    try {
      final m = await _repo.startMission(widget.missionId);
      if (!mounted) return;
      setState(() => _mission = m);
      _maybeStartAgentTicker();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec démarrage : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _completeMission() async {
    setState(() => _actionBusy = true);
    try {
      final m = await _repo.markMissionCompletedLive(widget.missionId);
      if (!mounted) return;
      setState(() => _mission = m);
      _gps.stopAgentLocationTicker();

      // Show rating dialog after mission completion
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => MissionRatingDialog(
            missionId: widget.missionId,
            onSubmit: (rating, comment) async {
              final ratingRepo = RatingRepository();
              try {
                await ratingRepo.submitRating(
                  missionId: widget.missionId,
                  ratedId: '', // Backend will infer from mission context
                  score: rating,
                  type: RatingType.clientRatesAgent,
                  comment: comment,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Évaluation envoyée avec succès')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur envoi évaluation: $e')),
                  );
                }
              }
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec clôture : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  @override
  void dispose() {
    _gps.removeListener(_onGpsUpdate);
    _gps.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dest = _destination;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CustomAppBar.detailStack(
        title: 'Suivi mission',
        detailTitleWidget: Text(
          _mission?.title ?? 'Mission',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        detailTrailingActions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.black),
            onPressed: () async {
              HapticFeedback.lightImpact();
              final phoneNumber = _mission?.agentPhone ?? '';
              if (phoneNumber.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Numéro de téléphone non disponible')),
                  );
                }
                return;
              }
              final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
              if (await canLaunchUrl(phoneUri)) {
                await launchUrl(phoneUri);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Impossible de lancer l\'appel')),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.black),
            onPressed: _handleChatButton,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : Column(
                  children: [
                    _StatusProgressBar(currentStep: _progressStep),
                    if (_gps.lastError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Text(
                          _gps.lastError!,
                          style:
                              TextStyle(color: Colors.red[800], fontSize: 12),
                        ),
                      ),
                    Expanded(
                      child: dest == null
                          ? const Center(
                              child: Text(
                                  'Coordonnées de destination indisponibles.'),
                            )
                          : ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _agentMarker ?? dest,
                                  initialZoom: 14,
                                  minZoom: 5,
                                  maxZoom: 18,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.all,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.fonaco',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: dest,
                                        width: 44,
                                        height: 44,
                                        child: _mapPin(
                                          color: Colors.redAccent,
                                          icon: Icons.flag,
                                        ),
                                      ),
                                      if (_agentMarker != null)
                                        Marker(
                                          point: _agentMarker!,
                                          width: 44,
                                          height: 44,
                                          child: _mapPin(
                                            color: const Color(0xFFFFD400),
                                            icon: Icons.delivery_dining,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                    ),
                    _bottomPanel(auth),
                  ],
                ),
    );
  }

  Widget _mapPin({required Color color, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }

  Widget _bottomPanel(AuthProvider auth) {
    final m = _mission;
    if (m == null) return const SizedBox.shrink();

    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Statut : ${_effectiveStatus.label}',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                m.address ?? m.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.black87, fontSize: 13),
              ),
              if (auth.isAgent) ...[
                const SizedBox(height: 12),
                if (_effectiveStatus == MissionStatus.ACCEPTED ||
                    _effectiveStatus == MissionStatus.ON_THE_WAY ||
                    _effectiveStatus == MissionStatus.ARRIVED)
                  FilledButton(
                    onPressed: _actionBusy ? null : _startMission,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD400),
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      _actionBusy ? 'Patientez…' : 'Démarrer la mission',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                if (_effectiveStatus == MissionStatus.IN_PROGRESS) ...[
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _actionBusy ? null : _completeMission,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: const Color(0xFFFFD400),
                    ),
                    child: Text(
                      _actionBusy ? 'Patientez…' : 'Marquer comme terminée',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _gps.isConnected
                        ? 'Position de l’agent mise à jour en direct.'
                        : 'Connexion au flux GPS…',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleChatButton() async {
    if (_mission == null) return;
    setState(() => _isChatLoading = true);
    try {
      final conversation = await _chatRepo.getOrCreateConversation(
        _mission!.id,
      );
      if (!mounted) return;
      setState(() => _isChatLoading = false);
      if (conversation != null) {
        context.push(
          AppRoutes.chatDetail,
          extra: {
            'chatId': conversation['id']?.toString(),
            'userName': _mission!.agentName ?? 'Agent',
            'agentAvatar': _mission!.avatarUrl,
            'missionId': _mission!.id,
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Impossible de créer la conversation')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChatLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}

class _StatusProgressBar extends StatelessWidget {
  final int currentStep;

  const _StatusProgressBar({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const labels = ['Acceptée', 'En cours', 'Terminée'];
    final progress = (currentStep + 1) / 3.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              3,
              (i) => AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: i <= currentStep ? Colors.black : Colors.black54,
                ),
                child: Text(labels[i]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AnimatedLinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                currentStep == 2
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFFD400),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedLinearProgressIndicator extends LinearProgressIndicator {
  const AnimatedLinearProgressIndicator({
    super.key,
    super.value,
    super.minHeight,
    super.backgroundColor,
    super.valueColor,
  });

  @override
  State<AnimatedLinearProgressIndicator> createState() =>
      _AnimatedLinearProgressIndicatorState();
}

class _AnimatedLinearProgressIndicatorState
    extends State<AnimatedLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value ?? 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedLinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: oldWidget.value ?? 0.0,
        end: widget.value ?? 0.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: _animation.value,
          minHeight: widget.minHeight,
          backgroundColor: widget.backgroundColor,
          valueColor: widget.valueColor,
        );
      },
    );
  }
}

/// Ouvre l’écran de suivi (à utiliser depuis la liste / détail mission).
void openMissionTracking(BuildContext context, String missionId) {
  context.push(
    AppRoutes.missionTracking,
    extra: {'missionId': missionId},
  );
}
