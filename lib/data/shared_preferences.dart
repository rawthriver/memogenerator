import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesStorage {
  static const String _memeKey = 'memes';

  static SharedPreferencesStorage? _instance;

  factory SharedPreferencesStorage.getInstance() => _instance ??= SharedPreferencesStorage._();

  SharedPreferencesStorage._();

  Future<List<String>> getMemes() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getStringList(_memeKey) ?? [];
  }

  Future<bool> setMemes(final List<String> list) async {
    final sp = await SharedPreferences.getInstance();
    return await sp.setStringList(_memeKey, list);
  }
}
