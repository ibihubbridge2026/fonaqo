import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../../core/models/mission_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/wallet_provider.dart';
import '../../../core/utils/recording_duration_tracker.dart';
import '../../../core/utils/transaction_pin_dialog.dart';
import '../../../core/widgets/feexpay_payment_bottom_sheet.dart';
import '../../../core/widgets/recording_timer_display.dart';
import '../../../core/widgets/voice_message_player.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../client/missions/mission_repository.dart';
import '../chat_repository.dart';
import '../models/chat_message_v2.dart';
import '../models/chat_room.dart';
import '../models/enums.dart';
import '../providers/chat_provider.dart';
import '../widgets/negotiation_card.dart';

/// Écran de conversation avec bulles alignées et pièces jointes.
class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String? agentAvatar;
  final String? missionId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.userName,
    this.agentAvatar,
    this.missionId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatRepository _repository = ChatRepository();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final ChatProvider _chatProvider;
  final MissionRepository _missionRepository = MissionRepository();
  MissionModel? _mission;
  String? _negotiationProcessingId;
  bool _initialized = false;
  bool _isRecording = false;
  bool _hasText = false;
  int _recordingSeconds = 0;
  final RecordingDurationTracker _recordingTracker = RecordingDurationTracker();

  static const _kChatBg = Color(0xFFECE5DD);
  static const _kAccentGreen = Color(0xFF25D366);
  static const _kYellow = Color(0xFFFFD400);

  @override
  void initState() {
    super.initState();
    _chatProvider = ChatProvider();
    _recordingTracker.onTick = (seconds) {
      if (mounted) setState(() => _recordingSeconds = seconds);
    };
    _messageController.addListener(_onMessageChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _onMessageChanged() {
    final has = _messageController.text.trim().isNotEmpty;
    if (has != _hasText && mounted) {
      setState(() => _hasText = has);
    }
  }

  Future<void> _bootstrap() async {
    String conversationId = widget.chatId;
    String? missionId = widget.missionId;

    if (conversationId.isEmpty && missionId != null && missionId.isNotEmpty) {
      final conv = await _repository.getOrCreateConversation(missionId);
      if (conv != null) {
        conversationId = conv['id']?.toString() ?? '';
        missionId = conv['mission']?.toString() ?? missionId;
      }
    }

    if (!mounted || conversationId.isEmpty) return;

    final room = ChatRoom(
      id: conversationId,
      missionId: missionId,
      name: widget.userName,
      participants: const [],
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    if (missionId != null && missionId.isNotEmpty) {
      await _chatProvider.connectWebSocket(context, missionId: missionId);
    }

    if (!mounted) return;

    await _chatProvider.selectConversation(
      room,
      context,
      missionId: missionId,
    );

    if (missionId != null && missionId.isNotEmpty) {
      try {
        final mission = await _missionRepository.fetchMissionDetails(missionId);
        if (mounted) setState(() => _mission = mission);
      } catch (_) {}
    }

    if (mounted) setState(() => _initialized = true);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _recordingTracker.dispose();
    _chatProvider.disconnectWebSocket();
    _chatProvider.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _stopRecordingTimer() {
    _recordingTracker.stop();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
    }
  }

  double get _currentMissionPrice =>
      _mission?.serviceAmount ?? _mission?.price ?? 0;

  Future<void> _proposeNewPrice() async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Proposer un nouveau tarif'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Montant (FCFA)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kYellow,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v == null || v <= 0) return;
              Navigator.pop(ctx, v);
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null) return;
    if (!mounted) return;
    final senderId = context.read<AuthProvider>().currentUser?.id;
    await _chatProvider.sendNegotiationProposal(amount, senderId: senderId);
    _scrollToBottom();
  }

  Future<void> _rejectNegotiation(ChatMessageV2 message) async {
    final missionId = widget.missionId;
    if (missionId == null || missionId.isEmpty) return;
    setState(() => _negotiationProcessingId = message.id);
    try {
      await _missionRepository.rejectNegotiation(
        missionId: missionId,
        messageId: message.id,
      );
      _chatProvider.patchNegotiationStatus(
        message.id,
        NegotiationStatus.rejected,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _negotiationProcessingId = null);
    }
  }

  Future<void> _acceptNegotiation(ChatMessageV2 message) async {
    final missionId = widget.missionId;
    final proposed = message.proposedPrice;
    if (missionId == null || missionId.isEmpty || proposed == null) return;

    setState(() => _negotiationProcessingId = message.id);
    try {
      final delta = proposed - _currentMissionPrice;
      String paymentMethod = 'wallet';
      String? paymentReference;

      if (delta > 0) {
        final wallet = context.read<WalletProvider>();
        await wallet.fetchBalance();
        if (!mounted) return;

        if (wallet.canAfford(delta)) {
          final pinOk = await verifyTransactionPinIfRequired(context);
          if (!pinOk || !mounted) return;
          paymentMethod = 'wallet';
        } else {
          final paid = await FeexPayPaymentBottomSheet.show(
            context,
            amount: delta,
            description: 'Complément tarif mission',
          );
          if (!paid || !mounted) return;
          paymentMethod = 'feexpay';
          paymentReference =
              'feex_${DateTime.now().millisecondsSinceEpoch}';
        }
      }

      final updated = await _missionRepository.acceptNegotiatedPrice(
        missionId: missionId,
        messageId: message.id,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
      );

      if (!mounted) return;
      setState(() => _mission = updated);
      _chatProvider.patchNegotiationStatus(
        message.id,
        NegotiationStatus.accepted,
      );
      await context.read<WalletProvider>().fetchBalance();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarif accepté et appliqué'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _negotiationProcessingId = null);
    }
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    final senderId = context.read<AuthProvider>().currentUser?.id;
    await _chatProvider.sendTextMessage(text, senderId: senderId);
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (file == null) return;
    if (!mounted) return;
    final senderId = context.read<AuthProvider>().currentUser?.id;
    await _chatProvider.sendMediaMessage(
      type: MessageType.image,
      content: file.path,
      fileName: file.name,
      fileSize: await file.length(),
      fileMimeType: 'image/jpeg',
      senderId: senderId,
    );
    _scrollToBottom();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final path = file.path;
    if (path == null) return;
    if (!mounted) return;
    final senderId = context.read<AuthProvider>().currentUser?.id;
    await _chatProvider.sendMediaMessage(
      type: MessageType.file,
      content: path,
      fileName: file.name,
      fileSize: file.size,
      fileMimeType: file.extension,
      senderId: senderId,
    );
    _scrollToBottom();
  }

  void _showAttachmentMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined, color: Colors.black87),
                title: const Text(
                  'Photo',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file, color: Colors.black87),
                title: const Text(
                  'Document',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      _stopRecordingTimer();
      if (path == null) return;
      if (!mounted) return;
      final file = File(path);
      final senderId = context.read<AuthProvider>().currentUser?.id;
      await _chatProvider.sendMediaMessage(
        type: MessageType.audio,
        content: path,
        fileName: 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
        fileSize: await file.length(),
        fileMimeType: 'audio/m4a',
        senderId: senderId,
      );
      _scrollToBottom();
      return;
    }

    if (!await _audioRecorder.hasPermission()) return;
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    if (mounted) {
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      _recordingTracker.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatProvider>.value(
      value: _chatProvider,
      child: Scaffold(
        backgroundColor: _kChatBg,
        appBar: CustomAppBar.detailStack(
          title: widget.userName,
          detailTitleWidget: Text(
            widget.userName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
        body: !_initialized
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD400)),
              )
            : Column(
                children: [
                  Expanded(
                    child: Consumer<ChatProvider>(
                      builder: (context, chat, _) {
                        final messages = chat.currentMessages;
                        final userId =
                            context.read<AuthProvider>().currentUser?.id ?? '';

                        if (messages.isEmpty) {
                          return const Center(
                            child: Text(
                              'Démarrez la conversation',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        final isAgent =
                            context.read<AuthProvider>().isAgent;

                        return Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final msg = messages[index];
                                  final isMe = msg.senderId == userId;
                                  return _MessageBubble(
                                    message: msg,
                                    isMe: isMe,
                                    audioPlayer: _audioPlayer,
                                    isClient: !isAgent,
                                    isProcessingNegotiation:
                                        _negotiationProcessingId == msg.id,
                                    onAcceptNegotiation: () =>
                                        _acceptNegotiation(msg),
                                    onRejectNegotiation: () =>
                                        _rejectNegotiation(msg),
                                  );
                                },
                              ),
                            ),
                            if (isAgent)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12, 0, 12, 6,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _proposeNewPrice,
                                    icon: const Icon(
                                      Icons.price_change_outlined,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Proposer un nouveau tarif',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black87,
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Color(0xFFFFD400),
                                        width: 1.5,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_rounded),
                                    color: const Color(0xFF54656F),
                                    tooltip: 'Pièce jointe',
                                    onPressed: _showAttachmentMenu,
                                  ),
                                  Expanded(
                                    child: _isRecording
                                        ? RecordingTimerDisplay(
                                            seconds: _recordingSeconds,
                                            textStyle: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red,
                                            ),
                                          )
                                        : TextField(
                                            controller: _messageController,
                                            minLines: 1,
                                            maxLines: 5,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                            decoration: const InputDecoration(
                                              hintText: 'Message',
                                              hintStyle: TextStyle(
                                                color: Color(0xFF8696A0),
                                                fontSize: 16,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                            ),
                                            onSubmitted: (_) {
                                              if (_hasText) _sendText();
                                            },
                                          ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _hasText
                                          ? Icons.send_rounded
                                          : (_isRecording
                                              ? Icons.stop_circle_rounded
                                              : Icons.mic_rounded),
                                      color: _hasText
                                          ? _kAccentGreen
                                          : (_isRecording
                                              ? Colors.red.shade700
                                              : const Color(0xFF54656F)),
                                    ),
                                    tooltip: _hasText
                                        ? 'Envoyer'
                                        : 'Message vocal',
                                    onPressed: _hasText
                                        ? _sendText
                                        : _toggleRecording,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageV2 message;
  final bool isMe;
  final AudioPlayer audioPlayer;
  final bool isClient;
  final bool isProcessingNegotiation;
  final VoidCallback? onAcceptNegotiation;
  final VoidCallback? onRejectNegotiation;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.audioPlayer,
    this.isClient = false,
    this.isProcessingNegotiation = false,
    this.onAcceptNegotiation,
    this.onRejectNegotiation,
  });

  static const _sentColor = Color(0xFFD9FDD3);
  static const _receivedColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.negotiationProposal &&
        isClient &&
        !isMe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: NegotiationCard(
          proposedAmount: message.proposedPrice ?? 0,
          status: message.negotiationStatus,
          isProcessing: isProcessingNegotiation,
          onAccept: message.isNegotiationPending
              ? onAcceptNegotiation
              : null,
          onReject: message.isNegotiationPending
              ? onRejectNegotiation
              : null,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                (message.senderName ?? '?').isNotEmpty
                    ? message.senderName![0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && (message.senderName?.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      message.senderName!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                  decoration: BoxDecoration(
                    color: isMe ? _sentColor : _receivedColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: Radius.circular(isMe ? 12 : 2),
                      bottomRight: Radius.circular(isMe ? 2 : 12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _MessageContent(
                          message: message,
                          isMe: isMe,
                          audioPlayer: audioPlayer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            _MessageStatusIcon(status: message.status),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 6),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _MessageStatusIcon extends StatelessWidget {
  final MessageStatus status;

  const _MessageStatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.grey.shade500,
          ),
        );
      case MessageStatus.sent:
        return Icon(Icons.check, size: 14, color: Colors.grey.shade600);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 14, color: Colors.grey.shade600);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 14, color: Color(0xFF53BDEB));
      case MessageStatus.failed:
        return Icon(Icons.error_outline, size: 14, color: Colors.red.shade600);
    }
  }
}

class _MessageContent extends StatelessWidget {
  final ChatMessageV2 message;
  final bool isMe;
  final AudioPlayer audioPlayer;

  const _MessageContent({
    required this.message,
    required this.isMe,
    required this.audioPlayer,
  });

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        final path = message.content ?? '';
        if (path.startsWith('/') && File(path).existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(path), fit: BoxFit.cover),
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                message.fileName ?? 'Image',
                style: TextStyle(
                  color: isMe ? Colors.black87 : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      case MessageType.audio:
        final path = message.content ?? '';
        return VoiceMessagePlayer(
          audioPath: path,
          durationSeconds: message.duration,
          isMe: isMe,
          player: audioPlayer,
        );
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file,
                color: isMe ? Colors.black87 : Colors.grey.shade700),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.fileName ?? 'Fichier',
                style: TextStyle(
                  color: isMe ? Colors.black87 : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case MessageType.negotiationProposal:
        final amount = message.proposedPrice ?? 0;
        return Text(
          'Proposition : ${amount.toStringAsFixed(0)} FCFA',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        );
      default:
        return Text(
          message.content ?? '',
          style: TextStyle(
            color: isMe ? Colors.black87 : Colors.black87,
            fontSize: 15,
            height: 1.35,
          ),
        );
    }
  }
}
