import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'services/diary_provider.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/themes/app_theme.dart';
import 'services/webdav_service.dart';
import 'services/diary_database.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置首选的屏幕方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 初始化数据库 - 支持Windows
  if (Platform.isWindows || Platform.isLinux) {
    // 初始化FFI
    sqfliteFfiInit();
    // 设置数据库工厂
    databaseFactory = databaseFactoryFfi;
  }
  
  // 初始化数据库
  await DiaryDatabase.instance.initialize();
  
  // 初始化WebDAV服务
  final webDavService = WebDavService();
  await webDavService.initialize();
  
  // 初始化主题服务
  final themeService = ThemeService();
  await themeService.initialize();
  
  // 测试WebDAV连接
  await _testWebDAVConnection();
  
  // 如果启用了启动时同步，执行同步操作
  if (webDavService.isEnabled && webDavService.syncOnStart) {
    // 同步操作将在后台进行
    _syncDiariesOnStart();
  }
  
  runApp(const MyApp());
}

// 测试WebDAV连接
Future<void> _testWebDAVConnection() async {
  // 在调试模式下进行WebDAV连接测试
  if (kDebugMode) {
    print('WebDAV功能已初始化');
    
    // 使用配置文件中的设置进行测试，不再使用硬编码凭据
    // 如果需要测试，请在应用中配置WebDAV设置
  }
}

// 启动时同步函数
Future<void> _syncDiariesOnStart() async {
  // 获取所有日记条目
  final entries = await DiaryDatabase.instance.readAllEntries();
  final webDavService = WebDavService();
  
  // 对每个条目执行同步
  for (final entry in entries) {
    await webDavService.syncDiaryEntry(entry);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
        ChangeNotifierProvider.value(value: ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: '每日心情',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
