import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/helpers.dart';
import '../providers/auth_provider.dart';
import '../providers/chats_provider.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final chats = context.watch<ChatsProvider>();
    final uid = context.watch<AuthProvider>().firebaseUser?.uid ?? '';

    if (chats.loading) return const LoadingView();
    if (chats.chats.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No chats yet',
        subtitle: 'Tap the chat button to start a new conversation',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chats.chats.length,
      itemBuilder: (_, i) {
        final c = chats.chats[i];
        String title;
        String? photo;
        if (c.isGroup) {
          title = c.name ?? 'Group';
          photo = c.photoUrl;
        } else {
          final otherUid = c.members.firstWhere((m) => m != uid, orElse: () => '');
          final other = chats.userFor(otherUid);
          title = other?.name ?? 'User';
          photo = other?.photoUrl;
        }

        return ListTile(
          leading: UserAvatar(name: title, photoUrl: photo, size: 48),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(
            c.lastMessage.isEmpty ? 'Say hi!' : c.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: c.lastMessageTime != null
              ? Text(Helpers.relative(c.lastMessageTime!), style: const TextStyle(fontSize: 12))
              : null,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: c.id)));
          },
        );
      },
    );
  }
}
