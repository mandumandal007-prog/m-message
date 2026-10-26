import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser?> fetchCurrentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    final doc = await _db.collection('users').doc(u.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  Future<void> signUp({required String name, required String email, required String password}) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final user = cred.user!;
    await user.updateDisplayName(name.trim());
    await _db.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'photoUrl': null,
      'bio': null,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    await _db.collection('users').doc(_auth.currentUser!.uid).set({
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    final u = _auth.currentUser;
    if (u != null) {
      await _db.collection('users').doc(u.uid).set({'lastSeen': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    }
    await _auth.signOut();
  }

  Future<void> updateProfile({String? name, String? photoUrl, String? bio}) async {
    final u = _auth.currentUser;
    if (u == null) return;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (bio != null) updates['bio'] = bio;
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(u.uid).update(updates);
      if (name != null) await u.updateDisplayName(name);
      if (photoUrl != null) await u.updatePhotoURL(photoUrl);
    }
  }
}
