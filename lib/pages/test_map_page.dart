import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_echarts/flutter_echarts.dart';

class TestMapPage extends StatefulWidget {
  const TestMapPage({super.key});

  @override
  State<TestMapPage> createState() => _TestMapPageState();
}

class _TestMapPageState extends State<TestMapPage> {
  String? _chinaJsonString;

  @override
  void initState() {
    super.initState();
    _loadChinaJson();
  }

  Future<void> _loadChinaJson() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/map/json/china-cities.json');
      final dynamic parsed = jsonString.isEmpty ? {} : json.decode(jsonString);
      final compact = json.encode(parsed);
      setState(() {
        _chinaJsonString = compact;
      });
    } catch (e) {
      setState(() {
        _chinaJsonString = '{}';
      });
    }
  }

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
          child: _chinaJsonString == null
              ? const Center(child: CircularProgressIndicator())
              : Echarts(
                  key: UniqueKey(),
                  option: '''

                  {
        title: {
            text: '中国地图',
            left: 'center',
            textStyle: {
                color: '#333'
            }
        },
        tooltip: {
            trigger: 'item',
            formatter: '{b}'
        },
        visualMap: {
            min: 0,
            max: 1000,
            left: 'left',
            top: 'bottom',
            text: ['高', '低'],
            calculable: true,
            inRange: {
                color: ['#e0ffff', '#006edd']
            }
        },
        series: [
            {
                name: '中国地图',
                type: 'map',
                map: 'china',
                roam: true,
                label: {
                    show: true,
                    fontSize: 12
                },
                emphasis: {
                    label: {
                        show: true
                    },
                    itemStyle: {
                        areaColor: '#ffeaa7'
                    }
                },
                data: [
                    { name: '北京', value: 177 },
                    { name: '天津', value: 42 },
                    { name: '河北', value: 102 },
                    { name: '山西', value: 81 },
                    { name: '内蒙古', value: 47 },
                    { name: '辽宁', value: 67 },
                    { name: '吉林', value: 82 },
                    { name: '黑龙江', value: 123 },
                    { name: '上海', value: 24 },
                    { name: '江苏', value: 92 },
                    { name: '浙江', value: 114 },
                    { name: '安徽', value: 109 },
                    { name: '福建', value: 116 },
                    { name: '江西', value: 91 },
                    { name: '山东', value: 119 },
                    { name: '河南', value: 137 },
                    { name: '湖北', value: 116 },
                    { name: '湖南', value: 114 },
                    { name: '重庆', value: 91 },
                    { name: '四川', value: 125 },
                    { name: '贵州', value: 62 },
                    { name: '云南', value: 83 },
                    { name: '西藏', value: 9 },
                    { name: '陕西', value: 80 },
                    { name: '甘肃', value: 56 },
                    { name: '青海', value: 10 },
                    { name: '宁夏', value: 18 },
                    { name: '新疆', value: 67 },
                    { name: '广东', value: 123 },
                    { name: '广西', value: 59 },
                    { name: '海南', value: 14 }
                ]
            }
        ]
    }
                  ''',
                  extraScript: '''
                    try {
                      var chinaGeoJson = ${_chinaJsonString!};
                      echarts.registerMap('china', chinaGeoJson);
                    } catch (e) {
                      console.error('注册中国地图失败:', e);
                    }
                  ''',
                ),
        ),
      ),
    );
  }
}
