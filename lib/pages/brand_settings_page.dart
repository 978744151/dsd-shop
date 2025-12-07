import 'package:flutter/material.dart';
import '../utils/http_client.dart';
import '../api/brand.dart';
import '../models/brand.dart';
import '../utils/storage.dart';
import '../utils/toast_util.dart';

class BrandSettingsPage extends StatefulWidget {
  const BrandSettingsPage({super.key});

  @override
  State<BrandSettingsPage> createState() => _BrandSettingsPageState();
}

class _BrandSettingsPageState extends State<BrandSettingsPage> {
  bool _isLoading = false;
  List<BrandModel> _brands = [];
  Map<String, String> _customScores = {}; // brandId -> score string

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // 读取本地存储的分数
    final saved = await Storage.getJson('brand_custom_scores');
    if (saved != null) {
      _customScores =
          saved.map((key, value) => MapEntry(key, value.toString()));
    }

    try {
      // 拉取品牌列表（尽量多取一些，支持搜索时可以扩展）
      final response = await HttpClient.get(brandApi.getBrand, params: {
        'page': 1,
        'limit': 200,
      });
      if (response['success'] == true) {
        final List<dynamic> data = response['data']['brands'] ?? [];
        _brands = data.map((e) => BrandModel.fromJson(e)).toList();
      }
    } catch (e) {
      // 网络错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取品牌失败：$e')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveScores() async {
    // 过滤掉空字符串
    final Map<String, dynamic> toSave = {};
    _customScores.forEach((k, v) {
      final val = v.trim();
      if (val.isNotEmpty) {
        toSave[k] = val;
      }
    });

    try {
      // 构建 {id, scoreVal} 列表
      final List<Map<String, dynamic>> items = toSave.entries
          .map((e) => {
                'id': e.key,
                'scoreVal': double.tryParse(e.value.toString()) ?? e.value,
              })
          .toList();

      // 同步到服务端 - 使用 scores: [{id, scoreVal}] 结构
      final resp = await HttpClient.post(brandApi.setBrandScores, body: {
        'scores': items,
      });

      // 本地缓存一份（仍按 id -> val 存）
      await Storage.setJson('brand_custom_scores', toSave);

      // 用户提示
      ToastUtil.showSuccess('分数已保存');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    }
  }

  void _clearAll() async {
    setState(() {
      _customScores.clear();
    });
    await Storage.remove('brand_custom_scores');
    ToastUtil.showWarning('已清空自定义分数');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 120, 160, 230),
        foregroundColor: Colors.black,
        title: const Text(
          '品牌中心',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveScores,
            child: const Text(
              '保存',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '为品牌设置自定义分数（数字）',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      // TextButton(
                      //   onPressed: _clearAll,
                      //   child: Text(
                      //     '全部清空',
                      //     style: TextStyle(color: Theme.of(context).primaryColor),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: _brands.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final brand = _brands[index];
                      final brandId = brand.id;
                      final name = brand.name ?? '';
                      final ctrlValue = _customScores[brandId] ?? brand.score?.toString() ?? '';
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name.isNotEmpty ? name : '未命名品牌',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                initialValue: ctrlValue,
                                keyboardType:
                                    const TextInputType.numberWithOptions(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: '分数',
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _customScores[brandId] = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}