import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/storage_service.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _uploading = false;

  Future<void> _changePhoto() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.firebaseUser?.uid;
    if (uid == null) return;
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (img == null) return;
    setState(() => _uploading = true);
    try {
      final url = await StorageService().uploadAvatar(uid: uid, file: File(img.path));
      await auth.updateProfile(photoUrl: url);
    } catch (e) {
      _snack('Could not update photo: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _editText({required String title, required String initial, required Future<void> Function(String) onSave, int maxLines = 1}) async {
    final ctl = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctl, autofocus: true, maxLines: maxLines),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result != null) await onSave(result);
  }

  Future<void> _editAi() async {
    final settings = context.read<SettingsProvider>();
    var provider = settings.aiProvider;
    final keyCtl = TextEditingController(text: settings.aiKey);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('AI assistant'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'deepseek', label: Text('DeepSeek')),
                  ButtonSegment(value: 'openai', label: Text('OpenAI')),
                ],
                selected: {provider},
                onSelectionChanged: (s) => setLocal(() => provider = s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyCtl,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'API key'),
              ),
              const SizedBox(height: 8),
              const Text('Your key is stored only on this phone.', style: TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (saved == true) await settings.setAi(provider: provider, key: keyCtl.text.trim());
  }

  void _snack(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final me = auth.appUser;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            GestureDetector(
              onTap: _uploading ? null : _changePhoto,
              child: Stack(children: [
                UserAvatar(name: me?.name ?? 'Me', photoUrl: me?.photoUrl, size: 72),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: scheme.primary,
                    child: _uploading
                        ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary))
                        : Icon(Icons.camera_alt, size: 14, color: scheme.onPrimary),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(me?.name ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                Text(me?.email ?? auth.firebaseUser?.email ?? '', style: TextStyle(color: scheme.outline)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        _section('Profile'),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Name'),
          subtitle: Text(me?.name ?? ''),
          onTap: () => _editText(title: 'Name', initial: me?.name ?? '', onSave: (v) async {
            if (v.isNotEmpty) await auth.updateProfile(name: v);
          }),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About'),
          subtitle: Text((me?.bio ?? '').isEmpty ? 'Add a few words about yourself' : me!.bio!),
          onTap: () => _editText(title: 'About', initial: me?.bio ?? '', maxLines: 3, onSave: (v) => auth.updateProfile(bio: v)),
        ),
        _section('Appearance'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('System')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => settings.setThemeMode(s.first),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.palette_outlined),
          title: const Text('Dynamic color'),
          subtitle: const Text('Use colors from your wallpaper (Android 12+)'),
          value: settings.dynamicColor,
          onChanged: settings.setDynamicColor,
        ),
        _section('AI assistant'),
        ListTile(
          leading: const Icon(Icons.auto_awesome_outlined),
          title: Text('${AppConstants.aiBotName} provider'),
          subtitle: Text(settings.hasAiKey
              ? '${settings.aiProvider == 'openai' ? 'OpenAI' : 'DeepSeek'} · key saved'
              : 'Add an API key to chat with ${AppConstants.aiBotName}'),
          onTap: _editAi,
        ),
        _section('More'),
        ListTile(
          leading: const Icon(Icons.share_outlined),
          title: const Text('Invite friends'),
          onTap: () => Share.share('Join me on ${AppConstants.appName}!'),
        ),
        ListTile(
          leading: Icon(Icons.logout, color: scheme.error),
          title: Text('Sign out', style: TextStyle(color: scheme.error)),
          onTap: () async {
            final yes = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Sign out?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
                ],
              ),
            );
            if (yes == true) await auth.signOut();
          },
        ),
        const SizedBox(height: 16),
        Center(child: Text('${AppConstants.appName} v1.0.0', style: TextStyle(color: scheme.outline, fontSize: 12))),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(title,
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
      );
}
