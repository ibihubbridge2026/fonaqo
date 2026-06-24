import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:fonaco/core/constants/app_constants.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/features/ai/ai_assistant_repository.dart';
import 'package:fonaco/features/client/models/agent_model.dart';
import 'package:fonaco/features/client/widgets/ai_agent_card.dart';
import 'package:fonaco/widgets/custom_app_bar.dart';
import 'package:go_router/go_router.dart';

/// Assistant IA Moki — aide via API backend + suggestions agents dynamiques.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiAssistantRepository _repository = AiAssistantRepository();

  static const _welcomeText =
      'Bonjour, je suis Moki 👋\n'
      'Je peux vous aider sur les missions, paiements, litiges '
      'et vous suggérer des agents disponibles près de vous.';

  final List<_ChatTurn> _messages = [
    const _ChatTurn(
      isUser: false,
      text: _welcomeText,
    ),
  ];

  static const _quickPrompts = [
    'Comment créer une mission ?',
    'Trouver un agent pour une livraison',
    'Paiement FeexPay ou portefeuille',
    'Ouvrir un litige',
  ];

  bool _thinking = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: AppConstants.locationTimeout,
        ),
      );
      if (!mounted) return;
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
    } catch (_) {}
  }

  List<Map<String, String>> _buildHistory() {
    return _messages
        .skip(1)
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .where((m) => m['content']!.isNotEmpty)
        .toList();
  }

  bool _isDuplicateWelcome(String reply) {
    final normalized = reply.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return normalized.contains('je suis moki') &&
        normalized.contains('bonjour');
  }

  List<_ChatTurn> get _visibleMessages {
    var welcomeKept = false;
    return _messages.where((m) {
      if (!m.isUser && _isDuplicateWelcome(m.text)) {
        if (welcomeKept) return false;
        welcomeKept = true;
      }
      return true;
    }).toList();
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

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _thinking) return;

    setState(() {
      _messages.add(_ChatTurn(isUser: true, text: text));
      _thinking = true;
    });
    _controller.clear();
    _scrollToBottom();

    final history = _buildHistory();
    if (history.isNotEmpty) {
      history.removeLast();
    }

    try {
      final response = await _repository.ask(
        message: text,
        history: history,
      );

      List<AgentModel> agents = const [];
      if (response.suggestAgents) {
        final rawAgents = await _repository.searchAgents(
          hints: response.agentSearch,
          latitude: _latitude ?? AppConstants.defaultLatitude,
          longitude: _longitude ?? AppConstants.defaultLongitude,
        );
        agents = rawAgents.map(AgentModel.fromApiMap).toList();
      }

      if (!mounted) return;
      setState(() {
        if (!_isDuplicateWelcome(response.reply)) {
          _messages.add(
            _ChatTurn(
              isUser: false,
              text: response.reply,
              agents: agents,
            ),
          );
        } else if (agents.isNotEmpty) {
          _messages.add(
            _ChatTurn(
              isUser: false,
              text: 'Voici des agents qui pourraient vous aider :',
              agents: agents,
            ),
          );
        }
        _thinking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatTurn(
            isUser: false,
            text: 'Désolé, une erreur est survenue. Réessayez dans un instant.',
          ),
        );
        _thinking = false;
      });
    }
    _scrollToBottom();
  }

  void _openAgentProfile(AgentModel agent) {
    context.push(AppRoutes.agentProfile, extra: {
        'agentId': agent.id,
        'agent': {
          'id': agent.id,
          'first_name': agent.name.split(' ').first,
          'last_name': agent.name.split(' ').skip(1).join(' '),
          'specialty': agent.specialty,
          'avatar_url': agent.avatarUrl,
          'rating': agent.rating,
          'is_verified': true,
          'expertise_tags': [agent.specialty],
        },
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CustomAppBar.detailStack(
        title: 'Assistant Moki',
        detailTitleWidget: const Row(
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
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  label: Text(
                    prompt,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  onPressed: _thinking ? null : () => _send(prompt),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _visibleMessages.length + (_thinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (_thinking && index == _visibleMessages.length) {
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
                return _Bubble(
                  turn: _visibleMessages[index],
                  onAgentTap: _openAgentProfile,
                );
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
                          hintText: 'Posez votre question ou décrivez votre besoin…',
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
                      onTap: _thinking ? null : () => _send(),
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
  final List<AgentModel> agents;

  const _ChatTurn({
    required this.isUser,
    required this.text,
    this.agents = const [],
  });
}

class _Bubble extends StatelessWidget {
  final _ChatTurn turn;
  final void Function(AgentModel agent) onAgentTap;

  const _Bubble({
    required this.turn,
    required this.onAgentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: turn.isUser ? 40 : 0,
        right: turn.isUser ? 0 : 40,
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment:
            turn.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!turn.isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFFFD400),
              child: const Icon(Icons.auto_awesome, size: 14, color: Colors.black),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: turn.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: turn.isUser
                        ? const Color(0xFFFFD400)
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(turn.isUser ? 16 : 4),
                      bottomRight: Radius.circular(turn.isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: turn.isUser
                          ? const Color(0xFFE0B800)
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
                if (turn.agents.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      'Agents suggérés',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  ...turn.agents.map(
                    (agent) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => onAgentTap(agent),
                        borderRadius: BorderRadius.circular(20),
                        child: AiAgentCard(agent: agent),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
