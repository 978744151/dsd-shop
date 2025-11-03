import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Add this import for RenderRepaintBoundary
import 'package:flutter_screenshot_callback/flutter_screenshot_callback.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'dart:typed_data';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:business_savvy/utils/toast_util.dart';
import '../utils/http_client.dart';
import '../api/brand.dart';
import 'dart:ui' as ui;

const Color kHeaderBackgroundColor = Color(0xFFF4F8FF);

class CompareDetailPage extends StatefulWidget {
  final String id;
  const CompareDetailPage({super.key, required this.id});

  @override
  State<CompareDetailPage> createState() => _CompareDetailPageState();
}

class _CompareDetailPageState extends State<CompareDetailPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _comparisonData = [];
  String _title = '';
  // Screenshot controllers
  final GlobalKey _tableKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    _fetchReportDetail();
  }

  Future<void> _fetchReportDetail() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response =
          await HttpClient.get(brandApi.getComparisonReportsDetail(widget.id));
      if (!mounted) return;
      if (response['success'] == true) {
        setState(() {
          _title = response['data']['title'];
          _comparisonData = List<Map<String, dynamic>>.from(
              response['data']['results'] ?? []);
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('获取报告详情失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取报告详情失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 生成表格截图
  Future<void> _captureAndShowImage() async {
    if (!mounted) return;
    try {
      // 延迟确保UI已经完全渲染
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 使用 RepaintBoundary 捕获 widget
      RenderRepaintBoundary? boundary = 
          _tableKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('截图生成失败，请重试')),
        );
        return;
      }
      
      // 捕获图像
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('截图生成失败，请重试')),
        );
        return;
      }
      
      Uint8List imageBytes = byteData.buffer.asUint8List();
      
      if (mounted) {
        _showImageDialog(imageBytes);
      }
    } catch (e) {
      // ignore: avoid_print
      print('截图错误: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('截图失败: ${e.toString()}')),
        );
      }
    }
  }

  // 显示生成的图片
  void _showImageDialog(Uint8List imageBytes) {
    if (!mounted) return;
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
                Center(
                  child: InteractiveViewer(
                    child: Image.memory(imageBytes),
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
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
                      GestureDetector(
                        onTap: () async {
                          await _saveImageToGallery(imageBytes);
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

  // 保存图片到相册
  Future<void> _saveImageToGallery(Uint8List imageBytes) async {
    try {
      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        quality: 100,
        name: "comparison_table_${DateTime.now().millisecondsSinceEpoch}",
      );
      if (result != null && result['isSuccess'] == true) {
        ToastUtil.showPrimary('图片已保存到相册');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败')),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('保存失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  /// 获取列颜色
  Color _getColumnColor(int index) {
    // 默认颜色列表
    const List<Color> defaultColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];
    return defaultColors[index % defaultColors.length];
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getBrandScoreColor(double score) {
    if (score == 10.0) {
      return Colors.purple; // 重奢10分
    } else if (score > 5.0 && score < 10.0) {
      return Colors.orange; // 5-10分
    } else {
      return Colors.red; // 1-5分
    }
  }

  // 构建完整表格用于截图（包含所有品牌数据）
  Widget _buildFullTableForScreenshot() {
    if (_comparisonData.isEmpty) return const SizedBox.shrink();

    // 获取所有品牌
    Set<String> allBrands = {};
    for (var data in _comparisonData) {
      List<dynamic> brands = data['brands'] ?? [];
      for (var brand in brands) {
        String brandName =
            brand['brand']?['name'] ?? brand['brand']?['code'] ?? '未知品牌';
        allBrands.add(brandName);
      }
    }

    List<String> sortedBrands = allBrands.toList()..sort();

    // 计算表格宽度，确保有足够空间显示所有数据
    double tableWidth = 154 + (_comparisonData.length * 150.0); // 进一步增加列宽和缓冲空间

    return Container(
      width: tableWidth,
      margin: const EdgeInsets.all(16), // 减少外边距避免溢出
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 表头
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: kHeaderBackgroundColor,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300,),
              ),
            ),
            child: Row(
              children: [
                // 固定列表头
                Container(
                  width: 150,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Text(
                    '品牌/对象',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
          // 动态列表头
                ..._comparisonData.asMap().entries.map((entry) {
                  int index = entry.key;
                  var data = entry.value;
                  String name = data['location']['name'] ?? '未知';
                  Color columnColor = _getColumnColor(index);
                  return Container(
                    width: 150,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: columnColor.withOpacity(0.1),
                      border: Border(
                        left: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: columnColor.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // 汇总信息行
          Container(
            height: 60,
            child: Row(
              children: [
                Container(
                  width: 150,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    '汇总信息',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.orange,
                    ),
                  ),
                ),
          ..._comparisonData.asMap().entries.map((entry) {
            int index = entry.key;
            var data = entry.value;
            List<dynamic> brands = data['brands'] ?? [];
            int brandCount = brands.length;
            Color columnColor = _getColumnColor(index);
            return Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: columnColor.withOpacity(0.1),
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                '总计: $brandCount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: columnColor.withOpacity(0.8),
                ),
              ),
            );
          }).toList(),
              ],
            ),
          ),
          // 门店数量
          Container(
            height: 60,
            child: Row(
              children: [
                Container(
                  width: 150,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    '门店数量',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.orange,
                    ),
                  ),
                ),
          ..._comparisonData.asMap().entries.map((entry) {
            int index = entry.key;
            var data = entry.value;
                        String totalStores =
                data['summary']?['totalStores']?.toString() ?? '0';
            Color columnColor = _getColumnColor(index);
            return Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: columnColor.withOpacity(0.1),
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                '总计: $totalStores',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: columnColor.withOpacity(0.8),
                ),
              ),
            );
          }).toList(),
              ],
            ),
          ),
          // 综合总分行
          // Container(
          //   height: 60,
          //   child: Row(
          //     children: [
          //       Container(
          //         width: 150,
          //         padding: const EdgeInsets.all(16),
          //         decoration: BoxDecoration(
          //           border: Border(
          //             bottom: BorderSide(color: Colors.grey.shade300),
          //           ),
          //         ),
          //         alignment: Alignment.centerLeft,
          //         child: const Text(
          //           '综合总分',
          //           style: TextStyle(
          //             fontWeight: FontWeight.bold,
          //             fontSize: 14,
          //             color: Colors.green,
          //           ),
          //         ),
          //       ),
          //       ..._comparisonData.map((data) {
          //         double totalScore = double.tryParse(
          //                 data['summary']?['totalScore']?.toString() ??
          //                     '0.0') ??
          //             0.0;
          //         return Container(
          //           width: 150,
          //           padding: const EdgeInsets.all(12),
          //           decoration: BoxDecoration(
          //             border: Border(
          //               left: BorderSide(color: Colors.grey.shade300),
          //               bottom: BorderSide(color: Colors.grey.shade300),
          //             ),
          //           ),
          //           alignment: Alignment.centerLeft,
          //           child: Text(
          //             totalScore.toStringAsFixed(1),
          //             style: TextStyle(
          //               fontWeight: FontWeight.bold,
          //               fontSize: 12,
          //               color: _getScoreColor(totalScore),
          //             ),
          //           ),
          //         );
          //       }).toList(),
          //     ],
          //   ),
          // ),

          // 品牌数据行
          ...sortedBrands.map((brandName) {
            // 计算该品牌的平均分数
            double totalScore = 0.0;
            int validScoreCount = 0;

            for (var data in _comparisonData) {
              List<dynamic> brands = data['brands'] ?? [];
              var brandData = brands.firstWhere(
                (b) =>
                    (b['brand']?['name'] ?? b['brand']?['code']) == brandName,
                orElse: () => null,
              );
              if (brandData != null) {
                double score = double.tryParse(
                        brandData['averageScore']?.toString() ?? '0.0') ??
                    0.0;
                if (score > 0) {
                  totalScore += score;
                  validScoreCount++;
                }
              }
            }

            double averageScore =
                validScoreCount > 0 ? totalScore / validScoreCount : 0.0;

            return Container(
              height: 70,
              child: Row(
                children: [
                  Container(
                    width: 150,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: validScoreCount > 0
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  brandName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Container(
                                //   padding: const EdgeInsets.symmetric(
                                //       vertical: 2, horizontal: 4),
                                //   decoration: BoxDecoration(
                                //     color: _getBrandScoreColor(averageScore),
                                //     borderRadius: BorderRadius.circular(8),
                                //   ),
                                //   child: Text(
                                //     averageScore.round().toString(),
                                //     style: const TextStyle(
                                //       color: Colors.white,
                                //       fontSize: 9,
                                //       fontWeight: FontWeight.bold,
                                //     ),
                                //   ),
                                // ),
                              ],
                            )
                          : Text(
                              brandName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                    ),
                  ),
                  ..._comparisonData.asMap().entries.map((entry) {
                    int index = entry.key;
                       var data = entry.value;
                    List<dynamic> brands = data['brands'] ?? [];
                    Color columnColor = _getColumnColor(index);
                    var brandData = brands.firstWhere(
                      (b) =>
                          (b['brand']?['name'] ?? b['brand']?['code']) ==
                          brandName,
                      orElse: () => null,
                    );
                    return Container(
                      width: 150,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: columnColor.withOpacity(0.1),
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      child: brandData == null
                          ? const Text('-',
                              style: TextStyle(color: Colors.grey))
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${brandData['storeCount'] ?? 0}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                // const SizedBox(height: 2),
                                // Text(
                                //   '1',
                                //   style: TextStyle(
                                //     fontSize: 11,
                                //     color: _getScoreColor(1.0),
                                //     fontWeight: FontWeight.w500,
                                //   ),
                                // ),
                              ],
                            ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
          // 免责声明
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: const Text(
              '懂商帝: 分值采用自定义输入分数,仅作参考',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFFFFFFFF),
        title: Text(
          _title.isNotEmpty ? _title : '商场对比报告',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                       child: RepaintBoundary(
                      key: _tableKey,
                      child: _buildFullTableForScreenshot(),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                // padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _comparisonData.isNotEmpty
                            ? _captureAndShowImage
                            : null,
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('生成图片'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
