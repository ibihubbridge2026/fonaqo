import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/features/agent/providers/agent_provider.dart';

/// Formulaire de soumission KYC agent (CNI + selfie).
class AgentKycSubmitScreen extends StatefulWidget {
  const AgentKycSubmitScreen({super.key});

  @override
  State<AgentKycSubmitScreen> createState() => _AgentKycSubmitScreenState();
}

class _AgentKycSubmitScreenState extends State<AgentKycSubmitScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _idCardPhoto;
  File? _selfiePhoto;
  bool _submitting = false;

  Future<void> _pickIdCard() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked != null && mounted) {
      setState(() => _idCardPhoto = File(picked.path));
    }
  }

  Future<void> _pickSelfie() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 1920,
    );
    if (picked != null && mounted) {
      setState(() => _selfiePhoto = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_idCardPhoto == null || _selfiePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez joindre la pièce d\'identité et le selfie'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final formData = FormData.fromMap({
        'id_card_photo': await MultipartFile.fromFile(
          _idCardPhoto!.path,
          filename: 'id_card.jpg',
        ),
        'selfie_photo': await MultipartFile.fromFile(
          _selfiePhoto!.path,
          filename: 'selfie.jpg',
        ),
      });

      final ok = await context
          .read<AgentProvider>()
          .profileRepository
          .submitKycDocuments(formData);

      if (!mounted) return;

      if (ok) {
        await context.read<AuthProvider>().checkAuth();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Documents envoyés — validation en cours par l\'administration',
            ),
          ),
        );
        context.go(AppRoutes.agentKycLock);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec de l\'envoi des documents'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Soumission KYC'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Pièce d\'identité et selfie',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Téléversez une photo lisible de votre CNI ou passeport, '
              'puis un selfie tenant votre pièce.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.45),
            ),
            const SizedBox(height: 24),
            _DocumentTile(
              label: 'Pièce d\'identité (recto)',
              file: _idCardPhoto,
              icon: Icons.badge_outlined,
              onPick: _pickIdCard,
            ),
            const SizedBox(height: 12),
            _DocumentTile(
              label: 'Selfie avec pièce',
              file: _selfiePhoto,
              icon: Icons.face_retouching_natural,
              onPick: _pickSelfie,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(_submitting ? 'Envoi...' : 'Soumettre mes documents'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD400),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String label;
  final File? file;
  final IconData icon;
  final VoidCallback onPick;

  const _DocumentTile({
    required this.label,
    required this.file,
    required this.icon,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28, color: Colors.black87),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      file != null ? 'Fichier sélectionné' : 'Appuyer pour choisir',
                      style: TextStyle(
                        color: file != null ? Colors.green.shade700 : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                file != null ? Icons.check_circle : Icons.add_a_photo_outlined,
                color: file != null ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
