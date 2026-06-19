import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/widgets/custom_app_bar.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/widgets/profile/profile_form_widgets.dart';

/// Écran de modification des informations personnelles (nom, email, photo).
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();

  File? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFormFromUser();
  }

  void _loadFormFromUser() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      _firstName.text = user.firstName ?? '';
      _lastName.text = user.lastName ?? '';
      final email = user.email;
      if (email.contains('@internal.fonaqo.local')) {
        _email.text = '';
      } else {
        _email.text = email;
      }
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      dynamic profileData;

      if (_profileImage != null) {
        profileData = FormData.fromMap({
          'first_name': _firstName.text.trim(),
          'last_name': _lastName.text.trim(),
          if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
          'profile_picture': await MultipartFile.fromFile(
            _profileImage!.path,
            filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        });
      } else {
        profileData = {
          'first_name': _firstName.text.trim(),
          'last_name': _lastName.text.trim(),
          if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        };
      }

      final success = await authProvider.updateProfile(profileData);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Erreur lors de la mise à jour',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur inattendue: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar.detailStack(
        title: 'Informations personnelles',
        detailTitleWidget: Text(
          'Informations personnelles',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ProfileAvatarEditor(
                  profileImage: _profileImage,
                  onPickImage: _pickImage,
                ),
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
                const SizedBox(height: 24),
                ProfileSaveButton(
                  isSaving: _isSaving,
                  onPressed: _saveProfile,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
