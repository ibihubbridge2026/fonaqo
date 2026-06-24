import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/features/agent/providers/agent_provider.dart';
import 'package:fonaco/features/agent/widgets/agent_pro_badge_preview_card.dart';

/// Demande et téléchargement du badge professionnel FONACO.
class AgentProBadgeScreen extends StatefulWidget {
  const AgentProBadgeScreen({super.key});

  @override
  State<AgentProBadgeScreen> createState() => _AgentProBadgeScreenState();
}

class _AgentProBadgeScreenState extends State<AgentProBadgeScreen> {
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic> _status = {};
  File? _photo;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await context.read<AgentProvider>().profileRepository.getProBadgeStatus();
    if (mounted) {
      setState(() {
        _status = data;
        _loading = false;
      });
    }
  }

  bool get _canRequest => _status['can_request'] == true;
  bool get _canDownload => _status['can_download'] == true;
  String get _badgeStatus => (_status['badge_status'] ?? 'NONE').toString();

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1920,
    );
    if (picked != null && mounted) {
      setState(() => _photo = File(picked.path));
    }
  }

  Future<void> _submitRequest() async {
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez une photo dédiée pour votre badge')),
      );
      return;
    }
    setState(() => _busy = true);
    final formData = FormData.fromMap({
      'badge_photo': await MultipartFile.fromFile(
        _photo!.path,
        filename: 'badge_photo.jpg',
      ),
    });
    final repo = context.read<AgentProvider>().profileRepository;
    final ok = await repo.requestProBadge(formData);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande envoyée — validation par le staff sous 48h')),
      );
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de l\'envoi de la demande')),
      );
    }
  }

  Future<void> _downloadBadge() async {
    setState(() => _busy = true);
    final path = await context.read<AgentProvider>().profileRepository.downloadProBadge();
    if (!mounted) return;
    setState(() => _busy = false);
    if (path != null) {
      await OpenFile.open(path);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement impossible')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Badge professionnel'),
        backgroundColor: const Color(0xFFFFD400),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD400)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Builder(
                    builder: (context) {
                      final user = context.watch<AuthProvider>().currentUser;
                      final fullName = [
                        user?.firstName,
                        user?.lastName,
                      ].where((s) => s != null && s.trim().isNotEmpty).join(' ');
                      return AgentProBadgePreviewCard(
                        agentName: fullName.isNotEmpty
                            ? fullName
                            : (user?.djangoUsername ?? 'Agent'),
                        specialty: 'Agent terrain',
                        agentCode: _status['agent_code']?.toString().isNotEmpty ==
                                true
                            ? _status['agent_code'].toString()
                            : 'AGT-XXXX',
                        phone: user?.phoneNumber,
                        photoUrl: _photo == null
                            ? _status['badge_photo_url']?.toString()
                            : null,
                        localPhoto: _photo,
                        isCertified: _status['is_internal'] == true,
                      );
                    },
                  ),
                  if (_photo != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _photo!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD400), width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          (_status['agent_code']?.toString().isNotEmpty ?? false)
                              ? 'ID ${_status['agent_code']}'
                              : 'Carte agent officielle Fonaqo',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _badgeStatus == 'PENDING'
                              ? 'Demande en cours d\'analyse'
                              : _badgeStatus == 'APPROVED'
                                  ? 'Badge validé — téléchargement illimité'
                                  : 'Photo portrait requise pour validation staff',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_canRequest) ...[
                    if (_photo != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_photo!, height: 200, width: double.infinity, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(_photo == null ? 'Choisir ma photo badge' : 'Changer la photo'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Prendre un selfie'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _busy ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD400),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text('Demander mon badge', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  if (_canDownload)
                    ElevatedButton.icon(
                      onPressed: _busy ? null : _downloadBadge,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Télécharger mon badge'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: const Color(0xFFFFD400),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  if (_badgeStatus == 'PENDING' && !_canDownload)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'Votre photo est en cours de validation. Vous recevrez un e-mail dès approbation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
