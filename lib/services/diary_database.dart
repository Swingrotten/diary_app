import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/diary_entry.dart';

class DiaryDatabase {
  static final DiaryDatabase instance = DiaryDatabase._init();
  static Database? _database;

  DiaryDatabase._init();

  Future<void> initialize() async {
    await database;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('diary.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    
    if (Platform.isWindows || Platform.isLinux) {
      // Windows/Linux路径处理
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbDir = join(documentsDir.path, 'DiaryApp');
      
      // 确保目录存在
      await Directory(dbDir).create(recursive: true);
      path = join(dbDir, filePath);
    } else {
      // Android/iOS路径处理
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path, 
      version: 2,  // 升级数据库版本
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // 创建新数据库
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diary_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        dateCreated TEXT NOT NULL,
        dateModified TEXT NOT NULL,
        tags TEXT NOT NULL,
        mood INTEGER NOT NULL,
        mediaLinks TEXT NOT NULL,
        isFavorite INTEGER NOT NULL,
        locationName TEXT,
        contentFormat TEXT NOT NULL DEFAULT 'plainText',
        syncedToWebDav INTEGER NOT NULL DEFAULT 0,
        lastSyncTime TEXT
      )
    ''');
  }
  
  // 升级数据库
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 添加新列
      try {
        await db.execute('ALTER TABLE diary_entries ADD COLUMN contentFormat TEXT NOT NULL DEFAULT "plainText"');
        await db.execute('ALTER TABLE diary_entries ADD COLUMN syncedToWebDav INTEGER NOT NULL DEFAULT 0');
        await db.execute('ALTER TABLE diary_entries ADD COLUMN lastSyncTime TEXT');
      } catch (e) {
        print('数据库升级错误: $e');
        // 某些数据库引擎不支持同时添加多列，尝试单独添加
        try {
          await db.execute('ALTER TABLE diary_entries ADD COLUMN contentFormat TEXT NOT NULL DEFAULT "plainText"');
        } catch (e) {
          print('添加contentFormat列错误: $e');
        }
        
        try {
          await db.execute('ALTER TABLE diary_entries ADD COLUMN syncedToWebDav INTEGER NOT NULL DEFAULT 0');
        } catch (e) {
          print('添加syncedToWebDav列错误: $e');
        }
        
        try {
          await db.execute('ALTER TABLE diary_entries ADD COLUMN lastSyncTime TEXT');
        } catch (e) {
          print('添加lastSyncTime列错误: $e');
        }
      }
    }
  }

  // 创建新日记条目
  Future<int> create(DiaryEntry entry) async {
    final db = await instance.database;
    
    final json = entry.toJson();
    
    // 将列表类型转换为字符串存储
    json['tags'] = entry.tags.join(',');
    json['mediaLinks'] = entry.mediaLinks.join(',');
    
    // 确保布尔值转换为整数
    json['isFavorite'] = entry.isFavorite ? 1 : 0;
    json['syncedToWebDav'] = entry.syncedToWebDav ? 1 : 0;
    
    final id = await db.insert('diary_entries', json);
    return id;
  }

  // 读取单个日记条目
  Future<DiaryEntry> readEntry(int id) async {
    final db = await instance.database;
    
    final maps = await db.query(
      'diary_entries',
      columns: ['id', 'title', 'content', 'dateCreated', 'dateModified', 
                'tags', 'mood', 'mediaLinks', 'isFavorite', 'locationName',
                'contentFormat', 'syncedToWebDav', 'lastSyncTime'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _convertToEntry(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  // 读取所有日记条目
  Future<List<DiaryEntry>> readAllEntries() async {
    final db = await instance.database;
    
    const orderBy = 'dateCreated DESC';
    final result = await db.query('diary_entries', orderBy: orderBy);
    
    return result.map((json) => _convertToEntry(json)).toList();
  }

  // 读取特定日期的日记条目
  Future<List<DiaryEntry>> readEntriesByDate(DateTime date) async {
    final db = await instance.database;
    
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final result = await db.query(
      'diary_entries',
      where: 'dateCreated BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'dateCreated DESC',
    );
    
    return result.map((json) => _convertToEntry(json)).toList();
  }

  // 更新日记条目
  Future<int> update(DiaryEntry entry) async {
    final db = await instance.database;
    
    // 先转换为JSON
    final json = entry.toJson();
    
    // 确保所有列表和布尔类型正确转换
    json['tags'] = entry.tags.join(',');
    json['mediaLinks'] = entry.mediaLinks.join(',');
    json['isFavorite'] = entry.isFavorite ? 1 : 0;
    json['syncedToWebDav'] = entry.syncedToWebDav ? 1 : 0;
    
    return db.update(
      'diary_entries',
      json,
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // 删除日记条目
  Future<int> delete(int id) async {
    final db = await instance.database;
    
    return await db.delete(
      'diary_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 将数据库记录转换为DiaryEntry对象
  DiaryEntry _convertToEntry(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      dateCreated: DateTime.parse(map['dateCreated'] as String),
      dateModified: DateTime.parse(map['dateModified'] as String),
      tags: map['tags'] != null && map['tags'].toString().isNotEmpty 
          ? (map['tags'] as String).split(',') 
          : [],
      mood: map['mood'] as int,
      mediaLinks: map['mediaLinks'] != null && map['mediaLinks'].toString().isNotEmpty 
          ? (map['mediaLinks'] as String).split(',') 
          : [],
      isFavorite: map['isFavorite'] == 1,
      locationName: map['locationName'] as String?,
      contentFormat: map['contentFormat'] != null
          ? ContentFormatExtension.fromString(map['contentFormat'] as String)
          : ContentFormat.plainText,
      syncedToWebDav: map['syncedToWebDav'] == 1,
      lastSyncTime: map['lastSyncTime'] != null 
          ? DateTime.parse(map['lastSyncTime'] as String)
          : null,
    );
  }

  // 关闭数据库
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}