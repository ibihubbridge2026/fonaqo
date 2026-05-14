import 'package:flutter/material.dart';

import '../../core/api/base_client.dart';
import '../../widgets/custom_app_bar.dart';

/// Liste des notifications côté client (Requester).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final BaseClient _api = BaseClient();
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.get('notifications/');
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        setState(() {
          _notifications = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  IconData _iconForTitle(String title) {
    if (title.toLowerCase().contains('agent') ||
        title.toLowerCase().contains('arriv')) {
      return Icons.directions_walk;
    }
    if (title.toLowerCase().contains('mission')) {
      return Icons.assignment_outlined;
    }
    if (title.toLowerCase().contains('message') ||
        title.toLowerCase().contains('chat')) {
      return Icons.chat_bubble_outline;
    }
    return Icons.notifications_none;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(
        title: 'Notifications',
        detailTitleWidget: Text(
          'Notifications',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!,
                style: TextStyle(color: Colors.red[700], fontSize: 13)),
            const SizedBox(height: 8),
            TextButton(
                onPressed: _loadNotifications, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('Aucune notification',
              style: TextStyle(color: Colors.grey, fontSize: 15)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: _notifications
          .map((notif) => _NotifTile(
                title: notif['title'] ?? '',
                subtitle: notif['body'] ?? '',
                time: notif['time_ago'] ?? '',
                icon: _iconForTitle(notif['title'] ?? ''),
                isRead: notif['is_read'] ?? false,
                onTap: () {
                  // TODO: Marquer comme lue via API
                },
              ))
          .toList(),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final bool isRead;
  final VoidCallback? onTap;

  const _NotifTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    this.isRead = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isRead ? Colors.white : const Color(0xFFFFD400).withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: isRead
              ? null
              : Border.all(color: const Color(0xFFFFD400).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD400).withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                      color: isRead ? Colors.black87 : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              time,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD400),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
