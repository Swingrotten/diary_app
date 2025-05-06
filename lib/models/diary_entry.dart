import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// 内容格式类型枚举
enum ContentFormat {
  plainText,  // 普通文本
  markdown,   // Markdown格式
  richText    // 富文本格式
}

// 将枚举转换为字符串和从字符串转换回枚举的扩展方法
extension ContentFormatExtension on ContentFormat {
  String toShortString() {
    return toString().split('.').last;
  }
  
  static ContentFormat fromString(String formatStr) {
    return ContentFormat.values.firstWhere(
      (e) => e.toShortString() == formatStr,
      orElse: () => ContentFormat.plainText,
    );
  }
}

// 日记条目数据模型
class DiaryEntry {
  int? id; // 数据库ID，新创建时可能为null
  String title; // 标题
  String content; // 内容
  DateTime dateCreated; // 创建日期
  DateTime dateModified; // 修改日期
  List<String> tags; // 标签列表
  int mood; // 心情指数 (1-5)
  List<String> mediaLinks; // 媒体文件链接
  bool isFavorite; // 是否收藏
  String? locationName; // 位置名称
  ContentFormat contentFormat; // 内容格式类型
  bool syncedToWebDav; // 是否已同步到WebDAV
  DateTime? lastSyncTime; // 最后同步时间

  DiaryEntry({
    this.id,
    required this.title,
    required this.content,
    required this.dateCreated,
    required this.dateModified,
    this.tags = const [],
    this.mood = 3,
    this.mediaLinks = const [],
    this.isFavorite = false,
    this.locationName,
    this.contentFormat = ContentFormat.plainText,
    this.syncedToWebDav = false,
    this.lastSyncTime,
  });

  // 从JSON创建实例
  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      dateCreated: DateTime.parse(json['dateCreated']),
      dateModified: DateTime.parse(json['dateModified']),
      tags: List<String>.from(json['tags'] ?? []),
      mood: json['mood'] ?? 3,
      mediaLinks: List<String>.from(json['mediaLinks'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
      locationName: json['locationName'],
      contentFormat: json['contentFormat'] != null 
          ? ContentFormatExtension.fromString(json['contentFormat'])
          : ContentFormat.plainText,
      syncedToWebDav: json['syncedToWebDav'] ?? false,
      lastSyncTime: json['lastSyncTime'] != null 
          ? DateTime.parse(json['lastSyncTime'])
          : null,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'dateCreated': dateCreated.toIso8601String(),
      'dateModified': dateModified.toIso8601String(),
      'tags': tags,
      'mood': mood,
      'mediaLinks': mediaLinks,
      'isFavorite': isFavorite ? 1 : 0,
      'locationName': locationName,
      'contentFormat': contentFormat.toShortString(),
      'syncedToWebDav': syncedToWebDav ? 1 : 0,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
    };
  }

  // 创建副本
  DiaryEntry copy({
    int? id,
    String? title,
    String? content,
    DateTime? dateCreated,
    DateTime? dateModified,
    List<String>? tags,
    int? mood,
    List<String>? mediaLinks,
    bool? isFavorite,
    String? locationName,
    ContentFormat? contentFormat,
    bool? syncedToWebDav,
    DateTime? lastSyncTime,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      tags: tags ?? List.from(this.tags),
      mood: mood ?? this.mood,
      mediaLinks: mediaLinks ?? List.from(this.mediaLinks),
      isFavorite: isFavorite ?? this.isFavorite,
      locationName: locationName ?? this.locationName,
      contentFormat: contentFormat ?? this.contentFormat,
      syncedToWebDav: syncedToWebDav ?? this.syncedToWebDav,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

// 心情类型，用于表示不同的心情
class MoodIcons {
  static const List<IconData> moodIconList = [
    Icons.sentiment_very_dissatisfied,
    Icons.sentiment_dissatisfied,
    Icons.sentiment_neutral,
    Icons.sentiment_satisfied,
    Icons.sentiment_very_satisfied,
  ];

  static IconData getMoodIcon(int mood) {
    // 确保mood在有效范围内(1-5)
    final index = (mood.clamp(1, 5) - 1);
    return moodIconList[index];
  }
  
  static Color getMoodColor(int mood) {
    switch (mood) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.yellow;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }
}