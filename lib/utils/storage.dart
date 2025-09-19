import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Storage {
  static Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  // 获取数据
  static Future<String?> getString(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  // 保存数据
  static Future<bool> setString(String key, String value) async {
    final prefs = await _prefs;
    return prefs.setString(key, value);
  }

  // 删除数据
  static Future<bool> remove(String key) async {
    final prefs = await _prefs;
    return prefs.remove(key);
  }

  // 保存对象
  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    return setString(key, json.encode(value));
  }

  // 获取对象
  static Future<Map<String, dynamic>?> getJson(String key) async {
    String? jsonString = await getString(key);
    return jsonString != null ? json.decode(jsonString) : null;
  }
}
