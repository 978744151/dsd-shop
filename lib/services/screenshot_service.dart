import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../utils/screenshot_util.dart';

/// 截图服务类，提供截图相关的通用方法
class ScreenshotService {
  static final ScreenshotService _instance = ScreenshotService._internal();
  factory ScreenshotService() => _instance;
  ScreenshotService._internal();

  /// 创建截图控制器
  static ScreenshotController createController() {
    return ScreenshotUtil.createController();
  }

  /// 捕获截图
  static Future<Uint8List?> captureScreenshot(
      ScreenshotController controller) async {
    try {
      return await controller.capture(
        delay: const Duration(milliseconds: 10),
        pixelRatio: 3.0,
      );
    } catch (e) {
      debugPrint('截图捕获失败: $e');
      return null;
    }
  }

  /// 保存图片到相册
  static Future<bool> saveImageToGallery(Uint8List imageBytes,
      {String? name}) async {
    try {
      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        quality: 100,
        name:
            name ?? "comparison_table_${DateTime.now().millisecondsSinceEpoch}",
      );
      return result['isSuccess'] == true;
    } catch (e) {
      debugPrint('保存图片失败: $e');
      return false;
    }
  }

  /// 显示截图预览对话框
  static void showScreenshotPreview({
    required BuildContext context,
    required Uint8List imageBytes,
  }) {
    ScreenshotUtil.showImageDialog(context, imageBytes);
  }

  /// 一键截图并显示预览
  static Future<void> captureAndShowPreview({
    required BuildContext context,
    required ScreenshotController controller,
    String? errorMessage,
  }) async {
    await ScreenshotUtil.captureAndShowImage(
      context: context,
      controller: controller,
      errorMessage: errorMessage,
    );
  }

  /// 批量截图
  static Future<List<Uint8List?>> captureMultipleScreenshots(
    List<ScreenshotController> controllers,
  ) async {
    List<Uint8List?> results = [];

    for (var controller in controllers) {
      final screenshot = await captureScreenshot(controller);
      results.add(screenshot);

      // 添加延迟避免过快连续截图
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return results;
  }

  /// 创建截图配置
  static Map<String, dynamic> createScreenshotConfig({
    double pixelRatio = 3.0,
    Duration delay = const Duration(milliseconds: 10),
    int quality = 100,
  }) {
    return {
      'pixelRatio': pixelRatio,
      'delay': delay,
      'quality': quality,
    };
  }

  /// 验证截图权限
  static Future<bool> checkScreenshotPermission() async {
    try {
      // 这里可以添加权限检查逻辑
      // 目前Flutter的screenshot插件不需要特殊权限
      return true;
    } catch (e) {
      debugPrint('权限检查失败: $e');
      return false;
    }
  }

  /// 获取截图文件大小
  static String getImageSize(Uint8List imageBytes) {
    double sizeInKB = imageBytes.length / 1024;
    if (sizeInKB < 1024) {
      return '${sizeInKB.toStringAsFixed(1)} KB';
    } else {
      double sizeInMB = sizeInKB / 1024;
      return '${sizeInMB.toStringAsFixed(1)} MB';
    }
  }

  /// 压缩图片
  static Future<Uint8List?> compressImage(
    Uint8List imageBytes, {
    int quality = 85,
  }) async {
    try {
      // 这里可以添加图片压缩逻辑
      // 目前返回原图片
      return imageBytes;
    } catch (e) {
      debugPrint('图片压缩失败: $e');
      return null;
    }
  }

  /// 创建水印截图
  static Future<Uint8List?> captureWithWatermark({
    required ScreenshotController controller,
    String? watermarkText,
    Color watermarkColor = Colors.grey,
    double watermarkOpacity = 0.3,
  }) async {
    try {
      // 基础截图
      final screenshot = await captureScreenshot(controller);
      if (screenshot == null) return null;

      // 这里可以添加水印逻辑
      // 目前返回原截图
      return screenshot;
    } catch (e) {
      debugPrint('水印截图失败: $e');
      return null;
    }
  }

  /// 截图错误处理
  static void handleScreenshotError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
  }) {
    final message = customMessage ?? '截图操作失败，请重试';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: '确定',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// 截图成功提示
  static void showScreenshotSuccess(
    BuildContext context, {
    String? customMessage,
  }) {
    final message = customMessage ?? '截图保存成功';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
