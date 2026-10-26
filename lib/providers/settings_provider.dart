import 'package:flutter/material.dart';
import '../services/local_prefs.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _dynamicColor = true;
  String _aiProvider = 'deepseek';
  String _aiKey = '';

  ThemeMode get themeMode => _themeMode;
  bool get dynamicColor => _dynamicColor;
  String get aiProvider => _aiProvider;
  String get aiKey => _aiKey;
  bool get hasAiKey => _aiKey.isNotEmpty;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final mode = await LocalPrefs.getThemeMode();
    _themeMode = switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _dynamicColor = await LocalPrefs.getDynamic();
    _aiProvider = await LocalPrefs.getAiProvider();
    _aiKey = await LocalPrefs.getAiKey();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode m) async {
    _themeMode = m;
    await LocalPrefs.setThemeMode(m.name);
    notifyListeners();
  }

  Future<void> setDynamicColor(bool v) async {
    _dynamicColor = v;
    await LocalPrefs.setDynamic(v);
    notifyListeners();
  }

  Future<void> setAi({String? provider, String? key}) async {
    if (provider != null) {
      _aiProvider = provider;
      await LocalPrefs.setAiProvider(provider);
    }
    if (key != null) {
      _aiKey = key;
      await LocalPrefs.setAiKey(key);
    }
    notifyListeners();
  }
}
