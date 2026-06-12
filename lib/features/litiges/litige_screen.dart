import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fonaco/features/client/missions/mission_repository.dart';
import '../../core/api/base_client.dart';
import '../../core/models/mission_model.dart';
import '../../core/mixins/base_screen_state.dart';
import '../../widgets/custom_app_bar.dart';

/// Écran d'ouverture d'un litige depuis le dashboard.
class LitigeScreen extends StatefulWidget {
  const LitigeScreen({super.key});

  @override
  State<LitigeScreen> createState() => _LitigeScreenState();
}

class _LitigeScreenState extends State<LitigeScreen> with BaseScreenState {
  final MissionRepository _missionRepo = MissionRepository();
  final BaseClient _api = BaseClient();
  final ImagePicker _imagePicker = ImagePicker();

  List<MissionModel> _missions = [];
  String? _selectedMissionId;
  String _reason = '';
  File? _evidenceFile;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final presetId = args?['missionId']?.toString();
      if (presetId != null && presetId.isNotEmpty) {
        _selectedMissionId = presetId;
      }
      _loadMissions();
    });
  }

  Future<void> _loadMissions() async {
    await executeWithLoading(
      () async {
        final missions = await _missionRepo.fetchMissionsList();

        final disputableMissions = missions.where((m) {
          return m.status != MissionStatus.DISPUTED &&
              m.status != MissionStatus.COMPLETED &&
              m.status != MissionStatus.PENDING &&
              (m.status == MissionStatus.ACCEPTED ||
                  m.status == MissionStatus.ON_THE_WAY ||
                  m.status == MissionStatus.ARRIVED ||
                  m.status == MissionStatus.IN_PROGRESS ||
                  m.status == MissionStatus.CANCELLED);
        }).toList();

        _missions = disputableMissions;
        if (_selectedMissionId != null &&
            !_missions.any((m) => m.id == _selectedMissionId)) {
          _selectedMissionId = null;
        }
        return null;
      },
      errorMessage: 'Erreur lors du chargement des missions',
    );
  }

  Future<void> _pickEvidence() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
    setState(() => _evidenceFile = File(file.path));
  }

  Future<void> _submitDispute() async {
    if (_selectedMissionId == null || _reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez sélectionner une mission et décrire le problème',
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final formData = FormData.fromMap({
        'reason': 'Litige sur mission',
        'description': _reason.trim(),
        if (_evidenceFile != null)
          'evidence_file': await MultipartFile.fromFile(
            _evidenceFile!.path,
            filename: 'evidence.jpg',
          ),
      });

      final response = await _api.dio.post(
        '/missions/$_selectedMissionId/open_dispute/',
        data: formData,
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
      if (mounted) setState(() => _submitting = false);
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
    if (isLoading) return buildLoadingIndicator();
    if (error != null) return buildErrorWidget(onRetry: _loadMissions);

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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Choisissez la mission concernée puis décrivez la situation.",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _Card(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedMissionId,
            hint: const Text('Sélectionner une mission'),
            isExpanded: true,
            items: _missions
                .map((mission) => DropdownMenuItem(
                      value: mission.id,
                      child: Text(mission.title),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedMissionId = value),
            decoration: InputDecoration(
              labelText: 'Mission',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: TextField(
            maxLines: 6,
            onChanged: (value) => _reason = value,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Décrivez le problème…',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                  color: const Color(0xFFFFD400).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.attach_file, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _evidenceFile == null
                      ? 'Ajouter une pièce jointe'
                      : 'Preuve sélectionnée',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: _pickEvidence,
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
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }
}
