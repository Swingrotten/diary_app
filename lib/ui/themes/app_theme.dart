import 'package:flutter/material.dart';

class AppTheme {
  // 品牌颜色 - 更柔和清新的主题色调
  static const Color primaryColor = Color(0xFF5C6BC0); // 靛蓝色主色调
  static const Color secondaryColor = Color(0xFF26A69A); // 青绿色辅助色
  static const Color accentColor = Color(0xFFFFB74D); // 橙色强调色
  static const Color errorColor = Color(0xFFEF5350); // 红色错误提示
  
  // 暗色主题颜色
  static const Color primaryDarkColor = Color(0xFF7986CB);
  static const Color secondaryDarkColor = Color(0xFF4DB6AC);
  static const Color accentDarkColor = Color(0xFFFFCC80);
  static const Color errorDarkColor = Color(0xFFE57373);
  
  // 文本颜色
  static const Color textColorLight = Color(0xFF37474F); // 深灰蓝文本色
  static const Color textColorSecondaryLight = Color(0xFF78909C); // 次要文本颜色
  static const Color textColorDark = Color(0xFFECEFF1);
  static const Color textColorSecondaryDark = Color(0xFFB0BEC5);
  
  // 背景和卡片颜色
  static const Color backgroundColorLight = Color(0xFFF8F9FB); // 淡雅背景色
  static const Color cardColorLight = Color(0xFFFFFFFF);
  static const Color backgroundColorDark = Color(0xFF1A1A2E); // 深蓝黑色背景
  static const Color cardColorDark = Color(0xFF252A41);
  
  // 浅色主题
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      surface: cardColorLight,
      background: backgroundColorLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textColorLight,
      onBackground: textColorLight,
    ),
    scaffoldBackgroundColor: backgroundColorLight,
    cardTheme: CardTheme(
      color: cardColorLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.08),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontSize: 20, 
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: cardColorLight,
      selectedItemColor: primaryColor,
      unselectedItemColor: textColorSecondaryLight,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      hintStyle: TextStyle(color: Colors.grey.shade400),
      labelStyle: TextStyle(color: Colors.grey.shade600),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade200,
      thickness: 1,
      space: 24,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade100,
      selectedColor: primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(color: textColorLight, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: textColorLight, 
        fontWeight: FontWeight.bold,
        fontSize: 24,
        letterSpacing: 0.2,
      ),
      titleMedium: TextStyle(
        color: textColorLight, 
        fontWeight: FontWeight.w600,
        fontSize: 18,
        letterSpacing: 0.1,
      ),
      titleSmall: TextStyle(
        color: textColorLight, 
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      bodyLarge: TextStyle(
        color: textColorLight, 
        fontSize: 16,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        color: textColorLight, 
        fontSize: 15,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: textColorSecondaryLight, 
        fontSize: 13,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.grey.shade800,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
  
  // 深色主题
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primaryDarkColor,
      secondary: secondaryDarkColor,
      tertiary: accentDarkColor,
      error: errorDarkColor,
      surface: cardColorDark,
      background: backgroundColorDark,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: textColorDark,
      onBackground: textColorDark,
    ),
    scaffoldBackgroundColor: backgroundColorDark,
    cardTheme: CardTheme(
      color: cardColorDark,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: cardColorDark,
      foregroundColor: textColorDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontSize: 20, 
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: cardColorDark,
      selectedItemColor: primaryDarkColor,
      unselectedItemColor: textColorSecondaryDark,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryDarkColor,
      foregroundColor: Colors.black,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryDarkColor,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryDarkColor,
        side: BorderSide(color: primaryDarkColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade900,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryDarkColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      hintStyle: TextStyle(color: Colors.grey.shade600),
      labelStyle: TextStyle(color: Colors.grey.shade400),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade800,
      thickness: 1,
      space: 24,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade800,
      selectedColor: primaryDarkColor.withOpacity(0.4),
      labelStyle: TextStyle(color: textColorDark, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade700),
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: textColorDark, 
        fontWeight: FontWeight.bold,
        fontSize: 24,
        letterSpacing: 0.2,
      ),
      titleMedium: TextStyle(
        color: textColorDark, 
        fontWeight: FontWeight.w600,
        fontSize: 18,
        letterSpacing: 0.1,
      ),
      titleSmall: TextStyle(
        color: textColorDark, 
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      bodyLarge: TextStyle(
        color: textColorDark, 
        fontSize: 16,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        color: textColorDark, 
        fontSize: 15,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: textColorSecondaryDark, 
        fontSize: 13,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.grey.shade900,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}