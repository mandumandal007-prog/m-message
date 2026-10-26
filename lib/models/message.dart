import 'package:cloud_firestore/cloud_firestore.dart';

class MessageReply {
  final String messageId;
  final String senderId;
  final String text;
  final String type;

  MessageReply({required this.messageId, required this.senderId, required this.text, required this.type});

  Map<String, dynamic> toMap() => {'messageId': messageId, 'senderId': senderId, 'text': text, 'type': type};

  factory MessageReply.fromMap(Map<String, dynamic> m) => MessageReply(
        messageId: m['messageId'] ?? '',
        senderId: m['senderId'] ?? '',
        text: m['text'] ?? '',
        type: m['type'] ?? 'text',
      );
}

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String type; // text | image | file | audio
  final String? mediaUrl;
  final String? fileName;
  final int? durationSec;
  final MessageReply? replyTo;
  final Map<String, List<String>> reactions; // emoji -> [uids]
  final bool edited;
  final bool deleted;
  final DateTime? createdAt;
  final List<String> readBy;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.type,
    this.mediaUrl,
    this.fileName,
    this.durationSec,
    this.replyTo,
    this.reactions = const {},
    this.edited = false,
    this.deleted = false,
    this.createdAt,
    this.readBy = const [],
  });

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final rawReactions = d['reactions'] as Map<String, dynamic>? ?? {};
    final reactions = rawReactions.map((k, v) => MapEntry(k, List<String>.from(v ?? [])));
    return Message(
      id: doc.id,
      senderId: (d['senderId'] as String?) ?? '',
      senderName: (d['senderName'] as String?) ?? '',
      text: (d['text'] as String?) ?? '',
      type: (d['type'] as String?) ?? 'text',
      mediaUrl: d['mediaUrl'] as String?,
      fileName: d['fileName'] as String?,
      durationSec: d['durationSec'] as int?,
      replyTo: d['replyTo'] != null ? MessageReply.fromMap(Map<String, dynamic>.from(d['replyTo'])) : null,
      reactions: reactions,
      edited: (d['edited'] as bool?) ?? false,
      deleted: (d['deleted'] as bool?) ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      readBy: List<String>.from(d['readBy'] ?? []),
    );
  }
}
