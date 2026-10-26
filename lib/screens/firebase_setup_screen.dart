import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// Shown when Firebase could not start (usually: android/app/google-services.json
/// was not added to the project before building).
class FirebaseSetupApp extends StatelessWidget {
  final String error;
  const FirebaseSetupApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(null),
      darkTheme: AppTheme.dark(null),
      home: FirebaseSetupScreen(error: error),
    );
  }
}

class FirebaseSetupScreen extends StatelessWidget {
  final String error;
  const FirebaseSetupScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.chat_bubble_rounded, size: 48, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(height: 20),
                const Text(AppConstants.appName, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.cloud_off_rounded, color: scheme.error),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Firebase is not connected yet',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        const Text(
                          'Login, chats and status need your Firebase project.\n\n'
                          '1. Firebase Console → Project settings → Add Android app\n'
                          '   package name: com.mmessage.app\n'
                          '2. Download google-services.json\n'
                          '3. Put it in the repo at android/app/google-services.json\n'
                          '4. Enable Email/Password sign-in, Firestore and Storage\n\n'
                          'GitHub Actions will then build a new APK automatically.',
                          style: TextStyle(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('Technical details', style: TextStyle(fontSize: 13)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(error, style: TextStyle(fontSize: 12, color: scheme.outline)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
