import 'package:flutter/material.dart';
import '../widgets/comparison_table_widget.dart';
import '../services/screenshot_service.dart';

/// 示例对比页面，演示如何使用封装后的对比表格组件
class ExampleComparisonPage extends StatefulWidget {
  const ExampleComparisonPage({Key? key}) : super(key: key);

  @override
  State<ExampleComparisonPage> createState() => _ExampleComparisonPageState();
}

class _ExampleComparisonPageState extends State<ExampleComparisonPage> {
  // 示例数据
  final List<Map<String, dynamic>> _sampleData = [
    {
      'location': {'name': '北京'},
      'summary': {
        'totalScore': 8.5,
        'totalStores': 125,
      },
      'brands': [
        {
          'brand': {'name': '星巴克', 'code': 'STARBUCKS'},
          'storeCount': 45,
          'averageScore': 8.2,
        },
        {
          'brand': {'name': '瑞幸咖啡', 'code': 'LUCKIN'},
          'storeCount': 38,
          'averageScore': 7.8,
        },
        {
          'brand': {'name': 'Costa', 'code': 'COSTA'},
          'storeCount': 22,
          'averageScore': 8.0,
        },
        {
          'brand': {'name': '太平洋咖啡', 'code': 'PACIFIC'},
          'storeCount': 20,
          'averageScore': 7.5,
        },
      ],
    },
    {
      'location': {'name': '上海'},
      'summary': {
        'totalScore': 8.8,
        'totalStores': 156,
      },
      'brands': [
        {
          'brand': {'name': '星巴克', 'code': 'STARBUCKS'},
          'storeCount': 52,
          'averageScore': 8.5,
        },
        {
          'brand': {'name': '瑞幸咖啡', 'code': 'LUCKIN'},
          'storeCount': 48,
          'averageScore': 8.2,
        },
        {
          'brand': {'name': 'Costa', 'code': 'COSTA'},
          'storeCount': 28,
          'averageScore': 8.3,
        },
        {
          'brand': {'name': '太平洋咖啡', 'code': 'PACIFIC'},
          'storeCount': 28,
          'averageScore': 8.0,
        },
      ],
    },
    {
      'location': {'name': '深圳'},
      'summary': {
        'totalScore': 8.2,
        'totalStores': 98,
      },
      'brands': [
        {
          'brand': {'name': '星巴克', 'code': 'STARBUCKS'},
          'storeCount': 35,
          'averageScore': 8.0,
        },
        {
          'brand': {'name': '瑞幸咖啡', 'code': 'LUCKIN'},
          'storeCount': 32,
          'averageScore': 7.9,
        },
        {
          'brand': {'name': 'Costa', 'code': 'COSTA'},
          'storeCount': 18,
          'averageScore': 7.8,
        },
        {
          'brand': {'name': '太平洋咖啡', 'code': 'PACIFIC'},
          'storeCount': 13,
          'averageScore': 7.2,
        },
      ],
    },
  ];

  // 自定义列颜色
  final List<Color> _customColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('对比表格组件示例'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面说明
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '组件功能演示',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '这个页面演示了封装后的对比表格组件的使用方法：',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• 可复用的表格组件\n'
                      '• 内置截图功能\n'
                      '• 自定义颜色配置\n'
                      '• 响应式布局\n'
                      '• 统一的样式风格',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 基础用法示例
            const Text(
              '基础用法',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            
            ComparisonTableWidget(
              comparisonData: _sampleData,
              title: '咖啡店对比分析',
              columnColors: _customColors,
            ),
            
            const SizedBox(height: 30),
            
            // 无截图按钮示例
            const Text(
              '无截图按钮版本',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            
            ComparisonTableWidget(
              comparisonData: _sampleData,
              title: '简化版表格',
              showScreenshotButton: false,
              headerBackgroundColor: Colors.grey.shade100,
            ),
            
            const SizedBox(height: 30),
            
            // 使用说明
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '使用说明',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '在其他页面使用这个组件：',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'import \'../widgets/comparison_table_widget.dart\';\n\n'
                        'ComparisonTableWidget(\n'
                        '  comparisonData: yourData,\n'
                        '  title: \'你的标题\',\n'
                        '  columnColors: yourColors,\n'
                        ')',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 服务类使用示例
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '截图服务使用',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '也可以单独使用截图服务：',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'import \'../services/screenshot_service.dart\';\n\n'
                        '// 创建控制器\n'
                        'final controller = ScreenshotService.createController();\n\n'
                        '// 截图并显示\n'
                        'await ScreenshotService.captureAndShowPreview(\n'
                        '  context: context,\n'
                        '  controller: controller,\n'
                        ');',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}