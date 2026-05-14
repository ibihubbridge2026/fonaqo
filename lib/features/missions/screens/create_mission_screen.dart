import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/main_wrapper.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/mission_provider.dart';
import '../../../core/services/feedback_service.dart';
import '../mission_repository.dart';
import '../widgets/create_mission_step_type.dart';
import '../widgets/create_mission_step_details.dart';
import '../widgets/create_mission_step_logistics.dart';
import '../widgets/create_mission_step_recap.dart';

/// Flux de création de mission (4 étapes, conteneur plat, sans FeexPay).
class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  final MissionRepository _repo = MissionRepository();

  int _step = 1;
  String? _flowType;
  int? _categoryId;
  String _categoryName = '';
  bool _needsProcuration = false;

  final TextEditingController _adminPlace = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _targetAgent = TextEditingController();
  final TextEditingController _price = TextEditingController(text: '15000');

  List<Map<String, dynamic>> _categories = [];
  bool _loadingCats = true;
  bool _submitting = false;

  static const double _defaultLat = 6.3725;
  static const double _defaultLng = 2.4318;

  @override
  void initState() {
    super.initState();
    for (final c in [_adminPlace, _address, _description, _price]) {
      c.addListener(() => setState(() {}));
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final rows = await _repo.fetchServiceCategories();
    if (!mounted) return;
    setState(() {
      _categories = rows;
      _loadingCats = false;
    });
  }

  @override
  void dispose() {
    _adminPlace.dispose();
    _address.dispose();
    _description.dispose();
    _targetAgent.dispose();
    _price.dispose();
    super.dispose();
  }

  void _cancelAndHome() {
    final shell = MainShellScope.maybeOf(context);
    setState(() {
      _step = 1;
      _flowType = null;
      _categoryId = null;
      _categoryName = '';
      _needsProcuration = false;
      _adminPlace.clear();
      _address.clear();
      _description.clear();
      _targetAgent.clear();
      _price.text = '15000';
    });
    shell?.closeCreateMission();
    shell?.setIndex(0);
  }

  String _missionTitle() {
    if (_flowType == 'queue') {
      final p = _adminPlace.text.trim();
      return "File d'attente — ${p.isEmpty ? 'Lieu' : p}";
    }
    final c = _categoryName.isEmpty ? 'Service' : _categoryName;
    return 'Service — $c';
  }

  String _missionDescription() {
    final base = _description.text.trim();
    if (_flowType == 'queue') {
      final place = _adminPlace.text.trim();
      return [
        if (place.isNotEmpty) 'Lieu administratif : $place.',
        if (base.isNotEmpty) base,
      ].join(' ');
    }
    return [
      if (_categoryName.isNotEmpty) 'Catégorie : $_categoryName.',
      if (_needsProcuration) 'Procuration requise.',
      if (base.isNotEmpty) base,
    ].join(' ');
  }

  String _recapSummaryLines() {
    final buf = StringBuffer();
    buf.writeln(
        _flowType == 'queue' ? "Type : file d'attente" : 'Type : service');
    if (_flowType == 'service') {
      buf.writeln('Catégorie : ${_categoryName.isEmpty ? '—' : _categoryName}');
      buf.writeln('Procuration : ${_needsProcuration ? 'oui' : 'non'}');
    } else {
      buf.writeln('Lieu : ${_adminPlace.text.trim()}');
    }
    buf.writeln('Adresse : ${_address.text.trim()}');
    final u = _targetAgent.text.trim();
    if (u.isNotEmpty) buf.writeln('Agent ciblé : $u');
    return buf.toString().trim();
  }

  Future<void> _confirm() async {
    final raw = _price.text.replaceAll(',', '.').trim();
    final price = double.tryParse(raw) ?? 0;
    if (price <= 0) return;

    setState(() => _submitting = true);
    try {
      await _repo.createMission(
        MissionCreatePayload(
          title: _missionTitle(),
          description: _missionDescription().trim().isEmpty
              ? _missionTitle()
              : _missionDescription(),
          address: _address.text.trim(),
          latitude: _defaultLat,
          longitude: _defaultLng,
          price: price,
          serviceFee: price * 0.10,
          requiresProcuration: _needsProcuration,
          targetAgentUsername: _targetAgent.text.trim().isEmpty
              ? null
              : _targetAgent.text.trim(),
        ),
      );
      if (!mounted) return;
      FeedbackService.showSuccess(context, 'Mission créée avec succès.');

      // Rafraîchir explicitement les missions avant de retourner à l'accueil
      if (mounted) {
        try {
          await Provider.of<MissionProvider>(context, listen: false)
              .refreshMissions();
        } catch (e) {
          // Le refresh a échoué mais on continue quand même
          print('Refresh missions failed: $e');
        }
      }

      // Rafraîchir la liste des missions en naviguant vers l'accueil avec indicateur de rafraîchissement
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F4F4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            child: Row(
              children: [
                Text(
                  'Étape $_step / 4',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Annuler et retour à l’accueil',
                  onPressed: _cancelAndHome,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE3E3E3)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _step == 1
                  ? CreateMissionStepType(
                      selected: _flowType,
                      onSelect: (v) => setState(() => _flowType = v),
                    )
                  : _step == 2
                      ? _loadingCats
                          ? const Center(child: CircularProgressIndicator())
                          : CreateMissionStepDetails(
                              flowType: _flowType ?? 'service',
                              categories: _categories,
                              selectedCategoryId: _categoryId,
                              onCategorySelected: (id) {
                                String name = '';
                                for (final row in _categories) {
                                  final rid = row['id'] is int
                                      ? row['id'] as int
                                      : int.tryParse('${row['id']}');
                                  if (rid == id) {
                                    name = row['name']?.toString() ?? '';
                                    break;
                                  }
                                }
                                setState(() {
                                  _categoryId = id;
                                  _categoryName = name;
                                });
                              },
                              needsProcuration: _needsProcuration,
                              onProcurationChanged: (v) =>
                                  setState(() => _needsProcuration = v),
                              adminPlaceController: _adminPlace,
                              onNext: () => setState(() => _step = 3),
                            )
                      : _step == 3
                          ? CreateMissionStepLogistics(
                              addressController: _address,
                              descriptionController: _description,
                              targetAgentController: _targetAgent,
                              onNext: () => setState(() => _step = 4),
                            )
                          : CreateMissionStepRecap(
                              priceController: _price,
                              summaryTitle: _missionTitle(),
                              summaryLines: _recapSummaryLines(),
                              isSubmitting: _submitting,
                              onConfirm: _confirm,
                            ),
            ),
          ),
          if (_step == 1 && _flowType != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => setState(() => _step = 2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD400),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continuer',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
