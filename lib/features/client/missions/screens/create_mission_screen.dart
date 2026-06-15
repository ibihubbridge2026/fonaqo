import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import 'package:fonaco/core/constants/app_constants.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/providers/mission_provider.dart';
import 'package:fonaco/core/providers/wallet_provider.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/core/services/dashboard_refresh_service.dart';
import 'package:fonaco/core/services/mission_audio_cleanup.dart';
import 'package:fonaco/core/services/feexpay_service.dart';
import 'package:fonaco/core/services/feedback_service.dart';
import 'package:fonaco/core/services/location_service.dart';
import 'package:fonaco/core/utils/mission_category_display.dart';
import 'package:fonaco/core/utils/transaction_pin_dialog.dart';
import 'package:fonaco/core/utils/recording_duration_tracker.dart';
import 'package:fonaco/core/widgets/address_autocomplete_field.dart';
import 'package:fonaco/core/widgets/fon_dialog.dart';
import 'package:fonaco/core/widgets/recording_timer_display.dart';
import 'package:fonaco/widgets/main_wrapper.dart';
import '../mission_repository.dart';
import 'mission_success_screen.dart';

enum _MissionDescriptionMode { text, vocal }

const _kYellow = Color(0xFFFFD400);
const _kSwitchGreen = Color(0xFF25D366);
const _kLabelStyle = TextStyle(
  fontWeight: FontWeight.w800,
  fontSize: 15,
  color: Colors.black,
);

/// Création de mission en 2 étapes.
class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  final MissionRepository _repo = MissionRepository();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final Logger _logger = Logger();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _vocalTitleController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _serviceAmountController = TextEditingController(
    text: AppConstants.defaultServiceAmount.toStringAsFixed(0),
  );
  final TextEditingController _purchaseAmountController = TextEditingController(
    text: AppConstants.defaultPurchaseAmount.toStringAsFixed(0),
  );

  int _step = 0;
  String _selectedType = 'queue';
  _MissionDescriptionMode _descriptionMode = _MissionDescriptionMode.text;
  bool _isUrgent = false;
  bool _isConfidential = false;
  String _paymentMethod = 'feexpay';
  bool _submitting = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  String? _voiceAudioPath;
  final RecordingDurationTracker _recordingTracker = RecordingDurationTracker();

  double? _gpsLat;
  double? _gpsLng;
  double? _destLat;
  double? _destLng;
  String _departureLabel = 'Ma position actuelle (GPS)';

  Map<String, int?> _categoryIds = {
    'livraison': null,
    'courses': null,
    'autre': null,
  };

  @override
  void initState() {
    super.initState();
    _recordingTracker.onTick = (seconds) {
      if (mounted) setState(() => _recordingSeconds = seconds);
    };
    _loadGpsPosition();
    _loadCategories();
  }

  @override
  void dispose() {
    _recordingTracker.dispose();
    _descriptionController.dispose();
    _vocalTitleController.dispose();
    _destinationController.dispose();
    _serviceAmountController.dispose();
    _purchaseAmountController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadGpsPosition() async {
    try {
      final locationService = LocationService();
      final perm = await locationService.checkAndRequestLocation();
      if (perm == LocationPermissionStatus.granted) {
        await locationService.getCurrentLocation();
        final pos = locationService.currentPosition;
        if (pos != null && mounted) {
          setState(() {
            _gpsLat = pos.latitude;
            _gpsLng = pos.longitude;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadCategories() async {
    try {
      final rows = await _repo.fetchServiceCategories();
      final grid = buildMissionCategoryGrid(rows);
      final map = <String, int?>{};
      for (final row in grid) {
        final name = row['name']?.toString().toLowerCase() ?? '';
        final id = row['id'] is int
            ? row['id'] as int
            : int.tryParse('${row['id']}');
        if (name.contains('livraison')) map['livraison'] = id;
        if (name.contains('courses')) map['courses'] = id;
        if (name.contains('autre')) map['autre'] = id;
      }
      if (!mounted) return;
      setState(() => _categoryIds = map);
    } catch (e) {
      _logger.w('Catégories non chargées: $e');
    }
  }

  double get _serviceAmountValue {
    final raw = _serviceAmountController.text.replaceAll(',', '.').trim();
    return double.tryParse(raw) ?? 0;
  }

  double get _purchaseAmountValue {
    final raw = _purchaseAmountController.text.replaceAll(',', '.').trim();
    return double.tryParse(raw) ?? 0;
  }

  double get _optionsCost =>
      (_isUrgent ? AppConstants.optionCost : 0) +
      (_isConfidential ? AppConstants.optionCost : 0);

  double get _fonnaqoFee => _serviceAmountValue * 0.10;

  double get _totalAmount =>
      _serviceAmountValue + _purchaseAmountValue + _optionsCost + _fonnaqoFee;

  int? get _resolvedCategoryId {
    if (_selectedType == 'queue') return null;
    final id = _categoryIds[_selectedType];
    return resolveCategoryIdForPayload(id);
  }

  String _categoryLabel() {
    switch (_selectedType) {
      case 'livraison':
        return 'Livraison';
      case 'courses':
        return 'Courses';
      case 'autre':
        return 'Autre service';
      default:
        return '';
    }
  }

  String _selectedTypeDisplayLabel() {
    switch (_selectedType) {
      case 'queue':
        return "File d'attente";
      case 'livraison':
        return 'Livraison';
      case 'courses':
        return 'Courses';
      case 'autre':
        return 'Autre';
      default:
        return '';
    }
  }

  bool get _isVocalMode => _descriptionMode == _MissionDescriptionMode.vocal;

  String _buildTitle() {
    final dest = _destinationController.text.trim();
    if (_isVocalMode) {
      final title = _vocalTitleController.text.trim();
      if (title.isNotEmpty) return title;
    }
    if (_selectedType == 'queue') {
      return "File d'attente — ${dest.isEmpty ? 'Destination' : dest}";
    }
    final desc = _descriptionController.text.trim();
    if (desc.isNotEmpty) {
      return desc.length > 30 ? desc.substring(0, 30) : desc;
    }
    return 'Service — ${_categoryLabel()}';
  }

  String _buildDescription() {
    if (_isVocalMode) {
      return 'Description vocale';
    }
    final base = _descriptionController.text.trim();
    if (_selectedType == 'queue') {
      return base.isEmpty ? _buildTitle() : base;
    }
    final parts = <String>[
      if (_categoryLabel().isNotEmpty) 'Catégorie : ${_categoryLabel()}.',
      if (base.isNotEmpty) base,
    ];
    return parts.join(' ').trim().isEmpty ? _buildTitle() : parts.join(' ');
  }

  Future<bool> _checkPhoneNumber() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) {
      _showSnack('Utilisateur non connecté', isError: true);
      return false;
    }
    if (user.phoneNumber == null || user.phoneNumber!.trim().isEmpty) {
      _showSnack(
        'Un numéro de téléphone est requis. Complétez votre profil.',
        isError: true,
      );
      return false;
    }
    return true;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  bool _validateStep1() {
    if (_isVocalMode) {
      if (_vocalTitleController.text.trim().isEmpty) {
        _showSnack('Indiquez un titre court pour votre mission vocale.', isError: true);
        return false;
      }
      if (_voiceAudioPath == null || !File(_voiceAudioPath!).existsSync()) {
        _showSnack('Enregistrez votre besoin via le micro.', isError: true);
        return false;
      }
    } else if (_descriptionController.text.trim().isEmpty) {
      _showSnack('Décrivez-nous votre mission avant de continuer.', isError: true);
      return false;
    }
    if (_destinationController.text.trim().isEmpty) {
      _showSnack('Indiquez une adresse de destination.', isError: true);
      return false;
    }
    return true;
  }

  void _goToStep2() {
    if (!_validateStep1()) return;
    setState(() => _step = 1);
  }

  void _goToStep1() => setState(() => _step = 0);

  Future<void> _toggleRecording() async {
    if (!_isVocalMode) return;

    if (_isRecording) {
      await _stopRecording();
      return;
    }

    final granted = await Permission.microphone.request();
    if (!granted.isGranted) {
      _showSnack('Permission microphone requise', isError: true);
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/mission_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: path,
      );
      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
          _voiceAudioPath = path;
        });
        _recordingTracker.start();
      }
    } catch (e) {
      _showSnack('Erreur enregistrement : $e', isError: true);
    }
  }

  void _stopRecordingTimer() {
    _recordingTracker.stop();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _stopRecordingTimer();
      if (!mounted) return;
      if (path != null && File(path).existsSync()) {
        setState(() => _voiceAudioPath = path);
        _showSnack('Enregistrement vocal enregistré.');
      } else {
        _showSnack('Enregistrement vide — réessayez.', isError: true);
      }
    } catch (e) {
      _showSnack('Erreur enregistrement : $e', isError: true);
    }
  }

  bool _validateAmounts() {
    if (_serviceAmountValue < AppConstants.minServiceAmount) {
      _showSnack(
        'Le montant minimal est de ${AppConstants.minServiceAmount.toStringAsFixed(0)} FCFA.',
        isError: true,
      );
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validateAmounts()) return;

    if (!await _checkPhoneNumber() || !mounted) return;

    final totalRequired = _totalAmount;
    final destination = _destinationController.text.trim();

    if (_paymentMethod == 'feexpay') {
      final paid = await FeexPayService.instance.requestPayment(
        context: context,
        amount: totalRequired,
        description: 'Paiement mission « ${_buildTitle()} »',
      );
      if (!paid || !mounted) return;
    } else {
      if (!context.mounted) return;
      final wallet = context.read<WalletProvider>();
      final navigator = Navigator.of(context);
      await wallet.fetchBalance();
      if (!mounted) return;
      if (!wallet.canAfford(totalRequired)) {
        final goRecharge = await showDialog<bool>(
          context: context,
          builder: (ctx) => FonDialog.alert(
            title: const Text('Solde insuffisant'),
            content: Text(
              'Montant requis : ${totalRequired.toStringAsFixed(0)} FCFA\n'
              'Solde : ${wallet.balanceCfa.toStringAsFixed(0)} FCFA',
            ),
            actions: [
              TextButton(
                style: FonDialog.secondaryActionStyle(),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: FonDialog.primaryActionStyle(),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Recharger'),
              ),
            ],
          ),
        );
        if (goRecharge == true && mounted) {
          context.push(AppRoutes.wallet);
        }
        return;
      }
      if (!mounted) return;
      final pinOk = await verifyTransactionPinIfRequired(context);
      if (!pinOk || !mounted) return;
    }

    setState(() => _submitting = true);
    try {
      final serviceFee = _fonnaqoFee + _optionsCost;
      final missionLat = _destLat ?? _gpsLat ?? AppConstants.defaultLatitude;
      final missionLng = _destLng ?? _gpsLng ?? AppConstants.defaultLongitude;

      final created = await _repo.createMission(
        MissionCreatePayload(
          title: _buildTitle(),
          description: _buildDescription(),
          address: destination,
          latitude: missionLat,
          longitude: missionLng,
          price: _serviceAmountValue,
          serviceFee: serviceFee,
          requiresProcuration: false,
          isUrgent: _isUrgent,
          isConfidential: _isConfidential,
          isVocalDescription: _isVocalMode,
          descriptionAudioPath: _isVocalMode ? _voiceAudioPath : null,
          purchaseAmount: _purchaseAmountValue,
          serviceAmount: _serviceAmountValue,
          categoryId: _resolvedCategoryId,
        ),
      );

      if (!mounted) return;

      final missionProvider = context.read<MissionProvider>();
      missionProvider.addMission(created);

      final title = _buildTitle();
      final total = _totalAmount;

      try {
        await missionProvider.refreshMissions();
        DashboardRefreshService.instance.requestRefresh();
      } catch (e, st) {
        _logger.e('Refresh missions', error: e, stackTrace: st);
      }

      if (!mounted) return;
      MainShellScope.maybeOf(context)?.closeCreateMission();

      await MissionAudioCleanup.purgeTemporaryRecordings();
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MissionSuccessScreen(
            missionTitle: title,
            totalAmount: total,
            categoryLabel: _selectedType == 'queue' ? null : _categoryLabel(),
          ),
        ),
      );

      if (mounted) _resetForm();
    } catch (e, st) {
      _logger.e('createMission failed', error: e, stackTrace: st);
      if (mounted) FeedbackService.showError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    setState(() {
      _step = 0;
      _selectedType = 'queue';
      _isUrgent = false;
      _isConfidential = false;
      _descriptionMode = _MissionDescriptionMode.text;
      _voiceAudioPath = null;
      _destLat = null;
      _destLng = null;
      _descriptionController.clear();
      _vocalTitleController.clear();
      _destinationController.clear();
      _serviceAmountController.text =
          AppConstants.defaultServiceAmount.toStringAsFixed(0);
      _purchaseAmountController.text =
          AppConstants.defaultPurchaseAmount.toStringAsFixed(0);
    });
    _loadGpsPosition();
  }

  void _cancelAndHome() {
    _resetForm();
    final shell = MainShellScope.maybeOf(context);
    shell?.closeCreateMission();
    shell?.setIndex(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(
              children: [
                if (_step == 1)
                  IconButton(
                    tooltip: 'Retour',
                    onPressed: _goToStep1,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                Expanded(
                  child: Text(
                    _step == 0 ? 'Nouvelle mission' : 'Options & paiement',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: _cancelAndHome,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: _StepIndicator(currentStep: _step),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: _step == 0 ? _buildStep1() : _buildStep2(),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting
                      ? null
                      : (_step == 0 ? _goToStep2 : _submit),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kYellow,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _step == 0
                                  ? Icons.arrow_forward_rounded
                                  : Icons.rocket_launch_rounded,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _step == 0
                                  ? 'Continuer'
                                  : 'Lancer la mission',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Choisissez une catégorie de mission', style: _kLabelStyle),
        const SizedBox(height: 12),
        _MissionTypeSelector(
          selected: _selectedType,
          onSelected: (v) => setState(() {
            _selectedType = v;
          }),
        ),
        const SizedBox(height: 24),
        Text(
          'Votre besoin pour : ${_selectedTypeDisplayLabel()}',
          style: _kLabelStyle,
        ),
        const SizedBox(height: 10),
        _DescriptionModeSelector(
          mode: _descriptionMode,
          onChanged: (mode) => setState(() {
            _descriptionMode = mode;
            if (mode == _MissionDescriptionMode.text) {
              _voiceAudioPath = null;
              if (_isRecording) {
                _audioRecorder.stop();
                _stopRecordingTimer();
              }
            } else {
              _descriptionController.clear();
            }
          }),
        ),
        const SizedBox(height: 12),
        if (_isVocalMode) ...[
          TextField(
            controller: _vocalTitleController,
            style: const TextStyle(color: Colors.black, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Titre court de la mission',
              labelStyle: const TextStyle(color: Colors.black),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          _VocalRecorder(
            isRecording: _isRecording,
            recordingSeconds: _recordingSeconds,
            hasRecording: _voiceAudioPath != null,
            onMicPressed: _toggleRecording,
          ),
        ] else
          _TextDescriptionField(controller: _descriptionController),
        const SizedBox(height: 24),
        const Text('Destination', style: _kLabelStyle),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.my_location_rounded, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Départ : $_departureLabel',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AddressAutocompleteField(
          controller: _destinationController,
          label: _selectedType == 'queue'
              ? 'Lieu administratif / destination'
              : 'Adresse de destination',
          onLocationSelected: (address, lat, lng) {
            setState(() {
              _destinationController.text = address;
              _destLat = lat;
              _destLng = lng;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RecapCard(
          typeLabel: _selectedType == 'queue'
              ? "File d'attente"
              : _categoryLabel(),
          description: _isVocalMode
              ? 'Description vocale — ${_vocalTitleController.text.trim()}'
              : _descriptionController.text.trim(),
          destination: _destinationController.text.trim(),
          totalAmount: _totalAmount,
        ),
        const SizedBox(height: 20),
        const Text('Options de la mission', style: _kLabelStyle),
        const SizedBox(height: 8),
        _OptionSwitch(
          title: 'Mission urgente',
          subtitle: '+${AppConstants.optionCost.toStringAsFixed(0)} FCFA',
          value: _isUrgent,
          onChanged: (v) => setState(() => _isUrgent = v),
        ),
        _OptionSwitch(
          title: 'Agent Interne Fonaqo',
          subtitle: '+${AppConstants.optionCost.toStringAsFixed(0)} FCFA',
          value: _isConfidential,
          onChanged: (v) => setState(() => _isConfidential = v),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
          child: Text(
            'Sélectionnez un agent recruté, formé et encadré directement par '
            'Fonaqo sous contrat de responsabilité strict.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Montants', style: _kLabelStyle),
        const SizedBox(height: 10),
        _AmountField(
          label: 'Montant prestation (FCFA)',
          helperText:
              'Minimum ${AppConstants.minServiceAmount.toStringAsFixed(0)} FCFA',
          controller: _serviceAmountController,
          icon: Icons.payments_outlined,
          errorText: _serviceAmountValue > 0 &&
                  _serviceAmountValue < AppConstants.minServiceAmount
              ? 'Montant minimal : ${AppConstants.minServiceAmount.toStringAsFixed(0)} FCFA'
              : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _AmountField(
          label: 'Montant achats (FCFA)',
          controller: _purchaseAmountController,
          icon: Icons.shopping_cart_outlined,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        const Text('Mode de paiement', style: _kLabelStyle),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PaymentChip(
                label: 'Portefeuille',
                icon: Icons.account_balance_wallet_outlined,
                selected: _paymentMethod == 'wallet',
                onTap: () => setState(() => _paymentMethod = 'wallet'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PaymentChip(
                label: 'FeexPay',
                icon: Icons.payment_rounded,
                selected: _paymentMethod == 'feexpay',
                onTap: () => setState(() => _paymentMethod = 'feexpay'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FeeBreakdown(
          serviceAmount: _serviceAmountValue,
          purchaseAmount: _purchaseAmountValue,
          optionsCost: _optionsCost,
          fonnaqoFee: _fonnaqoFee,
          total: _totalAmount,
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(2, (i) {
        final active = i <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == 0 ? 6 : 0, left: i == 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: active ? _kYellow : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _RecapCard extends StatelessWidget {
  final String typeLabel;
  final String description;
  final String destination;
  final double totalAmount;

  const _RecapCard({
    required this.typeLabel,
    required this.description,
    required this.destination,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kYellow.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.place_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  destination,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeeBreakdown extends StatelessWidget {
  final double serviceAmount;
  final double purchaseAmount;
  final double optionsCost;
  final double fonnaqoFee;
  final double total;

  const _FeeBreakdown({
    required this.serviceAmount,
    required this.purchaseAmount,
    required this.optionsCost,
    required this.fonnaqoFee,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    Widget row(String label, double value, {bool bold = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)} FCFA',
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        children: [
          row('Prestation', serviceAmount),
          row('Achats', purchaseAmount),
          if (optionsCost > 0) row('Options', optionsCost),
          row('Frais FONACO (10 %)', fonnaqoFee),
          const Divider(height: 16),
          row('Total', total, bold: true),
        ],
      ),
    );
  }
}

class _MissionTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _MissionTypeSelector({
    required this.selected,
    required this.onSelected,
  });

  static const _types = [
    ('queue', "File d'attente", Icons.hourglass_top_rounded),
    ('livraison', 'Livraison', Icons.local_shipping_rounded),
    ('courses', 'Courses', Icons.shopping_bag_rounded),
    ('autre', 'Autre', Icons.handyman_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final t = _types[index];
          return _TypeChip(
            value: t.$1,
            label: t.$2,
            icon: t.$3,
            selected: selected == t.$1,
            onTap: () => onSelected(t.$1),
          );
        },
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 108,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? _kYellow.withValues(alpha: 0.18) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _kYellow : const Color(0xFFE8E8E8),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _kYellow.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? _kYellow.withValues(alpha: 0.35) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.black : Colors.grey.shade600,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: Colors.black,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DescriptionModeSelector extends StatelessWidget {
  final _MissionDescriptionMode mode;
  final ValueChanged<_MissionDescriptionMode> onChanged;

  const _DescriptionModeSelector({
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeChip(
            label: 'Écriture',
            icon: Icons.edit_outlined,
            selected: mode == _MissionDescriptionMode.text,
            onTap: () => onChanged(_MissionDescriptionMode.text),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModeChip(
            label: 'Vocal',
            icon: Icons.mic_rounded,
            selected: mode == _MissionDescriptionMode.vocal,
            onTap: () => onChanged(_MissionDescriptionMode.vocal),
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _kYellow.withValues(alpha: 0.25) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _kYellow : const Color(0xFFE0E0E0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.black),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextDescriptionField extends StatelessWidget {
  final TextEditingController controller;

  const _TextDescriptionField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      minLines: 3,
      style: const TextStyle(color: Colors.black, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Décrivez votre besoin au clavier…',
        hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 15),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
    );
  }
}

class _VocalRecorder extends StatelessWidget {
  final bool isRecording;
  final int recordingSeconds;
  final bool hasRecording;
  final VoidCallback onMicPressed;

  const _VocalRecorder({
    required this.isRecording,
    required this.recordingSeconds,
    required this.hasRecording,
    required this.onMicPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecording ? Colors.red.shade300 : const Color(0xFFE0E0E0),
          width: isRecording ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isRecording)
            RecordingTimerDisplay(seconds: recordingSeconds)
          else
            Text(
              hasRecording
                  ? 'Enregistrement vocal prêt à être joint'
                  : 'Appuyez sur le micro pour enregistrer votre besoin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onMicPressed,
              borderRadius: BorderRadius.circular(32),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isRecording ? Colors.red.shade50 : _kYellow.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                  color: isRecording ? Colors.red.shade700 : Colors.black87,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OptionSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      activeThumbColor: Colors.white,
      activeTrackColor: _kSwitchGreen,
      onChanged: onChanged,
    );
  }
}

class _AmountField extends StatelessWidget {
  final String label;
  final String? helperText;
  final String? errorText;
  final TextEditingController controller;
  final IconData icon;
  final ValueChanged<String>? onChanged;

  const _AmountField({
    required this.label,
    required this.controller,
    required this.icon,
    this.helperText,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.black),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        helperText: helperText,
        helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        errorText: errorText,
        prefixIcon: Icon(icon, color: Colors.black),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? _kYellow.withValues(alpha: 0.2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _kYellow : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.black),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
