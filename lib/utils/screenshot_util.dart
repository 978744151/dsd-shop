import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// 截图工具类，提供通用的截图和图片展示功能
class ScreenshotUtil {
  /// 生成截图并显示
  static Future<void> captureAndShowImage({
    required BuildContext context,
    required ScreenshotController controller,
    String? errorMessage,
  }) async {
    if (!context.mounted) return;

    try {
      // 等待一帧确保UI稳定
      await Future.delayed(const Duration(milliseconds: 300));

      // 捕获截图
      final Uint8List? image = await controller.capture(
        delay: const Duration(milliseconds: 200),
        pixelRatio: 3.0, // 高像素比例，确保图片质量和完整性
      );

      if (context.mounted && image != null) {
        showImageDialog(context, image);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage ?? '截图生成失败，请重试')),
        );
      }
    } catch (e) {
      print('截图错误: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('截图失败: ${e.toString()}')),
        );
      }
    }
  }

  /// 显示图片对话框
  static void showImageDialog(BuildContext context, Uint8List imageBytes) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: MediaQuery.of(dialogContext).size.width,
            height: MediaQuery.of(dialogContext).size.height,
            color: Colors.black,
            child: Stack(
              children: [
                // 图片显示区域
                Center(
                  child: InteractiveViewer(
                    child: Image.memory(imageBytes),
                  ),
                ),
                // 底部操作栏
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 关闭图标
                      GestureDetector(
                        onTap: () {
                          if (Navigator.canPop(dialogContext)) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      // 下载图标
                      GestureDetector(
                        onTap: () async {
                          await saveImageToGallery(context, imageBytes);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Icon(
                            Icons.download,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 保存图片到相册
  static Future<void> saveImageToGallery(
    BuildContext context,
    Uint8List imageBytes, {
    String? fileName,
  }) async {
    try {
      // 使用 image_gallery_saver 保存图片到相册
      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        quality: 100,
        name: fileName ?? "screenshot_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (context.mounted) {
        if (result['isSuccess'] == true) {
          Fluttertoast.showToast(msg: '图片已保存到相册');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('保存失败，请检查相册权限'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 创建截图控制器
  static ScreenshotController createController() {
    return ScreenshotController();
  }
}
