import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../router/router.dart';
// ignore: depend_on_referenced_packages
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/toast_util.dart';
import '../config/env.dart';
import 'dart:io';

class HttpClient {
  static const String baseUrl = ApiConfig.baseUrl;
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String path,
      {Map<String, dynamic>? params}) async {
    final headers = await _getHeaders();

    // 构建带查询参数的 URL
    var uri = Uri.parse('$baseUrl$path');
    if (params != null) {
      uri = uri.replace(
          queryParameters:
              params.map((key, value) => MapEntry(key, value.toString())));
    }

    final response = await http
        .get(
      uri,
      headers: headers,
    )
        .timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('请求超时，请检查网络连接');
      },
    );
    return _handleResponse(response);
  }

  static Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    final response = await http
        .post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: json.encode(body),
    )
        .timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('请求超时，请检查网络连接');
      },
    );
    return _handleResponse(response);
  }

  static Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    final response = await http
        .put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: json.encode(body),
    )
        .timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('请求超时，请检查网络连接');
      },
    );
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String path) async {
    final headers = await _getHeaders();
    final response = await http
        .delete(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    )
        .timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('请求超时，请检查网络连接');
      },
    );
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    try {
      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        // _showErrorMessage('登录已过期，请重新登录');

        // ignore: depend_on_referenced_packages
        ToastUtil.showDanger("登录已过期，请重新登录");
        final context = router.routerDelegate.navigatorKey.currentContext;

        if (context != null) {
          router.go('/login');
        }
        throw Exception('未授权');
      }
      if (data['success'] != true) {
        final message = data['message'] ?? data['error'] ?? '请求失败';
        ToastUtil.showDanger(message);
        throw Exception(message); // 传递具体错误信息，避免catch块重复显示
      }

      return data;
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException') ||
          e.toString().contains('Connection reset by peer')) {
        _showErrorMessage('网络连接不稳定，请检查网络设置');
      } else if (e.toString().contains('TimeoutException') ||
          e.toString().contains('请求超时')) {
        _showErrorMessage('请求超时，请稍后重试');
      } else if (!e.toString().startsWith('Exception:')) {
        // 只有非自定义Exception才显示错误信息，避免重复弹框
        _showErrorMessage('${e.toString()}');
      }
      rethrow;
    }
  }

  static void _showErrorMessage(String message) {
    // ToastUtil.showDanger(message);
    Fluttertoast.showToast(msg: message);
    // final context = router.routerDelegate.navigatorKey.currentContext;
    // if (context != null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(message),
    //       duration: const Duration(seconds: 3),
    //       behavior: SnackBarBehavior.floating,
    //       backgroundColor: Colors.red[700],
    //       margin: EdgeInsets.only(
    //         bottom: MediaQuery.of(context).size.height - 100, // 计算距离顶部的位置
    //         left: 20,
    //         right: 20,
    //       ),
    //     ),
    //   );
  }

  static Future<dynamic> uploadFile(String path, File file,
      {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final headers = await _getHeaders();
        var uri = Uri.parse('$baseUrl$path');
        var request = http.MultipartRequest('POST', uri);
        request.headers.addAll(headers);
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
        // 设置超时时间为30秒
        var response = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('上传超时，请检查网络连接');
          },
        );

        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          final data = json.decode(responseData);

          if (data['success'] == true) {
            print('文件上传成功');
            return data;
          } else {
            throw Exception(data['message'] ?? '上传失败');
          }
        } else {
          throw Exception('服务器返回错误: ${response.statusCode}');
        }
      } catch (e) {
        print('上传尝试 $attempt 失败: $e');

        if (attempt == maxRetries) {
          // 最后一次尝试失败，抛出错误
          if (e.toString().contains('Connection reset by peer') ||
              e.toString().contains('SocketException')) {
            _showErrorMessage('网络连接不稳定，请检查网络设置后重试');
          } else if (e.toString().contains('TimeoutException') ||
              e.toString().contains('上传超时')) {
            _showErrorMessage('上传超时，请检查网络连接后重试');
          } else {
            _showErrorMessage('上传失败: ${e.toString()}');
            rethrow;
          }
        } else {
          // 等待后重试
          print('等待 ${attempt * 2} 秒后重试...');
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    throw Exception('上传失败: 已达到最大重试次数');
  }
}
