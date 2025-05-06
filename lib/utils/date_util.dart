import 'package:intl/intl.dart';

class DateUtil {
  // 获取今天的日期（不含时间）
  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  
  // 获取昨天的日期
  static DateTime get yesterday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - 1);
  }
  
  // 获取明天的日期
  static DateTime get tomorrow {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }
  
  // 获取本周的第一天（周一）
  static DateTime getFirstDayOfWeek() {
    final now = DateTime.now();
    final day = now.weekday;
    return DateTime(now.year, now.month, now.day - day + 1);
  }
  
  // 获取当月的第一天
  static DateTime getFirstDayOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }
  
  // 格式化日期为易读格式
  static String formatDate(DateTime date, {bool includeYear = true}) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == DateTime(now.year, now.month, now.day)) {
      return '今天';
    } else if (targetDate == yesterday) {
      return '昨天';
    } else if (targetDate == tomorrow) {
      return '明天';
    }
    
    if (includeYear && targetDate.year != now.year) {
      return DateFormat('yyyy年MM月dd日').format(date);
    }
    
    return DateFormat('MM月dd日').format(date);
  }
  
  // 格式化时间 HH:mm 格式
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
  
  // 格式化日期和时间
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy年MM月dd日 HH:mm').format(dateTime);
  }
  
  // 计算两个日期相差的天数
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
  
  // 获取一年中的第几周
  static int getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDayOfYear).inDays;
    int weekOfYear = ((dayOfYear + firstDayOfYear.weekday - 1) / 7).ceil();
    return weekOfYear;
  }
  
  // 获取"往年今日"日期列表
  static List<DateTime> getThisDayInPreviousYears({int years = 5}) {
    final now = DateTime.now();
    final List<DateTime> dates = [];
    
    for (int i = 1; i <= years; i++) {
      // 检查是否为闰年2月29日的特殊情况
      if (now.month == 2 && now.day == 29) {
        final year = now.year - i;
        if (DateTime(year, 2, 29).month == 2) { // 是闰年
          dates.add(DateTime(year, 2, 29));
        } else {
          dates.add(DateTime(year, 2, 28)); // 非闰年取2月28日
        }
      } else {
        dates.add(DateTime(now.year - i, now.month, now.day));
      }
    }
    
    return dates;
  }
}