import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fonaco/core/api/base_client.dart';

/// Écran de validation avant la création de mission vocale.
/// Affiche toutes les données extraites + complétées et laisse l'utilisateur
/// les corriger avant de confirmer la création.
class VocalValidationScreen extends StatefulWidget {
  /// Données extraites par le backend (après complétion des champs manquants).
  final Map<String, dynamic> extractedData;

  const VocalValidationScreen({super.key, required this.extractedData});

  @override
  State<VocalValidationScreen> createState() => _VocalValidationScreenState();
}

class _VocalValidationScreenState extends State<VocalValidationScreen> {
  final _formKey = GlobalKey<FormState>();
  final BaseClient _api = BaseClient();
  bool _isCreating = false;
  bool _isFetchingLocation = false;

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _budgetCtrl;

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    final d = widget.extractedData;
    _titleCtrl = TextEditingController(text: d['title']?.toString() ?? '');
    _descCtrl = TextEditingController(text: d['description']?.toString() ?? '');
    _addressCtrl = TextEditingController(text: d['address']?.toString() ?? '');
    final rawBudget = d['budget'];
    _budgetCtrl = TextEditingController(
      text: rawBudget != null ? rawBudget.toString() : '',
    );
    _latitude = (d['latitude'] as num?)?.toDouble();
    _longitude = (d['longitude'] as num?)?.toDouble();

    // Si pas de coordonnées, proposer GPS automatiquement
    if (_latitude == null || _longitude == null) {
      _fetchGPS();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchGPS() async {
    setState(() => _isFetchingLocation = true);
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 8));
      if (mounted) {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
        });
      }
    } catch (_) {
      // GPS non disponible — l'utilisateur devra confirmer l'adresse
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation des champs requis
    final title = _titleCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final budgetRaw = double.tryParse(_budgetCtrl.text.trim());

    if (title.isEmpty) {
      _showError('Le titre de la mission est requis.');
      return;
    }
    if (description.isEmpty) {
      _showError('La description de la mission est requise.');
      return;
    }
    if (address.isEmpty) {
      _showError('L\'adresse de la mission est requise.');
      return;
    }
    if (budgetRaw == null || budgetRaw <= 0) {
      _showError('Budget invalide : entrez un montant en FCFA.');
      return;
    }
    if (_latitude == null || _longitude == null) {
      _showError(
          'Localisation manquante. Activez le GPS ou saisissez une adresse précise.');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final d = widget.extractedData;
      final payload = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'price': budgetRaw,
        'service_fee': 0,
        'is_urgent': d['scheduled_date'] == 'ASAP' || d['is_urgent'] == true,
        'is_confidential': false,
        'requires_procuration': false,
        'purchase_amount': 0,
        'service_amount': budgetRaw,
        'recurrence': 'once',
      };
      // Catégorie : tags si category_id disponible
      if (d['category_id'] != null) {
        payload['tag_ids'] = [d['category_id']];
      }

      final response = await _api.post('missions/', data: payload);

      if (!mounted) return;
      setState(() => _isCreating = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.of(context)
          ..pop() // ferme VocalValidationScreen
          ..pop(); // ferme CreateMissionVocalScreen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission créée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final body = response.data;
        final msg = body is Map
            ? (body['error'] ??
                    body['detail'] ??
                    'Erreur ${response.statusCode}')
                .toString()
            : 'Erreur ${response.statusCode}';
        _showError(msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        _showError('Erreur : $e');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vérifier la mission',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isFetchingLocation)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionCard(
                  title: 'Détails de la mission',
                  children: [
                    _buildField(
                      controller: _titleCtrl,
                      label: 'Titre',
                      icon: Icons.title,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Titre requis'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _descCtrl,
                      label: 'Description',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Description requise'
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Localisation',
                  children: [
                    _buildField(
                      controller: _addressCtrl,
                      label: 'Adresse',
                      icon: Icons.location_on_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Adresse requise'
                          : null,
                    ),
                    if (_latitude != null && _longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.gps_fixed,
                                size: 14, color: Colors.green),
                            const SizedBox(width: 6),
                            Text(
                              'GPS : ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          onPressed: _isFetchingLocation ? null : _fetchGPS,
                          icon: const Icon(Icons.my_location, size: 16),
                          label: const Text('Utiliser ma position GPS'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Budget',
                  children: [
                    _buildField(
                      controller: _budgetCtrl,
                      label: 'Budget (FCFA)',
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Budget requis';
                        final n = double.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Montant invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _QuickAmounts(onSelected: (v) {
                      _budgetCtrl.text = v.toString();
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                // Informations non-éditables
                _buildInfoTile(
                  icon: Icons.schedule,
                  label: 'Planification',
                  value: _formatSchedule(widget.extractedData),
                ),
                if (widget.extractedData['category_name'] != null)
                  _buildInfoTile(
                    icon: Icons.category_outlined,
                    label: 'Catégorie',
                    value: widget.extractedData['category_name'].toString(),
                  ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isCreating ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirmer et créer la mission',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF6C5CE7)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatSchedule(Map<String, dynamic> d) {
    final parts = <String>[];
    final date = d['scheduled_date']?.toString();
    final slot = d['scheduled_time_slot']?.toString();
    const dateLabels = {
      'ASAP': 'Dès que possible',
      'TODAY': 'Aujourd\'hui',
      'TOMORROW': 'Demain',
      'THIS_WEEK': 'Cette semaine',
    };
    const slotLabels = {
      'MORNING': 'Matin',
      'AFTERNOON': 'Après-midi',
      'EVENING': 'Soir',
    };
    if (date != null) parts.add(dateLabels[date] ?? date);
    if (slot != null) parts.add(slotLabels[slot] ?? slot);
    return parts.isEmpty ? 'Non spécifié' : parts.join(' – ');
  }
}

// ─── Widgets utilitaires ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _QuickAmounts extends StatelessWidget {
  final ValueChanged<int> onSelected;
  const _QuickAmounts({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const amounts = [5000, 10000, 18000, 25000];
    return Wrap(
      spacing: 8,
      children: amounts
          .map((a) => ActionChip(
                label: Text('${a ~/ 1000}k FCFA',
                    style: const TextStyle(fontSize: 12)),
                onPressed: () => onSelected(a),
                backgroundColor:
                    const Color(0xFF6C5CE7).withValues(alpha: 0.08),
                side: const BorderSide(color: Color(0xFF6C5CE7), width: 0.5),
              ))
          .toList(),
    );
  }
}
