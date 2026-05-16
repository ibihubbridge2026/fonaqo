import 'package:flutter/material.dart';

import 'package:fonaco/widgets/custom_app_bar.dart';

/// Centre d'aide : FAQ accordéon + liens politiques en pied de page.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const CustomAppBar.detailStack(
        title: 'Centre d\'aide',
        detailTitleWidget: Text(
          'Centre d\'aide',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              'Questions fréquentes',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            const _FaqTile(
              question: 'Comment créer une mission ?',
              answer:
                  'Depuis l’accueil ou l’onglet Missions, ouvrez le flux « Créer une mission », '
                  'choisissez le type (file ou service), renseignez la logistique puis confirmez le récapitulatif.',
            ),
            const SizedBox(height: 10),
            const _FaqTile(
              question: 'Comment contacter un agent ?',
              answer:
                  'Une fois une mission créée ou acceptée, utilisez le chat lié à la mission. '
                  'Vous pouvez aussi consulter les suggestions d’agents sur l’accueil.',
            ),
            const SizedBox(height: 10),
            const _FaqTile(
              question: 'Que couvrent les frais FONACO (10 %) ?',
              answer:
                  'Les frais de service contribuent à la plateforme, au support et à la sécurisation des paiements '
                  '(hors intégration FeexPay en cours de déploiement).',
            ),
            const SizedBox(height: 10),
            const _FaqTile(
              question: 'Paiement et portefeuille',
              answer:
                  'Le portefeuille et les paiements seront synchronisés avec le backend après intégration complète des prestataires.',
            ),
            const SizedBox(height: 32),
            Text(
              'Politiques & confiance',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            _PolicyCard(
              title: 'Confidentialité',
              body:
                  'Nous traitons vos données personnelles uniquement pour fournir le service FONACO, '
                  'améliorer la sécurité des missions et respecter la réglementation applicable. '
                  'Vous pouvez demander l’accès ou la rectification via le support.',
            ),
            const SizedBox(height: 10),
            _PolicyCard(
              title: 'Conditions d’utilisation',
              body:
                  'L’utilisation de l’application implique le respect des lois locales, des agents et des clients. '
                  'Les missions frauduleuses ou les comportements abusifs peuvent entraîner la suspension du compte.',
            ),
            const SizedBox(height: 10),
            _PolicyCard(
              title: 'Sécurité',
              body:
                  'Les échanges sensibles passent par des canaux sécurisés. Ne partagez jamais votre mot de passe '
                  'ou codes OTP. Signalez tout incident depuis la section litiges ou le support.',
            ),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final String title;
  final String body;

  const _PolicyCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
