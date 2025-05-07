import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../services/diary_provider.dart';
import '../../models/diary_entry.dart';
import 'diary_edit_screen.dart';
import 'search_screen.dart';
import 'webdav_config_screen.dart';
import 'webdav_media_screen.dart';
import 'settings_screen.dart';
import 'tag_manager_screen.dart';
import 'mood_stats_screen.dart';
import '../widgets/diary_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 加载日记数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
      diaryProvider.loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的日记'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsMenu,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '日历',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '列表',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: '收藏',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewEntry,
        child: const Icon(Icons.add),
      ),
    );
  }

  // 显示设置菜单
  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('应用设置'),
              subtitle: const Text('主题、安全和数据管理'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.tag),
              title: const Text('标签管理'),
              subtitle: const Text('查看和编辑所有标签'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TagManagerScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('心情统计'),
              subtitle: const Text('查看情绪分析和统计图表'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MoodStatsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_sync),
              title: const Text('WebDAV同步设置'),
              subtitle: const Text('配置云同步服务'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WebDavConfigScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('WebDAV媒体管理'),
              subtitle: const Text('管理已上传的图片'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WebDavMediaScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('关于'),
              subtitle: const Text('应用信息和版本'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: '每日心情',
                  applicationVersion: 'v0.1.0',
                  applicationIcon: const Icon(Icons.book, size: 48),
                  children: const [
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text('一款简单易用的跨平台日记应用，帮助您记录每一天的心情与点滴。'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildCalendarView();
      case 1:
        return _buildListView();
      case 2:
        return _buildFavoritesView();
      default:
        return _buildCalendarView();
    }
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        // 日历组件
        TableCalendar(
          firstDay: DateTime.utc(2010, 10, 16),
          lastDay: DateTime.utc(2030, 3, 14),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            // 加载选定日期的日记
            final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
            diaryProvider.loadEntriesByDate(_selectedDay);
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        const Divider(),
        // 当天的日记列表
        Expanded(
          child: _buildEntriesForSelectedDate(),
        ),
      ],
    );
  }

  Widget _buildEntriesForSelectedDate() {
    final diaryProvider = Provider.of<DiaryProvider>(context);
    final formatter = DateFormat('yyyy年MM月dd日');
    final formattedDate = formatter.format(_selectedDay);
    
    // 筛选选中日期的日记
    final entries = diaryProvider.entries.where((entry) {
      final entryDate = DateTime(
        entry.dateCreated.year,
        entry.dateCreated.month,
        entry.dateCreated.day,
      );
      return entryDate == DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
      );
    }).toList();

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$formattedDate 没有日记', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('写日记'),
              onPressed: () => _createNewEntry(date: _selectedDay),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return DiaryListItem(
          entry: entries[index],
          onTap: () => _editEntry(entries[index]),
        );
      },
    );
  }

  Widget _buildListView() {
    final diaryProvider = Provider.of<DiaryProvider>(context);
    final entries = diaryProvider.entries;

    if (entries.isEmpty) {
      return const Center(
        child: Text('没有日记记录'),
      );
    }

    // 按日期分组显示
    final entriesByDate = diaryProvider.entriesByDate;
    final dates = entriesByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final entriesForDate = entriesByDate[date]!;
        final formatter = DateFormat('yyyy年MM月dd日');
        final formattedDate = formatter.format(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                formattedDate,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...entriesForDate.map((entry) => DiaryListItem(
                  entry: entry,
                  onTap: () => _editEntry(entry),
                )),
            const Divider(),
          ],
        );
      },
    );
  }

  Widget _buildFavoritesView() {
    final diaryProvider = Provider.of<DiaryProvider>(context);
    final favoriteEntries = diaryProvider.favoriteEntries;

    if (favoriteEntries.isEmpty) {
      return const Center(
        child: Text('没有收藏的日记'),
      );
    }

    return ListView.builder(
      itemCount: favoriteEntries.length,
      itemBuilder: (context, index) {
        return DiaryListItem(
          entry: favoriteEntries[index],
          onTap: () => _editEntry(favoriteEntries[index]),
        );
      },
    );
  }

  void _createNewEntry({DateTime? date}) {
    final now = DateTime.now();
    date ??= now;
    
    // 弹出格式选择对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择日记格式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('纯文本'),
              subtitle: const Text('普通文本，无格式'),
              leading: const Icon(Icons.text_fields),
              onTap: () {
                Navigator.of(context).pop();
                _createEntryWithFormat(date!, ContentFormat.plainText);
              },
            ),
            ListTile(
              title: const Text('Markdown'),
              subtitle: const Text('支持标题、加粗、列表等格式'),
              leading: const Icon(Icons.article),
              onTap: () {
                Navigator.of(context).pop();
                _createEntryWithFormat(date!, ContentFormat.markdown);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // 以指定格式创建日记
  void _createEntryWithFormat(DateTime date, ContentFormat format) {
    final now = DateTime.now();
    
    final newEntry = DiaryEntry(
      title: '',
      content: '',
      dateCreated: DateTime(date.year, date.month, date.day, now.hour, now.minute),
      dateModified: DateTime(date.year, date.month, date.day, now.hour, now.minute),
      contentFormat: format, // 设置内容格式
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditScreen(entry: newEntry, isNewEntry: true),
      ),
    );
  }

  void _editEntry(DiaryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditScreen(entry: entry),
      ),
    );
  }
}