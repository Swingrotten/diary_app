import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// import 'dart:convert';
// import 'package:flutter_quill/flutter_quill.dart' hide Text;
import '../../models/diary_entry.dart';
import '../../services/diary_provider.dart';

class DiaryListItem extends StatelessWidget {
  final DiaryEntry entry;
  final Function() onTap;

  const DiaryListItem({
    super.key,
    required this.entry,
    required this.onTap,
  });

  // 处理内容预览
  String _getContentPreview(String content) {
    // 简化处理，直接使用原始文本
    final contentPreview = content.length > 100
        ? '${content.substring(0, 100)}...'
        : content;
    return contentPreview;
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final timeString = timeFormat.format(entry.dateCreated);
    
    // 获取内容预览
    final contentPreview = _getContentPreview(entry.content);
    
    // 判断内容格式，显示对应的图标
    final formatIcon = entry.contentFormat == ContentFormat.markdown 
        ? Icons.article_outlined 
        : Icons.text_fields;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // 格式图标
                          Icon(formatIcon, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          // 标题
                          Expanded(
                            child: Text(
                              entry.title.isNotEmpty ? entry.title : '无标题',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 心情和收藏图标
                    Row(
                      children: [
                        Icon(
                          MoodIcons.getMoodIcon(entry.mood),
                          color: MoodIcons.getMoodColor(entry.mood),
                          size: 22,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: entry.isFavorite ? Colors.red : Colors.grey.shade400,
                            size: 22,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            // 切换收藏状态
                            final diaryProvider =
                                Provider.of<DiaryProvider>(context, listen: false);
                            diaryProvider.toggleFavorite(entry.id!);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                
                // 分隔线
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(color: Colors.grey.shade200, height: 1),
                ),
                
                // 内容预览
                Text(
                  contentPreview,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // 显示图片预览（如果有）
                if (entry.mediaLinks.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 图片缩略图
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: entry.mediaLinks.length > 3 ? 3 : entry.mediaLinks.length,
                          itemBuilder: (context, index) {
                            final showMoreIndicator = entry.mediaLinks.length > 3 && index == 2;
                            
                            return Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // 图片
                                    Image.file(
                                      File(entry.mediaLinks[index]),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                    // "更多"指示器
                                    if (showMoreIndicator)
                                      Container(
                                        color: Colors.black.withOpacity(0.5),
                                        child: Center(
                                          child: Text(
                                            '+${entry.mediaLinks.length - 2}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                
                // 底部信息栏
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 显示创建时间
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          timeString,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        
                        // 添加同步状态指示
                        if (entry.syncedToWebDav)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(
                              Icons.cloud_done, 
                              size: 14, 
                              color: Colors.green.shade400,
                            ),
                          ),
                      ],
                    ),
                    
                    // 显示标签
                    if (entry.tags.isNotEmpty)
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: entry.tags.map((tag) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue.shade100),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}