import 'package:flutter/material.dart';
import '../../../core/services/location_service.dart';

class Step2LogisticsForm extends StatefulWidget {
  final String mode;
  final VoidCallback onNext;

  const Step2LogisticsForm({
    super.key,
    required this.mode,
    required this.onNext,
  });

  @override
  State<Step2LogisticsForm> createState() => _Step2LogisticsFormState();
}

class _Step2LogisticsFormState extends State<Step2LogisticsForm> {
  final LocationService _locationService = LocationService();

  final TextEditingController _locationController =
      TextEditingController();

  final TextEditingController _budgetController =
      TextEditingController(
    text: '2500',
  );

  final TextEditingController _timeController =
      TextEditingController();

  bool _isLoadingLocation = false;
  bool _isUrgent = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _budgetController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    await _locationService.getCurrentLocation();

    if (mounted) {
      setState(() {
        _isLoadingLocation = false;

        if (_locationService.currentAddress.isNotEmpty) {
          _locationController.text =
              _locationService.currentAddress;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITRE
          const Text(
            "Où et quand ?",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 25),

          // CHAMP LIEU
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.black.withOpacity(0.05),
              ),
            ),
            child: TextField(
              controller: _locationController,
              readOnly: _isLoadingLocation,
              decoration: InputDecoration(
                prefixIcon: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFFD400),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.location_on,
                        color: Color(0xFFFFD400),
                        size: 20,
                      ),

                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.grey,
                    size: 20,
                  ),
                  tooltip: 'Rafraîchir la position',
                  onPressed: _loadCurrentLocation,
                ),

                hintText: _isLoadingLocation
                    ? 'Chargement de votre position...'
                    : 'Lieu de départ',

                border: InputBorder.none,

                hintStyle: const TextStyle(
                  fontSize: 13,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // PROCURATION
          if (widget.mode == 'service') ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C1C),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.gavel,
                        color: Color(0xFFFFD400),
                        size: 18,
                      ),

                      SizedBox(width: 8),

                      Text(
                        "Besoin d'une procuration ?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _buildProcBtn("✍️ Signature"),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child:
                            _buildProcBtn("📤 Upload PDF"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],

          // URGENCE
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.black.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.priority_high,
                  color: Colors.red[400],
                  size: 20,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Mission urgente",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      Text(
                        "Les agents seront notifiés en priorité",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                Switch(
                  value: _isUrgent,
                  activeThumbColor:
                      const Color(0xFFFFD400),
                  onChanged: (value) {
                    setState(() {
                      _isUrgent = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // HEURE + BUDGET
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  Icons.access_time,
                  "Heure",
                  controller: _timeController,
                  isHalf: true,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _buildInput(
                  Icons.euro,
                  "Budget proposé",
                  controller: _budgetController,
                  keyboardType:
                      TextInputType.number,
                  isHalf: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // BOUTON
          ElevatedButton(
            onPressed: widget.onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize:
                  const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              "VALIDER LES DÉTAILS",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    IconData icon,
    String hint, {
    bool isHalf = false,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          icon: Icon(
            icon,
            color: const Color(0xFFFFD400),
            size: 20,
          ),
          hintText: hint,
          border: InputBorder.none,
          hintStyle: const TextStyle(
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildProcBtn(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}