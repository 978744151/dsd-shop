import 'package:flutter/material.dart';
import 'package:flutter_echarts/flutter_echarts.dart';
import '../models/coach_data.dart';
import '../services/coach_service.dart';
import '../widgets/store_detail_dialog.dart';

class ShopDetailEcharts extends StatefulWidget {
  final String id;
  const ShopDetailEcharts({super.key, required this.id});

  @override
  State<ShopDetailEcharts> createState() => _ShopDetailEchartsState();
}

class _ShopDetailEchartsState extends State<ShopDetailEcharts> {
  String currentView = 'china'; // 'china' 或 'province'
  String selectedProvince = '';
  String selectedCity = '';
  List<CoachData> currentStores = [];
  bool showStoreDialog = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final coachData = CoachService.getMockCoachData();
    setState(() {
      currentStores = coachData;
    });
  }

  String _getChinaMapOption() {
    final data = CoachService.getProvinceMapData();
    final dataJson = data
        .map((item) => {
              'name': item['name'],
              'value': item['value'],
            })
        .toList();

    return '''
    {
      "title": {
        "text": "Coach门店分布图",
        "subtext": "点击省份查看详情",
        "left": "center",
        "textStyle": {
          "color": "#1E3A8A",
          "fontSize": 20,
          "fontWeight": "bold"
        },
        "subtextStyle": {
          "color": "#6B7280",
          "fontSize": 14
        }
      },
      "tooltip": {
        "trigger": "item",
        "formatter": function(params) {
          if (params.data && params.data.value) {
            return params.name + '<br/>Coach数量: ' + params.data.value + '人';
          }
          return params.name + '<br/>暂无数据';
        },
        "backgroundColor": "rgba(255,255,255,0.9)",
        "borderColor": "#1E3A8A",
        "borderWidth": 1,
        "textStyle": {
          "color": "#1F2937"
        }
      },
      "visualMap": {
        "min": 0,
        "max": 30,
        "left": "left",
        "top": "bottom",
        "text": ["高", "低"],
        "calculable": true,
        "inRange": {
          "color": ["#E0F2FE", "#0EA5E9", "#1E3A8A"]
        },
        "textStyle": {
          "color": "#1F2937"
        }
      },
      "series": [{
        "name": "Coach数量",
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
        "data": $dataJson
      }]
    }
    ''';
  }

  String _getProvinceMapOption(String provinceName) {
    final data = CoachService.getCityMapData(provinceName);
    final dataJson = data
        .map((item) => {
              'name': item['name'],
              'value': item['value'],
            })
        .toList();

    return '''
    {
      "title": {
        "text": "$provinceName Coach分布",
        "subtext": "点击城市查看门店详情",
        "left": "center",
        "textStyle": {
          "color": "#1E3A8A",
          "fontSize": 18,
          "fontWeight": "bold"
        },
        "subtextStyle": {
          "color": "#6B7280",
          "fontSize": 12
        }
      },
      "tooltip": {
        "trigger": "item",
        "formatter": function(params) {
          if (params.data && params.data.value) {
            return params.name + '<br/>Coach数量: ' + params.data.value + '人';
          }
          return params.name + '<br/>暂无数据';
        },
        "backgroundColor": "rgba(255,255,255,0.9)",
        "borderColor": "#1E3A8A",
        "borderWidth": 1,
        "textStyle": {
          "color": "#1F2937"
        }
      },
      "visualMap": {
        "min": 0,
        "max": 20,
        "left": "left",
        "top": "bottom",
        "text": ["高", "低"],
        "calculable": true,
        "inRange": {
          "color": ["#E0F2FE", "#0EA5E9", "#1E3A8A"]
        },
        "textStyle": {
          "color": "#1F2937"
        }
      },
      "series": [{
        "name": "Coach数量",
        "type": "map",
        "map": "$provinceName",
        "roam": true,
        "zoom": 1.5,
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
        "data": $dataJson
      }]
    }
    ''';
  }

  void _onMapClick(String name) {
    if (currentView == 'china') {
      // 点击省份，切换到省份视图
      setState(() {
        currentView = 'province';
        selectedProvince = name;
        selectedCity = '';

        // 获取该省份的门店数据
        final coachData = CoachService.getMockCoachData();
        currentStores =
            coachData.where((store) => store.province == name).toList();
      });
    } else if (currentView == 'province') {
      // 点击城市，显示门店详情
      setState(() {
        selectedCity = name;

        // 获取该城市的门店数据
        final coachData = CoachService.getMockCoachData();
        currentStores = coachData
            .where((store) =>
                store.province == selectedProvince && store.city == name)
            .toList();

        showStoreDialog = true;
      });
    }
  }

  void _onMapClickValue(String name, int value) {
    if (currentView == 'china') {
      // 点击省份数值，显示该省份所有门店
      setState(() {
        selectedProvince = name;
        selectedCity = '';

        // 获取该省份的门店数据
        final coachData = CoachService.getMockCoachData();
        currentStores =
            coachData.where((store) => store.province == name).toList();

        showStoreDialog = true;
      });
    } else if (currentView == 'province') {
      // 点击城市数值，显示该城市门店
      setState(() {
        selectedCity = name;

        // 获取该城市的门店数据
        final coachData = CoachService.getMockCoachData();
        currentStores = coachData
            .where((store) =>
                store.province == selectedProvince && store.city == name)
            .toList();

        showStoreDialog = true;
      });
    }
  }

  void _backToChina() {
    setState(() {
      currentView = 'china';
      selectedProvince = '';
      selectedCity = '';
      _loadInitialData();
    });
  }

  void _closeStoreDialog() {
    setState(() {
      showStoreDialog = false;
    });
  }

  // 模拟点击省份的方法
  void _simulateProvinceClick(String provinceName) {
    _onMapClick(provinceName);
  }

  // 模拟点击城市的方法
  void _simulateCityClick(String cityName) {
    _onMapClick(cityName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          currentView == 'china' ? 'Coach门店分布图' : '$selectedProvince Coach分布',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        leading: currentView == 'province'
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _backToChina,
              )
            : null,
        actions: [
          if (currentView == 'province')
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _backToChina,
              tooltip: '返回全国视图',
            ),
        ],
      ),
      body: Stack(
        children: [
          // 地图容器
          Container(
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
              child: Stack(
                children: [
                  // ECharts地图
                  Echarts(
                    option: currentView == 'china'
                        ? _getChinaMapOption()
                        : _getProvinceMapOption(selectedProvince),
                  ),

                  // 模拟点击区域（用于演示）
                  if (currentView == 'china')
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Column(
                        children: [
                          _buildQuickAccessButton('北京', 27),
                          const SizedBox(height: 8),
                          _buildQuickAccessButton('上海', 38),
                          const SizedBox(height: 8),
                          _buildQuickAccessButton('广东', 30),
                          const SizedBox(height: 8),
                          _buildQuickAccessButton('浙江', 18),
                        ],
                      ),
                    ),

                  if (currentView == 'province')
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Column(
                        children: [
                          _buildQuickAccessButton('广州市', 14),
                          const SizedBox(height: 8),
                          _buildQuickAccessButton('深圳市', 16),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 门店详情弹框
          if (showStoreDialog)
            Positioned(
              right: 16,
              top: 16,
              bottom: 16,
              child: StoreDetailDialog(
                title: selectedCity.isNotEmpty
                    ? '$selectedProvince - $selectedCity 门店详情'
                    : '$selectedProvince 门店详情',
                stores: currentStores,
                onClose: _closeStoreDialog,
              ),
            ),

          // 统计信息卡片
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentView == 'china' ? '全国统计' : '$selectedProvince 统计',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '门店数量: ${currentStores.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    'Coach总数: ${currentStores.fold(0, (sum, store) => sum + store.coachCount)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessButton(String name, int value) {
    return GestureDetector(
      onTap: () => currentView == 'china'
          ? _simulateProvinceClick(name)
          : _simulateCityClick(name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '$name ($value)',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
