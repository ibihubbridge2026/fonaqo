import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:fonaco/core/api/base_client.dart';
import 'package:fonaco/core/widgets/agent_progress_badge.dart';
import 'package:fonaco/widgets/custom_app_bar.dart';

/// Écran de profil d'un agent accessible par le client (données API).
class ClientAgentProfileScreen extends StatefulWidget {
  final String agentId;
  final bool showSelectAgentButton;

  const ClientAgentProfileScreen({
    super.key,
    required this.agentId,
    this.showSelectAgentButton = true,
  });

  factory ClientAgentProfileScreen.fromRouteArguments(
    Map<String, dynamic>? args,
  ) {
    final agent = args?['agent'] as Map<String, dynamic>? ?? {};
    final agentId =
        args?['agentId']?.toString() ?? agent['id']?.toString() ?? '';
    return ClientAgentProfileScreen(
      agentId: agentId,
      showSelectAgentButton: args?['showSelectAgentButton'] != false,
    );
  }

  @override
  State<ClientAgentProfileScreen> createState() =>
      _ClientAgentProfileScreenState();
}

class _ClientAgentProfileScreenState extends State<ClientAgentProfileScreen> {
  static const _fallbackAvatar = 'assets/images/avatar/user.png';
  final _client = BaseClient();

  Map<String, dynamic>? _data;
  bool _loading = true;
  int _reviewsVisible = 5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.agentId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await _client.get('public/artisans/${widget.agentId}/');
      final body = res.data;
      if (body is Map && body['data'] is Map) {
        _data = Map<String, dynamic>.from(body['data'] as Map);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD400)),
        ),
      );
    }

    final d = _data ?? {};
    final name =
        '${d['first_name'] ?? ''} ${d['last_name'] ?? ''}'.trim().isEmpty
            ? 'Agent'
            : '${d['first_name'] ?? ''} ${d['last_name'] ?? ''}'.trim();
    final role = d['specialty']?.toString() ??
        d['service_domain']?.toString() ??
        'Agent FONACO';
    final bio = d['bio']?.toString() ?? d['biography']?.toString() ?? '';
    final rating = (d['rating'] as num?)?.toDouble() ?? 0;
    final completed = d['completed_missions']?.toString() ?? '0';
    final avatar = d['avatar_url']?.toString();
    final isBoosted = d['is_boosted'] == true;
    final reviews = (d['reviews'] as List<dynamic>?) ?? [];
    final showSelect = widget.showSelectAgentButton;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar.detailStack(
        title: 'Profil Agent',
        detailTrailingActions: [
          if (d['certified'] == true)
            const Icon(Icons.verified, color: Colors.blue, size: 22),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatar != null && avatar.isNotEmpty
                  ? CachedNetworkImageProvider(avatar)
                  : const AssetImage(_fallbackAvatar) as ImageProvider,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000000),
              ),
            ),
            Text(role, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            AgentProgressBadge(
              badge: d['badge'] is Map
                  ? Map<String, dynamic>.from(d['badge'] as Map)
                  : null,
            ),
            if (isBoosted)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD400),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Boosté',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Color(0xFFFFD400)),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$completed missions',
                  style: const TextStyle(color: Color(0xFF000000)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (showSelect)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD400),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Sélectionner cet agent',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (bio.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'À propos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  bio,
                  style: const TextStyle(
                    height: 1.5,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Avis et Commentaires',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Aucun avis pour le moment'),
              )
            else
              ...reviews.take(_reviewsVisible).map((r) {
                final review = r as Map<String, dynamic>;
                final comment = review['comment']?.toString() ?? '';
                final short = comment.length > 120
                    ? '${comment.substring(0, 120)}…'
                    : comment;
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review['client_name']?.toString() ?? 'Client',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF000000),
                            ),
                          ),
                          const Spacer(),
                          Text('★ ${review['rating']}'),
                        ],
                      ),
                      if (short.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(short, style: const TextStyle(height: 1.4)),
                      ],
                    ],
                  ),
                );
              }),
            if (reviews.length > _reviewsVisible)
              TextButton(
                onPressed: () => setState(() => _reviewsVisible += 5),
                child: const Text('Charger plus'),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
