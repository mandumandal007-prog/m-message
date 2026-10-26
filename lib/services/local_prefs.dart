import 'package:shared_preferences/shared_preferences.dart';

class LocalPrefs {
  static const _kThemeMode = 'theme_mode';
  static const _kDynamic = 'dynamic_color';
  static const _kAiProvider = 'ai_provider';
  static const _kAiKey = 'ai_key';

  static Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  static Future<String> getThemeMode() async => (await _p).getString(_kThemeMode) ?? 'system';
  static Future<void> setThemeMode(String m) async => (await _p).setString(_kThemeMode, m);

  static Future<bool> getDynamic() async => (await _p).getBool(_kDynamic) ?? true;
  static Future<void> setDynamic(bool v) async => (await _p).setBool(_kDynamic, v);

  static Future<String> getAiProvider() async => (await _p).getString(_kAiProvider) ?? 'deepseek';
  static Future<void> setAiProvider(String p) async => (await _p).setString(_kAiProvider, p);

  static Future<String> getAiKey() async => (await _p).getString(_kAiKey) ?? '';
  static Future<void> setAiKey(String k) async => (await _p).setString(_kAiKey, k);
}
