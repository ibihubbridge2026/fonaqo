import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/widgets/agent_progress_badge.dart';
import 'package:fonaco/core/widgets/profile/profile_form_widgets.dart';
import 'package:fonaco/features/agent/providers/agent_provider.dart';
import 'package:fonaco/widgets/custom_app_bar.dart';

/// Modification du profil agent (infos de base + spécificités terrain).
class AgentPersonalInfoScreen extends StatefulWidget {
  const AgentPersonalInfoScreen({super.key});

  @override
  State<AgentPersonalInfoScreen> createState() =>
      _AgentPersonalInfoScreenState();
}

class _AgentPersonalInfoScreenState extends State<AgentPersonalInfoScreen> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _coverageZone = TextEditingController();
  final TextEditingController _bio = TextEditingController();

  static const _skillOptions = [
    'Transport & Logistique',
    'Courses & Achats',
    'Administratif',
    'Artisanat',
    'Ménage & Nettoyage',
  ];

  bool _isPolyvalent = true;
  final Set<String> _selectedSkills = {};

  final ImagePicker _imagePicker = ImagePicker();
  File? _profileImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Map<String, dynamic>? _agentBadge;

  Future<void> _loadProfile() async {
    final authUser = context.read<AuthProvider>().currentUser;
    final profile =
        await context.read<AgentProvider>().profileRepository.getProfile();

    if (!mounted) return;

    _firstName.text =
        profile['first_name']?.toString() ?? authUser?.firstName ?? '';
    _lastName.text =
        profile['last_name']?.toString() ?? authUser?.lastName ?? '';
    _email.text = profile['email']?.toString() ?? authUser?.email ?? '';
    _phone.text =
        profile['phone_number']?.toString() ?? authUser?.phoneNumber ?? '';
    _city.text = profile['city']?.toString() ?? '';
    _coverageZone.text = profile['address']?.toString() ?? '';
    final agentProfile = profile['agent_profile'];
    if (agentProfile is Map) {
      _bio.text = agentProfile['bio']?.toString() ?? '';
      final badge = agentProfile['badge'];
      if (badge is Map) {
        _agentBadge = Map<String, dynamic>.from(badge);
      } else {
        _agentBadge = null;
      }
    } else {
      _bio.text = profile['bio']?.toString() ?? '';
      _agentBadge = null;
    }
    final domain = profile['service_domain']?.toString().trim() ?? '';
    if (domain.isEmpty || domain.toLowerCase() == 'polyvalent') {
      _isPolyvalent = true;
      _selectedSkills.clear();
    } else {
      _isPolyvalent = false;
      _selectedSkills
        ..clear()
        ..addAll(domain.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    }
    setState(() {});
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _city.dispose();
    _coverageZone.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (pickedFile != null && mounted) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nom et le prénom sont obligatoires'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final serviceDomain = _isPolyvalent
        ? 'Polyvalent'
        : (_selectedSkills.isEmpty
            ? 'Polyvalent'
            : _selectedSkills.join(', '));

    try {
      final dynamic payload;
      if (_profileImage != null) {
        payload = FormData.fromMap({
          'first_name': _firstName.text.trim(),
          'last_name': _lastName.text.trim(),
          'email': _email.text.trim(),
          'city': _city.text.trim(),
          'address': _coverageZone.text.trim(),
          'service_domain': serviceDomain,
          'bio': _bio.text.trim(),
          'profile_picture': await MultipartFile.fromFile(
            _profileImage!.path,
            filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        });
      } else {
        payload = {
          'first_name': _firstName.text.trim(),
          'last_name': _lastName.text.trim(),
          'email': _email.text.trim(),
          'city': _city.text.trim(),
          'address': _coverageZone.text.trim(),
          'service_domain': serviceDomain,
          'bio': _bio.text.trim(),
        };
      }

      final result = await context
          .read<AgentProvider>()
          .profileRepository
          .updateProfile(payload);

      if (!mounted) return;

      if (result.isNotEmpty) {
        await context.read<AuthProvider>().checkAuth();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour du profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(
        title: 'Mon profil agent',
        detailTitleWidget: Text(
          'Mon profil agent',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ProfileAvatarEditor(
                profileImage: _profileImage,
                onPickImage: _pickImage,
              ),
              const SizedBox(height: 12),
              AgentProgressBadge(badge: _agentBadge),
              const SizedBox(height: 12),
              ProfileFieldCard(
                label: 'Prénom',
                controller: _firstName,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 12),
              ProfileFieldCard(
                label: 'Nom',
                controller: _lastName,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 12),
              ProfileFieldCard(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              ProfileFieldCard(
                label: 'Téléphone',
                controller: _phone,
                keyboardType: TextInputType.phone,
                readOnly: true,
              ),
              const SizedBox(height: 12),
              ProfileFieldCard(
                label: 'Ville de service',
                controller: _city,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 12),
              ProfileFieldCard(
                label: 'Zone géographique de couverture',
                controller: _coverageZone,
                keyboardType: TextInputType.text,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              ProfileFieldCard(
                label: 'Bio',
                controller: _bio,
                keyboardType: TextInputType.multiline,
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mes Compétences',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Polyvalent'),
                      subtitle: const Text('Tous domaines par défaut'),
                      value: _isPolyvalent,
                      onChanged: (v) {
                        setState(() {
                          _isPolyvalent = v ?? true;
                          if (_isPolyvalent) _selectedSkills.clear();
                        });
                      },
                    ),
                    if (!_isPolyvalent) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _skillOptions.map((skill) {
                          final selected = _selectedSkills.contains(skill);
                          return FilterChip(
                            label: Text(skill),
                            selected: selected,
                            onSelected: (sel) {
                              setState(() {
                                if (sel) {
                                  _selectedSkills.add(skill);
                                } else {
                                  _selectedSkills.remove(skill);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ProfileSaveButton(
                isSaving: _isSaving,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
