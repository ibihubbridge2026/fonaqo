import 'package:flutter/material.dart';
import '../../../widgets/custom_app_bar.dart';
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
  String selectedMode = ''; // 'queue' ou 'service'

  void next() => setState(() => currentStep++);
  void back() => setState(() => currentStep--);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF0),
      appBar: CustomAppBar.detailStack(
        detailTitleWidget: Text(
          "Étape $currentStep/5",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        leadingOnBackPressed: () {
          if (currentStep > 1) {
            back();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    switch (currentStep) {
      case 1: return Step1TypeSelector(onTypeSelected: (mode) {
        selectedMode = mode;
        next();
      });
      case 2: return Step2LogisticsForm(mode: selectedMode, onNext: next);
      case 3: return Step3PaymentSummary(mode: selectedMode, onPaid: next);
      case 4: return Step4MatchingAgents(onConfirmed: next);
      case 5: return const Step5TrackingView();
      default: return const SizedBox.shrink();
    }
  }
}