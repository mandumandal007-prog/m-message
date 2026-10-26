import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/status.dart';

class StatusService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Status>> streamActiveStatuses() {
    return _db
        .collection('statuses')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: false)
        .snapshots()
        .map((s) {
          final list = s.docs.map(Status.fromDoc).toList();
          list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return list;
        });
  }

  Future<void> createStatus({
    required String userId,
    required String userName,
    String? userPhoto,
    required String type,
    String? text,
    String? imageUrl,
    String backgroundColor = '#4D6BFE',
    int hoursValid = 24,
  }) async {
    final now = DateTime.now();
    await _db.collection('statuses').add({
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'type': type,
      'text': text,
      'imageUrl': imageUrl,
      'backgroundColor': backgroundColor,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(Duration(hours: hoursValid))),
      'viewers': [],
    });
  }

  Future<void> markViewed(String statusId, String uid) async {
    await _db.collection('statuses').doc(statusId).update({
      'viewers': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> deleteStatus(String statusId) async {
    await _db.collection('statuses').doc(statusId).delete();
  }

  Future<void> cleanupExpired() async {
    final expired = await _db
        .collection('statuses')
        .where('expiresAt', isLessThan: Timestamp.now())
        .get();
    for (final doc in expired.docs) {
      await doc.reference.delete();
    }
  }
}
