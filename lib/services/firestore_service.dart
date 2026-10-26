import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/app_user.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ----- Users -----
  Stream<List<AppUser>> streamAllUsers() {
    return _db.collection('users').snapshots().map((s) => s.docs.map(AppUser.fromDoc).toList());
  }

  Future<AppUser?> getUser(String uid) async {
    final d = await _db.collection('users').doc(uid).get();
    if (!d.exists) return null;
    return AppUser.fromDoc(d);
  }

  Stream<AppUser?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((d) => d.exists ? AppUser.fromDoc(d) : null);
  }

  // ----- Chats -----
  Stream<List<Chat>> streamMyChats(String uid) {
    return _db
        .collection('chats')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((s) {
          final list = s.docs.map(Chat.fromDoc).toList();
          list.sort((a, b) {
            final ta = a.lastMessageTime ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final tb = b.lastMessageTime ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return tb.compareTo(ta);
          });
          return list;
        });
  }

  Stream<Chat?> streamChat(String chatId) {
    return _db.collection('chats').doc(chatId).snapshots().map((d) => d.exists ? Chat.fromDoc(d) : null);
  }

  Future<String> ensureDirectChat(String myUid, String otherUid) async {
    final id = Chat.directId(myUid, otherUid);
    final ref = _db.collection('chats').doc(id);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'type': 'direct',
        'members': [myUid, otherUid],
        'admins': [],
        'createdBy': myUid,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return id;
  }

  Future<String> createGroupChat({
    required String name,
    required List<String> memberIds,
    required String creatorId,
    String? photoUrl,
  }) async {
    final id = _uuid.v4();
    await _db.collection('chats').doc(id).set({
      'type': 'group',
      'name': name,
      'photoUrl': photoUrl,
      'members': [creatorId, ...memberIds],
      'admins': [creatorId],
      'createdBy': creatorId,
      'lastMessage': 'Group created',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return id;
  }

  // ----- Messages -----
  Stream<List<Message>> streamMessages(String chatId, {int limit = 200}) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Message.fromDoc).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    String type = 'text',
    String? mediaUrl,
    String? fileName,
    int? durationSec,
    MessageReply? replyTo,
  }) async {
    final msgRef = _db.collection('chats').doc(chatId).collection('messages').doc();
    final now = FieldValue.serverTimestamp();

    await msgRef.set({
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'durationSec': durationSec,
      'replyTo': replyTo?.toMap(),
      'reactions': <String, dynamic>{},
      'edited': false,
      'deleted': false,
      'readBy': [senderId],
      'createdAt': now,
    });

    final preview = switch (type) {
      'image' => '📷 Photo',
      'file' => '📎 ${fileName ?? 'File'}',
      'audio' => '🎤 Voice message',
      _ => text,
    };

    await _db.collection('chats').doc(chatId).update({
      'lastMessage': preview,
      'lastMessageTime': now,
      'lastSenderId': senderId,
    });
  }

  Future<void> toggleReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String uid,
  }) async {
    final ref = _db.collection('chats').doc(chatId).collection('messages').doc(messageId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
      final list = List<String>.from(reactions[emoji] ?? []);
      if (list.contains(uid)) {
        list.remove(uid);
      } else {
        list.add(uid);
      }
      if (list.isEmpty) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = list;
      }
      tx.update(ref, {'reactions': reactions});
    });
  }

  Future<void> editMessage(String chatId, String messageId, String newText) async {
    await _db.collection('chats').doc(chatId).collection('messages').doc(messageId).update({
      'text': newText,
      'edited': true,
    });
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _db.collection('chats').doc(chatId).collection('messages').doc(messageId).update({
      'deleted': true,
      'text': '',
      'mediaUrl': null,
    });
  }

  Future<void> markRead(String chatId, String messageId, String uid) async {
    final ref = _db.collection('chats').doc(chatId).collection('messages').doc(messageId);
    await ref.update({'readBy': FieldValue.arrayUnion([uid])});
  }

  Future<void> addMemberToGroup(String chatId, String uid) async {
    await _db.collection('chats').doc(chatId).update({
      'members': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> removeMemberFromGroup(String chatId, String uid) async {
    await _db.collection('chats').doc(chatId).update({
      'members': FieldValue.arrayRemove([uid]),
    });
  }
}
