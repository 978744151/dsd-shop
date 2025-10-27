import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/nft_category.dart';
import '../models/nft.dart';
import '../config/env.dart';

class NFTService {
  // 获取NFT分类
  static Future<List<NFTCategory>> getCategories() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.nftCategories));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data =
            responseData['data'] ?? []; // 修改这里，获取 data 字段
        return data.map((json) => NFTCategory.fromJson(json)).toList();
      }
      throw Exception('获取分类失败');
    } catch (e) {
      throw Exception('获取分类失败: $e');
    }
  }

  // 获取NFT列表
  static Future<List<NFT>> getNFTs({
    String? category,
    required int page,
    required int perPage,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.nfts}?page=$page&perPage=$perPage&category=$category'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data =
            responseData['data']['data'] ?? []; // 修改这里，获取正确的数据路径
        return data.map((json) => NFT.fromJson(json)).toList();
      }
      throw Exception('获取NFT列表失败');
    } catch (e) {
      throw Exception('获取NFT列表失败: $e');
    }
  }
}