import 'package:cloud_firestore/cloud_firestore.dart';

class Status {
  final String id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String type; // 'text' | 'image'
  final String? text;
  final String? imageUrl;
  final String backgroundColor; // hex
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final List<String> viewers;

  Status({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.type,
    this.text,
    this.imageUrl,
    required this.backgroundColor,
    this.createdAt,
    this.expiresAt,
    this.viewers = const [],
  });

  factory Status.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Status(
      id: doc.id,
      userId: (d['userId'] as String?) ?? '',
      userName: (d['userName'] as String?) ?? '',
      userPhoto: d['userPhoto'] as String?,
      type: (d['type'] as String?) ?? 'text',
      text: d['text'] as String?,
      imageUrl: d['imageUrl'] as String?,
      backgroundColor: (d['backgroundColor'] as String?) ?? '#4D6BFE',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate(),
      viewers: List<String>.from(d['viewers'] ?? []),
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isViewed => viewers.contains(userId); // caller overrides with current uid if needed
}
