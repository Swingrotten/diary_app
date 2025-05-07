import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:path/path.dart' as path;
import '../models/diary_entry.dart';
import 'diary_database.dart';

/// WebDAV服务类，负责同步日记和媒体文件到WebDAV服务器
class WebDavService {
  static final WebDavService _instance = WebDavService._internal();
  webdav.Client? _client;
  bool _isEnabled = false;
  bool _syncOnStart = false;
  bool _syncOnChange = false;
  String _serverUrl = '';
  
  // 单例模式
  factory WebDavService() {
    return _instance;
  }
  
  WebDavService._internal();
  
  // 获取当前客户端实例
  webdav.Client? get client => _client;
  
  // WebDAV服务是否已启用
  bool get isEnabled => _isEnabled;
  
  // 获取服务器URL
  String get serverUrl => _serverUrl;
  
  // 是否在启动时同步
  bool get syncOnStart => _syncOnStart;
  
  // 是否在内容变更时同步
  bool get syncOnChange => _syncOnChange;
  
  /// 初始化WebDAV服务
  Future<void> initialize() async {
    // 尝试从配置文件加载设置
    final config = await _loadConfig();
    if (config != null) {
      try {
        final serverUrl = config['serverUrl'] as String;
        final username = config['username'] as String;
        final password = config['password'] as String;
        
        _serverUrl = serverUrl;
        _syncOnStart = config['syncOnStart'] as bool? ?? false;
        _syncOnChange = config['syncOnChange'] as bool? ?? false;
        
        if (serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty) {
          _client = webdav.newClient(
            serverUrl,
            user: username,
            password: password,
          );
          _isEnabled = true;
          debugPrint('WebDAV服务初始化成功');
        }
      } catch (e) {
        debugPrint('WebDAV服务初始化失败: $e');
        _isEnabled = false;
        _client = null;
      }
    }
  }
  
  /// 保存WebDAV配置到文件
  Future<bool> saveConfig({
    required String serverUrl,
    required String username,
    required String password,
    required bool syncOnStart,
    required bool syncOnChange,
  }) async {
    try {
      final configDir = await _getConfigDir();
      final configFile = File(path.join(configDir.path, 'webdav_config.json'));
      
      final config = {
        'serverUrl': serverUrl,
        'username': username,
        'password': password,
        'syncOnStart': syncOnStart,
        'syncOnChange': syncOnChange,
      };
      
      await configFile.writeAsString(jsonEncode(config));
      
      // 保存成功后更新当前实例
      _serverUrl = serverUrl;
      _client = webdav.newClient(
        serverUrl,
        user: username,
        password: password,
      );
      _isEnabled = true;
      _syncOnStart = syncOnStart;
      _syncOnChange = syncOnChange;
      
      return true;
    } catch (e) {
      debugPrint('保存WebDAV配置失败: $e');
      return false;
    }
  }
  
  /// 获取配置目录
  Future<Directory> _getConfigDir() async {
    Directory configDir;
    
    if (Platform.isWindows || Platform.isLinux) {
      final documentsDir = await getApplicationDocumentsDirectory();
      final dirPath = path.join(documentsDir.path, 'DiaryApp', 'Config');
      configDir = Directory(dirPath);
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final dirPath = path.join(appDir.path, 'Config');
      configDir = Directory(dirPath);
    }
    
    // 确保目录存在
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }
    
    return configDir;
  }
  
  /// 加载WebDAV配置
  Future<Map<String, dynamic>?> _loadConfig() async {
    try {
      final configDir = await _getConfigDir();
      final configFile = File(path.join(configDir.path, 'webdav_config.json'));
      
      if (await configFile.exists()) {
        final jsonStr = await configFile.readAsString();
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      debugPrint('加载WebDAV配置失败: $e');
      return null;
    }
  }
  
  /// 测试WebDAV连接
  Future<bool> testConnection(String serverUrl, String username, String password) async {
    try {
      // 创建临时客户端
      final testClient = webdav.newClient(
        serverUrl,
        user: username,
        password: password,
      );
      
      // 检查连接 - 尝试ping和目录读取
      await testClient.ping();
      
      // 尝试读取根目录或创建临时测试文件来完全验证
      try {
        // 尝试列出根目录
        await testClient.readDir('/');
        
        // 创建一个临时文件来测试写入权限
        final testContent = 'test_${DateTime.now().millisecondsSinceEpoch}';
        final testPath = 'webdav_test_${DateTime.now().millisecondsSinceEpoch}.txt';
        
        // 转换为Uint8List并写入文件
        final Uint8List contentBytes = Uint8List.fromList(utf8.encode(testContent));
        await testClient.write(
          testPath,
          contentBytes,
        );
        
        // 读取刚写入的文件
        final content = await testClient.read(testPath);
        final contentStr = utf8.decode(content);
        
        // 验证内容
        final isContentValid = contentStr == testContent;
        
        // 删除测试文件
        await testClient.remove(testPath);
        
        return isContentValid;
      } catch (dirError) {
        debugPrint('WebDAV目录操作测试失败: $dirError');
        // 仅Ping成功也认为连接正常
        return true;
      }
    } catch (e) {
      debugPrint('WebDAV连接测试失败: $e');
      return false;
    }
  }
  
  /// 获取当前配置
  Future<Map<String, dynamic>?> getCurrentConfig() async {
    return await _loadConfig();
  }
  
  /// 同步日记条目到WebDAV
  Future<bool> syncDiaryEntry(DiaryEntry entry) async {
    if (!_isEnabled || _client == null) return false;
    
    try {
      // 创建日期格式化的目录名
      final dateStr = '${entry.dateCreated.year}${entry.dateCreated.month.toString().padLeft(2, '0')}${entry.dateCreated.day.toString().padLeft(2, '0')}';
      final remoteDirPath = '每日心情/日记/$dateStr';
      
      // 确保远程目录存在
      try {
        await _client!.mkdir(remoteDirPath);
      } catch (e) {
        // 忽略目录已存在的错误
        debugPrint('创建目录可能已存在: $e');
      }
      
      // 创建要上传的日记内容
      final entryJson = entry.toJson();
      
      // 创建带ID的文件名
      final fileName = 'diary_${entry.id}.json';
      final remoteFilePath = '$remoteDirPath/$fileName';
      
      // 转换为Uint8List
      final jsonString = jsonEncode(entryJson);
      final Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString));
      
      // 上传日记内容
      await _client!.write(
        remoteFilePath,
        bytes,
      );
      
      // 使用DiaryDatabase更新条目的同步状态
      await _updateEntrySyncStatus(entry);
      
      return true;
    } catch (e) {
      debugPrint('同步日记到WebDAV失败: $e');
      return false;
    }
  }
  
  /// 更新日记条目的同步状态
  Future<void> _updateEntrySyncStatus(DiaryEntry entry) async {
    try {
      // 创建一个带有更新同步状态的新条目
      final updatedEntry = entry.copy(
        syncedToWebDav: true,
        lastSyncTime: DateTime.now(),
      );
      
      // 更新数据库
      final db = await DiaryDatabase.instance.database;
      
      // 只更新同步相关字段
      await db.update(
        'diary_entries',
        {
          'syncedToWebDav': 1,
          'lastSyncTime': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    } catch (e) {
      debugPrint('更新同步状态失败: $e');
    }
  }
  
  /// 标准化媒体文件路径（将临时文件移动到按日期组织的目录中）
  Future<String> standardizeMediaFile(String originalPath, DateTime dateCreated) async {
    try {
      final originalFile = File(originalPath);
      if (!await originalFile.exists()) {
        return originalPath;
      }
      
      // 创建标准化的媒体目录
      final mediaDir = await _getMediaDir();
      
      // 创建按年月日组织的目录
      final dateDir = path.join(
        mediaDir.path,
        '${dateCreated.year}',
        '${dateCreated.month.toString().padLeft(2, '0')}',
        '${dateCreated.day.toString().padLeft(2, '0')}',
      );
      
      // 确保目录存在
      final dateDirObj = Directory(dateDir);
      if (!await dateDirObj.exists()) {
        await dateDirObj.create(recursive: true);
      }
      
      // 创建文件名（使用原文件名但加上时间戳）
      final originalFileName = path.basename(originalPath);
      final fileExt = path.extension(originalFileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = 'image_${timestamp}$fileExt';
      
      // 新文件路径
      final newPath = path.join(dateDir, newFileName);
      
      // 复制文件到新位置
      final newFile = await originalFile.copy(newPath);
      
      // 如果原文件是临时文件，删除它
      if (originalPath.contains('cache') || originalPath.contains('temp')) {
        await originalFile.delete();
      }
      
      return newFile.path;
    } catch (e) {
      debugPrint('标准化媒体文件路径失败: $e');
      return originalPath;
    }
  }
  
  /// 获取媒体文件目录
  Future<Directory> _getMediaDir() async {
    Directory directory;
    
    if (Platform.isWindows || Platform.isLinux) {
      final documentsDir = await getApplicationDocumentsDirectory();
      final mediaDir = path.join(documentsDir.path, 'DiaryApp', 'Media');
      directory = Directory(mediaDir);
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = path.join(appDir.path, 'Media');
      directory = Directory(mediaDir);
    }
    
    // 确保目录存在
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    return directory;
  }
  
  /// 获取远程媒体文件列表
  Future<List<webdav.File>> getRemoteMediaFiles() async {
    if (!_isEnabled || _client == null) return [];
    
    try {
      final List<webdav.File> allFiles = [];
      
      // 确保媒体目录存在
      try {
        await _client!.mkdir('每日心情/媒体');
      } catch (e) {
        // 忽略目录已存在的错误
        debugPrint('创建媒体目录可能已存在: $e');
      }
      
      // 读取媒体目录
      final files = await _client!.readDir('每日心情/媒体');
      
      // 对每个日期目录递归读取文件
      for (var dateDir in files) {
        if (dateDir.isDir ?? false) {
          try {
            final dateFiles = await _client!.readDir('每日心情/媒体/${dateDir.name}');
            allFiles.addAll(dateFiles.where((f) => !(f.isDir ?? true)));
          } catch (e) {
            debugPrint('读取日期目录失败: $e');
          }
        }
      }
      
      return allFiles;
    } catch (e) {
      debugPrint('获取远程媒体文件列表失败: $e');
      return [];
    }
  }
  
  /// 删除远程媒体文件
  Future<bool> deleteRemoteMediaFile(String remotePath) async {
    if (!_isEnabled || _client == null) return false;
    
    try {
      await _client!.remove(remotePath);
      return true;
    } catch (e) {
      debugPrint('删除远程媒体文件失败: $e');
      return false;
    }
  }
} 