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
    // final token = await _getToken();
    final token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2ODllYWMzNDQwODk5Nzk5YTE4YWJhNjkiLCJlbWFpbCI6Ijk3ODc0NDE1MUBxcS5jb20iLCJyb2xlIjoiYWRtaW4iLCJpYXQiOjE3NTU4NTE3ODIsImV4cCI6MTc1NjQ1NjU4Mn0.PhXrpo4hmobGBYj6ZI05WEAmkGXCAvDnyOANcyKD7Gk';

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

    final response = await http.get(
      uri,
      headers: headers,
    );
    return _handleResponse(response);
  }

  static Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    try {
      final data = json.decode(response.body);
      print(response);
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
      if (response.statusCode != 200 || data['success'] != true) {
        final message = data['message'] ?? data['error'] ?? '请求失败';
        _showErrorMessage(message);
        throw Exception(message);
      }

      return data;
    } catch (e) {
      // if (e.toString().contains('SocketException') ||
      //     e.toString().contains('HandshakeException')) {
      //   _showErrorMessage('网络连接不安全或无法访问，请检查网络设置');
      // } else if (e.toString().contains('TimeoutException')) {
      //   _showErrorMessage('请求超时，请稍后重试');
      // } else {
      //   _showErrorMessage('网络请求失败：${e.toString()}');
      // }
      rethrow;
    }
  }

  static void _showErrorMessage(String message) {
    ToastUtil.showDanger(message);
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

  static Future<dynamic> uploadFile(String path, File file) async {
    final headers = await _getHeaders();
    var uri = Uri.parse('$baseUrl$path');
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    return json.decode(responseData);
  }
}
