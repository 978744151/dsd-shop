import 'package:flutter/material.dart';
import '../utils/http_client.dart';
import '../api/brand.dart';
import '../widgets/comparison_table_widget.dart';
import '../utils/screenshot_util.dart';

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

 final GlobalKey _tableBoundaryKey = ScreenshotUtil.createBoundaryKey();
  @override
  void initState() {
    super.initState();
    _fetchReportDetail();
  }

  Future<void> _captureAndShowImage(BuildContext context) async {
    await ScreenshotUtil.captureAndShowImage(
      context: context,
      errorMessage: '表格截图生成失败，请重试',
    );
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
                child:  RepaintBoundary(
                  key: _tableBoundaryKey, // Wrap the table with the unique boundary key
                 child: ComparisonTableWidget(
                   comparisonData: _comparisonData,
                    title: _title,
                    showScreenshotButton: false,
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
                        onPressed: () => _captureAndShowImage(context,),
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