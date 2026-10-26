import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadChatMedia({required String chatId, required File file, required String ext}) async {
    final ref = _storage.ref().child('chats/$chatId/${_uuid.v4()}.$ext');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  Future<String> uploadAvatar({required String uid, required File file}) async {
    final ref = _storage.ref().child('avatars/$uid/avatar.jpg');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  Future<String> uploadStatus({required String uid, required File file}) async {
    final ref = _storage.ref().child('statuses/$uid/${_uuid.v4()}.jpg');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }
}
