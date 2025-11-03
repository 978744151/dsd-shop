import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';

class ImageUploadUtil {
  /// Web平台专用的图片上传方法
  /// 使用XFile的readAsBytes方法，兼容Web平台
  /// [imageFile] 要上传的图片文件
  /// [uploadPath] 上传路径，默认为'/upload/image'
  static Future<Map<String, dynamic>> uploadImageForWeb(
    XFile imageFile, {
    String uploadPath = 'upload/image',
  }) async {
    try {
      // 获取token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('请先登录');
      }

      // 读取图片字节数据 - 使用XFile的readAsBytes方法，Web兼容
      final bytes = await imageFile.readAsBytes();

      // 创建multipart请求 - H5方式
      final uri = Uri.parse('${ApiConfig.baseUrl}$uploadPath');
      final request = http.MultipartRequest('POST', uri);

      // 添加认证头
      request.headers['Authorization'] = 'Bearer $token';

      // 添加文件
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      // 发送请求
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('上传失败: ${response.statusCode}');
      }
    } catch (e) {
      print('H5图片上传错误: $e');
      rethrow;
    }
  }

  /// 通用图片上传方法，自动检测平台并选择合适的上传方式
  /// [imageFile] 要上传的图片文件
  /// [uploadPath] 上传路径，默认为'/upload/image'
  static Future<Map<String, dynamic>> uploadImage(
    XFile imageFile, {
    String uploadPath = 'upload/image',
  }) async {
    return await uploadImageForWeb(imageFile, uploadPath: uploadPath);
  }
}
