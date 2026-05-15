import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/services/chat_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/agent_provider.dart';
import '../widgets/dispute_bottom_sheet.dart';
import '../widgets/voice_recording_button.dart';
import '../widgets/voice_message_bubble.dart';
import '../widgets/image_message_bubble.dart';
import '../widgets/file_message_bubble.dart';
import '../../../core/services/audio_service.dart';
import '../repository/agent_repository.dart';

class AgentChatScreen extends StatefulWidget {
  const AgentChatScreen({super.key});

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  List<ChatMessage> _messages = [];
  bool _isConnected = false;
  bool _isOtherUserOnline = false;
  bool _isDisputed = false;
  String? _currentUserId;
  String? _missionId;
  String? _otherUserId;
  final AudioService _audioService = AudioService();
  final AgentRepository _agentRepository = AgentRepository();
  final ImagePicker _imagePicker = ImagePicker();

  // État des uploads
  Map<String, double> _uploadProgress = {};
  Map<String, bool> _uploadingFiles = {};

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatService.disconnect();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    // Récupérer les infos utilisateur et mission
    final authProvider = context.read<AuthProvider>();
    _currentUserId = authProvider.currentUser?.id?.toString();

    // TODO: Récupérer missionId depuis les arguments ou navigation
    _missionId = 'mission_123'; // Placeholder
    _otherUserId = 'client_456'; // Placeholder

    if (_currentUserId != null && _missionId != null) {
      await _connectToChat();
    }
  }

  Future<void> _connectToChat() async {
    try {
      await _chatService.connect(_missionId!, _currentUserId!);

      // Écouter les messages
      _chatService.messageStream.listen((message) {
        if (mounted) {
          setState(() {
            _messages.add(message);
          });
          _scrollToBottom();
        }
      });

      // Écouter le statut de connexion
      _chatService.connectionStream.listen((isConnected) {
        if (mounted) {
          setState(() {
            _isConnected = isConnected;
            _isOtherUserOnline = isConnected; // Simplification
          });
        }
      });

      // Écouter les signaux de typing
      _chatService.typingStream.listen((userId) {
        if (mounted && userId != _currentUserId) {
          // TODO: Afficher indicateur "en train d'écrire"
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur connexion chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || !_isConnected) return;

    try {
      await _chatService.sendMessage(text);
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur envoi message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showVoIPSecurityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Appel sécurisé',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Pour votre protection, FONAQO vous conseille de privilégier le chat écrit pour garder une trace de vos échanges. Voulez-vous quand même lancer un appel internet ?',
          style: TextStyle(
            fontSize: 16,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
            child: const Text(
              'Rester sur le chat',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startVoIPCall();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD400),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Appeler quand même',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startVoIPCall() {
    print('🚀 Démarrage appel VoIP pour la mission $_missionId');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connexion VoIP en cours...'),
        backgroundColor: Color(0xFFFFD400),
        duration: Duration(seconds: 3),
      ),
    );

    // TODO: Implémenter Agora VoIP ici
    // 1. Initialiser Agora Engine
    // 2. Rejoindre le channel
    // 3. Gérer les états d'appel
  }

  void _showDisputeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DisputeBottomSheet(
        missionId: _missionId!,
        onDisputeOpened: () {
          setState(() {
            _isDisputed = true;
          });
        },
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  final List<Map<String, dynamic>> messages = [
    {
      "isMe": false,
      "message": "Bonjour, vous êtes arrivé ?",
      "time": "08:30",
    },
    {
      "isMe": true,
      "message": "Oui, je suis sur place.",
      "time": "08:32",
    },
    {
      "isMe": false,
      "message": "Voici la preuve d’arrivée.",
      "time": "08:33",
      "image": "https://images.unsplash.com/photo-1520607162513-77705c0f0d4a",
    },
    {
      "isMe": true,
      "message": "Parfait, merci 👌",
      "time": "08:34",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CHAT',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            // Indicateur de statut en ligne
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'dispute') {
                _showDisputeBottomSheet();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'dispute',
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Signaler un problème'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.black),
            onPressed: _showVoIPSecurityDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Bannière de litige si applicable
          if (_isDisputed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mission suspendue - Un administrateur FONAQO examine votre cas',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Statut de connexion
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: _isConnected
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isConnected ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (!_isConnected) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(18),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final bool isMe = message.isMe;

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFFFFD400) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.image != null)
                          Container(
                            height: 160,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              image: DecorationImage(
                                image: NetworkImage(message.image!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        Text(
                          message.text,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // INPUT
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        // Icône trombone pour les médias
                        GestureDetector(
                          onTap: _showMediaPicker,
                          child: Icon(
                            Icons.attach_file,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.image_outlined,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: "Écrire un message...",
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                            onChanged: (value) {
                              setState(
                                  () {}); // Mettre à jour l'UI pour changer le bouton
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Bouton dynamique : Micro ou Envoyer
                _messageController.text.trim().isEmpty
                    ? VoiceRecordingButton(
                        onRecordingComplete: _sendVoiceMessage,
                        onCancel: () {
                          setState(() {});
                        },
                      )
                    : Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD400),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(
                            Icons.send,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Envoie un message vocal
  Future<void> _sendVoiceMessage(String audioPath) async {
    try {
      // TODO: Uploader le fichier audio vers le serveur
      // Pour l'instant, simuler l'envoi
      final voiceMessage = {
        'type': 'voice',
        'url': audioPath, // URL temporaire, sera remplacée par l'URL du serveur
        'duration': _audioService.recordingDuration,
        'timestamp': DateTime.now(),
        'isMe': true,
      };

      // Ajouter le message à la liste
      setState(() {
        _messages.add(ChatMessage(
          sender: _currentUserId ?? 'Moi',
          text: '🎙️ Message vocal',
          timestamp: DateTime.now(),
          audioUrl: audioPath,
          audioDuration: _audioService.recordingDuration,
          isMe: true,
          type: 'voice',
        ));
      });

      // Envoyer via WebSocket
      await _chatService.sendMessage({
        'type': 'voice',
        'text': '🎙️ Message vocal',
        'audio_url': audioPath,
        'audio_duration': _audioService.recordingDuration.inSeconds,
        'mission_id': _missionId,
        'sender_id': _currentUserId,
        'receiver_id': _otherUserId,
      });

      // Scroller vers le bas
      _scrollToBottomNew();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur envoi message vocal: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scrollToBottomNew() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Affiche le sélecteur de médias
  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: const Text(
                'Partager un média',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Options
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Colors.blue,
                ),
              ),
              title: const Text('Galerie photo'),
              subtitle: const Text('Choisir une image'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),

            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.green,
                ),
              ),
              title: const Text('Appareil photo'),
              subtitle: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),

            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description,
                  color: Colors.orange,
                ),
              ),
              title: const Text('Document'),
              subtitle: const Text('PDF, Word, Excel...'),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Sélectionne une image depuis la galerie
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadAndSendFile(File(image.path), 'image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur sélection image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Prend une photo avec l'appareil
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadAndSendFile(File(image.path), 'image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur prise photo: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Sélectionne un document
  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt'
        ],
      );

      if (result != null && result.files.single.path != null) {
        await _uploadAndSendFile(File(result.files.single.path!), 'document');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur sélection document: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Upload et envoie un fichier
  Future<void> _uploadAndSendFile(File file, String fileType) async {
    final fileId = DateTime.now().millisecondsSinceEpoch.toString();

    // Ajouter le message en état d'upload
    setState(() {
      _uploadingFiles[fileId] = true;
      _uploadProgress[fileId] = 0.0;

      _messages.add(ChatMessage(
        sender: _currentUserId ?? 'Moi',
        text: '📎 ${file.path.split('/').last}',
        timestamp: DateTime.now(),
        image: fileType == 'image' ? file.path : null,
        isMe: true,
        type: fileType,
      ));
    });

    try {
      // Uploader le fichier
      final uploadData = await _agentRepository.uploadChatFile(
        file,
        _missionId ?? '',
        onProgress: (progress) {
          setState(() {
            _uploadProgress[fileId] = progress;
          });
        },
      );

      if (uploadData != null) {
        // Envoyer le message via WebSocket
        await _chatService.sendMessage({
          'type': fileType,
          'text': fileType == 'image' ? '📷 Photo' : '📎 Document',
          'file_url': uploadData['url'],
          'file_name': file.path.split('/').last,
          'file_size': uploadData['size'],
          'file_type': fileType,
          'mission_id': _missionId,
          'sender_id': _currentUserId,
          'receiver_id': _otherUserId,
        });

        // Mettre à jour le message avec l'URL
        setState(() {
          _uploadingFiles[fileId] = false;
          final messageIndex = _messages.indexWhere(
            (msg) => msg.text.contains(file.path.split('/').last),
          );
          if (messageIndex != -1) {
            _messages[messageIndex] = ChatMessage(
              sender: _currentUserId ?? 'Moi',
              text: fileType == 'image'
                  ? '📷 Photo'
                  : '📎 ${file.path.split('/').last}',
              timestamp: _messages[messageIndex].timestamp,
              image: uploadData['url'],
              isMe: true,
              type: fileType,
            );
          }
        });
      } else {
        throw Exception('Échec de l\'upload');
      }
    } catch (e) {
      // Supprimer le message en cas d'erreur
      setState(() {
        _uploadingFiles.remove(fileId);
        _uploadProgress.remove(fileId);
        _messages.removeWhere(
          (msg) => msg.text.contains(file.path.split('/').last),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur upload: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    _scrollToBottomNew();
  }
}
