import 'package:flutter/material.dart';

import '../../../widgets/custom_app_bar.dart';

/// Centre d’aide (FAQ + support) — UI simple.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(
        detailTitleWidget: Text('Centre d’aide', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            _FaqTile(question: 'Comment créer une mission ?', answer: 'Depuis l’accueil, appuyez sur “CRÉER UNE MISSION”.'),
            SizedBox(height: 12),
            _FaqTile(question: 'Comment contacter un agent ?', answer: 'Ouvrez l’onglet Agents ou utilisez le chat.'),
            SizedBox(height: 12),
            _FaqTile(question: 'Paiement et facturation', answer: 'Les options de paiement seront disponibles dans une prochaine version.'),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12)],
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w900)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(answer, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}

