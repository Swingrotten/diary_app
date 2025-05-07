import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/diary_provider.dart';
import '../../models/diary_entry.dart';
import '../widgets/diary_list_item.dart';
import 'diary_edit_screen.dart';

class TagManagerScreen extends StatefulWidget {
  const TagManagerScreen({super.key});

  @override
  State<TagManagerScreen> createState() => _TagManagerScreenState();
}

class _TagManagerScreenState extends State<TagManagerScreen> {
  final _newTagController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  
  // 编辑状态
  bool _isEditing = false;
  String? _editingTag;
  final _editingController = TextEditingController();
  
  @override
  void dispose() {
    _newTagController.dispose();
    _searchController.dispose();
    _editingController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('标签管理'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.done : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                // 退出编辑模式时清除状态
                if (!_isEditing) {
                  _editingTag = null;
                  _editingController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索标签...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // 添加新标签
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTagController,
                    decoration: InputDecoration(
                      hintText: '添加新标签...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: _addNewTag,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text('添加'),
                ),
              ],
            ),
          ),
          
          // 统计信息
          _buildTagStatistics(),
          
          // 标签列表
          Expanded(
            child: Consumer<DiaryProvider>(
              builder: (context, diaryProvider, child) {
                // 获取所有标签及其使用计数
                final tagStats = _getTagStatistics(diaryProvider);
                // 过滤标签
                final filteredTags = tagStats.entries
                    .where((entry) => entry.key.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();
                
                return filteredTags.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? '暂无标签，请添加一个标签'
                              : '没有找到匹配的标签',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredTags.length,
                        itemBuilder: (context, index) {
                          final tag = filteredTags[index].key;
                          final count = filteredTags[index].value;
                          
                          // 如果正在编辑此标签，显示编辑界面
                          if (_isEditing && _editingTag == tag) {
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _editingController,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                          hintText: '编辑标签名称',
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.check),
                                      onPressed: () => _updateTag(tag),
                                      color: Colors.green,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel),
                                      onPressed: () {
                                        setState(() {
                                          _editingTag = null;
                                          _editingController.clear();
                                        });
                                      },
                                      color: Colors.orange,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          // 正常显示标签
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: ListTile(
                              title: Text(tag),
                              subtitle: Text('使用次数: $count'),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(
                                  tag.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              trailing: _isEditing
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _startEditingTag(tag),
                                          color: Colors.blue,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => _confirmDeleteTag(tag),
                                          color: Colors.red,
                                        ),
                                      ],
                                    )
                                  : null,
                              onTap: () {
                                if (!_isEditing) {
                                  // 显示拥有此标签的日记列表
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TaggedEntriesScreen(tag: tag),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建标签统计信息
  Widget _buildTagStatistics() {
    return Consumer<DiaryProvider>(
      builder: (context, diaryProvider, child) {
        final tagStats = _getTagStatistics(diaryProvider);
        final uniqueTagsCount = tagStats.length;
        
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                context: context,
                icon: Icons.tag,
                title: '标签数量',
                value: uniqueTagsCount.toString(),
              ),
              _buildStatCard(
                context: context,
                icon: Icons.note,
                title: '带标签的日记',
                value: _countEntriesWithTags(diaryProvider).toString(),
              ),
              _buildStatCard(
                context: context,
                icon: Icons.star,
                title: '最常用标签',
                value: _getMostUsedTag(tagStats),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 构建统计卡片
  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4.0),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2.0),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  // 获取标签使用统计
  Map<String, int> _getTagStatistics(DiaryProvider provider) {
    final stats = <String, int>{};
    
    for (final entry in provider.entries) {
      for (final tag in entry.tags) {
        stats[tag] = (stats[tag] ?? 0) + 1;
      }
    }
    
    return stats;
  }
  
  // 计算有标签的日记数量
  int _countEntriesWithTags(DiaryProvider provider) {
    return provider.entries.where((entry) => entry.tags.isNotEmpty).length;
  }
  
  // 获取最常用的标签
  String _getMostUsedTag(Map<String, int> tagStats) {
    if (tagStats.isEmpty) return '-';
    
    String mostUsedTag = '';
    int maxCount = 0;
    
    tagStats.forEach((tag, count) {
      if (count > maxCount) {
        maxCount = count;
        mostUsedTag = tag;
      }
    });
    
    return mostUsedTag;
  }
  
  // 添加新标签
  void _addNewTag() {
    final tag = _newTagController.text.trim();
    if (tag.isEmpty) return;
    
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    final existingTags = _getTagStatistics(diaryProvider).keys.toList();
    
    if (existingTags.contains(tag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('标签"$tag"已存在')),
      );
      return;
    }
    
    // 添加新标签到示例日记
    if (diaryProvider.entries.isNotEmpty) {
      final targetEntry = diaryProvider.entries.first;
      final updatedTags = List<String>.from(targetEntry.tags)..add(tag);
      
      final updatedEntry = targetEntry.copy(
        tags: updatedTags,
        dateModified: DateTime.now(),
      );
      
      diaryProvider.updateDiaryEntry(updatedEntry);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加标签"$tag"')),
      );
      
      _newTagController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无日记，请先创建一个日记再添加标签')),
      );
    }
  }
  
  // 开始编辑标签
  void _startEditingTag(String tag) {
    setState(() {
      _editingTag = tag;
      _editingController.text = tag;
    });
  }
  
  // 更新标签
  void _updateTag(String oldTag) async {
    final newTag = _editingController.text.trim();
    if (newTag.isEmpty || newTag == oldTag) {
      setState(() {
        _editingTag = null;
        _editingController.clear();
      });
      return;
    }
    
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    final existingTags = _getTagStatistics(diaryProvider).keys.toList();
    
    if (existingTags.contains(newTag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('标签"$newTag"已存在')),
      );
      return;
    }
    
    // 更新所有使用此标签的日记
    int updatedCount = 0;
    
    for (final entry in diaryProvider.entries) {
      if (entry.tags.contains(oldTag)) {
        final updatedTags = List<String>.from(entry.tags);
        updatedTags.remove(oldTag);
        updatedTags.add(newTag);
        
        final updatedEntry = entry.copy(
          tags: updatedTags,
          dateModified: DateTime.now(),
        );
        
        await diaryProvider.updateDiaryEntry(updatedEntry);
        updatedCount++;
      }
    }
    
    setState(() {
      _editingTag = null;
      _editingController.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已将"$oldTag"更新为"$newTag"，影响了$updatedCount篇日记')),
    );
  }
  
  // 确认删除标签
  void _confirmDeleteTag(String tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除标签'),
        content: Text('确定要删除标签"$tag"吗？此操作将从所有日记中移除此标签。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTag(tag);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  
  // 删除标签
  void _deleteTag(String tag) async {
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    int deletedCount = 0;
    
    for (final entry in diaryProvider.entries) {
      if (entry.tags.contains(tag)) {
        final updatedTags = List<String>.from(entry.tags)..remove(tag);
        
        final updatedEntry = entry.copy(
          tags: updatedTags,
          dateModified: DateTime.now(),
        );
        
        await diaryProvider.updateDiaryEntry(updatedEntry);
        deletedCount++;
      }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已从$deletedCount篇日记中删除标签"$tag"')),
    );
  }
}

// 显示带特定标签的日记列表
class TaggedEntriesScreen extends StatelessWidget {
  final String tag;
  
  const TaggedEntriesScreen({
    super.key,
    required this.tag,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('标签: $tag'),
      ),
      body: Consumer<DiaryProvider>(
        builder: (context, diaryProvider, child) {
          final taggedEntries = diaryProvider.entries
              .where((entry) => entry.tags.contains(tag))
              .toList();
          
          return taggedEntries.isEmpty
              ? Center(
                  child: Text(
                    '没有找到带此标签的日记',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  itemCount: taggedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = taggedEntries[index];
                    return DiaryListItem(
                      entry: entry,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiaryEditScreen(
                              entry: entry,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
        },
      ),
    );
  }
} 