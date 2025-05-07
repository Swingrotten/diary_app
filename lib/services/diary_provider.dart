import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import 'diary_database.dart';
import 'webdav_service.dart';

class DiaryProvider with ChangeNotifier {
  List<DiaryEntry> _entries = [];
  bool _isLoading = false;
  String? _error;
  final WebDavService _webDavService = WebDavService();

  // 获取所有日记条目
  List<DiaryEntry> get entries => _entries;
  
  // 获取收藏的日记条目
  List<DiaryEntry> get favoriteEntries => 
      _entries.where((entry) => entry.isFavorite).toList();
  
  // 加载状态
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 按日期分组的日记条目
  Map<DateTime, List<DiaryEntry>> get entriesByDate {
    final Map<DateTime, List<DiaryEntry>> result = {};
    
    for (final entry in _entries) {
      final date = DateTime(
        entry.dateCreated.year,
        entry.dateCreated.month,
        entry.dateCreated.day,
      );
      
      if (result.containsKey(date)) {
        result[date]!.add(entry);
      } else {
        result[date] = [entry];
      }
    }
    
    // 对每一天的日记按时间排序
    result.forEach((date, entriesForDate) {
      entriesForDate.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
    });
    
    return result;
  }

  // 加载所有日记
  Future<void> loadEntries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final loadedEntries = await DiaryDatabase.instance.readAllEntries();
      _entries = loadedEntries;
    } catch (e) {
      _error = '加载日记失败: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 加载特定日期的日记
  Future<void> loadEntriesByDate(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final loadedEntries = await DiaryDatabase.instance.readEntriesByDate(date);
      // 这里我们不替换所有条目，而是更新该日期的条目
      final otherEntries = _entries.where((entry) {
        final entryDate = DateTime(
          entry.dateCreated.year,
          entry.dateCreated.month,
          entry.dateCreated.day,
        );
        final targetDate = DateTime(date.year, date.month, date.day);
        return entryDate != targetDate;
      }).toList();
      
      _entries = [...otherEntries, ...loadedEntries];
    } catch (e) {
      _error = '加载日记失败: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 添加日记条目并支持自动同步
  Future<int> addDiaryEntry(DiaryEntry entry) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // 先保存到本地数据库
      final id = await DiaryDatabase.instance.create(entry);
      
      // 使用新ID更新条目，以便后续使用
      final updatedEntry = entry.copy(id: id);
      
      // 在UI线程之外执行WebDAV同步，避免阻塞UI
      if (_webDavService.isEnabled && _webDavService.syncOnChange) {
        // 使用Future.microtask确保不会阻塞UI线程，而且不关心结果
        Future.microtask(() async {
          try {
            await _webDavService.syncDiaryEntry(updatedEntry);
          } catch (e) {
            debugPrint('WebDAV同步失败(但不影响本地保存): $e');
          }
        });
      }
      
      // 刷新列表
      await loadEntries();
      return id;
    } catch (e) {
      _error = '添加日记失败: $e';
      debugPrint(_error);
      return -1; // 失败时返回-1
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 更新日记条目并支持自动同步
  Future<bool> updateDiaryEntry(DiaryEntry entry) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // 先更新本地数据库
      final result = await DiaryDatabase.instance.update(entry);
      final success = result > 0;
      
      // 在UI线程之外执行WebDAV同步，避免阻塞UI
      if (success && _webDavService.isEnabled && _webDavService.syncOnChange) {
        // 使用Future.microtask确保不会阻塞UI线程，而且不关心结果
        Future.microtask(() async {
          try {
            await _webDavService.syncDiaryEntry(entry);
          } catch (e) {
            debugPrint('WebDAV同步失败(但不影响本地保存): $e');
          }
        });
      }
      
      // 刷新列表
      await loadEntries();
      return success;
    } catch (e) {
      _error = '更新日记失败: $e';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 删除日记条目
  Future<bool> deleteDiaryEntry(int id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await DiaryDatabase.instance.delete(id);
      final success = result > 0;
      await loadEntries(); // 刷新列表
      return success;
    } catch (e) {
      _error = '删除日记失败: $e';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 切换收藏状态
  Future<void> toggleFavorite(int id) async {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index >= 0) {
      final entry = _entries[index];
      final updatedEntry = entry.copy(isFavorite: !entry.isFavorite);
      
      await updateDiaryEntry(updatedEntry);
    }
  }

  // 按标签搜索日记
  List<DiaryEntry> searchByTag(String tag) {
    return _entries.where((entry) => entry.tags.contains(tag)).toList();
  }

  // 按关键字搜索日记
  List<DiaryEntry> searchByKeyword(String keyword) {
    final lowercaseKeyword = keyword.toLowerCase();
    return _entries.where((entry) {
      return entry.title.toLowerCase().contains(lowercaseKeyword) ||
          entry.content.toLowerCase().contains(lowercaseKeyword);
    }).toList();
  }
  
  // 按心情筛选日记
  List<DiaryEntry> filterByMood(int mood) {
    return _entries.where((entry) => entry.mood == mood).toList();
  }
  
  // 获取指定日期范围内的日记
  List<DiaryEntry> getEntriesByDateRange(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    
    return _entries.where((entry) {
      return entry.dateCreated.isAfter(start) && 
             entry.dateCreated.isBefore(end);
    }).toList();
  }
  
  // 获取最近的n篇日记
  List<DiaryEntry> getRecentEntries(int count) {
    final sortedEntries = List<DiaryEntry>.from(_entries)
      ..sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
    
    return sortedEntries.take(count).toList();
  }
}