import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../widgets/dispute_bottom_sheet.dart';
import '../widgets/rating_dialog.dart';
import '../repository/agent_repository.dart';
import '../providers/agent_provider.dart';
import '../services/mission_timeline_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/location_service.dart';
import 'dart:convert';

class AgentActiveMissionScreen extends StatefulWidget {
  const AgentActiveMissionScreen({super.key});

  @override
  State<AgentActiveMissionScreen> createState() =>
      _AgentActiveMissionScreenState();
}

class _AgentActiveMissionScreenState extends State<AgentActiveMissionScreen> {
  final AgentRepository _agentRepository = AgentRepository();
  final LocationService _locationService = LocationService();
  final MissionTimelineService _timelineService = MissionTimelineService();

  // GPS Tracking
  StreamSubscription<Position>? _gpsSubscription;
  WebSocketChannel? _gpsWebSocket;
  bool _isGpsTracking = false;
  bool _isProcessing = false;
  bool _isDisputed = false;
  int _currentStep = 0;
  final String _missionId =
      'mission_id_placeholder'; // TODO: Récupérer depuis les arguments

  int currentStep = 1;

  final List<Map<String, dynamic>> missionSteps = [
    {
      'title': 'Mission acceptée',
      'subtitle': 'Vous avez accepté la mission',
      'icon': Icons.check_circle,
    },
    {
      'title': 'En route vers le client',
      'subtitle': 'Déplacement vers le point de départ',
      'icon': Icons.directions_bike,
    },
    {
      'title': 'Colis récupéré',
      'subtitle': 'Le colis a été récupéré',
      'icon': Icons.inventory_2,
    },
    {
      'title': 'Livraison en cours',
      'subtitle': 'Direction destination finale',
      'icon': Icons.local_shipping,
    },
    {
      'title': 'Mission terminée',
      'subtitle': 'Livraison confirmée',
      'icon': Icons.verified,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFEAEAEA),
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      "Mission active",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "En cours",
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Bouton d'urgence litige
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'dispute') {
                        _showDisputeBottomSheet();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
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
                            backgroundColor: const Color(0xFFFFD54F),
                            child: const Icon(
                              Icons.person,
                              color: Colors.black,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Jean Koffi",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Client vérifié • Livraison urgente",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
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
                                  children: const [
                                    Text(
                                      "Départ",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Cocody Angré 8ème tranche",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 28),
                                    Text(
                                      "Destination",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Plateau Avenue Chardy",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
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
                                "Distance",
                                "4.8 km",
                                Icons.route,
                              ),
                              _buildMiniStat(
                                "Temps",
                                "25 min",
                                Icons.access_time,
                              ),
                              _buildMiniStat(
                                "Gain",
                                "8500F",
                                Icons.payments,
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

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: List.generate(
                          missionSteps.length,
                          (index) {
                            final isCompleted = index < currentStep;
                            final isCurrent = index == currentStep;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      height: 42,
                                      width: 42,
                                      decoration: BoxDecoration(
                                        color: isCompleted || isCurrent
                                            ? const Color(0xFFFFD54F)
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        missionSteps[index]['icon'],
                                        color: isCompleted || isCurrent
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                    if (index != missionSteps.length - 1)
                                      Container(
                                        width: 2,
                                        height: 45,
                                        color: isCompleted
                                            ? const Color(0xFFFFD54F)
                                            : Colors.grey.shade300,
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          missionSteps[index]['title'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: isCompleted || isCurrent
                                                ? Colors.black
                                                : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          missionSteps[index]['subtitle'],
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // QR CODE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () {
                                _scanQRCode();
                              },
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                ),
                              )
                            : const Icon(Icons.qr_code_scanner),
                        label: Text(
                          _isProcessing
                              ? "Scan en cours..."
                              : "Scanner le QR Code",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD54F),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // TERMINER BUTTON
                    if (currentStep < missionSteps.length - 1)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isDisputed
                              ? null
                              : (_isProcessing
                                  ? null
                                  : () => _updateMissionStep('IN_PROGRESS')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDisputed
                                ? Colors.grey
                                : const Color(0xFFFFD400),
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
                                  _isDisputed
                                      ? 'Mission suspendue'
                                      : 'Valider l\'étape',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isDisputed
                              ? null
                              : (_isProcessing
                                  ? null
                                  : () => _completeMission()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isDisputed ? Colors.grey : Colors.green,
                            foregroundColor: Colors.white,
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
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isDisputed
                                      ? 'Mission suspendue'
                                      : 'Terminer la mission',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
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

  /// Met à jour l'étape de la mission
  Future<void> _updateMissionStep(String status) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await _agentRepository.updateMissionStep(
        _missionId,
        status,
      );

      if (success) {
        if (mounted) {
          setState(() {
            _currentStep++;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Étape "$status" complétée!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la mise à jour de l\'étape'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Scan le QR Code (simulation)
  void _scanQRCode() {
    // TODO: Implémenter le scan QR code réel
    _updateMissionStep('IN_PROGRESS');
  }

  /// Démarre le tracking GPS
  void _startGpsTracking() {
    if (_isGpsTracking) return;

    try {
      // Connecter au WebSocket GPS
      final wsUrl = 'ws://${ApiConfig.apiHostAndPort}/ws/gps/$_missionId/';
      _gpsWebSocket = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Démarrer le stream GPS
      _gpsSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Mettre à jour tous les 10m
        ),
      ).listen(
        (Position position) {
          if (_gpsWebSocket != null) {
            // Envoyer les coordonnées toutes les 10 secondes
            _sendGpsCoordinates(position);
          }
        },
        onError: (error) {
          print('Erreur GPS: $error');
        },
      );

      setState(() {
        _isGpsTracking = true;
      });

      print('GPS tracking démarré pour mission $_missionId');
    } catch (e) {
      print('Erreur démarrage GPS: $e');
    }
  }

  /// Arrête le tracking GPS
  void _stopGpsTracking() {
    if (!_isGpsTracking) return;

    _gpsSubscription?.cancel();
    _gpsWebSocket?.sink.close();
    _gpsSubscription = null;
    _gpsWebSocket = null;

    setState(() {
      _isGpsTracking = false;
    });

    print('GPS tracking arrêté');
  }

  /// Envoie les coordonnées GPS via WebSocket
  void _sendGpsCoordinates(Position position) {
    if (_gpsWebSocket == null) return;

    final gpsData = {
      'type': 'gps_update',
      'mission_id': _missionId,
      'agent_id': 'current_agent_id', // TODO: Récupérer depuis AuthProvider
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'timestamp': DateTime.now().toIso8601String(),
      'speed': position.speed,
      'heading': position.heading,
    };

    try {
      _gpsWebSocket!.sink.add(json.encode(gpsData));
      print(
          'Coordonnées GPS envoyées: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Erreur envoi GPS: $e');
    }
  }

  /// Initialise la timeline
  void _initializeTimeline() {
    _timelineService.connectToTimeline(_missionId, (stepData) {
      // Mettre à jour l'état de la timeline
      print('Timeline update: $stepData');
    });
  }

  /// Affiche le BottomSheet de litige
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

  /// Affiche le dialogue de notation
  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        missionId: _missionId,
        onRatingSubmitted: (rating, comment) async {
          final success = await _agentRepository.submitReview(
            _missionId,
            rating,
            comment,
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Merci pour votre évaluation!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  /// Termine la mission et crédite le solde
  Future<void> _completeMission() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Soumettre la preuve de complétion (simulation)
      final proofSubmitted = await _agentRepository.submitCompletion(
        _missionId,
        'path/to/photo.jpg', // TODO: Implémenter prise de photo
      );

      if (!proofSubmitted) {
        throw Exception('Erreur lors de la soumission de la preuve');
      }

      // 2. Valider la complétion via QR Code (simulation)
      final validated = await _agentRepository.validateCompletion(
        _missionId,
        'qr_code_data_simule', // TODO: Implémenter scan QR client
      );

      if (!validated) {
        throw Exception('Erreur lors de la validation');
      }

      // 3. Mettre à jour le statut final
      final success = await _agentRepository.updateMissionStep(
        _missionId,
        'COMPLETED',
      );

      if (success) {
        if (mounted) {
          // 4. Rafraîchir le solde du portefeuille
          final newBalance = await _agentRepository.refreshWalletBalance();

          // 5. Mettre à jour le solde dans AgentProvider
          if (context.mounted) {
            final agentProvider =
                Provider.of<AgentProvider>(context, listen: false);
            await agentProvider.fetchWalletDetails();
          }

          // Afficher un message de succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Mission terminée! Nouveau solde: ${newBalance.toStringAsFixed(2)} XOF'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Afficher le dialogue de notation
          _showRatingDialog();

          // Rediriger vers le dashboard après un délai
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/agent/dashboard',
                (route) => false,
              );
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la finalisation de la mission'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
