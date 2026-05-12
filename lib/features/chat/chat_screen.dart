import 'package:flutter/material.dart';

import '../../widgets/custom_app_bar.dart';

/// Liste de conversations factice avec barre composée commune et bulles riches.
///
/// Conservé depuis l’ancienne UI pour ne pas perdre les cas : message texte +
/// message avec fichier image distant.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  static const String _partnerAvatarUrl = 'https://i.pravatar.cc/150?u=julien';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(
        title: 'Conversation',
        detailTitleWidget: _ChatConversationTitle(
          partnerAvatarUrl: _partnerAvatarUrl,
        ),
        detailTrailingActions: [
          _ChatToolbarIcon(icon: Icons.call_outlined),
          _ChatToolbarIcon(icon: Icons.more_vert),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: const [
                _ChatDateDivider(label: 'AUJOURD’HUI'),
                SizedBox(height: 24),
                ChatMessageBubble(
                  message:
                      "Bonjour ! Je suis arrivé devant le bâtiment. Je prends votre place dans la file d'attente dès maintenant. Est-ce bien pour le guichet 4 ?",
                  isFromCurrentUser: false,
                  timestampLabel: '14:02',
                ),
                ChatMessageBubble(
                  message:
                      'Parfait, merci Julien. Oui, c’est bien le guichet 4. Je vous rejoins dans 15 minutes dès que j’approche du quartier.',
                  isFromCurrentUser: true,
                  timestampLabel: '14:05',
                ),
                ChatMessageBubble(
                  message:
                      "C'est noté. Voici une photo de l'avancement de la file. Il n'y a que 3 personnes devant moi.",
                  isFromCurrentUser: false,
                  timestampLabel: '14:10',
                  inlineImageNetworkUrl:
                      'https://images.unsplash.com/photo-1556742049-630566e4a00a?q=80&w=500',
                ),
              ],
            ),
          ),
          const ChatComposerPanel(),
        ],
      ),
    );
  }
}

class _ChatToolbarIcon extends StatelessWidget {
  final IconData icon;

  const _ChatToolbarIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.black),
      onPressed: () {},
    );
  }
}

/// Ligne titre conversation : avatar partenaire + nom + présence factice en ligne.
class _ChatConversationTitle extends StatelessWidget {
  final String partnerAvatarUrl;

  const _ChatConversationTitle({required this.partnerAvatarUrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 20,
          child: ClipOval(
            child: Image.network(
              partnerAvatarUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Icon(Icons.person, color: Colors.white70);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Julien B.',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'En ligne',
              style: TextStyle(color: Colors.green[600], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

/// Séparateur de date façon messenger.
class _ChatDateDivider extends StatelessWidget {
  final String label;

  const _ChatDateDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

/// Bulle enrichie pouvant contenir une image réseau en pièce jointe miniature.
///
/// [message]: texte métier envoyé dans la bulle.
///
/// [isFromCurrentUser]: alignement et couleurs inversées pour vos messages envoyés vers l’agent.
///
/// [timestampLabel]: petite horodate sous la bulle.
///
/// [inlineImageNetworkUrl]: optionnel pour afficher un visuel téléchargé (placeholder si HTTP échoue).
class ChatMessageBubble extends StatelessWidget {
  final String message;
  final bool isFromCurrentUser;
  final String timestampLabel;
  final String? inlineImageNetworkUrl;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
    required this.timestampLabel,
    this.inlineImageNetworkUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: isFromCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isFromCurrentUser ? const Color(0xFF1A1C1C) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isFromCurrentUser ? 20 : 0),
                bottomRight: Radius.circular(isFromCurrentUser ? 0 : 20),
              ),
              border: isFromCurrentUser
                  ? null
                  : const Border(
                      left: BorderSide(color: Color(0xFFFFD400), width: 4),
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: isFromCurrentUser ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
                if (inlineImageNetworkUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      inlineImageNetworkUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: Colors.grey[200],
                          height: 120,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timestampLabel,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre de saisi basse sticky (texte / pièce jointe / envoyer).
class ChatComposerPanel extends StatelessWidget {
  const ChatComposerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEEEEEE),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Écrire votre message...',
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.image_outlined, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFFFD400),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.black),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
