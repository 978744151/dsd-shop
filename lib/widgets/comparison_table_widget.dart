import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import '../utils/screenshot_util.dart';
import '../widgets/store_detail_dialog.dart';
import '../utils/http_client.dart';
import '../api/brand.dart';

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
  final Color headerTextColor;
  final Color cellTextColor;
  final Color borderColor;
  final Color firstColumnColor;
  final double rowHeight;
  final bool isOla;
  const ComparisonTableWidget(
      {Key? key,
      required this.comparisonData,
      this.title = '对比表格',
      this.showScreenshotButton = true,
      this.screenshotController,
      this.customTableBuilder,
      this.headerBackgroundColor = const Color(0xFFF5F5F5),
      this.columnColors,
      this.isCity = false,
      this.headerTextColor = Colors.black,
      this.cellTextColor = Colors.black,
      this.borderColor = const Color(0xFFe0e0e0),
      this.firstColumnColor = const Color(0xFFF5F5F5),
      this.rowHeight = 50,
      this.isOla = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller =
        screenshotController ?? ScreenshotUtil.createController();

    return Column(
      children: [
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

  // 筛选面板入口已移动至 ComparePage 的 AppBar 区域

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

    final List<Map<String, dynamic>> sortedBrands =
        brandScoreMap.entries.map((e) {
      final List<double> values = e.value;
      final double avg = values.isEmpty
          ? 0.0
          : (values.reduce((a, b) => a + b) / values.length);
      return {
        'name': e.key,
        'score': avg,
      };
    }).toList();
    // ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    double tableWidth = 142 + (comparisonData.length * 110.0);

    return Container(
      width: tableWidth,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
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
          _buildTableHeader(),
          _buildBrandCountRow(),
          _buildStoreCountRow(),
          _buildTotalScoreRow(),
          ...sortedBrands.map((b) =>
              _buildBrandDataRow(b['name'] as String, (b['score'] as double))),
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
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          // 固定列表头
          Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isCity ? 14 : 14, // 根据是否选择城市设置字体大小
                color: headerTextColor,
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
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 5),
              decoration: BoxDecoration(
                color: columnColor,
                border: Border(
                  left: BorderSide(color: borderColor),
                  // bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                locationName,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isCity ? 14 : 12, // 根据是否选择城市设置字体大小
                  color: cellTextColor,
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
      height: rowHeight,
      child: Row(
        children: [
          Container(
            width: 140,
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor),
                ),
                color: firstColumnColor),
            alignment: Alignment.centerLeft,
            child: Text(
              '品牌数量',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: headerTextColor,
              ),
            ),
          ),
          ...comparisonData.asMap().entries.map((entry) {
            int index = entry.key;
            var data = entry.value;
            String totalStores =
                data['summary']?['totalBrands']?.toString() ?? '0';
            Color columnColor = _getColumnColor(index);
            return Container(
              width: 110,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: columnColor,
                border: Border(
                  left: BorderSide(color: borderColor),
                  bottom: BorderSide(color: borderColor),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                totalStores,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: cellTextColor,
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
      height: rowHeight,
      child: Row(
        children: [
          Container(
            width: 140,
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor),
                ),
                color: firstColumnColor),
            alignment: Alignment.centerLeft,
            child: Text(
              '门店数量',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: headerTextColor,
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
                color: columnColor,
                border: Border(
                  left: BorderSide(color: borderColor),
                  bottom: BorderSide(color: borderColor),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                totalStores,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: cellTextColor,
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
      height: rowHeight,
      child: Row(
        children: [
          Container(
            width: 140,
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor),
                ),
                color: firstColumnColor),
            alignment: Alignment.centerLeft,
            child: Text(
              '综合总分',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: headerTextColor,
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
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              decoration: BoxDecoration(
                color: columnColor,
                border: Border(
                  left: BorderSide(color: borderColor),
                  bottom: BorderSide(color: borderColor),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                totalScore,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: cellTextColor,
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
      height: rowHeight,
      child: Row(
        children: [
          Container(
            width: 140,
            padding: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
              color: firstColumnColor,
            ),
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  Text(
                    brandName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: cellTextColor,
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
                color: columnColor,
                border: Border(
                  left: BorderSide(color: borderColor),
                  bottom: BorderSide(color: borderColor),
                ),
              ),
              alignment: Alignment.center,
              child: brandData == null
                  ? Text('', style: TextStyle(color: cellTextColor))
                  : Builder(builder: (ctx) {
                      return InkWell(
                        onTap: () async {
                          final String locationName =
                              data['location']?['name']?.toString() ?? '';
                          final String? locationId =
                              data['location']?['id']?.toString();
                          final String? brandId =
                              brandData?['brand']['_id']?.toString();

                          List<dynamic> stores = [];
                          bool fetched = false;
                          print(
                              'locationName: $locationName, locationId: $locationId, brandId: $brandData');
                          // 优先调用接口获取门店数据，按需传入 cityId 和 brandId
                          if (locationId != null &&
                              locationId.isNotEmpty &&
                              brandId != null &&
                              brandId.isNotEmpty) {
                            try {
                              final response = await HttpClient.get(
                                brandApi.getBrandDetail,
                                params: {
                                  'brandId': brandId,
                                  'cityId': locationId,
                                  'limit': 999,
                                  'isOla': isOla
                                },
                              );
                              if (response['success'] == true) {
                                final List<dynamic> storeData =
                                    (response['data']?['stores'] ?? [])
                                        as List<dynamic>;
                                // 直接保留原始 Map 列表，不做 CoachData 转换
                                stores =
                                    List<Map<String, dynamic>>.from(storeData);
                                fetched = true;
                              }
                            } catch (_) {
                              // 忽略错误，回退到已有数据
                            }
                          }

                          // 接口未成功或参数缺失时，回退到已有数据中的 stores
                          if (!fetched) {
                            final List<dynamic> rawStores =
                                (brandData['stores'] as List<dynamic>?) ?? [];
                            // 回退时也直接使用原始数据
                            stores = rawStores;
                          }

                          final String dialogTitle =
                              '${locationName.isEmpty ? '' : '$locationName - '}$brandName 门店';
                          _showStoreDialog(ctx, dialogTitle, stores);
                        },
                        child: Text(
                          '${brandData['storeCount'] ?? 0}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: cellTextColor,
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
      BuildContext context, String title, List<dynamic> stores) {
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
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: const Text(
        '更多商业信息就在 懂商帝',
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
  Color _getColumnColor(int index, {String role = 'background'}) {
    // 基础色板：优先使用外部传入的 columnColors
    final List<Color> defaultColors = const [
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
    final Color base = (columnColors != null && index < columnColors!.length)
        ? columnColors![index]
        : defaultColors[index % defaultColors.length];

    if (role == 'background') {
      return base;
    }

    // 根据亮度计算文字与边框颜色
    final double luminance = base.computeLuminance();
    final bool isDark = luminance < 0.5;
    switch (role) {
      case 'text':
      case 'headerText':
        return isDark ? Colors.white : Colors.black;
      case 'border':
        // 边框采用与文字同色的轻度透明以提升对比度
        final Color overlay = isDark ? Colors.white : Colors.black;
        return overlay.withOpacity(0.18);
      default:
        return base;
    }
  }

  /// 获取分数颜色
  Color _getScoreColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    if (score >= 4.0) return Colors.red;
    return Colors.grey;
  }
}
