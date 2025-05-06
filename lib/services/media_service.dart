import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'webdav_service.dart';

/// 媒体服务类，用于处理图片附件的选择、存储和管理
class MediaService {
  static final MediaService instance = MediaService._init();
  
  MediaService._init();

  final ImagePicker _imagePicker = ImagePicker();
  final WebDavService _webDavService = WebDavService();
  
  /// 获取应用存储图片的目录
  Future<Directory> get _mediaDirectory async {
    Directory directory;
    
    if (Platform.isWindows || Platform.isLinux) {
      final documentsDir = await getApplicationDocumentsDirectory();
      final mediaDir = path.join(documentsDir.path, 'DiaryApp', 'Media');
      directory = Directory(mediaDir);
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = path.join(appDir.path, 'Media');
      directory = Directory(mediaDir);
    }
    
    // 确保目录存在
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    return directory;
  }
  
  /// 从相机拍照
  Future<String?> takePhoto({
    ImageSource source = ImageSource.camera,
    DateTime? dateCreated,
  }) async {
    try {
      final XFile? imageFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (imageFile == null) return null;
      
      // 保存图片到应用目录，添加日期参数用于标准化路径
      return await _saveImage(File(imageFile.path), dateCreated: dateCreated);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
  
  /// 从图库选择图片
  Future<String?> pickImage({DateTime? dateCreated}) async {
    return takePhoto(source: ImageSource.gallery, dateCreated: dateCreated);
  }
  
  /// 选择多张图片
  Future<List<String>> pickMultipleImages({DateTime? dateCreated}) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (images.isEmpty) return [];
      
      List<String> savedPaths = [];
      for (var image in images) {
        final savedPath = await _saveImage(File(image.path), dateCreated: dateCreated);
        if (savedPath != null) {
          savedPaths.add(savedPath);
        }
      }
      
      return savedPaths;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }
  
  /// 保存图片到应用目录
  Future<String?> _saveImage(File imageFile, {DateTime? dateCreated}) async {
    try {
      // 初始化WebDAV服务
      await _webDavService.initialize();
      
      // 如果启用了WebDAV，使用标准化路径
      if (_webDavService.isEnabled && dateCreated != null) {
        return await _webDavService.standardizeMediaFile(imageFile.path, dateCreated);
      }
      
      // 否则使用旧的存储方式
      final directory = await _mediaDirectory;
      final uuid = const Uuid().v4();
      final fileExtension = path.extension(imageFile.path);
      final fileName = 'diary_image_$uuid$fileExtension';
      
      final savedFile = await imageFile.copy(
        path.join(directory.path, fileName),
      );
      
      return savedFile.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }
  
  /// 删除图片
  Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }
  
  /// 获取图片的本地URI
  String getImageUri(String imagePath) {
    if (Platform.isWindows || Platform.isLinux) {
      return 'file:$imagePath';
    }
    return imagePath;
  }
  
  /// 清理未被使用的媒体文件
  Future<int> cleanUnusedMedia(List<String> usedMediaPaths) async {
    try {
      final directory = await _mediaDirectory;
      final List<FileSystemEntity> files = directory.listSync();
      int deletedCount = 0;
      
      for (var file in files) {
        if (file is File) {
          final filePath = file.path;
          if (!usedMediaPaths.contains(filePath)) {
            await file.delete();
            deletedCount++;
          }
        }
      }
      
      return deletedCount;
    } catch (e) {
      debugPrint('Error cleaning unused media: $e');
      return 0;
    }
  }
  
  /// 同步图片到WebDAV
  Future<bool> syncImageToWebDav(String imagePath, DateTime dateCreated) async {
    try {
      await _webDavService.initialize();
      if (!_webDavService.isEnabled) return false;
      
      // 先标准化图片路径
      final standardPath = await _webDavService.standardizeMediaFile(imagePath, dateCreated);
      
      // 创建基于日期的目录名
      final dateStr = '${dateCreated.year}${dateCreated.month.toString().padLeft(2, '0')}${dateCreated.day.toString().padLeft(2, '0')}';
      final fileName = path.basename(standardPath);
      
      // 上传到WebDAV
      final client = _webDavService.client;
      if (client != null) {
        try {
          // 确保远程目录存在
          await client.mkdir('每日心情/媒体/$dateStr');
        } catch (e) {
          // 忽略目录已存在的错误
          debugPrint('创建WebDAV目录可能已存在: $e');
        }
        
        // 写入文件
        final file = File(standardPath);
        await client.writeFromFile(
          file.path,
          '每日心情/媒体/$dateStr/$fileName',
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('同步图片到WebDAV失败: $e');
      return false;
    }
  }
} 