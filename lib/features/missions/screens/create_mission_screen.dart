import 'package:flutter/material.dart';
import '../widgets/step_1_type_selector.dart';
import '../widgets/step_2_logistics_form.dart';
import '../widgets/step_3_payment_summary.dart';
import '../widgets/step_4_matching_agents.dart';
import '../widgets/step_5_tracking_view.dart';
import '../../../widgets/main_wrapper.dart';

class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  int currentStep = 1;
  String selectedMode = ''; // 'queue' ou 'service'
  String description = '';

  void next() => setState(() => currentStep++);
  void back() => setState(() => currentStep--);

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
              "Étape $currentStep/5",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
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
            selectedMode = mode;
            description = desc;
            next();
          },
        );
      case 2: return Step2LogisticsForm(mode: selectedMode, onNext: next);
      case 3: return Step3PaymentSummary(mode: selectedMode, onPaid: next);
      case 4: return Step4MatchingAgents(onConfirmed: next);
      case 5:
        return Step5TrackingView(
          onBackToMissions: () => MainShellScope.maybeOf(context)?.closeCreateMission(),
        );
      default: return const SizedBox.shrink();
    }
  }
}