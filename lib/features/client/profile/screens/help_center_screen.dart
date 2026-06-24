import 'package:flutter/material.dart';

import 'package:fonaco/core/config/app_configuration.dart';
import 'package:fonaco/core/services/support_config_service.dart';
import 'package:fonaco/widgets/custom_app_bar.dart';

/// Centre d'aide client — FAQ + contact support.
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  SupportConfig? _config;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cfg = await SupportConfigService().fetch(profile: 'client');
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
        question: 'Comment créer une mission ?',
        answer:
            'Depuis l\'accueil ou l\'onglet Missions, ouvrez « Créer une mission », '
            'choisissez le type, renseignez la logistique puis confirmez.',
      ),
      (
        question: 'Comment contacter un agent ?',
        answer:
            'Une fois une mission créée ou acceptée, utilisez le chat lié à la mission.',
      ),
      (
        question: 'Frais et paiement',
        answer:
            'Le montant affiché au récapitulatif est celui bloqué en séquestre. '
            'Les frais plateforme sont prélevés uniquement lors du versement à l\'agent.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfiguration.instance;
    final phone = _config?.phone ?? config.clientServicePhone;
    final email = _config?.email ?? config.clientSupportEmail;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const CustomAppBar.detailStack(
        title: 'Centre d\'aide',
        detailTitleWidget: Text(
          'Centre d\'aide',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD400)))
          : RefreshIndicator(
              color: const Color(0xFFFFD400),
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Text(
                    'Questions fréquentes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._faqs.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FaqTile(question: f.question, answer: f.answer),
                    ),
                  ),
                  const SizedBox(height: 24),
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
      collapsedBackgroundColor: Colors.white,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      collapsedShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        question,
        style:
            const TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          color: Colors.white,
          child: Text(answer,
              style: const TextStyle(height: 1.45, color: Colors.grey)),
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
