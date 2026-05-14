import 'package:flutter/material.dart';
import '../../core/api/base_client.dart';
import '../../core/models/mission_model.dart';
import '../missions/mission_repository.dart';
import '../../widgets/custom_app_bar.dart';

/// Écran d'ouverture d'un litige depuis le dashboard.
class LitigeScreen extends StatefulWidget {
  const LitigeScreen({super.key});

  @override
  State<LitigeScreen> createState() => _LitigeScreenState();
}

class _LitigeScreenState extends State<LitigeScreen> {
  final MissionRepository _missionRepo = MissionRepository();
  final BaseClient _api = BaseClient();

  List<MissionModel> _missions = [];
  bool _loading = true;
  String? _error;
  String? _selectedMissionId;
  String _reason = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final missions = await _missionRepo.fetchMissionsList();
      
      // Filtrage des missions éligibles au litige (on exclut les terminées/déjà en litige)
      final disputableMissions = missions.where((m) {
        return m.status != MissionStatus.DISPUTED &&
               m.status != MissionStatus.COMPLETED &&
               (m.status == MissionStatus.ACCEPTED ||
                m.status == MissionStatus.ON_THE_WAY ||
                m.status == MissionStatus.ARRIVED ||
                m.status == MissionStatus.IN_PROGRESS ||
                m.status == MissionStatus.CANCELLED);
      }).toList();

      if (!mounted) return;
      setState(() {
        _missions = disputableMissions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submitDispute() async {
    if (_selectedMissionId == null || _reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner une mission et décrire le problème')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });
    
    try {
      // Appel API vers ton backend Django
      final response = await _api.dio.post(
        '/missions/$_selectedMissionId/open_dispute/',
        data: {'reason': _reason.trim()},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Litige enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        throw Exception('Erreur ${response.statusCode}');
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
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(
        title: 'Ouvrir un litige',
        detailTitleWidget: Text(
          'Ouvrir un litige',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMissions,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_missions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Aucune mission éligible pour un litige',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const Text(
          'Expliquez le problème',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          "Choisissez la mission concernée puis décrivez la situation. Nous reviendrons vers vous rapidement.",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _Card(
          child: DropdownButtonFormField<String>(
            value: _selectedMissionId,
            hint: const Text('Sélectionner une mission'),
            items: _missions
                .map((mission) => DropdownMenuItem(
                      value: mission.id,
                      child: Text(mission.title),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedMissionId = value;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Mission',
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: TextField(
            maxLines: 6,
            onChanged: (value) => _reason = value,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Décrivez le problème, ajoutez des détails utiles…',
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD400).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.attach_file, color: Colors.black),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ajouter une pièce jointe',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bientôt disponible')),
                  );
                },
                child: const Text('Importer'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submitDispute,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'SOUMETTRE',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }
}