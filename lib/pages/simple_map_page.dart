import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_echarts/flutter_echarts.dart';
import 'package:go_router/go_router.dart';
import '../api/brand.dart';
import '../utils/http_client.dart';
import '../models/province.dart';
import '../models/brand.dart';

class SimpleMapPage extends StatefulWidget {
  final String? brandId;
  const SimpleMapPage({super.key, this.brandId});

  @override
  State<SimpleMapPage> createState() => _SimpleMapPageState();
}

class _SimpleMapPageState extends State<SimpleMapPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String? _chinaJsonString; // 全国 GeoJSON 字符串
  String? _currentMapJsonString; // 当前展示的地图 GeoJSON 字符串
  String _currentMapKey = ''; // eCharts 中 map 的 key
  bool _isProvince = false; // 是否为省份视图
  Map<String, String> _provinceNameToId = {}; // 省份中文名 -> 行政区划代码 id
  bool _isShowingStoreDialog = false;

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

  // 添加全称到简称的映射
  static const Map<String, String> _fullNameToShortName = {
    '北京市': '北京',
    '天津市': '天津',
    '河北省': '河北',
    '山西省': '山西',
    '内蒙古自治区': '内蒙古',
    '辽宁省': '辽宁',
    '吉林省': '吉林',
    '黑龙江省': '黑龙江',
    '上海市': '上海',
    '江苏省': '江苏',
    '浙江省': '浙江',
    '安徽省': '安徽',
    '福建省': '福建',
    '江西省': '江西',
    '山东省': '山东',
    '河南省': '河南',
    '湖北省': '湖北',
    '湖南省': '湖南',
    '重庆市': '重庆',
    '四川省': '四川',
    '贵州省': '贵州',
    '云南省': '云南',
    '西藏自治区': '西藏',
    '陕西省': '陕西',
    '甘肃省': '甘肃',
    '青海省': '青海',
    '宁夏回族自治区': '宁夏',
    '新疆维吾尔自治区': '新疆',
    '广东省': '广东',
    '广西壮族自治区': '广西',
    '海南省': '海南',
    '香港特别行政区': '香港',
    '澳门特别行政区': '澳门',
    '台湾省': '台湾',
  };
  List<dynamic> provinces = [];
  List<dynamic> _cityData = [];
  bool isLoading = true;
  String provinceId = '';

  // 添加门店列表相关状态变量
  List<dynamic> _storeList = []; // 门店列表数据
  bool _showStoreDialog = false; // 是否显示门店弹框
  bool _storeLoading = false; // 门店数据加载状态
  String _currentCityId = ''; // 当前选中的城市ID
  String _currentCityName = ''; // 当前选中的城市名称
  dynamic _selectedBrand;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      setState(() {});
    });
    fetchBrandDetail();
    _loadChinaJson();
    fetchProvinces(); // 调用获取省份数据的方法
  }

  // 获取省份数据的方法
  Future<void> fetchProvinces() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // 调用 brandApi.getTree 接口，传入 level=1 参数
      final response = await HttpClient.get(brandApi.getBrandTree, params: {
        'level': 1,
        'brandId': widget.brandId,
      });

      if (!mounted) return;

      if (response['success']) {
        // 获取返回数据中的 provinces 字段
        final List<dynamic> provincesData = response['data']['provinces'] ?? [];

        setState(() {
          // 处理 provinces 数据，例如保存到状态变量中
          // provinces = provincesData;
          provinces = provincesData.map((province) {
            final fullName = province['name'] as String;
            final shortName = _fullNameToShortName[fullName] ?? fullName;
            return {
              'name': shortName, // 使用简称
              'value': province['storeCount'] ?? 0,
              'fullName': fullName, // 保留全称用于显示
              'shopCount': province['shopCount'] ?? 0,
              'brandCount': province['brandCount'] ?? 0,
              'id': province['_id'],
            };
          }).toList()
            ..sort((b, a) => (a['value'] as int).compareTo(b['value'] as int));
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      // 添加错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取省份数据失败：${e.toString()}')),
      );
    }
  }

  Future<void> fetchCity() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // 调用 brandApi.getTree 接口，传入 level=1 参数
      final response = await HttpClient.get(brandApi.getBrandTree, params: {
        'level': 2,
        'brandId': widget.brandId,
        'provinceId': provinceId
      });

      if (!mounted) return;
      if (response['success']) {
        // 获取返回数据中的 provinces 字段
        final List<dynamic> cityData =
            response['data']['provinces'][0]['cities'] ?? [];

        setState(() {
          _cityData = cityData.map((city) {
            return {
              'name': city['name'], // 使用简称
              'value': city['storeCount'] ?? 0,
              'shopCount': city['shopCount'] ?? 0,
              'brandCount': city['brandCount'] ?? 0,
              'id': city['_id'],
            };
          }).toList()
            ..sort((b, a) => (a['value'] as int).compareTo(b['value'] as int));
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      // 添加错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取省份数据失败：${e.toString()}')),
      );
    }
  }

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
    await fetchCity();
    final _id = _nameToPinyin[provinceName];
    final List<String> candidatePaths = [
      'assets/map/json/province/$_id.json',
    ];
    // 调试输出
    // ignore: avoid_print
    // print('drillDown "$candidatePaths"');
    for (final path in candidatePaths) {
      try {
        final jsonString = await rootBundle.loadString(path);
        final dynamic parsed =
            jsonString.isEmpty ? {} : json.decode(jsonString);
        final compact = json.encode(parsed);

        if (mounted) {
          setState(() {
            _currentMapJsonString = compact;
            // 用唯一的 key 防止与 china 冲突，这里使用 id 或拼音或名称
            _currentMapKey = provinceName;
            _isProvince = true;
          });
        }

        return;
      } catch (_) {
        // 尝试下一个路径
      }
    }
    // 如果都失败，提示一下
    if (mounted) {}
  }

  // 获取门店列表的方法
  Future<void> fetchBrandDetail() async {
    if (!mounted) return;
    try {
      setState(() {
        _storeLoading = true;
      });
      // 调用 brandApi.getBrandTree 接口，传入 level=3 获取门店数据
      final response = await HttpClient.get(brandApi.getBrandBase, params: {
        'brandId': widget.brandId,
      });

      if (!mounted) return;

      if (response['success']) {
        setState(() {
          _selectedBrand = BrandModel.fromJson(response['data']['brand']);
        });
        print(_selectedBrand);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _storeLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取门店数据失败：${e.toString()}')),
      );
    } finally {
      setState(() {
        _storeLoading = false;
      });
    }
  }

  // 获取门店列表的方法
  Future<void> fetchStores(String cityId, String cityName) async {
    if (!mounted) return;
    try {
      setState(() {
        _storeLoading = true;
      });
      // 调用 brandApi.getBrandTree 接口，传入 level=3 获取门店数据
      final response = await HttpClient.get(brandApi.getBrandDetail, params: {
        'brandId': widget.brandId,
        'provinceId': provinceId,
        'cityId': cityId,
      });

      if (!mounted) return;

      if (response['success']) {
        final List<dynamic> storeData =
            response['data']['stores'].toList() ?? [];
        setState(() {
          _selectedBrand = BrandModel.fromJson(response['data']['brand']);
          _storeList = storeData;
          _storeLoading = false;
        });
        print(_selectedBrand);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _storeLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取门店数据失败：${e.toString()}')),
      );
    } finally {
      setState(() {
        _storeLoading = false;
      });
    }
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
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _currentMapJsonString == null
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                ),
              )
            : Echarts(
                key: UniqueKey(),
                option: '''
                {
                  title: {
                    text: '${_isProvince ? _currentMapKey : '${_selectedBrand?.name ?? ''}门店分布图'}',
                    subtext: '${_isProvince ? '点击城市查看详情' : '点击省份查看详情'}',
                    left: 'center',
                    top: 20,
                    textStyle: {
                      color: '#1E3A8A',
                      fontSize: 20,
                      fontWeight: 'bold'
                    },
                    subtextStyle: {
                      color: '#64748B',
                      fontSize: 14,
                      fontWeight: '500'
                    }
                  },
                  tooltip: {
                    trigger: 'item',
                    backgroundColor: 'rgba(30, 58, 138, 0.9)',
                    borderColor: '#1E3A8A',
                    borderWidth: 1,
                    textStyle: {
                      color: '#FFFFFF',
                      fontSize: 14
                    },
                    formatter: '{b}<br/>${_selectedBrand?.name ?? ''}门店: {c}家'
                  },
                  visualMap: {
                    min: 0,
                    max: 26,
                    left: 'left',
                    top: 'bottom',
                    text: ['高', '低'],
                    calculable: true,
                    inRange: {
                      color: ['#fff', '#0EA5E9', '#1E3A8A']
                    },
                    textStyle: {
                      color: '#1F2937',
                      fontSize: 12,
                      fontWeight: '600'
                    },
                    itemWidth: 20,
                    itemHeight: 120
                  },
                  series: [
                    {
                      name: '${_isProvince ? _currentMapKey : '${_selectedBrand?.name ?? ''}门店分布'}',
                      type: 'map',
                      map: '${_currentMapKey}',
                      roam: true,
                      zoom: ${_isProvince ? 1 : 1.4},
                      label: {
                        formatter: '{b} : {c}', 
                        show: true,
                        fontSize: 8,
                        color: '#1F2937',
                        fontWeight: '500'
                      },
                      emphasis: {
                        label: {
                          show: true,
                          fontSize: ${_isProvince ? 12 : 10},
                          color: '#1E3A8A',
                          fontWeight: 'bold'
                        },
                        itemStyle: {
                          areaColor: '#FEF3C7',
                          borderColor: '#1E3A8A',
                          borderWidth: 2
                        }
                      },
                      itemStyle: {
                        borderColor: '#E5E7EB',
                        borderWidth: 1,
                        areaColor: '#F8FAFC'
                      },
                      data:${!_isProvince ? json.encode(provinces) : json.encode(_cityData)}
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
                      // 传递完整的params对象，包含所有数据
                      Messager.postMessage(JSON.stringify({ 
                        type: 'map_click', 
                        name: params.name,
                        data: params.data,  // 包含shopCount, brandCount等数据
                        value: params.value,
                        dataIndex: params.dataIndex,
                        seriesIndex: params.seriesIndex,
                        componentType: params.componentType
                      }));
                    }
                  });
                } catch (e) {
                  console.error('注册地图失败:', e);
                }
              ''',
                onMessage: (String message) async {
                  if (_isShowingStoreDialog) {
                    return;
                  }
                  // 解析点击事件
                  try {
                    final Map<String, dynamic> m = json.decode(message);
                    print('点击事件: $m');

                    if (m['type'] == 'map_click') {
                      if (!_isProvince) {
                        // 点击省份，进入省份视图
                        setState(() {
                          provinceId = m['data']['id'];
                        });
                        _drillDownToProvince(m['name']?.toString() ?? '');
                      } else {
                        // 点击市区，显示门店列表底部弹框
                        final cityId = m['data']['id'];
                        final cityName = m['name']?.toString() ?? '';
                        _showStoreBottomSheet(cityId, cityName);
                      }
                    }
                  } catch (_) {}
                },
              ),
      ),
    );
  }

  // 显示门店列表底部弹框
  void _showStoreBottomSheet(String cityId, String cityName) async {
    setState(() {
      _currentCityId = cityId;
      _currentCityName = cityName;
      _isShowingStoreDialog = true;
    });
    await fetchStores(cityId, cityName);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => AbsorbPointer(
        // 使用AbsorbPointer完全阻止触摸事件穿透
        absorbing: false, // 允许弹框内部的触摸
        child: Container(
          // 添加全屏容器来捕获所有触摸事件
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {}, // 空处理器消费触摸事件
            child: Column(
              children: [
                // 上半部分空白区域，点击可关闭弹框
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                // 弹框内容区域
                _buildStoreBottomSheet(),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      print('弹框已关闭');
      setState(() {
        _storeList.clear();
        _storeLoading = false;
        _isShowingStoreDialog = false;
      });
    });
  }

  // 构建门店列表底部弹框
  Widget _buildStoreBottomSheet() {
    return AbsorbPointer(
      absorbing: false, // 允许弹框内容的正常交互

      child: Container(
        height: MediaQuery.of(context).size.height * 0.67,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // 拖拽指示器

            // 标题栏
            Column(
              children: [
                // Container(
                //   margin: const EdgeInsets.only(top: 8),
                //   width: 40,
                //   height: 4,
                //   decoration: BoxDecoration(
                //     color: Colors.grey.shade300,
                //     borderRadius: BorderRadius.circular(2),
                //   ),
                // ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$_currentCityName ${_selectedBrand?.name ?? ''} - 门店列表 (${_storeList.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 门店列表
            Expanded(
              child: _storeLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                      ),
                    )
                  : _storeList.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无门店数据',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _storeList.length,
                          itemBuilder: (context, index) {
                            final store = _storeList[index];
                            return _buildStoreItem(store);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建门店列表项
  Widget _buildStoreItem(Map<String, dynamic> store) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E3A8A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    store['mall']['name'] ?? '未知门店',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
            if (store['address'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      store['address'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (store['phone'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    store['phone'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade50,
            Colors.white,
          ],
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _isProvince ? _cityData.length : provinces.length,
        itemBuilder: (context, index) {
          final province = _isProvince ? _cityData[index] : provinces[index];

          final value = province['value'] as int;
          final name = province['name'] as String;

          // 根据数值设置颜色渐变
          Color getColorByValue(int val) {
            if (val >= 20) return const Color(0xFF1E3A8A); // 深蓝
            if (val >= 15) return const Color(0xFF3B82F6); // 蓝色
            if (val >= 10) return const Color(0xFF10B981); // 绿色
            if (val >= 5) return const Color(0xFFF59E0B); // 橙色
            return const Color(0xFFEF4444); // 红色
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (!_isProvince) {
                    setState(() {
                      provinceId = province['id'];
                    });

                    _drillDownToProvince(name);
                  } else {
                    _showStoreBottomSheet(province['id'], province['name']);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // 左侧数值圆圈
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              getColorByValue(value),
                              getColorByValue(value).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: getColorByValue(value).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            value.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // 中间信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedBrand?.name ?? ''}门店数量',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 右侧箭头
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Column(
            children: [
              // 自定义顶部区域
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 20,
                  right: 20,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 返回按钮
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1E3A8A),
                            const Color(0xFF3B82F6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3A8A).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          // Navigator.of(context).pop();
                          context.pop();
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // TabBar
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: _tabController == null
                            ? const SizedBox.shrink()
                            : TabBar(
                                controller: _tabController!,
                                indicator: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF1E3A8A),
                                      const Color(0xFF3B82F6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1E3A8A)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: const Color(0xFF64748B),
                                labelStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                                unselectedLabelStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                tabs: const [
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.map, size: 18),
                                        SizedBox(width: 6),
                                        Text('地图视图'),
                                      ],
                                    ),
                                  ),
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.list_alt, size: 18),
                                        SizedBox(width: 6),
                                        Text('列表视图'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              // TabBarView 内容
              Expanded(
                child: _tabController == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                        ),
                      )
                    : TabBarView(
                        controller: _tabController!,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildMapView(),
                          _buildListView(),
                        ],
                      ),
              ),
              // 省份视图时的返回按钮 - 只在地图视图显示
              if (_isProvince)
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1E3A8A),
                          const Color(0xFF3B82F6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _backToChina,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.map,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '返回全国地图',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // 门店列表弹框
            ],
          ),
          if (_showStoreDialog)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                    // child: _buildStoreDialog(),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
