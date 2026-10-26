import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/status.dart';
import '../providers/auth_provider.dart';
import '../services/status_service.dart';
import '../widgets/common.dart';
import 'create_status_screen.dart';
import 'status_viewer_screen.dart';

class StatusTab extends StatelessWidget {
  const StatusTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = StatusService();
    final uid = context.watch<AuthProvider>().firebaseUser?.uid ?? '';
    final me = context.watch<AuthProvider>().appUser;

    return Scaffold(
      body: StreamBuilder<List<Status>>(
        stream: service.streamActiveStatuses(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingView();
          final all = snapshot.data!;
          final myStatuses = all.where((s) => s.userId == uid).toList();
          final others = all.where((s) => s.userId != uid).toList();
          final grouped = <String, List<Status>>{};
          for (final s in others) {
            grouped.putIfAbsent(s.userId, () => []).add(s);
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              ListTile(
                leading: Stack(
                  children: [
                    UserAvatar(name: me?.name ?? 'Me', photoUrl: me?.photoUrl, size: 52),
                    if (myStatuses.isNotEmpty)
                      Positioned(
                        right: 0, bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                title: const Text('My status', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(myStatuses.isEmpty ? 'Tap to add status update' : '${myStatuses.length} updates'),
                onTap: () {
                  if (myStatuses.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => StatusViewerScreen(statuses: myStatuses, initialIndex: 0),
                    ));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateStatusScreen()));
                  }
                },
                trailing: myStatuses.isEmpty
                    ? IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateStatusScreen())),
                      )
                    : IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateStatusScreen())),
                      ),
              ),
              const Divider(),
              if (grouped.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: EmptyState(
                    icon: Icons.donut_large_outlined,
                    title: 'No recent updates',
                    subtitle: 'Status updates from your contacts appear here',
                  ),
                )
              else
                ...grouped.entries.map((e) {
                  final list = e.value;
                  final first = list.first;
                  return ListTile(
                    leading: UserAvatar(name: first.userName, photoUrl: first.userPhoto, size: 52),
                    title: Text(first.userName, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('${list.length} update${list.length > 1 ? 's' : ''}'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => StatusViewerScreen(statuses: list, initialIndex: 0),
                    )),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
