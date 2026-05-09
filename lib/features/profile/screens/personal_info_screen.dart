import 'package:flutter/material.dart';

import '../../../widgets/custom_app_bar.dart';

/// Écran de modification des informations personnelles (nom, email optionnel, téléphone, photo).
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final TextEditingController _name = TextEditingController(text: 'Thomas Kouassi');
  final TextEditingController _email = TextEditingController(text: 'thomas@exemple.com');
  final TextEditingController _phone = TextEditingController(text: '+225 00 00 00 00');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(
        detailTitleWidget: Text('Informations personnelles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const _AvatarEditor(),
              const SizedBox(height: 12),
              _FieldCard(label: 'Nom complet', controller: _name),
              const SizedBox(height: 12),
              _FieldCard(label: 'Email (optionnel)', controller: _email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _FieldCard(label: 'Téléphone', controller: _phone, keyboardType: TextInputType.phone),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD400),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('ENREGISTRER', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _FieldCard({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12)],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            child: ClipOval(
              child: Image.asset(
                'assets/images/avatar/user.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.black54),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Photo de profil',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Modifier')),
        ],
      ),
    );
  }
}

