import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? bio;
  final DateTime? lastSeen;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.bio,
    this.lastSeen,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: (d['name'] as String?) ?? 'User',
      email: (d['email'] as String?) ?? '',
      photoUrl: d['photoUrl'] as String?,
      bio: d['bio'] as String?,
      lastSeen: (d['lastSeen'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'bio': bio,
        'lastSeen': FieldValue.serverTimestamp(),
      };

  AppUser copyWith({String? name, String? photoUrl, String? bio, DateTime? lastSeen}) => AppUser(
        uid: uid,
        name: name ?? this.name,
        email: email,
        photoUrl: photoUrl ?? this.photoUrl,
        bio: bio ?? this.bio,
        lastSeen: lastSeen ?? this.lastSeen,
      );
}
