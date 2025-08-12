import 'package:flutter/material.dart';
import 'package:flutter_echarts/flutter_echarts.dart';

class TestMapPage extends StatefulWidget {
  const TestMapPage({super.key});

  @override
  State<TestMapPage> createState() => _TestMapPageState();
}

class _TestMapPageState extends State<TestMapPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ECharts地图测试'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Echarts(
            option: '''
            {
              "title": {
                "text": "中国地图测试",
                "left": "center",
                "textStyle": {
                  "color": "#1E3A8A",
                  "fontSize": 20,
                  "fontWeight": "bold"
                }
              },
              "tooltip": {
                "trigger": "item",
                "formatter": "{b}<br/>测试数据: {c}"
              },
              "visualMap": {
                "min": 0,
                "max": 100,
                "left": "left",
                "top": "bottom",
                "text": ["高", "低"],
                "calculable": true,
                "inRange": {
                  "color": ["#E0F2FE", "#0EA5E9", "#1E3A8A"]
                }
              },
              "series": [{
                "name": "测试数据",
                "type": "map",
                "map": "china",
                "roam": true,
                "zoom": 1.2,
                "center": [105, 36],
                "label": {
                  "show": true,
                  "fontSize": 10,
                  "color": "#1F2937"
                },
                "emphasis": {
                  "label": {
                    "show": true,
                    "fontSize": 12,
                    "color": "#1F2937"
                  },
                  "itemStyle": {
                    "areaColor": "#FEF3C7",
                    "borderColor": "#1E3A8A",
                    "borderWidth": 2
                  }
                },
                "itemStyle": {
                  "borderColor": "#E5E7EB",
                  "borderWidth": 1
                },
                "data": [
                  {"name": "北京", "value": 50},
                  {"name": "上海", "value": 80},
                  {"name": "广东", "value": 70},
                  {"name": "浙江", "value": 60},
                  {"name": "江苏", "value": 40},
                  {"name": "四川", "value": 30},
                  {"name": "湖北", "value": 25},
                  {"name": "陕西", "value": 20}
                ]
              }]
            }
            ''',
          ),
        ),
      ),
    );
  }
}
