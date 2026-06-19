import 'package:flutter/material.dart';

import 'package:fonaco/core/config/app_configuration.dart';
import 'package:fonaco/core/services/support_config_service.dart';
import 'package:fonaco/widgets/custom_app_bar.dart';

/// Centre d'aide agent — FAQ dynamique via API + contact support.
class AgentHelpCenterScreen extends StatefulWidget {
  const AgentHelpCenterScreen({super.key});

  @override
  State<AgentHelpCenterScreen> createState() => _AgentHelpCenterScreenState();
}

class _AgentHelpCenterScreenState extends State<AgentHelpCenterScreen> {
  SupportConfig? _config;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cfg = await SupportConfigService().fetch(profile: 'agent');
    if (mounted) {
      setState(() {
        _config = cfg;
        _loading = false;
      });
    }
  }

  List<({String question, String answer})> get _faqs {
    if (_config != null && _config!.faqs.isNotEmpty) return _config!.faqs;
    return const [
      (
        question: 'Comment accepter une mission ?',
        answer:
            'Depuis l\'accueil ou l\'onglet Missions, parcourez les missions disponibles '
            'près de vous et appuyez sur « Accepter ».',
      ),
      (
        question: 'Validation KYC',
        answer:
            'Téléversez votre pièce d\'identité et un selfie. Une fois approuvé, '
            'vous accédez au dashboard complet.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfiguration.instance;
    final phone = _config?.phone ?? config.clientServicePhone;
    final email = _config?.email ?? config.agentSupportEmail;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(
        title: 'Centre d\'aide Agent',
        detailTitleWidget: Text(
          'Centre d\'aide Agent',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD400)))
          : RefreshIndicator(
              color: const Color(0xFFFFD400),
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ..._faqs.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FaqTile(
                        question: f.question,
                        answer: f.answer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ContactCard(email: email, phone: phone),
                ],
              ),
            ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      collapsedBackgroundColor: const Color(0xFFFFD400),
      backgroundColor: const Color(0xFFFFD400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      collapsedShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: const TextStyle(height: 1.45)),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String email;
  final String phone;

  const _ContactCard({required this.email, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD400),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD400)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contacter le support',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('Téléphone : $phone'),
          Text('Email : $email'),
        ],
      ),
    );
  }
}
