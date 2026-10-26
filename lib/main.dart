import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/chats_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/firebase_setup_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase reads its config from android/app/google-services.json.
  // If that file was not added yet, the app still opens and explains what is missing
  // instead of crashing on launch.
  String? firebaseError;
  try {
    await Firebase.initializeApp();
  } catch (e) {
    firebaseError = e.toString();
  }

  runApp(firebaseError == null ? const MMessageApp() : FirebaseSetupApp(error: firebaseError));
}

class MMessageApp extends StatelessWidget {
  const MMessageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return DynamicColorBuilder(
            builder: (lightDynamic, darkDynamic) {
              final useDynamic = settings.dynamicColor;
              return MaterialApp(
                title: AppConstants.appName,
                debugShowCheckedModeBanner: false,
                themeMode: settings.themeMode,
                theme: AppTheme.light(useDynamic ? lightDynamic : null),
                darkTheme: AppTheme.dark(useDynamic ? darkDynamic : null),
                home: const SplashScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
