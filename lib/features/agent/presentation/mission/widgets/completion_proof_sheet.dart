import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/services/image_compression_service.dart';
import 'package:fonaco/core/services/mission_audio_cleanup.dart';
import 'package:fonaco/features/agent/providers/agent_provider.dart';

/// Bottom sheet de soumission de preuve photo (complétion mission).
class CompletionProofSheet extends StatefulWidget {
  final String missionId;

  const CompletionProofSheet({super.key, required this.missionId});

  static Future<bool> show(BuildContext context, {required String missionId}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompletionProofSheet(missionId: missionId),
    ).then((value) => value ?? false);
  }

  @override
  State<CompletionProofSheet> createState() => _CompletionProofSheetState();
}

class _CompletionProofSheetState extends State<CompletionProofSheet> {
  final ImagePicker _picker = ImagePicker();
  final ImageCompressionService _compression = ImageCompressionService();

  File? _preview;
  bool _isSubmitting = false;

  Future<void> _capturePhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;

    final compressed = await _compression.compressUntilTargetSize(
      filePath: photo.path,
      targetSizeMB: 3.0,
      minQuality: 50,
    );

    if (!mounted) return;
    setState(() {
      _preview = compressed != null ? File(compressed.path) : File(photo.path);
    });
  }

  Future<void> _submit() async {
    if (_preview == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final success = await context
        .read<AgentProvider>()
        .missionRepository
        .submitCompletion(widget.missionId, _preview!.path);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      await MissionAudioCleanup.purgeTemporaryRecordings();
      if (!mounted) return;

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preuve transmise ! En attente de validation client.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await context.read<AgentProvider>().fetchWalletDetails();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'envoi de la preuve'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Preuve de complétion',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Prenez une photo claire du résultat ou du colis livré.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          if (_preview != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _preview!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: Icon(Icons.camera_alt_outlined,
                    size: 48, color: Colors.grey),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _capturePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Prendre une photo de preuve'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting || _preview == null ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD400),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Envoyer la preuve',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
