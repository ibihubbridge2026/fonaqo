import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/wallet_provider.dart';
import '../../../widgets/main_wrapper.dart';
import '../mission_repository.dart';
import '../widgets/step_1_type_selector.dart';
import '../widgets/step_2_logistics_form.dart';
import '../widgets/step_3_payment_summary.dart';
import '../widgets/step_4_matching_agents.dart';
import '../widgets/step_5_tracking_view.dart';

class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  int currentStep = 1;
  String _mode = '';
  String _description = '';
  String _logisticsAddress = '';
  double _logisticsLat = 5.36;
  double _logisticsLng = -4.0083;

  final MissionRepository _missionRepository = MissionRepository();

  void next() => setState(() => currentStep++);
  void back() => setState(() => currentStep--);

  String _missionTitle() {
    final prefix = _mode == 'queue' ? 'File' : 'Libre';
    final short = _description.trim().isEmpty
        ? 'Sans description'
        : (_description.trim().length > 120
            ? '${_description.trim().substring(0, 120)}…'
            : _description.trim());
    return 'Mission $prefix — $short';
  }

  Future<void> _onPaymentValidated(MissionPaymentTotals totals) async {
    final wallet = context.read<WalletProvider>();
    if (!wallet.canAfford(totals.totalCfa)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solde portefeuille insuffisant (simulation).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final priceMission = totals.paySupplierDirectly
        ? 1.0
        : totals.purchaseBudgetCfa;

    try {
      await _missionRepository.createMission(
        MissionCreatePayload(
          title: _missionTitle(),
          description:
              _description.trim().isEmpty ? _missionTitle() : _description.trim(),
          address: _logisticsAddress,
          latitude: _logisticsLat,
          longitude: _logisticsLng,
          price: priceMission,
          serviceFee: totals.serviceFeeCfa,
        ),
      );

      if (!mounted) return;

      final ok = wallet.deduct(totals.totalCfa);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour du portefeuille local.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Paiement enregistré'),
          content: const Text(
            'Votre mission a été créée et le montant a été réservé sur votre portefeuille (simulation).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );

      if (mounted) next();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de créer la mission : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                if (currentStep > 1) {
                  back();
                } else {
                  MainShellScope.maybeOf(context)?.closeCreateMission();
                }
              },
              icon: const Icon(Icons.close, color: Colors.black),
            ),
            Text(
              'Étape $currentStep/5',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            child: _buildStep(),
          ),
        ),
      ],
    );
  }

  Widget _buildStep() {
    switch (currentStep) {
      case 1:
        return Step1TypeSelector(
          onNext: (mode, desc) {
            setState(() {
              _mode = mode;
              _description = desc;
            });
            next();
          },
        );
      case 2:
        return Step2LogisticsForm(
          mode: _mode,
          onNext: (draft) {
            setState(() {
              _logisticsAddress = draft.address;
              _logisticsLat = draft.latitude;
              _logisticsLng = draft.longitude;
            });
            next();
          },
        );
      case 3:
        return Step3PaymentSummary(
          mode: _mode,
          onPayAndValidate: _onPaymentValidated,
        );
      case 4:
        return Step4MatchingAgents(onConfirmed: next);
      case 5:
        return Step5TrackingView(
          onBackToMissions: () =>
              MainShellScope.maybeOf(context)?.closeCreateMission(),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
