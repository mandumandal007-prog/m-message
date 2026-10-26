import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  User? _firebaseUser;
  AppUser? _appUser;
  bool _loading = true;

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get loading => _loading;
  bool get isLoggedIn => _firebaseUser != null;

  AuthProvider() {
    _service.authStateChanges.listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        _appUser = await _service.fetchCurrentUser();
      } else {
        _appUser = null;
      }
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> refresh() async {
    _appUser = await _service.fetchCurrentUser();
    notifyListeners();
  }

  Future<void> signUp({required String name, required String email, required String password}) async {
    await _service.signUp(name: name, email: email, password: password);
    await refresh();
  }

  Future<void> signIn({required String email, required String password}) async {
    await _service.signIn(email: email, password: password);
    await refresh();
  }

  Future<void> signOut() async {
    await _service.signOut();
    _appUser = null;
    _firebaseUser = null;
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? photoUrl, String? bio}) async {
    await _service.updateProfile(name: name, photoUrl: photoUrl, bio: bio);
    await refresh();
  }
}
