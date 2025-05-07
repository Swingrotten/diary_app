import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static const String _lightTheme = 'light';
  static const String _darkTheme = 'dark';
  static const String _systemTheme = 'system';
  
  late SharedPreferences _prefs;
  String _currentThemeMode = _systemTheme;
  
  // 单例模式
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  
  ThemeService._internal();
  
  // 初始化
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadThemePreference();
  }
  
  // 加载主题首选项
  void _loadThemePreference() {
    _currentThemeMode = _prefs.getString(_themeKey) ?? _systemTheme;
    notifyListeners();
  }
  
  // 获取当前主题模式
  ThemeMode get themeMode {
    switch (_currentThemeMode) {
      case _lightTheme:
        return ThemeMode.light;
      case _darkTheme:
        return ThemeMode.dark;
      case _systemTheme:
      default:
        return ThemeMode.system;
    }
  }
  
  // 获取当前主题模式的文本表示
  String get currentThemeMode => _currentThemeMode;
  
  // 切换到浅色主题
  Future<void> setLightTheme() async {
    await _prefs.setString(_themeKey, _lightTheme);
    _currentThemeMode = _lightTheme;
    notifyListeners();
  }
  
  // 切换到深色主题
  Future<void> setDarkTheme() async {
    await _prefs.setString(_themeKey, _darkTheme);
    _currentThemeMode = _darkTheme;
    notifyListeners();
  }
  
  // 切换到跟随系统
  Future<void> setSystemTheme() async {
    await _prefs.setString(_themeKey, _systemTheme);
    _currentThemeMode = _systemTheme;
    notifyListeners();
  }
  
  // 切换主题（循环：系统 -> 浅色 -> 深色 -> 系统）
  Future<void> toggleTheme() async {
    switch (_currentThemeMode) {
      case _systemTheme:
        await setLightTheme();
        break;
      case _lightTheme:
        await setDarkTheme();
        break;
      case _darkTheme:
        await setSystemTheme();
        break;
    }
  }
} 