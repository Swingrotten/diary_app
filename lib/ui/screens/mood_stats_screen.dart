import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/diary_entry.dart';
import '../../services/diary_provider.dart';

class MoodStatsScreen extends StatefulWidget {
  const MoodStatsScreen({super.key});

  @override
  State<MoodStatsScreen> createState() => _MoodStatsScreenState();
}

class _MoodStatsScreenState extends State<MoodStatsScreen> {
  String _selectedTimeRange = '近7天';
  final List<String> _timeRanges = ['近7天', '近30天', '近90天', '全部'];
  
  // 心情颜色定义
  static const Map<int, Color> moodColors = {
    1: Colors.red,
    2: Colors.orange,
    3: Colors.yellow,
    4: Colors.lightGreen,
    5: Colors.green,
  };
  
  // 心情名称
  static const Map<int, String> moodNames = {
    1: '很糟',
    2: '不佳',
    3: '一般',
    4: '不错',
    5: '很棒',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('心情统计'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<DiaryProvider>(
          builder: (context, diaryProvider, child) {
            // 处理日记数据为可视化格式
            final processedData = _processData(diaryProvider.entries);
            
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 时间范围选择器
                  _buildTimeRangeSelector(),
                  
                  const SizedBox(height: 24),
                  
                  // 心情分布卡片
                  _buildMoodDistributionCard(processedData),
                  
                  const SizedBox(height: 16),
                  
                  // 心情趋势卡片
                  _buildMoodTrendCard(processedData),
                  
                  const SizedBox(height: 16),
                  
                  // 心情日记数量卡片
                  _buildMoodEntriesCountCard(processedData),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  // 构建时间范围选择器
  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 20),
          const SizedBox(width: 8),
          const Text('选择时间范围: '),
          const Spacer(),
          DropdownButton<String>(
            value: _selectedTimeRange,
            icon: const Icon(Icons.arrow_drop_down),
            elevation: 16,
            underline: Container(height: 0),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedTimeRange = newValue;
                });
              }
            },
            items: _timeRanges.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  // 构建心情分布卡片
  Widget _buildMoodDistributionCard(Map<String, dynamic> data) {
    final moodDistribution = data['moodDistribution'] as Map<int, int>;
    final totalEntries = data['totalEntries'] as int;
    
    if (totalEntries == 0) {
      return _buildEmptyCard('心情分布', '暂无数据');
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '心情分布',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: moodDistribution.entries.map((entry) {
                    final percent = entry.value / totalEntries * 100;
                    return PieChartSectionData(
                      color: moodColors[entry.key] ?? Colors.grey,
                      value: entry.value.toDouble(),
                      title: '${percent.toStringAsFixed(1)}%',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: moodDistribution.entries.map((entry) {
                return _buildLegendItem(
                  color: moodColors[entry.key] ?? Colors.grey,
                  label: moodNames[entry.key] ?? '未知',
                  count: entry.value,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建心情趋势卡片
  Widget _buildMoodTrendCard(Map<String, dynamic> data) {
    final moodTrend = data['moodTrend'] as Map<String, double>;
    
    if (moodTrend.isEmpty) {
      return _buildEmptyCard('心情趋势', '暂无数据');
    }
    
    // 获取所有日期，并排序
    final dates = moodTrend.keys.toList()..sort();
    
    // 定义日期格式化方法
    String formatDate(String date) {
      // 日期格式为: yyyy-MM-dd
      final parts = date.split('-');
      return '${parts[1]}-${parts[2]}';
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '心情趋势',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          // 显示1-5的刻度
                          if (value % 1 == 0 && value >= 1 && value <= 5) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          // 显示日期，仅选择几个点避免过于拥挤
                          if (value.toInt() % (dates.length ~/ 5 + 1) == 0 && value.toInt() < dates.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                formatDate(dates[value.toInt()]),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  minX: 0,
                  maxX: (dates.length - 1).toDouble(),
                  minY: 1,
                  maxY: 5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: dates.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          moodTrend[entry.value] ?? 0,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                '选定时间范围内的每日平均心情评分',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建心情日记数量卡片
  Widget _buildMoodEntriesCountCard(Map<String, dynamic> data) {
    final moodDistribution = data['moodDistribution'] as Map<int, int>;
    final totalEntries = data['totalEntries'] as int;
    
    if (totalEntries == 0) {
      return _buildEmptyCard('日记统计', '暂无数据');
    }
    
    final entriesPerDay = data['entriesPerDay'] as double;
    final mostFrequentMood = _getMostFrequentMood(moodDistribution);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '日记统计',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  icon: Icons.note_alt,
                  value: totalEntries.toString(),
                  label: '日记总数',
                ),
                _buildStatCard(
                  icon: Icons.calendar_today,
                  value: entriesPerDay.toStringAsFixed(1),
                  label: '日均数量',
                ),
                _buildStatCard(
                  icon: mostFrequentMood == null 
                      ? Icons.mood 
                      : MoodIcons.getMoodIcon(mostFrequentMood),
                  value: mostFrequentMood == null 
                      ? '-' 
                      : moodNames[mostFrequentMood] ?? '未知',
                  label: '最常心情',
                  color: mostFrequentMood == null 
                      ? Colors.grey 
                      : moodColors[mostFrequentMood],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建空数据卡片
  Widget _buildEmptyCard(String title, String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.sentiment_neutral,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建图表图例项
  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int count,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($count)',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
  
  // 构建统计卡片
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  // 处理日记数据为可视化格式
  Map<String, dynamic> _processData(List<DiaryEntry> entries) {
    // 根据选择的时间范围过滤数据
    final filteredEntries = _filterEntriesByTimeRange(entries);
    
    // 计算心情分布
    final moodDistribution = <int, int>{};
    for (final entry in filteredEntries) {
      moodDistribution[entry.mood] = (moodDistribution[entry.mood] ?? 0) + 1;
    }
    
    // 计算心情趋势（按日期分组，计算每天的平均心情）
    final moodByDate = <String, List<int>>{};
    for (final entry in filteredEntries) {
      final dateStr = DateFormat('yyyy-MM-dd').format(entry.dateCreated);
      if (!moodByDate.containsKey(dateStr)) {
        moodByDate[dateStr] = [];
      }
      moodByDate[dateStr]!.add(entry.mood);
    }
    
    // 计算每天平均心情
    final moodTrend = <String, double>{};
    moodByDate.forEach((date, moods) {
      final sum = moods.reduce((a, b) => a + b);
      moodTrend[date] = sum / moods.length;
    });
    
    // 计算日均日记数量
    double entriesPerDay = 0;
    if (filteredEntries.isNotEmpty) {
      // 找出最早和最晚的日期
      DateTime? earliest;
      DateTime? latest;
      
      for (final entry in filteredEntries) {
        if (earliest == null || entry.dateCreated.isBefore(earliest)) {
          earliest = entry.dateCreated;
        }
        if (latest == null || entry.dateCreated.isAfter(latest)) {
          latest = entry.dateCreated;
        }
      }
      
      if (earliest != null && latest != null) {
        // 计算相差的天数
        final difference = latest.difference(earliest).inDays + 1;
        entriesPerDay = filteredEntries.length / difference;
      }
    }
    
    return {
      'totalEntries': filteredEntries.length,
      'moodDistribution': moodDistribution,
      'moodTrend': moodTrend,
      'entriesPerDay': entriesPerDay,
    };
  }
  
  // 根据选择的时间范围过滤日记
  List<DiaryEntry> _filterEntriesByTimeRange(List<DiaryEntry> entries) {
    if (entries.isEmpty) return [];
    
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedTimeRange) {
      case '近7天':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '近30天':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '近90天':
        startDate = now.subtract(const Duration(days: 90));
        break;
      case '全部':
      default:
        return entries;
    }
    
    return entries.where((entry) => entry.dateCreated.isAfter(startDate)).toList();
  }
  
  // 获取最常见的心情
  int? _getMostFrequentMood(Map<int, int> moodDistribution) {
    if (moodDistribution.isEmpty) return null;
    
    int? mostFrequentMood;
    int maxCount = 0;
    
    moodDistribution.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequentMood = mood;
      }
    });
    
    return mostFrequentMood;
  }
}