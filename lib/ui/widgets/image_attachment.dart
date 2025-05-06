import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/media_service.dart';

/// 图片附件组件，用于显示和管理日记中的图片
class ImageAttachment extends StatelessWidget {
  final String imagePath;
  final Function()? onTap;
  final Function()? onDelete;
  final double size;
  final bool showDeleteButton;

  const ImageAttachment({
    super.key,
    required this.imagePath,
    this.onTap,
    this.onDelete,
    this.size = 120.0,
    this.showDeleteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 图片
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: GestureDetector(
              onTap: onTap,
              child: Image.file(
                File(imagePath),
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
            ),
          ),
          
          // 删除按钮
          if (showDeleteButton && onDelete != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 图片选择按钮
class AddImageButton extends StatelessWidget {
  final Function() onTap;
  final double size;

  const AddImageButton({
    super.key,
    required this.onTap,
    this.size = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        color: Colors.grey.shade100,
      ),
      child: Stack(
        children: [
          // 虚线效果
          Positioned.fill(
            child: CustomPaint(
              painter: DashedBorderPainter(
                color: Colors.grey.shade300,
                strokeWidth: 1,
                gap: 4,
              ),
            ),
          ),
          // 点击区域和图标
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8.0),
            child: const Center(
              child: Icon(
                Icons.add_photo_alternate,
                color: Colors.grey,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 虚线边框绘制器
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    // 绘制矩形的虚线边框
    _drawDashedLine(canvas, paint, Offset(0, 0), Offset(size.width, 0));
    _drawDashedLine(canvas, paint, Offset(size.width, 0), Offset(size.width, size.height));
    _drawDashedLine(canvas, paint, Offset(size.width, size.height), Offset(0, size.height));
    _drawDashedLine(canvas, paint, Offset(0, size.height), Offset(0, 0));
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    final Path path = Path();
    path.moveTo(start.dx, start.dy);
    path.lineTo(end.dx, end.dy);
    
    final double distance = (end - start).distance;
    final double dashLength = 4.0;
    final int dashCount = (distance / (dashLength + gap)).floor();
    
    for (int i = 0; i < dashCount; i++) {
      final double startFraction = i * (dashLength + gap) / distance;
      final double endFraction = (i * (dashLength + gap) + dashLength) / distance;
      if (endFraction > 1.0) break;
      
      final Offset dashStart = Offset.lerp(start, end, startFraction)!;
      final Offset dashEnd = Offset.lerp(start, end, endFraction)!;
      
      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// 图片列表组件，用于显示多张图片
class ImageAttachmentList extends StatelessWidget {
  final List<String> imagePaths;
  final Function(String) onImageTap;
  final Function(String) onImageDelete;
  final Function() onAddImage;
  final double imageSize;
  final bool canAddMore;

  const ImageAttachmentList({
    super.key,
    required this.imagePaths,
    required this.onImageTap,
    required this.onImageDelete,
    required this.onAddImage,
    this.imageSize = 120.0,
    this.canAddMore = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: imageSize + 8.0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 已附加的图片
          ...imagePaths.map((path) => ImageAttachment(
                imagePath: path,
                size: imageSize,
                onTap: () => onImageTap(path),
                onDelete: () => onImageDelete(path),
              )),
              
          // 添加图片按钮
          if (canAddMore)
            AddImageButton(
              onTap: onAddImage,
              size: imageSize,
            ),
        ],
      ),
    );
  }
}

/// 图片查看对话框
class ImageViewDialog extends StatelessWidget {
  final String imagePath;

  const ImageViewDialog({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 图片
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 100,
                    ),
                  );
                },
              ),
            ),
            
            // 关闭按钮
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 图片选择来源对话框
class ImageSourceDialog extends StatelessWidget {
  final Function() onCamera;
  final Function() onGallery;
  final Function() onMultiple;

  const ImageSourceDialog({
    super.key,
    required this.onCamera,
    required this.onGallery,
    required this.onMultiple,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('选择图片来源'),
      children: [
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            onCamera();
          },
          child: const ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('拍照'),
          ),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            onGallery();
          },
          child: const ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('从相册选择一张'),
          ),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            onMultiple();
          },
          child: const ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('从相册选择多张'),
          ),
        ),
      ],
    );
  }
} 