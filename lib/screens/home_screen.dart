import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chats_provider.dart';
import '../providers/settings_provider.dart';
import '../services/status_service.dart';
import 'chats_tab.dart';
import 'status_tab.dart';
import 'settings_screen.dart';
import 'ai_chat_screen.dart';
import 'new_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _statusService = StatusService();
  bool _bound = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_bound) {
        final uid = context.read<AuthProvider>().firebaseUser?.uid;
        if (uid != null) {
          context.read<ChatsProvider>().bind(uid);
          _bound = true;
        }
        _statusService.cleanupExpired().catchError((_) {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Chats', 'Status', 'Settings'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index], style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          if (_index == 0)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearch(context),
            ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          ChatsTab(),
          StatusTab(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: _index == 0
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'ai',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
                  },
                  child: const Icon(Icons.auto_awesome),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'new',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NewChatScreen()));
                  },
                  child: const Icon(Icons.chat),
                ),
              ],
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chats'),
          NavigationDestination(icon: Icon(Icons.donut_large_outlined), selectedIcon: Icon(Icons.donut_large), label: 'Status'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _ChatSearchDelegate(context.read<ChatsProvider>(), context.read<AuthProvider>().firebaseUser?.uid ?? '', context.read<SettingsProvider>()),
    );
  }
}

class _ChatSearchDelegate extends SearchDelegate {
  final ChatsProvider chats;
  final String uid;
  final SettingsProvider settings;

  _ChatSearchDelegate(this.chats, this.uid, this.settings);

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.close), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final filtered = chats.chats.where((c) {
      final name = c.isGroup
          ? (c.name ?? '')
          : (chats.userFor(c.members.firstWhere((m) => m != uid, orElse: () => ''))?.name ?? '');
      return name.toLowerCase().contains(query.toLowerCase()) && query.isNotEmpty;
    }).toList();
    if (filtered.isEmpty) {
      return const Center(child: Text('No chats found'));
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final c = filtered[i];
        final name = c.isGroup
            ? (c.name ?? 'Group')
            : (chats.userFor(c.members.firstWhere((m) => m != uid, orElse: () => ''))?.name ?? 'User');
        return ListTile(
          leading: CircleAvatar(child: Text(name[0].toUpperCase())),
          title: Text(name),
          onTap: () => close(context, c),
        );
      },
    );
  }
}
