import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Step5TrackingView extends StatelessWidget {
  /// Appelée lorsque l’utilisateur veut revenir à la liste des missions (dans le shell).
  final VoidCallback onBackToMissions;

  /// Affiche le bouton bas (retour menu) si true.
  final bool showBackButton;

  const Step5TrackingView({
    super.key,
    required this.onBackToMissions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // CARTE DE TRACKING RÉELLE
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white, width: 8),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                // Google Maps
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(5.3363, -4.0260), // Abidjan
                    zoom: 14,
                  ),
                  markers: {
                    // Position client
                    Marker(
                      markerId: const MarkerId('client'),
                      position: const LatLng(5.3363, -4.0260),
                      infoWindow: const InfoWindow(title: 'Votre position'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue),
                    ),
                    // Position agent
                    Marker(
                      markerId: const MarkerId('agent'),
                      position: const LatLng(5.3400, -4.0280),
                      infoWindow: const InfoWindow(title: 'Agent en route'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen),
                    ),
                  },
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('route'),
                      color: const Color(0xFFFFD400),
                      width: 4,
                      points: const [
                        LatLng(5.3363, -4.0260),
                        LatLng(5.3380, -4.0270),
                        LatLng(5.3400, -4.0280),
                      ],
                    ),
                  },
                ),
                // Badge temps
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10)
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, color: Color(0xFFFFD400), size: 14),
                          SizedBox(width: 5),
                          Text("ARRIVÉE: 12 MIN",
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text("L'AGENT EST EN ROUTE",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: Text(
              "Moussa D. a accepté votre mission et se dirige vers le lieu.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),

        const SizedBox(height: 30),
        // PROGRESS BAR
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stepProgress("Publiée", true),
            _stepProgress("En route", true, isActive: true),
            _stepProgress("Terminée", false),
          ],
        ),

        if (showBackButton) ...[
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: onBackToMissions,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("MENU PRINCIPAL",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ],
    );
  }

  Widget _stepProgress(String label, bool isDone, {bool isActive = false}) {
    return Column(
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? const Color(0xFFFFD400) : Colors.grey[300],
            border: isActive ? Border.all(color: Colors.black, width: 2) : null,
          ),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isDone ? Colors.black : Colors.grey)),
      ],
    );
  }
}
