import 'package:flutter/material.dart';

import 'package:fonaco/widgets/custom_app_bar.dart';

/// Paramètres de notifications.
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _smsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(
        title: 'Notifications',
        detailTitleWidget: Text(
          'Notifications',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SwitchTile(
              title: 'Notifications push',
              subtitle: 'Missions, messages, alertes importantes',
              value: _pushEnabled,
              onChanged: (v) => setState(() => _pushEnabled = v),
            ),
            const SizedBox(height: 12),
            _SwitchTile(
              title: 'Email',
              subtitle: 'Récap, factures et confirmations',
              value: _emailEnabled,
              onChanged: (v) => setState(() => _emailEnabled = v),
            ),
            const SizedBox(height: 12),
            _SwitchTile(
              title: 'SMS',
              subtitle: 'Urgences et codes de vérification',
              value: _smsEnabled,
              onChanged: (v) => setState(() => _smsEnabled = v),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: SwitchListTile(
        activeThumbColor: const Color(0xFFFFD400),
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}
