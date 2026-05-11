import 'package:flutter/material.dart';

import '../../../widgets/custom_app_bar.dart';

/// Sélection de la langue (UI simple).
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _current = 'fr';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(
        title: 'Langue',
        detailTitleWidget: Text(
          'Langue',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _RadioTile(
              label: 'Français (FR)',
              value: 'fr',
              groupValue: _current,
              onChanged: (v) => setState(() => _current = v),
            ),
            const SizedBox(height: 12),
            _RadioTile(
              label: 'English (EN)',
              value: 'en',
              groupValue: _current,
              onChanged: (v) => setState(() => _current = v),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _RadioTile({
    required this.label,
    required this.value,
    required this.groupValue,
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
      child: RadioListTile<String>(
        activeColor: const Color(0xFFFFD400),
        value: value,
        groupValue: groupValue,
        onChanged: (v) {
          if (v == null) return;
          onChanged(v);
        },
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
