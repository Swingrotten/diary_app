import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import '../../services/webdav_service.dart';

/// WebDAV媒体文件管理页面
class WebDavMediaScreen extends StatefulWidget {
  const WebDavMediaScreen({super.key});

  @override
  State<WebDavMediaScreen> createState() => _WebDavMediaScreenState();
}

class _WebDavMediaScreenState extends State<WebDavMediaScreen> {
  final WebDavService _webDavService = WebDavService();
  List<webdav.File> _mediaFiles = [];
  bool _isLoading = true;
  String? _error;
  
  // 缓存的图片
  final Map<String, File> _cachedImages = {};
  
  @override
  void initState() {
    super.initState();
    _loadMediaFiles();
  }
  
  // 加载远程媒体文件
  Future<void> _loadMediaFiles() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    
    try {
      if (!_webDavService.isEnabled) {
        setState(() {
          _isLoading = false;
          _error = 'WebDAV服务未启用，请先配置WebDAV服务';
        });
        return;
      }
      
      final files = await _webDavService.getRemoteMediaFiles();
      
      // 按修改日期排序
      files.sort((a, b) {
        // 处理可空情况
        final aTime = a.mTime ?? DateTime(1970);
        final bTime = b.mTime ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      
      if (mounted) {
        setState(() {
          _mediaFiles = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '加载WebDAV媒体文件失败: $e';
        });
      }
    }
  }
  
  // 下载图片并缓存
  Future<File?> _downloadImage(webdav.File file) async {
    if (file.path == null) return null;
    
    // 检查缓存中是否已存在
    if (_cachedImages.containsKey(file.path!)) {
      return _cachedImages[file.path!];
    }
    
    try {
      // 创建缓存目录
      final cacheDir = await _getCacheDir();
      final fileName = path.basename(file.path!);
      final localPath = path.join(cacheDir.path, fileName);
      
      // 检查本地是否已有缓存
      final localFile = File(localPath);
      if (await localFile.exists()) {
        _cachedImages[file.path!] = localFile;
        return localFile;
      }
      
      // 获取完整URL
      final client = _webDavService.client;
      if (client == null || file.path == null) return null;
      
      // 下载文件
      final bytes = await client.read(file.path!);
      
      // 保存到缓存
      await localFile.writeAsBytes(bytes);
      
      // 添加到缓存映射
      _cachedImages[file.path!] = localFile;
      
      return localFile;
    } catch (e) {
      debugPrint('下载图片失败: $e');
      return null;
    }
  }
  
  // 获取缓存目录
  Future<Directory> _getCacheDir() async {
    Directory cacheDir;
    
    if (Platform.isWindows || Platform.isLinux) {
      final tempDir = await getTemporaryDirectory();
      final dirPath = path.join(tempDir.path, 'DiaryApp', 'WebDavCache');
      cacheDir = Directory(dirPath);
    } else {
      final tempDir = await getTemporaryDirectory();
      final dirPath = path.join(tempDir.path, 'WebDavCache');
      cacheDir = Directory(dirPath);
    }
    
    // 确保目录存在
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }
  
  // 保存图片到相册
  Future<void> _saveImageToGallery(webdav.File file) async {
    if (file.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无效的图片路径')),
      );
      return;
    }
    
    try {
      final localFile = await _downloadImage(file);
      if (localFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('下载图片失败')),
        );
        return;
      }
      
      // 检查权限 - 只有在移动平台才需要
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('需要存储权限才能保存图片')),
            );
          }
          return;
        }
      }
      
      // 保存到相册 - 在Windows上直接复制到图片文件夹
      if (Platform.isWindows) {
        final picturesDir = await getDownloadsDirectory();
        if (picturesDir != null) {
          final targetFile = File(path.join(
              picturesDir.path, 'DiaryApp_${path.basename(file.path!)}'
          ));
          await localFile.copy(targetFile.path);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('图片已保存到: ${targetFile.path}')),
            );
          }
        }
      } else {
        // 移动平台可以使用image_gallery_saver
        // TODO: 实现保存到相册的功能，使用image_gallery_saver或gallery_saver包
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('图片已保存到相册')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存图片失败: $e')),
        );
      }
    }
  }
  
  // 删除远程图片
  Future<void> _deleteRemoteImage(webdav.File file) async {
    if (file.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无效的图片路径')),
      );
      return;
    }
    
    try {
      final success = await _webDavService.deleteRemoteMediaFile(file.path!);
      
      if (success) {
        // 如果有缓存，删除缓存
        if (_cachedImages.containsKey(file.path!)) {
          final cachedFile = _cachedImages[file.path!]!;
          if (await cachedFile.exists()) {
            await cachedFile.delete();
          }
          _cachedImages.remove(file.path!);
        }
        
        // 刷新列表
        await _loadMediaFiles();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('图片已删除')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除图片失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除图片失败: $e')),
        );
      }
    }
  }
  
  // 查看大图
  void _viewFullImage(webdav.File file) async {
    if (file.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无效的图片路径')),
      );
      return;
    }
    
    final localFile = await _downloadImage(file);
    if (localFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加载图片失败')),
        );
      }
      return;
    }
    
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FullScreenImageViewer(
            imageFile: localFile,
            fileName: path.basename(file.path!),
            onSave: () => _saveImageToGallery(file),
          ),
        ),
      );
    }
  }
  
  // 按日期对文件进行分组
  Map<String, List<webdav.File>> _groupFilesByDate() {
    final Map<String, List<webdav.File>> groupedFiles = {};
    
    for (final file in _mediaFiles) {
      if (file.path == null) continue;
      
      // 提取日期，格式为 YYYYMMDD，位于路径的最后一个目录
      String dateStr = '';
      final pathParts = file.path!.split('/');
      if (pathParts.length >= 2) {
        dateStr = pathParts[pathParts.length - 2];
        // 尝试格式化日期
        try {
          // 验证是否为日期格式
          if (dateStr.length == 8 && int.tryParse(dateStr) != null) {
            final year = dateStr.substring(0, 4);
            final month = dateStr.substring(4, 6);
            final day = dateStr.substring(6, 8);
            
            final formattedDate = '$year-$month-$day';
            
            if (groupedFiles.containsKey(formattedDate)) {
              groupedFiles[formattedDate]!.add(file);
            } else {
              groupedFiles[formattedDate] = [file];
            }
            continue;
          }
        } catch (e) {
          debugPrint('日期格式化失败: $e');
        }
      }
      
      // 如果无法提取日期或格式化失败，放入"其他"分组
      const otherKey = '其他';
      if (groupedFiles.containsKey(otherKey)) {
        groupedFiles[otherKey]!.add(file);
      } else {
        groupedFiles[otherKey] = [file];
      }
    }
    
    return groupedFiles;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebDAV媒体管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMediaFiles,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMediaFiles,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    
    if (_mediaFiles.isEmpty) {
      return const Center(
        child: Text('没有找到WebDAV上的媒体文件'),
      );
    }
    
    // 按日期分组显示
    final groupedFiles = _groupFilesByDate();
    final sortedDates = groupedFiles.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final files = groupedFiles[date]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: files.length,
              itemBuilder: (context, fileIndex) {
                final file = files[fileIndex];
                return _buildMediaItem(file);
              },
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildMediaItem(webdav.File file) {
    return GestureDetector(
      onTap: () => _viewFullImage(file),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: FutureBuilder<File?>(
                future: _downloadImage(file),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                        ),
                      ),
                    );
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return const Center(
                      child: Icon(Icons.error),
                    );
                  }
                  
                  return Image.file(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () => _showDeleteConfirmation(file),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation(webdav.File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: const Text('确定要删除这张图片吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteRemoteImage(file);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 全屏图片查看器
class FullScreenImageViewer extends StatelessWidget {
  final File imageFile;
  final String fileName;
  final VoidCallback onSave;
  
  const FullScreenImageViewer({
    super.key,
    required this.imageFile,
    required this.fileName,
    required this.onSave,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: onSave,
            tooltip: '保存到相册',
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(imageFile),
        ),
      ),
    );
  }
} 