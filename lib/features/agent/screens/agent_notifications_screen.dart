import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/providers/notification_provider.dart';
import 'package:fonaco/features/agent/providers/agent_provider.dart';

enum _AgentNotifType { mission, dispute, system, payment, boost, other }

class AgentNotificationsScreen extends StatefulWidget {
  const AgentNotificationsScreen({super.key});

  @override
  State<AgentNotificationsScreen> createState() =>
      _AgentNotificationsScreenState();
}

class _AgentNotificationsScreenState extends State<AgentNotificationsScreen> {
  List<_AgentNotificationItem> _items = [];
  bool _isLoading = true;
  bool _isMarkingAll = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final raw = await context
          .read<AgentProvider>()
          .profileRepository
          .getNotifications();

      final items = raw.map(_AgentNotificationItem.fromApi).toList();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement : $e')),
      );
    }
  }

  Future<void> _markAsRead(String id) async {
    final index = _items.indexWhere((n) => n.id == id);
    if (index < 0 || _items[index].isRead) return;

    setState(() => _items[index] = _items[index].copyWith(isRead: true));

    final ok = await context
        .read<AgentProvider>()
        .profileRepository
        .markNotificationAsRead(id);
    if (!ok && mounted) {
      setState(() => _items[index] = _items[index].copyWith(isRead: false));
    } else if (mounted) {
      await context.read<NotificationProvider>().refreshCounts();
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() => _isMarkingAll = true);
    final ok = await context
        .read<AgentProvider>()
        .profileRepository
        .markAllNotificationsAsRead();
    if (!mounted) return;
    if (ok) {
      setState(() {
        _items = _items.map((n) => n.copyWith(isRead: true)).toList();
      });
      await context.read<NotificationProvider>().refreshCounts();
    }
    setState(() => _isMarkingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _isMarkingAll ? null : _markAllAsRead,
              child: Text(
                _isMarkingAll ? '...' : 'Tout lire',
                style: const TextStyle(
                  color: Color(0xFFE0B800),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune notification',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _NotificationTile(
                        item: item,
                        onTap: () => _markAsRead(item.id),
                      );
                    },
                  ),
                ),
    );
  }
}

class _AgentNotificationItem {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final _AgentNotifType type;
  final bool isRead;

  const _AgentNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.type,
    required this.isRead,
  });

  factory _AgentNotificationItem.fromApi(Map<String, dynamic> json) {
    final title = json['title']?.toString() ?? '';
    final lower = title.toLowerCase();
    _AgentNotifType type;
    if (lower.contains('litige') || lower.contains('dispute')) {
      type = _AgentNotifType.dispute;
    } else if (lower.contains('mission')) {
      type = _AgentNotifType.mission;
    } else if (lower.contains('paiement') || lower.contains('wallet')) {
      type = _AgentNotifType.payment;
    } else if (lower.contains('boost')) {
      type = _AgentNotifType.boost;
    } else if (lower.contains('système') || lower.contains('system')) {
      type = _AgentNotifType.system;
    } else {
      type = _AgentNotifType.other;
    }

    return _AgentNotificationItem(
      id: json['id']?.toString() ?? '',
      title: title,
      body: json['body']?.toString() ?? '',
      timeAgo: json['time_ago']?.toString() ??
          json['created_at']?.toString() ??
          '',
      type: type,
      isRead: json['is_read'] == true,
    );
  }

  _AgentNotificationItem copyWith({bool? isRead}) {
    return _AgentNotificationItem(
      id: id,
      title: title,
      body: body,
      timeAgo: timeAgo,
      type: type,
      isRead: isRead ?? this.isRead,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final _AgentNotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  Color get _badgeColor {
    switch (item.type) {
      case _AgentNotifType.mission:
        return const Color(0xFF2EC4B6);
      case _AgentNotifType.dispute:
        return Colors.orange.shade700;
      case _AgentNotifType.system:
        return Colors.blueGrey;
      case _AgentNotifType.payment:
        return Colors.blue;
      case _AgentNotifType.boost:
        return Colors.purple;
      case _AgentNotifType.other:
        return Colors.grey;
    }
  }

  String get _typeLabel {
    switch (item.type) {
      case _AgentNotifType.mission:
        return 'Nouvelle Mission';
      case _AgentNotifType.dispute:
        return 'Rappel Litige';
      case _AgentNotifType.system:
        return 'Système';
      case _AgentNotifType.payment:
        return 'Paiement';
      case _AgentNotifType.boost:
        return 'Boost';
      case _AgentNotifType.other:
        return 'Alerte';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0.5,
      color: item.isRead ? Colors.white : const Color(0xFFF5FBFA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _badgeColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _typeLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _badgeColor,
                ),
              ),
            ),
            if (!item.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF2EC4B6),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.title,
              style: TextStyle(
                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                color: Colors.black,
                fontSize: 15,
              ),
            ),
            if (item.body.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                item.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              item.timeAgo,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
