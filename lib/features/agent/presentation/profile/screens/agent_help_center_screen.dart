import 'package:flutter/material.dart';

import 'package:fonaco/core/config/app_configuration.dart';
import 'package:fonaco/widgets/custom_app_bar.dart';

/// Centre d'aide agent — FAQ missions, boost, KYC, litiges.
class AgentHelpCenterScreen extends StatelessWidget {
  const AgentHelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppConfiguration.instance;

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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _FaqTile(
            question: 'Comment accepter une mission ?',
            answer:
                'Depuis l\'accueil ou l\'onglet Missions, parcourez les missions disponibles '
                'près de vous et appuyez sur « Accepter ». Vous serez guidé étape par étape.',
          ),
          const SizedBox(height: 10),
          const _FaqTile(
            question: 'Qu\'est-ce que le boost profil ?',
            answer:
                'Le boost vous donne une priorité de 10 minutes sur les nouvelles missions '
                'dans votre zone. Activez-le depuis l\'accueil ou votre profil.',
          ),
          const SizedBox(height: 10),
          const _FaqTile(
            question: 'Validation KYC',
            answer:
                'Téléversez votre pièce d\'identité et un selfie depuis l\'écran de verrouillage KYC. '
                'Une fois approuvé par FONACO, vous accédez au dashboard complet.',
          ),
          const SizedBox(height: 10),
          const _FaqTile(
            question: 'Fin de mission et paiement',
            answer:
                'Soumettez une photo preuve, attendez la validation client (QR), puis les fonds '
                'escrow sont libérés sur votre portefeuille agent.',
          ),
          const SizedBox(height: 10),
          const _FaqTile(
            question: 'Litige sur une mission',
            answer:
                'Depuis la mission active, ouvrez un litige avec description et motif. '
                'L\'équipe FONACO examine le dossier sous 48 h.',
          ),
          const SizedBox(height: 24),
          _ContactCard(
            email: config.agentSupportEmail,
            phone: config.clientServicePhone,
          ),
        ],
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
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          title: Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          children: [
            Text(
              answer,
              style: TextStyle(color: Colors.grey.shade700, height: 1.45),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD400),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Support agent FONACO',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$email · $phone',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }
}
