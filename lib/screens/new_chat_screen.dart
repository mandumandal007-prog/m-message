import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/chats_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _db = FirestoreService();
  final _searchCtl = TextEditingController();
  final Set<String> _selected = {};
  bool _creating = false;

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _startDirect(AppUser other) async {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final chatId = await context.read<ChatsProvider>().startDirectChat(uid, other.uid);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId)));
  }

  Future<void> _createGroup(List<AppUser> users) async {
    if (_selected.isEmpty) return;
    final nameCtl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New group'),
        content: TextField(
          controller: nameCtl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Group name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    setState(() => _creating = true);
    try {
      final uid = context.read<AuthProvider>().firebaseUser!.uid;
      final chatId = await context.read<ChatsProvider>().createGroup(
            name: name,
            memberIds: _selected.toList(),
            creatorId: uid,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId)));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().firebaseUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text(_selected.isEmpty ? 'New chat' : '${_selected.length} selected'),
        actions: [
          if (_selected.isNotEmpty)
            TextButton(
              onPressed: _creating ? null : () async {
                // Get users for selected
                final all = await _db.streamAllUsers().first;
                final selected = all.where((u) => _selected.contains(u.uid)).toList();
                await _createGroup(selected);
              },
              child: const Text('Next'),
            ),
        ],
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: _db.streamAllUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingView();
          final users = snapshot.data!.where((u) => u.uid != uid).toList();
          final filtered = users
              .where((u) =>
                  u.name.toLowerCase().contains(_searchCtl.text.toLowerCase()) ||
                  u.email.toLowerCase().contains(_searchCtl.text.toLowerCase()))
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchCtl,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search people…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.people_outline,
                        title: 'No users found',
                        subtitle: 'Invite friends to join M Message',
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final u = filtered[i];
                          return ListTile(
                            leading: UserAvatar(name: u.name, photoUrl: u.photoUrl, size: 44),
                            title: Text(u.name),
                            subtitle: Text(u.email, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Checkbox(
                              value: _selected.contains(u.uid),
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selected.add(u.uid);
                                  } else {
                                    _selected.remove(u.uid);
                                  }
                                });
                              },
                            ),
                            onTap: () {
                              if (_selected.isEmpty) {
                                _startDirect(u);
                              } else {
                                setState(() {
                                  if (_selected.contains(u.uid)) {
                                    _selected.remove(u.uid);
                                  } else {
                                    _selected.add(u.uid);
                                  }
                                });
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
