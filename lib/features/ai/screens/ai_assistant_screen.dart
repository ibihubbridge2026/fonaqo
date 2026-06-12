import 'package:flutter/material.dart';

import '../../../widgets/custom_app_bar.dart';

/// Assistant IA Moki — aide générale et suggestions d'agents.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatTurn> _messages = [
    const _ChatTurn(
      isUser: false,
      text:
          'Bonjour, je suis Moki 👋\n'
          'Posez-moi vos questions sur FONACO : création de mission, '
          'paiement, agents disponibles, litiges…',
    ),
  ];
  bool _thinking = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _thinking) return;

    setState(() {
      _messages.add(_ChatTurn(isUser: true, text: text));
      _thinking = true;
    });
    _controller.clear();
    _scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatTurn(isUser: false, text: _replyFor(text)));
      _thinking = false;
    });
    _scrollToBottom();
  }

  String _replyFor(String input) {
    final q = input.toLowerCase();
    if (q.contains('agent') || q.contains('favori')) {
      return 'Consultez l’onglet Agents ou vos favoris depuis l’accueil. '
          'Vous pouvez contacter un agent après qu’il accepte votre mission.';
    }
    if (q.contains('mission') || q.contains('créer')) {
      return 'Pour créer une mission : onglet Missions → CRÉER. '
          'Choisissez la catégorie, décrivez votre besoin (texte ou micro), '
          'puis indiquez la destination.';
    }
    if (q.contains('paiement') || q.contains('wallet') || q.contains('feex')) {
      return 'Vous pouvez payer via FeexPay ou votre portefeuille FONACO. '
          'Le montant minimal de prestation est de 500 FCFA.';
    }
    if (q.contains('annul')) {
      return 'Une mission acceptée ou en cours peut être annulée avec un '
          'dédommagement obligatoire de 20 % pour l’agent.';
    }
    if (q.contains('litige')) {
      return 'Ouvrez un litige depuis le détail d’une mission en cours. '
          'Notre équipe revient vers vous sous 24 h ouvrées maximum.';
    }
    return 'Merci pour votre message. Pour une aide personnalisée, '
        'consultez le centre d’aide ou contactez le support FONACO.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CustomAppBar.detailStack(
        title: 'Assistant Moki',
        detailTitleWidget: Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFB8860B), size: 22),
            SizedBox(width: 8),
            Text(
              'Moki — Assistant IA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (_thinking && index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final msg = _messages[index];
                return _Bubble(turn: msg);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Posez votre question…',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: const Color(0xFFFFD400),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _send,
                      borderRadius: BorderRadius.circular(24),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.send_rounded, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTurn {
  final bool isUser;
  final String text;
  const _ChatTurn({required this.isUser, required this.text});
}

class _Bubble extends StatelessWidget {
  final _ChatTurn turn;
  const _Bubble({required this.turn});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: turn.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: turn.isUser ? const Color(0xFFD9FDD3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: turn.isUser
                ? const Color(0xFFB8E6B0)
                : const Color(0xFFE8E8E8),
          ),
        ),
        child: Text(
          turn.text,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
