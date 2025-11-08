import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:business_savvy/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:fluttertoast/fluttertoast.dart';
  // 截图相关
final GlobalKey _screenshotKey = GlobalKey();
final GlobalKey _fullTableScreenshotKey = GlobalKey();
/// 截图工具类，提供通用的截图和图片展示功能
class ScreenshotUtil {
  /// 生成截图并显示
    static GlobalKey createBoundaryKey() => GlobalKey();
  /// 
   static Future<void> captureAndShowImage({
    required BuildContext context,
    String? errorMessage,
  }) async {
    if (!context.mounted) return;

    try {
      // 等待当前帧绘制完成，确保UI完全稳定，提升在鸿蒙设备上的兼容性
      await WidgetsBinding.instance.endOfFrame;

      // 使用 RepaintBoundary 捕获 widget
      final RenderRepaintBoundary? boundary =
          _fullTableScreenshotKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage ?? '截图生成失败，请检查截图区域是否已正确包裹')),
        );
        return;
      }

      // 动态获取像素比并限制上限，避免高像素比导致的内存问题（鸿蒙部分机型较敏感）
      final double devicePixelRatio = ui.PlatformDispatcher.instance.views.isNotEmpty
          ? ui.PlatformDispatcher.instance.views.first.devicePixelRatio
          : ui.window.devicePixelRatio; // 兼容旧API
      final double safePixelRatio = devicePixelRatio.clamp(1.0, 2.0);

      // 捕获图像
      final ui.Image image = await boundary.toImage(pixelRatio: safePixelRatio);

      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage ?? '截图生成失败，请重试')),
        );
        return;
      }

      final Uint8List imageBytes = byteData.buffer.asUint8List();

      if (context.mounted) {
        showImageDialog(context, imageBytes);
      }
    } catch (e) {
      // 捕获异常并反馈
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage ?? '截图失败: ${e.toString()}')),
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
           ToastUtil.showPrimary('保存成功');
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

 
  // 暴露用于全表截图的 Key，供外部包裹 RepaintBoundary 使用
  static GlobalKey get fullTableKey => _fullTableScreenshotKey;
}