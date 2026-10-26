import 'package:flutter/foundation.dart';
import '../models/chat.dart';
import '../models/app_user.dart';
import '../services/firestore_service.dart';

class ChatsProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();
  final Map<String, AppUser> _userCache = {};

  List<Chat> _chats = [];
  bool _loading = true;

  List<Chat> get chats => _chats;
  bool get loading => _loading;

  void bind(String uid) {
    _db.streamMyChats(uid).listen((list) {
      _chats = list;
      _loading = false;
      notifyListeners();
      for (final c in list) {
        if (c.type == 'direct') {
          final other = c.members.firstWhere((m) => m != uid, orElse: () => '');
          if (other.isNotEmpty && !_userCache.containsKey(other)) {
            _db.streamUser(other).listen((u) {
              if (u != null) {
                _userCache[other] = u;
                notifyListeners();
              }
            });
          }
        }
      }
    });
  }

  AppUser? userFor(String uid) => _userCache[uid];

  Future<void> precacheUsers(List<String> uids) async {
    for (final uid in uids) {
      if (_userCache.containsKey(uid)) continue;
      final u = await _db.getUser(uid);
      if (u != null) _userCache[uid] = u;
    }
    notifyListeners();
  }

  Future<String> startDirectChat(String myUid, String otherUid) => _db.ensureDirectChat(myUid, otherUid);

  Future<String> createGroup({required String name, required List<String> memberIds, required String creatorId, String? photoUrl}) =>
      _db.createGroupChat(name: name, memberIds: memberIds, creatorId: creatorId, photoUrl: photoUrl);

  Chat? chatById(String id) {
    for (final c in _chats) {
      if (c.id == id) return c;
    }
    return null;
  }
}
