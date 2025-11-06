import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import '../utils/screenshot_util.dart';
import '../widgets/store_detail_dialog.dart';
import '../models/coach_data.dart';

/// 对比表格组件，可复用的表格展示和截图功能
class ComparisonTableWidget extends StatelessWidget {
  final List<Map<String, dynamic>> comparisonData;
  final String title;
  final bool showScreenshotButton;
  final ScreenshotController? screenshotController;
  final Widget Function(List<Map<String, dynamic>> data)? customTableBuilder;
  final Color headerBackgroundColor;
  final List<Color>? columnColors;
  final bool isCity; // 是否为城市选择，用于控制字体大小

  const ComparisonTableWidget({
    Key? key,
    required this.comparisonData,
    this.title = '对比表格',
    this.showScreenshotButton = true,
    this.screenshotController,
    this.customTableBuilder,
    this.headerBackgroundColor = const Color(0xFFF5F5F5),
    this.columnColors,
    this.isCity = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller =
        screenshotController ?? ScreenshotUtil.createController();

    return Column(
      children: [
        // Padding(
        //   padding: const EdgeInsets.all(0),
        //   child: ElevatedButton.icon(
        //     onPressed: () => _captureAndShowImage(context, controller),
        //     icon: const Icon(Icons.camera_alt),
        //     label: const Text('生成表格图片'),
        //     style: ElevatedButton.styleFrom(
        //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        //     ),
        //   ),
        // ),

        // 可滚动的表格显示区域
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Screenshot(
                controller: controller,
                child: customTableBuilder?.call(comparisonData) ??
                    _buildDefaultTable(context),
              ),
            ),
          ),
        ),
        // 截图按钮
        if (showScreenshotButton)
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
                    onPressed: () => _captureAndShowImage(context, controller),
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
    );
  }

  /// 生成截图并显示
  Future<void> _captureAndShowImage(
      BuildContext context, ScreenshotController controller) async {
    await ScreenshotUtil.captureAndShowImage(
      context: context,
      controller: controller,
      errorMessage: '表格截图生成失败，请重试',
    );
  }

  /// 构建默认表格
  Widget _buildDefaultTable(BuildContext context) {
    if (comparisonData.isEmpty) return const SizedBox.shrink();

    // 获取所有品牌及其平均分值
    final Map<String, List<double>> brandScoreMap = {};
    for (var data in comparisonData) {
      List<dynamic> brands = data['brands'] ?? [];
      for (var brand in brands) {
        String brandName =
            brand['brand']?['name'] ?? brand['brand']?['code'] ?? '未知品牌';
        // 支持两种字段：averageScore 或 totalScore
        final String? scoreStr = brand['totalScore']?.toString();
        final double? score =
            scoreStr != null ? double.tryParse(scoreStr) : null;
        if (score != null) {
          brandScoreMap.putIfAbsent(brandName, () => []);
          brandScoreMap[brandName]!.add(score);
        } else {
          brandScoreMap.putIfAbsent(brandName, () => []);
        }
      }
    }

    // 计算平均分值并排序品牌名称
    final List<Map<String, dynamic>> sortedBrands = brandScoreMap.entries
        .map((e) {
      final List<double> values = e.value;
      final double avg = values.isEmpty
          ? 0.0
          : (values.reduce((a, b) => a + b) / values.length);
      return {
        'name': e.key,
        'score': avg,
      };
    }).toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    // 计算表格宽度
    double tableWidth = 142 + (comparisonData.length * 110.0);

    return Container(
      width: tableWidth,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1),
        // borderRadius: BorderRadius.circular(12),
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
          _buildTableHeader(),

          // 品牌数量行
          _buildBrandCountRow(),

          // 门店数量行
          _buildStoreCountRow(),

          // 综合总分行
          _buildTotalScoreRow(),

          // 品牌数据行（传入品牌名称与总分/平均分）
          ...sortedBrands.map((b) =>
              _buildBrandDataRow(b['name'] as String, (b['score'] as double))),

          // 免责声明
          _buildDisclaimer(),
        ],
      ),
    );
  }

  /// 构建表头
  Widget _buildTableHeader() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: headerBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 固定列表头
          Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isCity ? 14 : 10, // 根据是否选择城市设置字体大小
                color: Colors.black,
              ),
            ),
          ),
          // 动态列头
          ...comparisonData.asMap().entries.map((entry) {
            int index = entry.key;
            var data = entry.value;
            String locationName =
                data['location']?['name']?.toString() ?? '未知地区';
            Color columnColor = _getColumnColor(index);
            return Container(
              width: 110,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: columnColor.withOpacity(0.2),
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                locationName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isCity ? 14 : 10, // 根据是否选择城市设置字体大小
                  color: columnColor,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 构建品牌数量行
  Widget _buildBrandCountRow() {
    return Container(
      height: 60,
      child: Row(
        children: [
          Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: const Text(
              '品牌数量',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
          ),
          ...comparisonData.asMap().entries.map((entry) {
            int index = entry.key;
            var data = entry.value;
            String totalStores =
                data['summary']?['totalStores']?.toString() ?? '0';
            Color columnColor = _getColumnColor(index);
            return Container(
              width: 110,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: columnColor.withOpacity(0.2),
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                totalStores,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: columnColor,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 构建门店数量行
  Widget _buildStoreCountRow() {
    return Container(
      height: 60,
      child: Row(
        children: [
          Container(
            width: 140,
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
                color: Colors.blue,
              ),
            ),
          ),
          ...comparisonData.asMap().entries.map((entry) {
            int index = entry.key;
            var data = entry.value;
            String totalStores =
                data['summary']?['totalStores']?.toString() ?? '0';
            Color columnColor = _getColumnColor(index);
            return Container(
              width: 110,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: columnColor.withOpacity(0.2),
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                totalStores,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: columnColor,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
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

  /// 构建综合总分行
  Widget _buildTotalScoreRow() {
    return Container(
      height: 60,
      child: Row(
        children: [
          Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: const Text(
              '综合总分',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
          ),
          ...comparisonData.asMap().entries.map((entry) {
            int index = entry.key;
            var data = entry.value;
            String totalScore =
                data['summary']?['totalScore']?.toString() ?? '0';
            Color columnColor = _getColumnColor(index);
            return Container(
              width: 110,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: columnColor.withOpacity(0.2),
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                totalScore,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 构建品牌数据行
  Widget _buildBrandDataRow(String brandName, double averageScore) {
    return Container(
      height: 60,
      child: Row(
        children: [
          Container(
            width: 140,
            padding: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                // color: Color(0xFF4e65ff).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  Text(
                    brandName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.black,
                    ),
                  ),
                  if (averageScore > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 4),
                      decoration: BoxDecoration(
                        color: _getBrandScoreColor(averageScore),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        averageScore.round().toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          ...comparisonData.asMap().entries.map((entry) {
            int index = entry.key;
            var data = entry.value;
            List<dynamic> brands = data['brands'] ?? [];
            var brandData = brands.firstWhere(
              (b) => (b['brand']?['name'] ?? b['brand']?['code']) == brandName,
              orElse: () => null,
            );
            Color columnColor = _getColumnColor(index);
            return Container(
              width: 110,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: columnColor.withOpacity(0.2),
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              alignment: Alignment.center,
              child: brandData == null
                  ? Text('', style: TextStyle(color: columnColor))
                  : Builder(builder: (ctx) {
                      return InkWell(
                        onTap: () {
                          final String locationName =
                              data['location']?['name']?.toString() ?? '';
                          final List<dynamic> rawStores =
                              (brandData['stores'] as List<dynamic>?) ?? [];
                          final List<CoachData> stores = rawStores
                              .map((e) => CoachData.fromJson(
                                  (e as Map<String, dynamic>)))
                              .toList();
                          final String dialogTitle =
                              '${locationName.isEmpty ? '' : '$locationName - '}$brandName 门店';
                          _showStoreDialog(ctx, dialogTitle, stores);
                        },
                        child: Text(
                          '${brandData['storeCount'] ?? 0}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      );
                    }),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showStoreDialog(
      BuildContext context, String title, List<CoachData> stores) {
    // 避免在构建阶段进行导航，延迟到帧结束后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        useRootNavigator: true,
        barrierDismissible: true,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: StoreDetailDialog(
            title: title,
            stores: stores,
            onClose: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ),
      );
    });
  }

  /// 构建免责声明
  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: const Text(
        '懂商帝: 分值采用用户自定义输入分数,仅作统计参考',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 获取列颜色
  Color _getColumnColor(int index) {
    if (columnColors != null && index < columnColors!.length) {
      return columnColors![index];
    }
    // 默认颜色列表
    final defaultColors = [
      Colors.blue,
      Colors.pink,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.cyan,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.lime,
    ];
    return defaultColors[index % defaultColors.length];
  }

  /// 获取分数颜色
  Color _getScoreColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    if (score >= 4.0) return Colors.red;
    return Colors.grey;
  }
}
