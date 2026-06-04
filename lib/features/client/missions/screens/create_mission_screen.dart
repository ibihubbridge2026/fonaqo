import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/constants/app_constants.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/providers/mission_provider.dart';
import 'package:fonaco/core/services/feedback_service.dart';
import 'package:fonaco/core/services/location_service.dart';
import 'package:fonaco/widgets/main_wrapper.dart';
import '../mission_repository.dart';
import '../widgets/create_mission_step_type.dart';
import '../widgets/create_mission_step_details.dart';
import '../widgets/create_mission_step_logistics.dart';
import '../widgets/create_mission_step_recap.dart';
import 'mission_success_screen.dart';

/// Flux de création de mission (4 étapes, conteneur plat, sans FeexPay).
class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  final MissionRepository _repo = MissionRepository();
  final Logger _logger = Logger();

  int _step = 1;
  String? _flowType;
  int? _categoryId;
  String _categoryName = '';
  bool _needsProcuration = false;
  bool _isUrgent = false;
  bool _isConfidential = false;
  String _recurrence = 'once'; // 'once', 'weekly', 'monthly'

  final TextEditingController _adminPlace = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _targetAgent = TextEditingController();
  final TextEditingController _serviceAmount = TextEditingController(
      text: AppConstants.defaultServiceAmount.toStringAsFixed(0));
  final TextEditingController _purchaseAmount = TextEditingController(
      text: AppConstants.defaultPurchaseAmount.toStringAsFixed(0));

  List<Map<String, dynamic>> _categories = [];
  bool _loadingCats = true;
  String? _catsError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _adminPlace,
      _address,
      _description,
      _serviceAmount,
      _purchaseAmount,
    ]) {
      c.addListener(() => setState(() {}));
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCats = true;
      _catsError = null;
    });
    try {
      final rows = await _repo
          .fetchServiceCategories()
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() {
        _categories = rows;
        _loadingCats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCats = false;
        _catsError =
            'Impossible de charger les catégories. Vérifiez votre connexion.';
      });
    }
  }

  @override
  void dispose() {
    _adminPlace.dispose();
    _address.dispose();
    _description.dispose();
    _targetAgent.dispose();
    _serviceAmount.dispose();
    _purchaseAmount.dispose();
    super.dispose();
  }

  double get _serviceAmountValue {
    final raw = _serviceAmount.text.replaceAll(',', '.').trim();
    return double.tryParse(raw) ?? 0;
  }

  double get _purchaseAmountValue {
    final raw = _purchaseAmount.text.replaceAll(',', '.').trim();
    return double.tryParse(raw) ?? 0;
  }

  double get _optionsCost =>
      (_isUrgent ? AppConstants.optionCost : 0) +
      (_isConfidential ? AppConstants.optionCost : 0);

  double get _fonnaqoFee => _serviceAmountValue * 0.10;

  double get _totalAmount =>
      _serviceAmountValue + _purchaseAmountValue + _optionsCost + _fonnaqoFee;

  void _cancelAndHome() {
    final shell = MainShellScope.maybeOf(context);
    setState(() {
      _step = 1;
      _flowType = null;
      _categoryId = null;
      _categoryName = '';
      _needsProcuration = false;
      _isUrgent = false;
      _isConfidential = false;
      _adminPlace.clear();
      _address.clear();
      _description.clear();
      _targetAgent.clear();
      _serviceAmount.text = '15000';
      _purchaseAmount.text = '0';
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

  /// Vérifie que l'utilisateur a un numéro de téléphone
  Future<bool> _checkPhoneNumber() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur non connecté'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    if (currentUser.phoneNumber == null || currentUser.phoneNumber!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Un numéro de téléphone est requis pour créer une mission. Veuillez compléter votre profil.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return false;
    }

    return true;
  }

  /// Vérifie la localisation avant la soumission de la mission
  Future<bool> _checkLocationBeforeSubmission() async {
    try {
      final locationService = LocationService();
      final permissionStatus = await locationService.checkAndRequestLocation();

      if (permissionStatus == LocationPermissionStatus.granted) {
        // La permission est accordée, obtenir la position actuelle
        await locationService.getCurrentLocation();

        // Vérifier si nous avons une position valide
        if (locationService.currentPosition != null) {
          return true;
        } else {
          // La permission est accordée mais pas de position disponible
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Impossible d\'obtenir votre position. Veuillez réessayer.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return false;
        }
      } else {
        // La permission est refusée
        String message =
            'La localisation est nécessaire pour créer une mission. Veuillez l\'activer pour continuer.';

        if (permissionStatus == LocationPermissionStatus.deniedForever) {
          message +=
              ' Vous pouvez l\'activer dans les paramètres de votre appareil.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 6),
              action: permissionStatus == LocationPermissionStatus.deniedForever
                  ? SnackBarAction(
                      label: 'Paramètres',
                      textColor: Colors.white,
                      onPressed: () => locationService.openAppSettings(),
                    )
                  : null,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Erreur lors de la vérification de la localisation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _confirm() async {
    final serviceAmount = _serviceAmountValue;
    final purchaseAmount = _purchaseAmountValue;
    if (serviceAmount <= 0) return;

    // Vérifier que l'utilisateur a un numéro de téléphone
    final phoneCheck = await _checkPhoneNumber();
    if (!phoneCheck) return;

    // Vérifier la localisation avant de soumettre la mission
    final locationCheck = await _checkLocationBeforeSubmission();
    if (!locationCheck) return;

    setState(() => _submitting = true);
    try {
      // Frais Fonnaqo (10% de la prestation) + coût des options.
      final serviceFee = _fonnaqoFee + _optionsCost;
      await _repo.createMission(
        MissionCreatePayload(
          title: _missionTitle(),
          description: _missionDescription().trim().isEmpty
              ? _missionTitle()
              : _missionDescription(),
          address: _address.text.trim(),
          latitude: AppConstants.abidjanCenterLatitude,
          longitude: AppConstants.abidjanCenterLongitude,
          price: serviceAmount,
          serviceFee: serviceFee,
          requiresProcuration: _needsProcuration,
          isUrgent: _isUrgent,
          isConfidential: _isConfidential,
          purchaseAmount: purchaseAmount,
          serviceAmount: serviceAmount,
          recurrence: _recurrence,
          targetAgentUsername: _targetAgent.text.trim().isEmpty
              ? null
              : _targetAgent.text.trim(),
        ),
      );
      if (!mounted) return;

      final missionTitle = _missionTitle();
      final total = _totalAmount;

      // Rafraîchissement des missions en arrière-plan (best-effort).
      try {
        await Provider.of<MissionProvider>(context, listen: false)
            .refreshMissions();
      } catch (e, st) {
        _logger.e('Refresh missions failed', error: e, stackTrace: st);
      }

      if (!mounted) return;
      // Redirection vers la page de succès.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MissionSuccessScreen(
            missionTitle: missionTitle,
            totalAmount: total,
          ),
        ),
      );
    } catch (e, st) {
      _logger.e('createMission failed', error: e, stackTrace: st);
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
        color: Color(0xFFF8F9FA),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Spacer(),
                IconButton(
                  tooltip: 'Annuler et retour à l’accueil',
                  onPressed: _cancelAndHome,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildStepper(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_step == 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: CreateMissionStepType(
                        selected: _flowType,
                        onSelect: (v) => setState(() => _flowType = v),
                      ),
                    ),
                  if (_step == 2)
                    _loadingCats
                        ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _catsError != null
                            ? Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 48, color: Colors.red),
                                    const SizedBox(height: 16),
                                    Text(
                                      _catsError!,
                                      textAlign: TextAlign.center,
                                      style:
                                          const TextStyle(color: Colors.red),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadCategories,
                                      child: const Text('Réessayer'),
                                    ),
                                  ],
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20),
                                child: CreateMissionStepDetails(
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
                                  addressController: _address,
                                  descriptionController: _description,
                                  recurrence: _recurrence,
                                  onRecurrenceChanged: (v) =>
                                      setState(() => _recurrence = v),
                                  onNext: () => setState(() => _step = 3),
                                ),
                              ),
                  if (_step == 3)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: CreateMissionStepLogistics(
                        targetAgentController: _targetAgent,
                        isUrgent: _isUrgent,
                        isConfidential: _isConfidential,
                        onUrgentChanged: (v) => setState(() => _isUrgent = v),
                        onConfidentialChanged: (v) =>
                            setState(() => _isConfidential = v),
                        onNext: () => setState(() => _step = 4),
                      ),
                    ),
                  if (_step == 4)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: CreateMissionStepRecap(
                        serviceAmountController: _serviceAmount,
                        purchaseAmountController: _purchaseAmount,
                        isUrgent: _isUrgent,
                        isConfidential: _isConfidential,
                        summaryTitle: _missionTitle(),
                        summaryLines: _recapSummaryLines(),
                        isSubmitting: _submitting,
                        onConfirm: _confirm,
                      ),
                    ),
                  if (_step == 1 && _flowType != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => setState(() => _step = 2),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD400),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continuer',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.chevron_right, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_step == 2)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_flowType == 'queue' &&
                                      _adminPlace.text.trim().isNotEmpty) ||
                                  (_flowType == 'service' &&
                                      _categoryId != null)
                              ? () => setState(() => _step = 3)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD400),
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: Colors.grey[300],
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continuer',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.chevron_right, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_step == 3)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => setState(() => _step = 4),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD400),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continuer',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.chevron_right, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: List.generate(4, (index) {
        final isActive = index < _step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
            height: 8,
            decoration: BoxDecoration(
              color:
                  isActive ? const Color(0xFFFFD400) : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
