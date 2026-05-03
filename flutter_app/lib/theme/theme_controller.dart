import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/glass.dart';

class ThemeController extends ChangeNotifier {
  AppPalette _current;
  ThemeController(this._current);

  AppPalette get current => _current;

  Future<void> setPalette(AppPalette p) async {
    if (p.name == _current.name) return;
    _current = p;
    setActivePalette(p);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_name', p.name);
    notifyListeners();
  }

  static Future<ThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('theme_name') ?? palettes.first.name;
    final p = palettes.firstWhere(
      (x) => x.name == name,
      orElse: () => palettes.first,
    );
    setActivePalette(p);
    return ThemeController(p);
  }
}
