import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/status_service.dart';
import '../services/storage_service.dart';
import '../core/constants.dart';

class CreateStatusScreen extends StatefulWidget {
  const CreateStatusScreen({super.key});

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> {
  final _textCtl = TextEditingController();
  File? _image;
  Color _bg = AppConstants.primaryBlue;
  bool _posting = false;

  static const _colors = [
    Color(0xFF4D6BFE),
    Color(0xFFD32F2F),
    Color(0xFF388E3C),
    Color(0xFFF57C00),
    Color(0xFF7B1FA2),
    Color(0xFF00796B),
    Color(0xFF5D4037),
    Color(0xFF37474F),
  ];

  @override
  void dispose() {
    _textCtl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _image = File(img.path));
  }

  Future<void> _post() async {
    final me = context.read<AuthProvider>().appUser;
    if (me == null) return;
    if (_image == null && _textCtl.text.trim().isEmpty) return;

    setState(() => _posting = true);
    try {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await StorageService().uploadStatus(uid: me.uid, file: _image!);
      }
      await StatusService().createStatus(
        userId: me.uid,
        userName: me.name,
        userPhoto: me.photoUrl,
        type: _image != null ? 'image' : 'text',
        text: _textCtl.text.trim().isEmpty ? null : _textCtl.text.trim(),
        imageUrl: imageUrl,
        backgroundColor: '#${_bg.toARGB32().toRadixString(16).substring(2)}',
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _image != null ? Colors.black : _bg;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: _image != null ? Colors.white : Colors.white,
        title: const Text('New status'),
        actions: [
          TextButton(
            onPressed: _posting ? null : _post,
            child: _posting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _image != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.file(_image!, fit: BoxFit.contain),
                Positioned(
                  bottom: 24, left: 16, right: 16,
                  child: TextField(
                    controller: _textCtl,
                    style: const TextStyle(color: Colors.white),
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Add a caption…',
                      hintStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.black45,
                    ),
                  ),
                ),
                Positioned(
                  top: 12, right: 12,
                  child: IconButton.filled(
                    onPressed: () => setState(() => _image = null),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _textCtl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w600),
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Type a status…',
                        hintStyle: TextStyle(color: Colors.white70, fontSize: 22),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: _colors
                          .map((c) => GestureDetector(
                                onTap: () => setState(() => _bg = c),
                                child: Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _bg == c ? Colors.white : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 32),
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Add photo'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
