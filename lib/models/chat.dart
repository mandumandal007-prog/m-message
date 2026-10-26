import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String type; // 'direct' | 'group'
  final String? name;
  final String? photoUrl;
  final List<String> members;
  final List<String> admins;
  final String createdBy;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String? lastSenderId;
  final DateTime? createdAt;

  Chat({
    required this.id,
    required this.type,
    this.name,
    this.photoUrl,
    required this.members,
    required this.admins,
    required this.createdBy,
    required this.lastMessage,
    this.lastMessageTime,
    this.lastSenderId,
    this.createdAt,
  });

  factory Chat.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Chat(
      id: doc.id,
      type: (d['type'] as String?) ?? 'direct',
      name: d['name'] as String?,
      photoUrl: d['photoUrl'] as String?,
      members: List<String>.from(d['members'] ?? []),
      admins: List<String>.from(d['admins'] ?? []),
      createdBy: (d['createdBy'] as String?) ?? '',
      lastMessage: (d['lastMessage'] as String?) ?? '',
      lastMessageTime: (d['lastMessageTime'] as Timestamp?)?.toDate(),
      lastSenderId: d['lastSenderId'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isGroup => type == 'group';

  static String directId(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}
