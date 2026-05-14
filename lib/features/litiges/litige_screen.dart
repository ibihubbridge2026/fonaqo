import 'package:flutter/material.dart';

import '../../core/api/base_client.dart';
import '../../core/models/mission_model.dart';
import '../missions/mission_repository.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/models/mission_model.dart';
import '../missions/mission_repository.dart';

/// Écran d'ouverture d'un litige depuis le dashboard.
class LitigeScreen extends StatefulWidget {
  const LitigeScreen({super.key});

  @override
  State<LitigeScreen> createState() => _LitigeScreenState();
}

class _LitigeScreenState extends State<LitigeScreen> {
<<<<<<< HEAD
  final MissionRepository _missionRepository = MissionRepository();
  List<MissionModel> _eligibleMissions = [];
  bool _isLoading = false;
  String? _selectedMissionId;
=======
  final MissionRepository _missionRepo = MissionRepository();
  final BaseClient _api = BaseClient();

  List<MissionModel> _missions = [];
  bool _loading = true;
  String? _error;
  String? _selectedMissionId;
  String _reason = '';
  bool _submitting = false;
>>>>>>> baf250f (mmisse a jour ddu gradle)

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _loadEligibleMissions();
  }

  Future<void> _loadEligibleMissions() async {
    setState(() => _isLoading = true);

    try {
      final missions = await _missionRepository.fetchMissionsList();
      final eligible = missions.where((mission) {
        // Seulement les missions en cours ou annulées peuvent avoir des litiges
        return mission.status == MissionStatus.ACCEPTED ||
            mission.status == MissionStatus.ON_THE_WAY ||
            mission.status == MissionStatus.ARRIVED ||
            mission.status == MissionStatus.IN_PROGRESS ||
            mission.status == MissionStatus.CANCELLED;
      }).toList();

      setState(() {
        _eligibleMissions = eligible;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
=======
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
      // Only show missions that can be disputed (not already disputed)
      final disputableMissions = missions
          .where((m) =>
              m.status != MissionStatus.DISPUTED &&
              m.status != MissionStatus.CANCELLED &&
              m.status != MissionStatus.COMPLETED)
          .toList();

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
            content: Text(
                'Veuillez sélectionner une mission et décrire le problème')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });
    try {
      final response = await _api.post(
        'missions/$_selectedMissionId/open_dispute/',
        data: {'reason': _reason.trim()},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Litige enregistré avec succès')),
        );
        Navigator.of(context).pop();
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
>>>>>>> baf250f (mmisse a jour ddu gradle)
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
            Text(_error!, style: TextStyle(color: Colors.red[700])),
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
<<<<<<< HEAD
          const SizedBox(height: 16),
          _Card(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedMissionId,
                    items: _eligibleMissions.isEmpty
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text("Aucune mission éligible"),
                            ),
                          ]
                        : _eligibleMissions.map((mission) {
                            return DropdownMenuItem(
                              value: mission.id,
                              child: Text(
                                  "${mission.title} • ${mission.formattedStatus}"),
                            );
                          }).toList(),
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
=======
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
            initialValue: _selectedMissionId,
            hint: const Text('Sélectionner une mission'),
            items: _missions
                .map((mission) => DropdownMenuItem(
                      value: mission.id,
                      child:
                          Text('${mission.title} • ${mission.statusDisplay}'),
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
>>>>>>> baf250f (mmisse a jour ddu gradle)
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
                  // TODO: Implement file attachment
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Fonctionnalité bientôt disponible')),
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
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
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
