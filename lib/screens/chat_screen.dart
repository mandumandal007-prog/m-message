import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/helpers.dart';
import '../models/app_user.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../providers/auth_provider.dart';
import '../providers/chats_provider.dart';
import '../services/call_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../widgets/common.dart';
import '../widgets/message_bubble.dart';
import '../widgets/voice_recorder.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _db = FirestoreService();
  final _storage = StorageService();
  final _textCtl = TextEditingController();
  final _focus = FocusNode();
  final _scrollCtl = ScrollController();

  MessageReply? _replyTo;
  Message? _editing;
  bool _showEmoji = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _textCtl.addListener(() => setState(() {}));
    _focus.addListener(() {
      if (_focus.hasFocus && _showEmoji) setState(() => _showEmoji = false);
    });
  }

  @override
  void dispose() {
    _textCtl.dispose();
    _focus.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  String get _uid => context.read<AuthProvider>().firebaseUser?.uid ?? '';
  String get _myName => context.read<AuthProvider>().appUser?.name ?? 'User';

  String _chatTitle(Chat? chat, ChatsProvider chats, String uid) {
    if (chat == null) return '';
    if (chat.isGroup) return chat.name ?? 'Group';
    final other = chats.userFor(chat.members.firstWhere((m) => m != uid, orElse: () => ''));
    return other?.name ?? 'User';
  }

  Future<void> _sendText() async {
    final text = _textCtl.text.trim();
    if (text.isEmpty) return;
    if (_editing != null) {
      final msg = _editing!;
      setState(() => _editing = null);
      _textCtl.clear();
      await _db.editMessage(widget.chatId, msg.id, text);
      return;
    }
    final reply = _replyTo;
    _textCtl.clear();
    setState(() => _replyTo = null);
    await _db.sendMessage(
      chatId: widget.chatId,
      senderId: _uid,
      senderName: _myName,
      text: text,
      replyTo: reply,
    );
    _scrollToBottom();
  }

  Future<void> _sendMedia({required File file, required String type, required String ext, String? fileName, int? durationSec}) async {
    setState(() => _uploading = true);
    try {
      final url = await _storage.uploadChatMedia(chatId: widget.chatId, file: file, ext: ext);
      final reply = _replyTo;
      setState(() => _replyTo = null);
      await _db.sendMessage(
        chatId: widget.chatId,
        senderId: _uid,
        senderName: _myName,
        text: '',
        type: type,
        mediaUrl: url,
        fileName: fileName,
        durationSec: durationSec,
        replyTo: reply,
      );
      _scrollToBottom();
    } catch (e) {
      _snack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final img = await ImagePicker().pickImage(source: source, imageQuality: 75, maxWidth: 1920);
    if (img == null) return;
    final ext = img.path.contains('.') ? img.path.split('.').last : 'jpg';
    await _sendMedia(file: File(img.path), type: 'image', ext: ext);
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles();
    if (res == null || res.files.single.path == null) return;
    final f = res.files.single;
    final ext = f.extension ?? 'bin';
    await _sendMedia(file: File(f.path!), type: 'file', ext: ext, fileName: f.name);
  }

  Future<void> _recordVoice() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isDismissible: false,
      builder: (_) => const VoiceRecorderSheet(),
    );
    if (result == null) return;
    final file = result['file'] as File;
    final duration = result['duration'] as int? ?? 0;
    await _sendMedia(file: file, type: 'audio', ext: 'm4a', durationSec: duration);
  }

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _attachButton(ctx, Icons.photo_library_outlined, 'Gallery', () => _pickImage(ImageSource.gallery)),
              _attachButton(ctx, Icons.photo_camera_outlined, 'Camera', () => _pickImage(ImageSource.camera)),
              _attachButton(ctx, Icons.insert_drive_file_outlined, 'File', _pickFile),
              _attachButton(ctx, Icons.mic_none, 'Voice', _recordVoice),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachButton(BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    final scheme = Theme.of(ctx).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: scheme.secondaryContainer,
            child: Icon(icon, color: scheme.onSecondaryContainer),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollCtl.hasClients) {
      _scrollCtl.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _startCall(Chat? chat, String title, bool video) async {
    final ok = await CallService.startCall(chatId: widget.chatId, video: video, chatName: title);
    if (!ok) _snack('Could not start the call');
  }

  Future<void> _confirmDelete(Message m) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This message will be deleted for everyone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) await _db.deleteMessage(widget.chatId, m.id);
  }

  void _showGroupInfo(Chat chat) {
    final chats = context.read<ChatsProvider>();
    chats.precacheUsers(chat.members);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (ctx, scroll) => Consumer<ChatsProvider>(
          builder: (ctx, chats, _) => ListView(
            controller: scroll,
            children: [
              ListTile(
                leading: UserAvatar(name: chat.name ?? 'Group', photoUrl: chat.photoUrl, size: 52),
                title: Text(chat.name ?? 'Group', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                subtitle: Text('${chat.members.length} members'),
              ),
              const Divider(),
              ...chat.members.map((m) {
                final u = chats.userFor(m);
                final isAdmin = chat.admins.contains(m);
                return ListTile(
                  leading: UserAvatar(name: u?.name ?? 'User', photoUrl: u?.photoUrl),
                  title: Text(m == _uid ? 'You' : (u?.name ?? 'User')),
                  subtitle: u?.email.isNotEmpty == true ? Text(u!.email) : null,
                  trailing: isAdmin ? const Chip(label: Text('Admin')) : null,
                );
              }),
              const Divider(),
              ListTile(
                leading: Icon(Icons.exit_to_app, color: Theme.of(ctx).colorScheme.error),
                title: Text('Leave group', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _db.removeMemberFromGroup(chat.id, _uid);
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().firebaseUser?.uid ?? '';
    final chats = context.watch<ChatsProvider>();
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<Chat?>(
      stream: _db.streamChat(widget.chatId),
      builder: (context, chatSnap) {
        final chat = chatSnap.data ?? chats.chatById(widget.chatId);
        final title = _chatTitle(chat, chats, uid);
        AppUser? other;
        if (chat != null && !chat.isGroup) {
          other = chats.userFor(chat.members.firstWhere((m) => m != uid, orElse: () => ''));
        }
        final subtitle = chat == null
            ? ''
            : chat.isGroup
                ? '${chat.members.length} members'
                : (other?.lastSeen != null ? 'last seen ${Helpers.relative(other!.lastSeen!)}' : '');

        return PopScope(
          canPop: !_showEmoji,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _showEmoji) setState(() => _showEmoji = false);
          },
          child: Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: InkWell(
                onTap: chat != null && chat.isGroup ? () => _showGroupInfo(chat) : null,
                child: Row(children: [
                  UserAvatar(
                    name: title.isEmpty ? '?' : title,
                    photoUrl: chat?.isGroup == true ? chat?.photoUrl : other?.photoUrl,
                    size: 38,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                        if (subtitle.isNotEmpty)
                          Text(subtitle, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: scheme.outline)),
                      ],
                    ),
                  ),
                ]),
              ),
              actions: [
                IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () => _startCall(chat, title, true)),
                IconButton(icon: const Icon(Icons.call_outlined), onPressed: () => _startCall(chat, title, false)),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<Message>>(
                    stream: _db.streamMessages(widget.chatId),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return EmptyState(icon: Icons.error_outline, title: 'Could not load messages', subtitle: '${snap.error}');
                      }
                      if (!snap.hasData) return const LoadingView();
                      final messages = snap.data!;
                      if (messages.isEmpty) {
                        return const EmptyState(icon: Icons.waving_hand_outlined, title: 'No messages yet', subtitle: 'Say hi 👋');
                      }
                      for (final m in messages) {
                        if (m.senderId != uid && !m.readBy.contains(uid)) {
                          _db.markRead(widget.chatId, m.id, uid).catchError((_) {});
                        }
                      }
                      return ListView.builder(
                        controller: _scrollCtl,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[i];
                          final isMine = m.senderId == uid;
                          final next = i + 1 < messages.length ? messages[i + 1] : null; // older message
                          final showDate = m.createdAt != null &&
                              (next == null ||
                                  next.createdAt == null ||
                                  Helpers.formatDate(next.createdAt!) != Helpers.formatDate(m.createdAt!));
                          final showSender = chat?.isGroup == true && !isMine && (next == null || next.senderId != m.senderId);
                          return Column(
                            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (showDate)
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(Helpers.formatDate(m.createdAt!), style: const TextStyle(fontSize: 12)),
                                  ),
                                ),
                              if (showSender && m.senderName.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 20, top: 6),
                                  child: Text(m.senderName,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.primary)),
                                ),
                              MessageBubble(
                                message: m,
                                isMine: isMine,
                                currentUserName: _myName,
                                onReply: () {
                                  setState(() {
                                    _editing = null;
                                    _replyTo = MessageReply(
                                      messageId: m.id,
                                      senderId: m.senderId,
                                      text: m.type == 'text' ? m.text : (m.fileName ?? m.type),
                                      type: m.type,
                                    );
                                  });
                                  _focus.requestFocus();
                                },
                                onCopy: () {
                                  Clipboard.setData(ClipboardData(text: m.text));
                                  _snack('Copied');
                                },
                                onEdit: () {
                                  setState(() {
                                    _replyTo = null;
                                    _editing = m;
                                    _textCtl.text = m.text;
                                    _textCtl.selection = TextSelection.collapsed(offset: m.text.length);
                                  });
                                  _focus.requestFocus();
                                },
                                onDelete: () => _confirmDelete(m),
                                onReact: (emoji) => _db.toggleReaction(
                                  chatId: widget.chatId,
                                  messageId: m.id,
                                  emoji: emoji,
                                  uid: uid,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                if (_uploading) const LinearProgressIndicator(minHeight: 2),
                _buildComposerBanner(scheme),
                _buildInputBar(scheme),
                if (_showEmoji)
                  SizedBox(
                    height: 280,
                    child: EmojiPicker(
                      textEditingController: _textCtl,
                      config: const Config(height: 280),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposerBanner(ColorScheme scheme) {
    if (_replyTo == null && _editing == null) return const SizedBox.shrink();
    final isEdit = _editing != null;
    final text = isEdit ? _editing!.text : (_replyTo!.type == 'text' ? _replyTo!.text : '[${_replyTo!.type}]');
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
      ),
      child: Row(children: [
        Icon(isEdit ? Icons.edit : Icons.reply, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isEdit ? 'Editing message' : 'Replying',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.primary)),
            Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () => setState(() {
            if (isEdit) _textCtl.clear();
            _replyTo = null;
            _editing = null;
          }),
        ),
      ]),
    );
  }

  Widget _buildInputBar(ColorScheme scheme) {
    final hasText = _textCtl.text.trim().isNotEmpty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _textCtl,
                focusNode: _focus,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message',
                  prefixIcon: IconButton(
                    icon: Icon(_showEmoji ? Icons.keyboard_outlined : Icons.emoji_emotions_outlined),
                    onPressed: () {
                      if (_showEmoji) {
                        _focus.requestFocus();
                      } else {
                        _focus.unfocus();
                        setState(() => _showEmoji = true);
                      }
                    },
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _uploading ? null : _showAttachSheet,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            FloatingActionButton(
              heroTag: null,
              elevation: 0,
              onPressed: hasText ? _sendText : (_uploading ? null : _recordVoice),
              child: Icon(hasText ? (_editing != null ? Icons.check : Icons.send) : Icons.mic),
            ),
          ],
        ),
      ),
    );
  }
}
