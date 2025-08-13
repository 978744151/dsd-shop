import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_echarts/flutter_echarts.dart';

class SimpleMapPage extends StatefulWidget {
  const SimpleMapPage({super.key});

  @override
  State<SimpleMapPage> createState() => _SimpleMapPageState();
}

class _SimpleMapPageState extends State<SimpleMapPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String? _chinaJsonString; // 全国 GeoJSON 字符串
  String? _currentMapJsonString; // 当前展示的地图 GeoJSON 字符串
  String _currentMapKey = ''; // eCharts 中 map 的 key
  bool _isProvince = false; // 是否为省份视图
  Map<String, String> _provinceNameToId = {}; // 省份中文名 -> 行政区划代码 id

  // 中文名 -> 标准拼音（小写、无分隔符）
  static const Map<String, String> _nameToPinyin = {
    '北京': 'beijing',
    '天津': 'tianjin',
    '河北': 'hebei',
    '山西': 'shanxi',
    '内蒙古': 'neimenggu',
    '辽宁': 'liaoning',
    '吉林': 'jilin',
    '黑龙江': 'heilongjiang',
    '上海': 'shanghai',
    '江苏': 'jiangsu',
    '浙江': 'zhejiang',
    '安徽': 'anhui',
    '福建': 'fujian',
    '江西': 'jiangxi',
    '山东': 'shandong',
    '河南': 'henan',
    '湖北': 'hubei',
    '湖南': 'hunan',
    '重庆': 'chongqing',
    '四川': 'sichuan',
    '贵州': 'guizhou',
    '云南': 'yunnan',
    '西藏': 'xizang',
    '陕西': 'shaanxi',
    '甘肃': 'gansu',
    '青海': 'qinghai',
    '宁夏': 'ningxia',
    '新疆': 'xinjiang',
    '广东': 'guangdong',
    '广西': 'guangxi',
    '海南': 'hainan',
    '香港': 'xianggang',
    '澳门': 'aomen',
    '台湾': 'taiwan',
  };

  // 拼音 -> 行政区划代码 id（全部小写、去除空格/连字符）
  static const Map<String, String> _pinyinToProvinceId = {
    'beijing': '110000',
    'tianjin': '120000',
    'hebei': '130000',
    'shanxi': '140000',
    'neimenggu': '150000',
    'liaoning': '210000',
    'jilin': '220000',
    'heilongjiang': '230000',
    'shanghai': '310000',
    'jiangsu': '320000',
    'zhejiang': '330000',
    'anhui': '340000',
    'fujian': '350000',
    'jiangxi': '360000',
    'shandong': '370000',
    'henan': '410000',
    'hubei': '420000',
    'hunan': '430000',
    'guangdong': '440000',
    'guangxi': '450000',
    'hainan': '460000',
    'chongqing': '500000',
    'sichuan': '510000',
    'guizhou': '520000',
    'yunnan': '530000',
    'xizang': '540000',
    'shaanxi': '610000',
    'gansu': '620000',
    'qinghai': '630000',
    'ningxia': '640000',
    'xinjiang': '650000',
    'taiwan': '710000',
    'xianggang': '810000',
    'aomen': '820000',
  };

// 将第96行的声明修改为：
  static const List<Map<String, dynamic>> _provinceData = [
    {"name": "北京", "value": 17},
    {"name": "天津", "value": 6},
    {"name": "河北", "value": 8},
    {"name": "山西", "value": 6},
    {"name": "内蒙古", "value": 6},
    {"name": "辽宁", "value": 9},
    {"name": "吉林", "value": 3},
    {"name": "黑龙江", "value": 5},
    {"name": "上海", "value": 15},
    {"name": "江苏", "value": 26},
    {"name": "浙江", "value": 14},
    {"name": "安徽", "value": 5},
    {"name": "福建", "value": 7},
    {"name": "江西", "value": 3},
    {"name": "山东", "value": 16},
    {"name": "河南", "value": 8},
    {"name": "湖北", "value": 10},
    {"name": "湖南", "value": 9},
    {"name": "重庆", "value": 6},
    {"name": "四川", "value": 11},
    {"name": "贵州", "value": 3},
    {"name": "云南", "value": 4},
    {"name": "西藏", "value": 0},
    {"name": "陕西", "value": 10},
    {"name": "甘肃", "value": 4},
    {"name": "青海", "value": 2},
    {"name": "宁夏", "value": 2},
    {"name": "新疆", "value": 2},
    {"name": "广东", "value": 16},
    {"name": "广西", "value": 4},
    {"name": "海南", "value": 6},
    {"name": "香港", "value": 12},
    {"name": "澳门", "value": 0},
  ];

  String _normalizeKey(String input) {
    final lower = input.toLowerCase();
    final buffer = StringBuffer();
    for (final ch in lower.runes) {
      final c = String.fromCharCode(ch);
      if ((c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 122) || // a-z
          (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57)) {
        // 0-9
        buffer.write(c);
      }
    }
    return buffer.toString();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChinaJson();
  }

  Future<void> _loadChinaJson() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/map/json/china.json');
      // 保证是紧凑字符串，避免引号冲突
      final dynamic parsed = jsonString.isEmpty ? {} : json.decode(jsonString);
      final compact = json.encode(parsed);
      setState(() {
        _chinaJsonString = compact;
        _currentMapJsonString = compact;
        _currentMapKey = '';
        _isProvince = false;
        // 尝试构建 name -> id 映射，便于定位省份资产
        try {
          if (parsed is Map && parsed['features'] is List) {
            for (final f in (parsed['features'] as List)) {
              final props = (f is Map) ? f['properties'] : null;
              final name = (props is Map) ? props['name']?.toString() : null;
              final id = (props is Map) ? props['id']?.toString() : null;
              if (name != null && id != null) {
                _provinceNameToId[name] = id;
              }
            }
          }
        } catch (_) {}
      });
    } catch (e) {
      // 读取失败时置为空对象，避免JS执行报错
      setState(() {
        _chinaJsonString = '{}';
        _currentMapJsonString = '{}';
        _currentMapKey = '';
        _isProvince = false;
      });
    }
  }

  Future<void> _drillDownToProvince(String provinceName) async {
    // 规范化：得到拼音 key
    // 通过拼音获取 id（或从全国 features 构建的 name->id）
    final _id = _nameToPinyin[provinceName];
    final List<String> candidatePaths = [
      'assets/map/json/province/$_id.json',
    ];
    // 调试输出
    // ignore: avoid_print
    // print('drillDown "$candidatePaths"');
    for (final path in candidatePaths) {
      print(path);
      try {
        final jsonString = await rootBundle.loadString(path);
        final dynamic parsed =
            jsonString.isEmpty ? {} : json.decode(jsonString);
        final compact = json.encode(parsed);
        print(compact);
        setState(() {
          _currentMapJsonString = compact;
          // 用唯一的 key 防止与 china 冲突，这里使用 id 或拼音或名称
          _currentMapKey = provinceName;
          _isProvince = true;
        });
        return;
      } catch (_) {
        // 尝试下一个路径
      }
    }
    // 如果都失败，提示一下
    if (mounted) {}
  }

  void _backToChina() {
    if (_chinaJsonString == null) return;
    setState(() {
      _currentMapJsonString = _chinaJsonString;
      _currentMapKey = '';
      _isProvince = false;
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Widget _buildMapView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
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
        child: _currentMapJsonString == null
            ? const Center(child: CircularProgressIndicator())
            : Echarts(
                key: UniqueKey(),
                option: '''

                        {
        title: {
            text: '${_currentMapKey}',
            left: 'center',
            textStyle: {
                color: '#333'
            }
        },
        tooltip: {
            trigger: 'item',
            formatter: '{b}: {c}'
        },
        visualMap: {
            min: 0,
            max: 26,
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
                name: '${_currentMapKey}',
                type: 'map',
                map: '${_currentMapKey}',
                roam: true,
                zoom: '${_isProvince ? 1.0 : 1.4}',
                label: {
                    show: true,
                    formatter: '{name|{b}}{value|({c})}',
                    rich: {
                        name: {
                            color: '#666',
                            fontSize: 6,
                            fontWeight: 'bold'
                        },
                        value: {
                            color: '#333',
                            fontSize: 6,
                             fontWeight: 'bold'
                        }
                    }
                },
                emphasis: {
                    label: {
                        show: true,
                        formatter: '{name|{b}}{value|({c})}',
                        rich: {
                            name: {
                                color: '#333',
                                fontSize: 8
                            },
                            value: {
                                color: '#fff',
                                fontSize: 8
                            }
                        }
                    },
                    itemStyle: {
                        areaColor: '#ffeaa7'
                    }
                },
                data: ${json.encode(_provinceData)}
            }
        ]
    }
                        ''',
                        extraScript: '''
                          try {
                            // 注册当前地图（全国或省份）
                            var currentGeoJson = ${_currentMapJsonString!};
                            echarts.registerMap('${_currentMapKey}', currentGeoJson);
                       
                            // 绑定点击事件，通知 Flutter 处理下钻
                            chart.off('click');
                            chart.on('click', function(params) {
                              if (params && params.name) {
                                Messager.postMessage(JSON.stringify({ type: 'map_click', name: params.name }));
                              }
                            });
                          } catch (e) {
                            console.error('注册中国地图失败:', e);
                          }
                        ''',
                        onMessage: (String message) {
                          // 解析点击事件
                          try {
                            final Map<String, dynamic> m = json.decode(message);
                            if (m['type'] == 'map_click' && !_isProvince) {
                              _drillDownToProvince(m['name']?.toString() ?? '');
                            }
                          } catch (_) {}
                        },
                      ),
      ),
    );
  }

  Widget _buildListView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
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
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _provinceData.length,
          itemBuilder: (context, index) {
            final province = _provinceData[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    province['value'].toString(),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  province['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text('教练数量: ${province['value']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  if (!_isProvince) {
                    _drillDownToProvince(province['name']);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 自定义顶部区域
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 返回按钮
                IconButton(
                  onPressed: () {
                    if (_isProvince) {
                      _backToChina();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // TabBar
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _tabController == null ? const SizedBox.shrink() : TabBar(
                       controller: _tabController!,
                      indicator: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: '地图视图'),
                        Tab(text: '列表视图'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // TabBarView 内容
          Expanded(
             child: _tabController == null ? const Center(child: CircularProgressIndicator()) : TabBarView(
               controller: _tabController!,
              children: [
                _buildMapView(),
                _buildListView(),
              ],
            ),
          ),
          // 省份视图时的返回按钮
          if (_isProvince)
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _backToChina,
                  icon: const Icon(Icons.map),
                  label: const Text('返回全国地图'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
