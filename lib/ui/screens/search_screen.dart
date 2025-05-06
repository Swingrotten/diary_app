import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/diary_entry.dart';
import '../../services/diary_provider.dart';
import '../widgets/diary_list_item.dart';
import 'diary_edit_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DiaryEntry> _searchResults = [];
  String _activeTab = "关键词"; // 当前激活的搜索类型
  int? _selectedMood; // 选中的心情
  String? _selectedTag; // 选中的标签

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_activeTab == "关键词") {
        _searchByKeyword();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchByKeyword() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    setState(() {
      _searchResults = diaryProvider.searchByKeyword(keyword);
    });
  }

  void _searchByTag(String tag) {
    setState(() {
      _selectedTag = tag;
      final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
      _searchResults = diaryProvider.searchByTag(tag);
    });
  }

  void _searchByMood(int mood) {
    setState(() {
      _selectedMood = mood;
      final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
      _searchResults = diaryProvider.filterByMood(mood);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索日记'),
      ),
      body: Column(
        children: [
          // 搜索类型切换
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: ["关键词", "标签", "心情"].map((tab) {
                final isActive = _activeTab == tab;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _activeTab = tab;
                          // 切换到关键词搜索时，如果有文本则立即搜索
                          if (tab == "关键词" && _searchController.text.isNotEmpty) {
                            _searchByKeyword();
                          } else {
                            // 切换到其他标签时清空结果
                            _searchResults = [];
                            _selectedTag = null;
                            _selectedMood = null;
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? Theme.of(context).primaryColor : Colors.grey.shade200,
                        foregroundColor: isActive ? Colors.white : Colors.black,
                      ),
                      child: Text(tab),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 搜索框或选择区域
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSearchInput(),
          ),
          
          // 搜索结果
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _getEmptyMessage(),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      return DiaryListItem(
                        entry: _searchResults[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DiaryEditScreen(
                                entry: _searchResults[index],
                              ),
                            ),
                          ).then((_) {
                            // 返回时重新搜索以更新结果
                            if (_activeTab == "关键词") {
                              _searchByKeyword();
                            } else if (_activeTab == "标签" && _selectedTag != null) {
                              _searchByTag(_selectedTag!);
                            } else if (_activeTab == "心情" && _selectedMood != null) {
                              _searchByMood(_selectedMood!);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 获取空搜索结果的提示信息
  String _getEmptyMessage() {
    if (_activeTab == "关键词") {
      return _searchController.text.isEmpty
          ? "输入关键词开始搜索"
          : "没有找到包含 \"${_searchController.text}\" 的日记";
    } else if (_activeTab == "标签") {
      return _selectedTag == null ? "请选择一个标签" : "没有使用标签 \"$_selectedTag\" 的日记";
    } else {
      return _selectedMood == null ? "请选择一种心情" : "没有对应心情的日记";
    }
  }

  // 根据当前激活的标签构建不同的搜索输入界面
  Widget _buildSearchInput() {
    switch (_activeTab) {
      case "关键词":
        return TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '搜索标题或内容...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      case "标签":
        return _buildTagSelector();
      case "心情":
        return _buildMoodSelector();
      default:
        return const SizedBox.shrink();
    }
  }

  // 构建标签选择器
  Widget _buildTagSelector() {
    final diaryProvider = Provider.of<DiaryProvider>(context);
    // 获取所有日记中使用的标签
    final allTags = <String>{};
    for (final entry in diaryProvider.entries) {
      allTags.addAll(entry.tags);
    }

    return Container(
      height: 50,
      child: allTags.isEmpty
          ? const Center(child: Text('没有可用的标签'))
          : ListView(
              scrollDirection: Axis.horizontal,
              children: allTags.map((tag) {
                final isSelected = tag == _selectedTag;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _searchByTag(tag);
                      } else {
                        setState(() {
                          _selectedTag = null;
                          _searchResults = [];
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
    );
  }

  // 构建心情选择器
  Widget _buildMoodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(5, (index) {
        final mood = index + 1;
        final isSelected = mood == _selectedMood;
        return GestureDetector(
          onTap: () {
            if (isSelected) {
              setState(() {
                _selectedMood = null;
                _searchResults = [];
              });
            } else {
              _searchByMood(mood);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: MoodIcons.getMoodColor(mood),
                      width: 2,
                    )
                  : null,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              MoodIcons.getMoodIcon(mood),
              color: MoodIcons.getMoodColor(mood),
              size: 36,
            ),
          ),
        );
      }),
    );
  }
} 