import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/services/global_storage.dart';

class ThemeController extends GetxController {
  final RxBool _isDarkMode = true.obs;
  
  static const String _themeKey = 'is_dark_mode';

  bool get isDarkMode => _isDarkMode.value;
  
  ThemeMode get themeMode => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromStorage();
  }

  Future<void> _loadThemeFromStorage() async {
    final savedTheme = StorageService.read(_themeKey);
    if (savedTheme != null) {
      _isDarkMode.value = savedTheme as bool;
    }
  }

  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
    _saveThemeToStorage();
    Get.changeThemeMode(themeMode);
    update();
  }

  void setTheme(bool isDark) {
    _isDarkMode.value = isDark;
    _saveThemeToStorage();
    Get.changeThemeMode(themeMode);
  }

  Future<void> _saveThemeToStorage() async {
    StorageService.write(_themeKey, _isDarkMode.value);
  }
}
