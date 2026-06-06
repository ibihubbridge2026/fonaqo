import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fonaco/widgets/custom_app_bar.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/utils/marker_icon_cache.dart';
import 'package:fonaco/features/chat/chat_repository.dart';
import 'mission_repository.dart';

class MissionDetailScreen extends StatefulWidget {
  final String? missionId;

  const MissionDetailScreen({super.key, this.missionId});

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  final MissionRepository _missionRepository = MissionRepository();
  final ChatRepository _chatRepository = ChatRepository();
  final MarkerIconCache _markerCache = MarkerIconCache();
  MissionModel? _mission;
  bool _isLoading = true;
  bool _isChatLoading = false;
  String? _errorMessage;
  String? _resolvedMissionId;

  @override
  void initState() {
    super.initState();
    // Utilise un post-frame callback pour gérer les deux modes d'initialisation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMission();
    });
  }

  void _initializeMission() {
    // 1. Priorité au missionId passé par le constructeur
    // 2. Sinon, on cherche dans les arguments de la route
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _resolvedMissionId = widget.missionId ?? args?['missionId']?.toString();

    if (_resolvedMissionId != null) {
      _loadMissionDetails();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ID de mission non fourni';
      });
    }
  }

  Future<void> _loadMissionDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final missionData =
          await _missionRepository.fetchMissionDetails(_resolvedMissionId!);
      if (mounted) {
        setState(() {
          _mission = missionData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement : ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  bool _hasAgentAccepted() {
    if (_mission == null) return false;
    final acceptedStatuses = [
      MissionStatus.ACCEPTED,
      MissionStatus.ON_THE_WAY,
      MissionStatus.ARRIVED,
      MissionStatus.IN_PROGRESS,
      MissionStatus.COMPLETED
    ];
    return acceptedStatuses.contains(_mission!.status);
  }

  bool _isMissionFinal() {
    if (_mission == null) return false;
    return _mission!.status == MissionStatus.COMPLETED ||
        _mission!.status == MissionStatus.CANCELLED;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CustomAppBar.detailStack(
        title: _mission?.title ?? 'Détails de la mission',
        detailTitleWidget: Text(
          _mission?.title ?? "Détails de la mission",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMissionDetails,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_mission == null) {
      return const Center(child: Text('Mission non trouvée'));
    }

    return Stack(
      children: [
        // Google Maps en arrière-plan - toujours affichée
        Positioned.fill(
          child: _buildGoogleMap(),
        ),
        // DraggableScrollableSheet
        DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle pour le drag
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mini-profil agent enrichi
                          if (_hasAgentAccepted()) _buildAgentMiniProfile(),
                          const SizedBox(height: 20),
                          // Badge de statut
                          _buildStatusBadge(),
                          const SizedBox(height: 16),
                          // Timeline directe
                          _buildTimeline(),
                          const SizedBox(height: 24),
                          // ExpansionTiles simplifiés
                          _buildExpansionTile(
                            title: 'Informations de la mission',
                            icon: Icons.assignment_outlined,
                            initiallyExpanded: true,
                            children: [_buildMissionInfo()],
                          ),
                          const SizedBox(height: 12),
                          _buildExpansionTile(
                            title: 'Documents & Preuves',
                            icon: Icons.folder_open_rounded,
                            children: [_buildDocumentsSection()],
                          ),
                          const SizedBox(height: 12),
                          _buildExpansionTile(
                            title: 'Règles de Sécurité & Recommandations',
                            icon: Icons.shield_outlined,
                            children: [_buildSafetyRules()],
                          ),
                          const SizedBox(height: 24),
                          // Bouton de validation
                          if (_mission!.status == MissionStatus.COMPLETED)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _confirmReleaseFunds(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF7C600),
                                  foregroundColor: const Color(0xFF121212),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'VALIDER ET LIBÉRER LES FONDS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          // Section litige
                          if (_mission!.status != MissionStatus.DISPUTED &&
                              _mission!.status != MissionStatus.CANCELLED)
                            _buildLitigeSection(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGoogleMap() {
    // Coordonnées par défaut (Abidjan)
    final missionLat = _mission?.latitude ?? 5.3363;
    final missionLng = _mission?.longitude ?? -4.0260;
    final missionPosition = LatLng(missionLat, missionLng);

    // Déterminer le mode de la carte selon le statut
    final isPending = _mission?.status == MissionStatus.PENDING;
    final isFinal = _isMissionFinal();

    // Vérifier si l'agent a des coordonnées valides
    final hasAgentCoords = _mission?.agentName != null &&
        _mission?.latitude != null &&
        _mission?.longitude != null;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: missionPosition,
        zoom: 14,
      ),
      // Désactiver les gestes pour les missions terminées/annulées
      scrollGesturesEnabled: !isFinal,
      zoomGesturesEnabled: !isFinal,
      zoomControlsEnabled: !isFinal,
      tiltGesturesEnabled: !isFinal,
      rotateGesturesEnabled: !isFinal,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
      markers: _buildMarkers(isPending, hasAgentCoords, missionPosition),
      polylines:
          _buildPolylines(isPending, isFinal, hasAgentCoords, missionPosition),
      circles: _buildCircles(isPending, missionPosition),
    );
  }

  Set<Marker> _buildMarkers(
      bool isPending, bool hasAgentCoords, LatLng missionPosition) {
    final markers = <Marker>{};

    // Toujours afficher le marqueur client
    markers.add(
      Marker(
        markerId: const MarkerId('client'),
        position: missionPosition,
        infoWindow: InfoWindow(title: 'Position mission'),
        icon: _markerCache.missionMarker,
      ),
    );

    // Ajouter le marqueur agent seulement si:
    // - La mission n'est pas pending
    // - L'agent a des coordonnées valides
    // - La mission n'est pas terminée/annulée (mode historique)
    if (!isPending && hasAgentCoords && !_isMissionFinal()) {
      markers.add(
        Marker(
          markerId: const MarkerId('agent'),
          position: LatLng(
            _mission!.latitude! + 0.0037, // Offset simulé pour l'agent
            _mission!.longitude! - 0.0020,
          ),
          infoWindow: InfoWindow(title: _mission!.agentName ?? 'Agent'),
          icon: _markerCache.clusterMarker,
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(bool isPending, bool isFinal,
      bool hasAgentCoords, LatLng missionPosition) {
    // Afficher la polyline seulement si:
    // - La mission n'est pas pending
    // - L'agent a des coordonnées valides
    if (isPending || !hasAgentCoords) {
      return {};
    }

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        color: const Color(0xFFF7C600),
        width: 5,
        points: [
          missionPosition,
          LatLng(
            _mission!.latitude! + 0.0037,
            _mission!.longitude! - 0.0020,
          ),
          LatLng(
            _mission!.latitude! + 0.0050,
            _mission!.longitude! - 0.0030,
          ),
        ],
      ),
    };
  }

  Set<Circle> _buildCircles(bool isPending, LatLng missionPosition) {
    // Afficher le cercle jaune seulement pour les missions pending
    if (!isPending) {
      return {};
    }

    return {
      Circle(
        circleId: const CircleId('search_zone'),
        center: missionPosition,
        radius: 500, // 500m de rayon
        fillColor: Colors.yellow.withValues(alpha: 0.15),
        strokeColor: const Color(0xFFF7C600).withValues(alpha: 0.3),
        strokeWidth: 2,
      ),
    };
  }

  Widget _buildStatusBadge() {
    final status = _mission!.status;
    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    IconData iconData;
    String text;

    if (status == MissionStatus.CANCELLED) {
      backgroundColor = Colors.red[50]!;
      borderColor = Colors.red[200]!;
      iconColor = Colors.red[700]!;
      iconData = Icons.warning_amber_rounded;
      text = 'Mission Annulée';
    } else if (status == MissionStatus.DISPUTED) {
      backgroundColor = Colors.orange[50]!;
      borderColor = Colors.orange[200]!;
      iconColor = Colors.orange[700]!;
      iconData = Icons.shield_outlined;
      text = 'Litige En Cours';
    } else if (status == MissionStatus.COMPLETED) {
      backgroundColor = Colors.green[50]!;
      borderColor = Colors.green[200]!;
      iconColor = Colors.green[700]!;
      iconData = Icons.check_circle;
      text = 'Mission Terminée avec succès';
    } else {
      backgroundColor = const Color(0xFFF7C600).withValues(alpha: 0.15);
      borderColor = const Color(0xFFF7C600).withValues(alpha: 0.3);
      iconColor = const Color(0xFFF7C600);
      iconData = Icons.directions_car;
      text =
          '${_mission!.statusDisplay.toUpperCase()} - Arrivée estimée : 12 min';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            color: iconColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF121212),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildDetailRow('Lieu', _mission!.address ?? 'Adresse non spécifiée'),
          _buildDetailRow('Prix', '${_mission!.price.toStringAsFixed(0)} FCFA'),
          _buildDetailRow('Catégorie', _mission!.category ?? 'Non catégorisée'),
          _buildDetailRow(
              'Date',
              _mission!.createdAt != null
                  ? _mission!.createdAt.toString().split(' ')[0]
                  : 'Date non disponible'),
          _buildDetailRow(
              'Client', _mission!.clientName ?? 'Client non spécifié'),
          if (_mission!.agentName != null)
            _buildDetailRow('Agent', _mission!.agentName!),
          if (_mission!.isUrgent) _buildDetailRow('Urgence', 'Oui'),
          if (_mission!.isConfidential) _buildDetailRow('Confidentiel', 'Oui'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF121212),
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF121212),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReleaseFunds(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer ?'),
        content: const Text("Voulez-vous libérer les fonds à l'agent ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ANNULER')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('CONFIRMER')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: Appeler l'API pour libérer les fonds
      // Rediriger vers l'écran de notation
      Navigator.pushNamed(context, AppRoutes.rating);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Fonds libérés !'), backgroundColor: Colors.green));
      }
    }
  }

  Widget _buildAgentMiniProfile() {
    final agentAvatarUrl = _mission?.avatarUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Photo de l'agent avec CachedNetworkImage
          Stack(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey[200],
                child: agentAvatarUrl != null && agentAvatarUrl.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: agentAvatarUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 32,
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 32,
                      ),
              ),
              // Badge vérifié bleu officiel
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Info agent
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _mission!.agentName ?? 'Agent',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF121212),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Vérifié',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFFF7C600),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '4.8',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF121212),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '125 missions',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bouton chat
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7C600),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isChatLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF121212)),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.chat,
                      color: Color(0xFF121212),
                    ),
                    onPressed: _handleChatButton,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionTile({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF121212),
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF121212),
            ),
          ),
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          children: children,
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final steps = [
      {'title': 'Créée', 'completed': true, 'icon': Icons.check_circle},
      {
        'title': 'Acceptée',
        'completed': _mission!.status.index >= MissionStatus.ACCEPTED.index,
        'icon': Icons.check_circle,
      },
      {
        'title': 'En cours',
        'completed': _mission!.status.index >= MissionStatus.IN_PROGRESS.index,
        'icon': Icons.access_time,
      },
      {
        'title': 'Terminée',
        'completed': _mission!.status == MissionStatus.COMPLETED,
        'icon': Icons.flag,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isLast = index == steps.length - 1;
          final isCompleted = step['completed'] as bool;
          final icon = step['icon'] as IconData;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFF22C55E)
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : icon,
                      color: isCompleted ? Colors.white : Colors.grey[600],
                      size: 14,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: isCompleted
                          ? const Color(0xFF22C55E)
                          : Colors.grey[300],
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Text(
                    step['title'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? const Color(0xFF121212)
                          : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description, color: Colors.grey, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Aucun document pour le moment',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyRules() {
    final rules = [
      'Ne partagez jamais vos informations bancaires',
      'Rencontrez l\'agent dans un lieu public',
      'Vérifiez l\'identité de l\'agent avant de commencer',
      'Signalez tout comportement suspect',
      'Conservez une preuve de la transaction',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rules.map((rule) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green[700],
                    size: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rule,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF121212),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLitigeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Icône bouclier rouge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Texte
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signaler un problème',
                  style: TextStyle(
                    color: Color(0xFF121212),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Un souci ? Nous intervenons.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Bouton rouge
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.litige,
                arguments: {'missionId': _resolvedMissionId},
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Ouvrir',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChatButton() async {
    if (_mission == null || _resolvedMissionId == null) return;

    setState(() => _isChatLoading = true);

    try {
      // Créer ou récupérer la conversation pour cette mission
      final conversation = await _chatRepository.getOrCreateConversation(
        _resolvedMissionId!,
      );

      if (conversation != null && mounted) {
        final conversationId = conversation['id']?.toString();
        if (conversationId != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.chatDetail,
            arguments: {'conversationId': conversationId},
          );
        } else {
          throw Exception('Conversation ID not found in response');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de créer la conversation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture du chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChatLoading = false);
      }
    }
  }
}
