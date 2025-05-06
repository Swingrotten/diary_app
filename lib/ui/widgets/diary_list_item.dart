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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                  Row(
                    children: [
                      Icon(
                        MoodIcons.getMoodIcon(entry.mood),
                        color: MoodIcons.getMoodColor(entry.mood),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: entry.isFavorite ? Colors.red : null,
                        ),
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
              const SizedBox(height: 8),
              Text(
                contentPreview,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // 显示图片预览（如果有）
              if (entry.mediaLinks.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 图片数量提示
                    Row(
                      children: [
                        const Icon(Icons.photo, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.mediaLinks.length}张图片',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                              border: Border.all(color: Colors.grey.shade300),
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
                    const SizedBox(height: 8),
                  ],
                ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 显示创建时间
                  Text(
                    timeString,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  // 显示标签
                  if (entry.tags.isNotEmpty)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: entry.tags.map((tag) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: Chip(
                                label: Text(
                                  tag,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
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
    );
  }
}