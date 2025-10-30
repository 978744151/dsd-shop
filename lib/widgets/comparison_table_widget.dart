import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import '../utils/screenshot_util.dart';

/// 对比表格组件，可复用的表格展示和截图功能
class ComparisonTableWidget extends StatelessWidget {
  final List<Map<String, dynamic>> comparisonData;
  final String title;
  final bool showScreenshotButton;
  final ScreenshotController? screenshotController;
  final Widget Function(List<Map<String, dynamic>> data)? customTableBuilder;
  final Color headerBackgroundColor;
  final List<Color>? columnColors;

  const ComparisonTableWidget({
    Key? key,
    required this.comparisonData,
    this.title = '对比表格',
    this.showScreenshotButton = true,
    this.screenshotController,
    this.customTableBuilder,
    this.headerBackgroundColor = const Color(0xFFF5F5F5),
    this.columnColors,
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

    // 获取所有品牌
    Set<String> allBrands = {};
    for (var data in comparisonData) {
      List<dynamic> brands = data['brands'] ?? [];
      for (var brand in brands) {
        String brandName =
            brand['brand']?['name'] ?? brand['brand']?['code'] ?? '未知品牌';
        allBrands.add(brandName);
      }
    }

    List<String> sortedBrands = allBrands.toList()..sort();

    // 计算表格宽度
    double tableWidth = 154 + (comparisonData.length * 150.0);

    return Container(
      width: tableWidth,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 2),
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
          // _buildTotalScoreRow(),

          // 品牌数据行
          ...sortedBrands.map((brandName) => _buildBrandDataRow(brandName)),

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
          bottom: BorderSide(color: Colors.grey.shade300, width: 2),
        ),
      ),
      child: Row(
        children: [
          // 固定列表头
          Container(
            width: 150,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Text(
              '品牌',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          // 动态列表头
          ...comparisonData.asMap().entries.map((entry) {
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
    );
  }

  /// 构建品牌数量行
  Widget _buildBrandCountRow() {
    return Container(
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
              '品牌数量',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.orange,
              ),
            ),
          ),
          ...comparisonData.asMap().entries.map((entry) {
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
    );
  }

  /// 构建门店数量行
  Widget _buildStoreCountRow() {
    return Container(
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
                totalStores,
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
    );
  }

  /// 构建综合总分行
  Widget _buildTotalScoreRow() {
    return Container(
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
              '综合总分',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.green,
              ),
            ),
          ),
          ...comparisonData.asMap().entries.map((entry) {
            int index = entry.key;
            var data = entry.value;
            double totalScore = double.tryParse(
                    data['summary']?['totalScore']?.toString() ?? '0.0') ??
                0.0;
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
                totalScore.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: _getScoreColor(totalScore),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 构建品牌数据行
  Widget _buildBrandDataRow(String brandName) {
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
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                brandName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
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
                  ? Text('-',
                      style: TextStyle(color: columnColor.withOpacity(0.6)))
                  : Text(
                      '${brandData['storeCount'] ?? 0}',
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
    );
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

  /// 获取分数颜色
  Color _getScoreColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    if (score >= 4.0) return Colors.red;
    return Colors.grey;
  }
}
