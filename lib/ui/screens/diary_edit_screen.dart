import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
// import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../models/diary_entry.dart';
import '../../services/diary_provider.dart';
import '../../services/media_service.dart';
import '../../services/webdav_service.dart';
import '../../services/diary_database.dart';
import '../widgets/image_attachment.dart';

class DiaryEditScreen extends StatefulWidget {
  final DiaryEntry entry;
  final bool isNewEntry;

  const DiaryEditScreen({
    super.key,
    required this.entry,
    this.isNewEntry = false,
  });

  @override
  State<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends State<DiaryEditScreen> {
  // late QuillController _controller;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late int _selectedMood;
  late List<String> _tags;
  late bool _isFavorite;
  late List<String> _mediaLinks;
  bool _isDirty = false; // 标记是否有未保存的修改
  late ContentFormat _contentFormat; // 内容格式
  bool _isPreviewMode = false; // 是否处于预览模式
  final WebDavService _webDavService = WebDavService();

  @override
  void initState() {
    super.initState();
    // 初始化WebDAV服务
    _webDavService.initialize();
    // 获取内容格式
    _contentFormat = widget.entry.contentFormat;
    
    // 初始化编辑器 - 暂时使用普通TextField
    _contentController = TextEditingController();
    if (widget.entry.content.isNotEmpty) {
      try {
        // 尝试从JSON中提取纯文本
        final contentJson = jsonDecode(widget.entry.content);
        // 这里简化处理，先直接保存JSON字符串
        _contentController.text = widget.entry.content;
      } catch (e) {
        // 如果解析失败，直接使用原始内容
        _contentController.text = widget.entry.content;
      }
    }
    _contentController.addListener(_onTextChanged);
    
    _titleController = TextEditingController(text: widget.entry.title);
    _titleController.addListener(_onTitleChanged);
    
    _selectedMood = widget.entry.mood;
    _tags = List.from(widget.entry.tags);
    _isFavorite = widget.entry.isFavorite;
    _mediaLinks = List.from(widget.entry.mediaLinks);
  }

  void _onTextChanged() {
    setState(() {
      _isDirty = true;
    });
  }

  void _onTitleChanged() {
    setState(() {
      _isDirty = true;
    });
  }

  @override
  void dispose() {
    // _controller.dispose();
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNewEntry ? '新日记' : '编辑日记'),
        actions: [
          // 格式选择
          IconButton(
            icon: _getFormatIcon(),
            onPressed: _showFormatSelectionDialog,
            tooltip: '选择内容格式',
          ),
          // 预览开关 (仅支持Markdown模式)
          if (_contentFormat == ContentFormat.markdown)
            IconButton(
              icon: Icon(
                _isPreviewMode ? Icons.edit : Icons.remove_red_eye,
              ),
              onPressed: () {
                setState(() {
                  _isPreviewMode = !_isPreviewMode;
                });
              },
              tooltip: _isPreviewMode ? '编辑模式' : '预览模式',
            ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.tag),
            onPressed: _showTagsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // 获取格式图标
  Widget _getFormatIcon() {
    switch (_contentFormat) {
      case ContentFormat.plainText:
        return const Icon(Icons.text_fields);
      case ContentFormat.markdown:
        return const Icon(Icons.article);
      case ContentFormat.richText:
        return const Icon(Icons.format_bold);
      default:
        return const Icon(Icons.text_fields);
    }
  }

  // 显示格式选择对话框
  void _showFormatSelectionDialog() {
    if (!_isDirty || _contentController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('选择内容格式'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFormatOption(ContentFormat.plainText, '纯文本', '普通文本，无格式'),
              _buildFormatOption(ContentFormat.markdown, 'Markdown', '支持标题、加粗、列表等格式'),
              // _buildFormatOption(ContentFormat.richText, '富文本', '所见即所得的格式编辑'),
            ],
          ),
        ),
      );
    } else {
      // 已有内容时，提示格式转换可能导致格式丢失
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('注意'),
          content: const Text('更改内容格式可能会导致现有格式丢失。确定要更改吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('选择内容格式'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFormatOption(ContentFormat.plainText, '纯文本', '普通文本，无格式'),
                        _buildFormatOption(ContentFormat.markdown, 'Markdown', '支持标题、加粗、列表等格式'),
                        // _buildFormatOption(ContentFormat.richText, '富文本', '所见即所得的格式编辑'),
                      ],
                    ),
                  ),
                );
              },
              child: const Text('继续'),
            ),
          ],
        ),
      );
    }
  }

  // 构建格式选项
  Widget _buildFormatOption(ContentFormat format, String title, String description) {
    return ListTile(
      title: Text(title),
      subtitle: Text(description),
      leading: _getFormatIconByType(format),
      selected: _contentFormat == format,
      onTap: () {
        setState(() {
          _contentFormat = format;
          // 如果切换到Markdown，且是空内容，添加一些提示内容
          if (format == ContentFormat.markdown && _contentController.text.isEmpty) {
            _contentController.text = '# 标题\n\n正文内容\n\n## 小标题\n\n- 列表项1\n- 列表项2\n\n**加粗文本** *斜体文本*';
          }
        });
        Navigator.of(context).pop();
      },
    );
  }

  // 根据格式类型获取图标
  Widget _getFormatIconByType(ContentFormat format) {
    switch (format) {
      case ContentFormat.plainText:
        return const Icon(Icons.text_fields);
      case ContentFormat.markdown:
        return const Icon(Icons.article);
      case ContentFormat.richText:
        return const Icon(Icons.format_bold);
      default:
        return const Icon(Icons.text_fields);
    }
  }

  Widget _buildBody() {
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');
    final dateString = dateFormat.format(widget.entry.dateCreated);
    
    return Column(
      children: [
        // 标题输入
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: '输入标题...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
        
        // 日期和心情
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateString),
              _buildMoodSelector(),
            ],
          ),
        ),
        
        const Divider(),
        
        // 图片附件
        if (_mediaLinks.isNotEmpty || true)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ImageAttachmentList(
              imagePaths: _mediaLinks,
              onImageTap: _viewImage,
              onImageDelete: _deleteImage,
              onAddImage: _addImage,
            ),
          ),
        
        // 内容编辑区域 - 根据格式和预览模式显示不同的编辑器
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildContentEditor(),
          ),
        ),
        
        // 标签显示
        if (_tags.isNotEmpty)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tags.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(_tags[index]),
                    onDeleted: () {
                      setState(() {
                        _tags.removeAt(index);
                        _isDirty = true;
                      });
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // 构建内容编辑器
  Widget _buildContentEditor() {
    // Markdown模式下的预览
    if (_contentFormat == ContentFormat.markdown && _isPreviewMode) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        width: double.infinity, // 使容器宽度充满父容器
        constraints: const BoxConstraints(minHeight: 300), // 设置最小高度
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 内容左对齐
          children: [
            // 预览模式标题
            if (_titleController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _titleController.text,
                  style: const TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            // Markdown内容
            Expanded(
              child: MarkdownBody(
                data: _contentController.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  p: const TextStyle(fontSize: 14, height: 1.5),
                  blockquote: TextStyle(
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                  code: TextStyle(
                    backgroundColor: Colors.grey.shade200,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // 普通编辑模式
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _contentController,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(fontSize: 14, height: 1.5),
        decoration: InputDecoration(
          hintText: _contentFormat == ContentFormat.markdown
              ? '使用Markdown语法编写...'
              : '写下你的日记...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Row(
      children: List.generate(5, (index) {
        final mood = index + 1;
        return IconButton(
          icon: Icon(
            MoodIcons.getMoodIcon(mood),
            color: _selectedMood == mood
                ? MoodIcons.getMoodColor(mood)
                : Colors.grey,
            size: _selectedMood == mood ? 30 : 24,
          ),
          onPressed: () {
            setState(() {
              _selectedMood = mood;
              _isDirty = true;
            });
          },
        );
      }),
    );
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
      _isDirty = true;
    });
  }

  // 添加图片
  void _addImage() async {
    showDialog(
      context: context,
      builder: (context) => ImageSourceDialog(
        onCamera: () async {
          final imagePath = await MediaService.instance.takePhoto(
            dateCreated: widget.entry.dateCreated,
          );
          if (imagePath != null && mounted) {
            setState(() {
              _mediaLinks.add(imagePath);
              _isDirty = true;
            });
          }
        },
        onGallery: () async {
          final imagePath = await MediaService.instance.pickImage(
            dateCreated: widget.entry.dateCreated,
          );
          if (imagePath != null && mounted) {
            setState(() {
              _mediaLinks.add(imagePath);
              _isDirty = true;
            });
          }
        },
        onMultiple: () async {
          final imagePaths = await MediaService.instance.pickMultipleImages(
            dateCreated: widget.entry.dateCreated,
          );
          if (imagePaths.isNotEmpty && mounted) {
            setState(() {
              _mediaLinks.addAll(imagePaths);
              _isDirty = true;
            });
          }
        },
      ),
    );
  }

  // 查看图片
  void _viewImage(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => ImageViewDialog(imagePath: imagePath),
    );
  }

  // 删除图片
  void _deleteImage(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除图片'),
        content: const Text('确定要删除这张图片吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _mediaLinks.remove(imagePath);
                _isDirty = true;
              });
              // 在后台删除文件
              MediaService.instance.deleteImage(imagePath);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showTagsDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: '输入标签',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final tag = textController.text.trim();
              if (tag.isNotEmpty && !_tags.contains(tag)) {
                setState(() {
                  _tags.add(tag);
                  _isDirty = true;
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除日记'),
        content: const Text('确定要删除这篇日记吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
              
              // 获取需要删除的图片
              final imagesToDelete = List<String>.from(_mediaLinks);
              
              // 删除日记条目
              if (widget.entry.id != null) {
                await diaryProvider.deleteDiaryEntry(widget.entry.id!);
              }
              
              // 删除图片文件
              for (var imagePath in imagesToDelete) {
                await MediaService.instance.deleteImage(imagePath);
              }
              
              if (mounted) {
                Navigator.of(context).pop(); // 关闭对话框
                Navigator.of(context).pop(); // 返回上一页
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _saveEntry() async {
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);

    // 将内容直接保存为文本
    final content = _contentController.text;

    try {
      // 使用当前值创建更新后的日记条目
      final updatedEntry = widget.entry.copy(
        title: _titleController.text,
        content: content,
        dateModified: DateTime.now(),
        tags: _tags,
        mood: _selectedMood,
        isFavorite: _isFavorite,
        mediaLinks: _mediaLinks,
        contentFormat: _contentFormat,
      );

      int resultId = -1;
      bool success = false;
  
      if (widget.isNewEntry) {
        // 创建新日记
        debugPrint('正在保存新日记...');
        resultId = await diaryProvider.addDiaryEntry(updatedEntry);
        success = resultId > 0;
        debugPrint('新日记保存结果: ID = $resultId, 成功 = $success');
      } else {
        // 更新现有日记
        debugPrint('正在更新日记 ID: ${widget.entry.id}...');
        success = await diaryProvider.updateDiaryEntry(updatedEntry);
        debugPrint('更新日记结果: 成功 = $success');
      }
      
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存日记失败')),
          );
        }
        return;
      }
      
      // 如果WebDAV已启用，尝试同步
      if (_webDavService.isEnabled) {
        // 先同步图片
        debugPrint('正在同步媒体文件...');
        for (var imagePath in _mediaLinks) {
          try {
            await MediaService.instance.syncImageToWebDav(
              imagePath, 
              widget.entry.dateCreated,
            );
          } catch (e) {
            debugPrint('同步图片失败: $e');
          }
        }
        
        // 同步日记条目
        if (resultId > 0 || updatedEntry.id != null) {
          final entryToSync = resultId > 0 
              ? await DiaryDatabase.instance.readEntry(resultId)
              : updatedEntry;
          
          try {
            debugPrint('正在同步日记...');
            await _webDavService.syncDiaryEntry(entryToSync);
          } catch (e) {
            debugPrint('同步日记失败: $e');
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('保存日记时发生错误: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存日记时发生错误: $e')),
        );
      }
    }
  }
}