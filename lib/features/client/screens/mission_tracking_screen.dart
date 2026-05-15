import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/config/api_config.dart';

/// Écran de tracking de mission pour le client
class MissionTrackingScreen extends StatefulWidget {
  final String missionId;
  final String agentName;
  final LatLng startPoint;
  final LatLng endPoint;

  const MissionTrackingScreen({
    super.key,
    required this.missionId,
    required this.agentName,
    required this.startPoint,
    required this.endPoint,
  });

  @override
  State<MissionTrackingScreen> createState() => _MissionTrackingScreenState();
}

class _MissionTrackingScreenState extends State<MissionTrackingScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  WebSocketChannel? _gpsWebSocket;
  Marker? _agentMarker;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Animation du marqueur
  AnimationController? _markerAnimationController;
  Animation<LatLng>? _markerAnimation;
  LatLng? _currentAgentPosition;
  
  // Timeline
  List<Map<String, dynamic>> _timelineSteps = [];
  int _currentStep = 0;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeTracking();
    _setupMarkerAnimation();
  }
  
  @override
  void dispose() {
    _gpsWebSocket?.sink.close();
    _markerAnimationController?.dispose();
    super.dispose();
  }
  
  void _setupMarkerAnimation() {
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }
  
  void _initializeTracking() {
    // Initialiser la carte avec les points de départ et d'arrivée
    _markers.addAll([
      Marker(
        markerId: const MarkerId('start'),
        position: widget.startPoint,
        infoWindow: const InfoWindow(title: 'Point de départ'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: widget.endPoint,
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    ]);
    
    // Ajouter la polyligne du trajet
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [widget.startPoint, widget.endPoint],
        color: Colors.blue,
        width: 3,
      ),
    );
    
    // Connecter au WebSocket GPS
    _connectGpsWebSocket();
  }
  
  void _connectGpsWebSocket() {
    try {
      final wsUrl = 'ws://${ApiConfig.apiHostAndPort}/ws/gps/${widget.missionId}/';
      _gpsWebSocket = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _gpsWebSocket!.stream.listen(
        (data) {
          final gpsData = json.decode(data) as Map<String, dynamic>;
          _handleGpsUpdate(gpsData);
        },
        onError: (error) {
          print('Erreur WebSocket GPS: $error');
        },
        onDone: () {
          print('WebSocket GPS déconnecté');
        },
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur connexion WebSocket GPS: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _handleGpsUpdate(Map<String, dynamic> gpsData) {
    if (gpsData['type'] != 'gps_update') return;
    
    final newPosition = LatLng(
      gpsData['latitude'] as double,
      gpsData['longitude'] as double,
    );
    
    // Animer le marqueur vers la nouvelle position
    _animateMarkerToPosition(newPosition);
  }
  
  void _animateMarkerToPosition(LatLng newPosition) {
    if (_currentAgentPosition == null) {
      // Première position - créer le marqueur
      _createAgentMarker(newPosition);
      return;
    }
    
    // Animer depuis la position actuelle vers la nouvelle
    _markerAnimation = Tween<LatLng>(
      begin: _currentAgentPosition!,
      end: newPosition,
    ).animate(CurvedAnimation(
      parent: _markerAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    _markerAnimationController!.forward(from: 0.0);
    
    _markerAnimation!.addListener(() {
      if (_markerAnimation!.isCompleted) {
        _updateAgentMarkerPosition(_markerAnimation!.value!);
      } else {
        _updateAgentMarkerPosition(_markerAnimation!.value!);
      }
    });
  }
  
  void _createAgentMarker(LatLng position) {
    setState(() {
      _currentAgentPosition = position;
      _agentMarker = Marker(
        markerId: const MarkerId('agent'),
        position: position,
        infoWindow: InfoWindow(title: widget.agentName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      );
      _markers.add(_agentMarker!);
    });
  }
  
  void _updateAgentMarkerPosition(LatLng position) {
    if (_agentMarker == null) {
      _createAgentMarker(position);
      return;
    }
    
    setState(() {
      _currentAgentPosition = position;
      _agentMarker = _agentMarker!.copyWith(positionParam: position);
      _markers = _markers.map((marker) {
        return marker.markerId == const MarkerId('agent') 
            ? _agentMarker! 
            : marker;
      }).toSet();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suivi de livraison',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text(
              widget.agentName,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Column(
        children: [
          // Carte
          Expanded(
            flex: 3,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: widget.startPoint,
                      zoom: 14,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _adjustCameraToShowRoute();
                    },
                  ),
          ),
          
          // Timeline
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progression de la mission',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Barre de progression
                  LinearProgressIndicator(
                    value: _currentStep / 3.0, // 3 étapes totales
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFFFD400),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Timeline
                  Expanded(
                    child: ListView.builder(
                      itemCount: _timelineSteps.length,
                      itemBuilder: (context, index) {
                        final step = _timelineSteps[index];
                        final isCompleted = index < _currentStep;
                        final isCurrent = index == _currentStep;
                        
                        return _TimelineStep(
                          title: step['title'] ?? '',
                          subtitle: step['subtitle'] ?? '',
                          time: step['time'] ?? '',
                          isCompleted: isCompleted,
                          isCurrent: isCurrent,
                          icon: step['icon'] ?? Icons.check_circle,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _adjustCameraToShowRoute() {
    if (_mapController == null) return;
    
    final bounds = LatLngBounds(
      southwest: LatLng(
        widget.startPoint.latitude < widget.endPoint.latitude
            ? widget.startPoint.latitude
            : widget.endPoint.latitude,
        widget.startPoint.longitude < widget.endPoint.longitude
            ? widget.startPoint.longitude
            : widget.endPoint.longitude,
      ),
      northeast: LatLng(
        widget.startPoint.latitude > widget.endPoint.latitude
            ? widget.startPoint.latitude
            : widget.endPoint.latitude,
        widget.startPoint.longitude > widget.endPoint.longitude
            ? widget.startPoint.longitude
            : widget.endPoint.longitude,
      ),
    );
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }
}

/// Widget pour une étape de la timeline
class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool isCompleted;
  final bool isCurrent;
  final IconData icon;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isCompleted,
    required this.isCurrent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted 
                  ? const Color(0xFFFFD400)
                  : isCurrent
                      ? const Color(0xFFFFD400).withOpacity(0.3)
                      : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isCompleted || isCurrent ? Colors.black : Colors.grey.shade600,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isCompleted || isCurrent ? Colors.black : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: isCompleted ? const Color(0xFFFFD400) : Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
