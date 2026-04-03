import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:business_savvy/pages/feedback_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_echarts/flutter_echarts.dart';
import 'package:go_router/go_router.dart';
import 'package:business_savvy/pages/mall_brand_page.dart';
import 'package:business_savvy/pages/feedback_page.dart';
import 'package:business_savvy/pages/mall_brand_page.dart';
import '../api/brand.dart';
import '../utils/http_client.dart';
import '../models/province.dart';
import '../models/brand.dart';
import '../utils/screenshot_util.dart';
import 'package:business_savvy/widgets/ai_floating_button.dart';

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
    '北京市': 'beijing',
    '天津市': 'tianjin',
    '河北省': 'hebei',
    '山西省': 'shanxi',
    '内蒙古': 'neimenggu',
    '辽宁省': 'liaoning',
    '吉林省': 'jilin',
    '黑龙江省': 'heilongjiang',
    '上海市': 'shanghai',
    '江苏省': 'jiangsu',
    '浙江省': 'zhejiang',
    '安徽省': 'anhui',
    '福建省': 'fujian',
    '江西省': 'jiangxi',
    '山东省': 'shandong',
    '河南省': 'henan',
    '湖北省': 'hubei',
    '湖南省': 'hunan',
    '重庆省': 'chongqing',
    '四川省': 'sichuan',
    '贵州省': 'guizhou',
    '云南省': 'yunnan',
    '西藏': 'xizang',
    '陕西省': 'shanxi1',
    '甘肃省': 'gansu',
    '青海省': 'qinghai',
    '宁夏省': 'ningxia',
    '新疆': 'xinjiang',
    '广东省': 'guangdong',
    '广西': 'guangxi',
    '海南省': 'hainan',
    '香港': 'xianggang',
    '澳门': 'aomen',
    '台湾省': 'taiwan',
  };

  // 拼音 -> 行政区划代码 id（全部小写、去除空格/连字符）

  // 添加全称到简称的映射
  static const Map<String, String> _fullNameToShortName = {
    '北京市': '北京',
    '天津市': '天津',
    '河北省': '河北',
    '山西省': '山西',
    '内蒙古': '内蒙古',
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
    '西藏': '西藏',
    '陕西省': '陕西',
    '甘肃省': '甘肃',
    '青海省': '青海',
    '宁夏': '宁夏',
    '新疆': '新疆',
    '广东省': '广东',
    '广西': '广西',
    '海南省': '海南',
    '香港': '香港',
    '澳门': '澳门',
    '台湾省': '台湾',
  };
  List<dynamic> provinces = [];
  List<dynamic> _cityData = [];
  List<dynamic> _allCityData = [];
  List<dynamic> _columnCityData = [];
  bool isLoading = true;
  String provinceId = '';

  bool _allCityLoading = false;
  String? _selectedProvinceIdForCities; // 选中的省份ID，用于显示城市列表
  String? _selectedProvinceName; // 选中的省份名称

  // 列表视图相关状态变量
  String? _selectedCityIdForMalls; // 选中的城市ID
  List<dynamic> _mallsForSelectedCity = []; // 选中城市的商场列表
  bool _mallsLoading = false; // 商场加载状态

  // 添加门店列表相关状态变量
  List<dynamic> _storeList = []; // 门店列表数据
  bool _showStoreDialog = false; // 是否显示门店弹框
  bool _storeLoading = false; // 门店数据加载状态
  String _currentCityId = ''; // 当前选中的城市ID
  String? _currentCityName = ''; // 当前选中的城市名称
  dynamic _selectedBrand;
  bool _tabSwipeLocked = false;

  final GlobalKey _tableKey = GlobalKey();
  List<dynamic> _brandCitiesAll = [];
  bool _brandCitiesLoading = false;
  // 列表视图排序状态
  String _sortField = 'shopCount'; // 排序字段：'shopCount'（门店数）
  bool _sortAscending = false; // 是否升序
  // 市级地图
  String? _citiesJsonString; // 全国市级 GeoJSON
  bool _citiesJsonLoading = false; // 市级 JSON 加载中
  bool _cityMapShowLabel = true; // 市级地图是否显示城市名称
  bool _cityMapShowCount = true; // 市级地图是否显示门店数量（只显示>0的）
  bool _cityMapBubbleMode = false; // 市级地图渲染模式：false=颜色覆盖 true=气泡
  bool _cityMapDarkGold = false; // 市级地图主题：true=黑金 false=白天
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this, initialIndex: 2);
    _tabController!.addListener(() {
      setState(() {});
      final idx = _tabController!.index;
      // 列表(4) 和 省级(5) 都需要 allCityData
      if ((idx == 5 || idx == 4) && _allCityData.isEmpty && !_allCityLoading) {
        fetchAllCitiesOverview();
      }

      // 表格 tab (index 3)
      if (idx == 3 && _brandCitiesAll.isEmpty && !_brandCitiesLoading) {
        fetchAllCitiesByBrand();
      }

      // 市级地图 tab (index 1)
      if (idx == 1) {
        _loadCitiesJson();
        if (_allCityData.isEmpty && !_allCityLoading) {
          fetchAllCitiesOverview();
        }
      }
    });
    fetchBrandDetail();
    _loadChinaJson();
    fetchProvinces(); // 调用获取省份数据的方法
  }

  Future<void> fetchAllCitiesByBrand() async {
    if (!mounted) return;
    setState(() {
      _brandCitiesLoading = true;
    });

    try {
      final response = await HttpClient.get(brandApi.getBrandTreeBy, params: {
        'level': 2,
        'brandId': widget.brandId,
      });

      if (!mounted) return;
      if (response['success']) {
        final List<dynamic> citiesData = response['data']['cities'] ?? [];
        final List<dynamic> flattenedCities = [];
        for (final c in citiesData) {
          final List<dynamic> malls = c['malls'] ?? [];
          final List<Map<String, dynamic>> mallNamesList = malls
              .where((m) => (m['name'] ?? '').toString().isNotEmpty)
              .map((m) => {
                    'name': (m['name'] ?? '').toString(),
                    'typeStr': m['typeStr']?.toString() ?? '',
                    'remark': m['remark']?.toString() ?? '',
                  })
              .toList();
          flattenedCities.add({
            'name': c['name'],
            'value': c['storeCount'] ?? 0,
            'shopCount': mallNamesList.length,
            'brandCount': c['brandCount'] ?? 0,
            'id': c['_id'],
            'provinceId': c['provinceId']?.toString() ?? '',
            'mallNamesList': mallNamesList,
          });
        }
        flattenedCities
            .sort((b, a) => (a['shopCount'] as int).compareTo(b['shopCount'] as int));
        setState(() {
          _brandCitiesAll = flattenedCities;
          _brandCitiesLoading = false;
        });
      } else {
        setState(() {
          _brandCitiesLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _brandCitiesLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取品牌城市数据失败：${e.toString()}')),
      );
    }
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
        'level': 2,
        'brandId': widget.brandId,
      });

      if (!mounted) return;

      if (response['success']) {
        // 获取返回数据中的 provinces 字段
        final List<dynamic> provincesData = response['data']['provinces'] ?? [];

        setState(() {
          // 处理 provinces 数据，例如保存到状态变量中
          // provinces = provincesData;
          final processedProvinces = provincesData.map((province) {
            final fullName = province['name'] as String;
            final shortName = fullName;
            return {
              'name': shortName, // 使用简称
              'value': province['storeCount'] ?? 0,
              'fullName': fullName ?? '', // 保留全称用于显示
              'shopCount': province['shopCount'] ?? 0,
              'brandCount': province['brandCount'] ?? 0,
              'adcode': province['_id'],
            };
          }).toList();

          // 为地图中存在但API数据中不存在的特殊区域添加默认值，避免显示 NaN
          final specialAreas = [
            {
              'name': '南海',
              'value': 0,
              'fullName': '南海',
              'shopCount': 0,
              'brandCount': 0,
              'adcode': '100000_JD',
            },
          ];

          // 检查是否已存在这些区域的数据，如果不存在则添加默认值
          for (var area in specialAreas) {
            final exists =
                processedProvinces.any((item) => item['name'] == area['name']);
            if (!exists) {
              processedProvinces.add(area);
            }
          }

          provinces = processedProvinces
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
              'value': city['storeCount'] ?? 0, // 修复：使用整数 0 而不是字符串 '0'
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

  // 获取指定省份下的城市列表
  Future<void> fetchCitiesByProvince(String provinceId, String provinceName) async {
    if (!mounted) return;

    setState(() {
      _allCityLoading = true;
      _selectedProvinceIdForCities = provinceId;
      _selectedProvinceName = provinceName;
    });

    try {
      final response = await HttpClient.get(brandApi.getBrandTree, params: {
        'level': 2,
        'brandId': widget.brandId,
        'provinceId': provinceId,
      });

      if (!mounted) return;
      if (response['success']) {
        final List<dynamic> provincesData = response['data']['provinces'] ?? [];
        
        if (provincesData.isNotEmpty) {
          final List<dynamic> cities = provincesData[0]['cities'] ?? [];
          final List<dynamic> cityList = cities.map((c) {
            return {
              'name': c['name'],
              'value': c['storeCount'] ?? 0,
              'shopCount': c['shopCount'] ?? 0,
              'brandCount': c['brandCount'] ?? 0,
              'id': c['_id'],
              'provinceId': provinceId,
            };
          }).toList();

          cityList.removeWhere((item) => (item['value'] ?? 0) == 0);
          cityList.sort((b, a) => (a['value'] as int).compareTo(b['value'] as int));

          setState(() {
            _allCityData = cityList;
            _allCityLoading = false;
          });
        } else {
          setState(() {
            _allCityData = [];
            _allCityLoading = false;
          });
        }
      } else {
        setState(() {
          _allCityLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _allCityLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取城市数据失败：${e.toString()}')),
      );
    }
  }

  Future<void> fetchAllCitiesOverview() async {
    if (!mounted) return;
    setState(() {
      _allCityLoading = true;
    });

    try {
      final response = await HttpClient.get(brandApi.getBrandTree, params: {
        'level': 2,
        'brandId': widget.brandId,
      });

      if (!mounted) return;
      if (response['success']) {
        final List<dynamic> provincesData = response['data']['provinces'] ?? [];

        final List<dynamic> flattenedCities = [];
        for (final p in provincesData) {
          final String pid = p['_id']?.toString() ?? '';
          final List<dynamic> cities = p['cities'] ?? [];
          for (final c in cities) {
            flattenedCities.add({
              'name': c['name'],
              'value': c['storeCount'] ?? 0,
              'shopCount': c['shopCount'] ?? 0,
              'brandCount': c['brandCount'] ?? 0,
              'id': c['_id'],
              'provinceId': pid,
            });
          }
        }

        flattenedCities.removeWhere((item) => (item['value'] ?? 0) == 0);
        flattenedCities
            .sort((b, a) => (a['value'] as int).compareTo(b['value'] as int));

        setState(() {
          _allCityData = flattenedCities;
          _columnCityData = flattenedCities;
          _allCityLoading = false;
        });
      } else {
        setState(() {
          _allCityLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _allCityLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取城市数据失败：${e.toString()}')),
      );
    }
  }

  // 获取指定城市的商场列表
  Future<void> fetchMallsByCity(String cityId) async {
    if (!mounted) return;
    setState(() {
      _mallsLoading = true;
      _mallsForSelectedCity = [];
    });

    try {
      final response = await HttpClient.get(brandApi.getMalls, params: {
        'cityId': cityId,
        'brands': widget.brandId,
      });

      if (!mounted) return;

      if (response['success']) {
        final List<dynamic> mallsData = response['data']['malls'] ?? [];
        setState(() {
          _mallsForSelectedCity = mallsData;
          _mallsLoading = false;
        });
      } else {
        setState(() {
          _mallsLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mallsLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取商场数据失败：${e.toString()}')),
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
              final adcode =
                  (props is Map) ? props['adcode']?.toString() : null;
              if (name != null && adcode != null) {
                _provinceNameToId[name] = adcode;
              }
            }
          }
        } catch (_) {}
        print(parsed);
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

  Future<void> _loadCitiesJson() async {
    if (_citiesJsonString != null) return; // 已加载过则跳过
    if (_citiesJsonLoading) return;
    setState(() {
      _citiesJsonLoading = true;
    });
    try {
      final jsonString =
          await rootBundle.loadString('assets/map/json/china-cities.json');
      final dynamic parsed = jsonString.isEmpty ? {} : json.decode(jsonString);
      final compact = json.encode(parsed);
      if (!mounted) return;
      setState(() {
        _citiesJsonString = compact;
        _citiesJsonLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _citiesJsonString = '{}';
        _citiesJsonLoading = false;
      });
    }
  }

  Future<void> _drillDownToProvince(String provinceName) async {
    print('provinceName: $provinceName');
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
  Future<void> fetchStores(String cityId, String? cityName,
      {String? customProvinceId}) async {
    if (!mounted) return;
    try {
      setState(() {
        _storeLoading = true;
      });

      // 检查是否为直辖市
      final municipalities = ['北京市', '上海市', '天津市', '重庆市'];
      final isMunicipality = municipalities.contains(cityName);

      Map<String, dynamic> params = {
        'brandId': widget.brandId,
      };

      if (isMunicipality) {
        // 直辖市：使用cityId作为provinceId，不传cityId
        params['provinceId'] = cityId;
      } else {
        // 普通城市：传入provinceId和cityId
        params['provinceId'] = customProvinceId ?? provinceId;
        params['cityId'] = cityId;
      }
      params['limit'] = 999;
      // 调用 brandApi.getBrandDetail 接口获取门店数据
      final response =
          await HttpClient.get(brandApi.getBrandDetail, params: params);

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
            : Listener(
                onPointerDown: (event) {
                  if (_tabController?.index == 1) {
                    setState(() {
                      _tabSwipeLocked = true;
                    });
                  }
                },
                onPointerUp: (event) {
                  if (_tabController?.index == 1) {
                    setState(() {
                      _tabSwipeLocked = false;
                    });
                  }
                },
                onPointerCancel: (event) {
                  if (_tabController?.index == 1) {
                    setState(() {
                      _tabSwipeLocked = false;
                    });
                  }
                },
                child: Echarts(
                key: ValueKey('map_${_currentMapKey}_${_isProvince}'),
                option: '''
                {
                  title: {
                    text: '${_isProvince ? _currentMapKey : '${_selectedBrand?.name ?? ''}门店分布图'}',
                    subtext: '${_isProvince ? (_selectedBrand?.code ?? '') : '${_selectedBrand?.code ?? ''} (已收录${_selectedBrand?.storeCount ?? '-'}个 收录日期 ${(_selectedBrand?.updatedAt ?? '').toString().split('T').first} )'}',
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
                        // 点击省份
                        final provinceName = m['name']?.toString() ?? '';
                        final provinceDataId = m['data']['adcode'];

                        // 检查是否为直辖市
                        final municipalities = ['北京市', '上海市', '天津市', '重庆市'];
                        if (municipalities.contains(provinceName)) {
                          // 直辖市直接显示门店列表，使用省份ID作为城市ID
                          _showStoreBottomSheet(provinceDataId, provinceName);
                        } else {
                          // 普通省份，进入省份视图
                          setState(() {
                            provinceId = provinceDataId;
                          });
                          _drillDownToProvince(provinceName);
                        }
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
      ),
    );
  }

  // 显示门店列表底部弹框
  void _showStoreBottomSheet(String cityId, String? cityName,
      {String? customProvinceId}) async {
    // setState(() {
    //   _currentCityId = cityId;
    //   _currentCityName = cityName;
    //   _isShg = true;
    // });
    _currentCityId = cityId;
    _currentCityName = cityName;
    _isShowingStoreDialog = true;
    await fetchStores(cityId, cityName, customProvinceId: customProvinceId);
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
        child: GestureDetector(
          onTap: () {
            // 跳转到门店详情页面
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MallBrandPage(
                  mallId: store['mall']['_id'],
                ),
              ),
            );
          },
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
      child: Column(
        children: [
          // 表格区域
          Expanded(
            child: _brandCitiesLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                    ),
                  )
                : _brandCitiesAll.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.table_chart,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无数据',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: RepaintBoundary(
                            key: _tableKey,
                            child: Container(
                              color: Colors.black,
                              child: Container(
                                width: 800,
                                color: Colors.white,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Table(
                                border: TableBorder.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                columnWidths: const {
                                  0: FixedColumnWidth(60),
                                  1: FixedColumnWidth(90),
                                  2: FixedColumnWidth(60),
                                  3: FlexColumnWidth(),
                                },
                                children: [
                                  // 表头
                                  TableRow(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E3A8A),
                                    ),
                                    children: [
                                      // 序号列表头
                                      const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text(
                                          '序号',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      // 城市列表头
                                      const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text(
                                          '城市',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      // 门店数排序列表头（可点击排序）
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (_sortField == 'shopCount') {
                                              _sortAscending = !_sortAscending;
                                            } else {
                                              _sortField = 'shopCount';
                                              _sortAscending = false;
                                            }
                                            _brandCitiesAll.sort((a, b) {
                                              final av = (a['shopCount'] as int? ?? 0);
                                              final bv = (b['shopCount'] as int? ?? 0);
                                              return _sortAscending ? av.compareTo(bv) : bv.compareTo(av);
                                            });
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '${_selectedBrand?.storeCount ?? ''}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              // const SizedBox(width: 4),
                                              // Icon(
                                              //   _sortField == 'shopCount'
                                              //       ? (_sortAscending
                                              //           ? Icons.arrow_upward
                                              //           : Icons.arrow_downward)
                                              //       : Icons.unfold_more,
                                              //   color: Colors.white70,
                                              //   size: 14,
                                              // ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // 门店列表列表头
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          '${_selectedBrand?.name ?? ''}(${_selectedBrand?.code ?? ''}) 城市分布',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // 数据行
                                  ..._brandCitiesAll.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final city = entry.value;
                                    final cityName = city['name']?.toString() ?? '-';
                                    final mallNamesList = city['mallNamesList'] as List<dynamic>? ?? [];
                                    final mallCount = mallNamesList.length;
                                    final isEven = index % 2 == 0;

                                    return TableRow(
                                      decoration: BoxDecoration(
                                        color: isEven ? Colors.white : const Color(0xFFF5F7FF),
                                      ),
                                      children: [
                                        // 序号列
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        // 城市名列
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            cityName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        // 门店数列
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            mallCount.toString(),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF1E3A8A),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        // 门店列表列
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: mallNamesList.isEmpty
                                              ? const Text(
                                                  '-',
                                                  style: TextStyle(fontSize: 13, height: 1.5),
                                                )
                                              : Wrap(
                                                  spacing: 0,
                                                  runSpacing: 0,
                                                  children: mallNamesList.map((m) {
                                                    final name = (m as Map<String, dynamic>)['name']?.toString() ?? '';
                                                    final typeStr = m['typeStr']?.toString() ?? '';
                                                    final remark = m['remark']?.toString() ?? '';
                                                    return RichText(
                                                      text: TextSpan(
                                                        style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                                                        children: [
                                                          TextSpan(text: name),
                                                          if (typeStr.isNotEmpty || remark.isNotEmpty) ...
                                                            [
                                                              const TextSpan(text: '('),
                                                              if (typeStr.isNotEmpty)
                                                                TextSpan(
                                                                  text: typeStr,
                                                                  style: const TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Color(0xFFE67E22),
                                                                    fontSize: 12,
                                                                  ),
                                                                ),
                                                              if (typeStr.isNotEmpty && remark.isNotEmpty)
                                                                const TextSpan(text: '-'),
                                                              if (remark.isNotEmpty)
                                                                TextSpan(
                                                                  text: remark,
                                                                  style: const TextStyle(
                                                                    color: ui.Color.fromARGB(255, 236, 18, 18),
                                                                    fontSize: 11,
                                                                  ),
                                                                ),
                                                              const TextSpan(text: ')'),
                                                            ],
                                                        ],
                                                      ),
                                                    );
                                                  }).expand((w) => [w, const Text('、', style: TextStyle(fontSize: 13, height: 1.5))]).toList()
                                                    ..removeLast(),
                                                ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                              // 尾行：应用商店搜索信息
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E3A8A),
                                  border: Border(
                                    left: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                                    right: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                                    bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    '应用商店搜索 商业星球 查看更多商业内容',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                          ),
                        ),
                      ),
                    ),
          ),
          // 截图按钮
          if (_brandCitiesAll.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _captureAndShowTableImage(context),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('生成图片'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 生成表格截图并显示
  Future<void> _captureAndShowTableImage(BuildContext context) async {
    try {
      // 获取RepaintBoundary
      RenderRepaintBoundary? boundary = _tableKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('表格渲染未完成，请稍后再试')),
          );
        }
        return;
      }

      // 等待渲染完成
      await Future.delayed(const Duration(milliseconds: 300));

      // 捕获图像
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('截图生成失败')),
          );
        }
        return;
      }

      Uint8List imageBytes = byteData.buffer.asUint8List();

      // 显示预览对话框
      if (context.mounted) {
        ScreenshotUtil.showImageDialog(context, imageBytes);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('截图失败: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildProvinceOverviewView() {
    // 如果已选中省份，显示该省份的城市列表
    if (_selectedProvinceName != null) {
      return _buildCityOverviewView();
    }

    // 否则显示省级列表
    final filteredData = provinces;

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
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                final province = filteredData[index];

                final value = province['value'] as int;
                final name = province['name'] as String;

                Color getColorByValue(int val) {
                  if (val >= 20) return const Color(0xFF1E3A8A);
                  if (val >= 10) return const Color(0xFF3B82F6);
                  if (val >= 5) return const Color(0xFF10B981);
                  if (val > 0) return const Color(0xFFF59E0B);
                  return const Color(0xFFEF4444);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                      onTap: () async {
                        final municipalities = ['北京市', '上海市', '天津市', '重庆市'];
                        if (municipalities.contains(name)) {
                          _showStoreBottomSheet(province['adcode'], name);
                        } else {
                          // 加载该省份的城市数据，在当前页面显示
                          await fetchCitiesByProvince(province['adcode'], name);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
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
                                    color:
                                        getColorByValue(value).withOpacity(0.3),
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

  Widget _buildCityOverviewView() {
    final filteredData = _allCityData;

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
      child: Column(
        children: [
          // 如果有选中的省份，显示省份名称和返回按钮
          if (_selectedProvinceName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
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
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedProvinceIdForCities = null;
                        _selectedProvinceName = null;
                        _allCityData = [];
                      });
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_selectedProvinceName - 城市列表',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _allCityLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                    ),
                  )
                : filteredData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_city,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedProvinceName != null ? '该省份暂无城市数据' : '请从省级列表选择一个省份',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                final city = filteredData[index];

                final value = city['value'] as int;
                final name = city['name'] as String;

                Color getColorByValue(int val) {
                  if (val >= 20) return const Color(0xFF1E3A8A);
                  if (val >= 10) return const Color(0xFF3B82F6);
                  if (val >= 5) return const Color(0xFF10B981);
                  if (val > 0) return const Color(0xFFF59E0B);
                  return const Color(0xFFEF4444);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                        final municipalities = ['北京市', '上海市', '天津市', '重庆市'];
                        if (municipalities.contains(name)) {
                          _showStoreBottomSheet(city['id'], '');
                        } else {
                          _showStoreBottomSheet(city['id'], name,
                              customProvinceId: city['provinceId']);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
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
                                    color:
                                        getColorByValue(value).withOpacity(0.3),
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
          ),
        ],
      ),
    );
  }

  // 弹框内模式选择chip辅助方法
  Widget _buildModeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool isDark = true,
  }) {
    final activeColor = isDark ? const Color(0xFFD4A843) : const Color(0xFF1E3A8A);
    final inactiveBorder = isDark ? const Color(0x55D4A843) : const Color(0x554E65FF);
    final inactiveText = isDark ? const Color(0xFFB8A060) : const Color(0xFF4E65FF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? activeColor : inactiveBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : inactiveText,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 弹框内开关行辅助方法
  Widget _buildDialogSwitch({
    required String label,
    required bool value,
    required VoidCallback onTap,
    bool isDark = true,
  }) {
    final labelColor = isDark ? const Color(0xFFB8A060) : const Color(0xFF1E3A8A);
    final activeColor = isDark ? const Color(0xFFD4A843) : const Color(0xFF1E3A8A);
    final inactiveColor = isDark ? const Color(0xFF2A2010) : const Color(0xFFDDDDDD);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: labelColor),
        ),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: value ? activeColor : inactiveColor,
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 市级地图视图
  Widget _buildCityMapView() {
    // 数据或 JSON 未就绪
    if (_citiesJsonLoading || _allCityLoading ||
        _citiesJsonString == null || _allCityData.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A843)),
        ),
      );
    }

    // 将 _allCityData 转为 ECharts data，去掉城市名末尾的「市」字以匹配 GeoJSON
    final cityMapData = _allCityData.map((c) {
      String name = c['name']?.toString() ?? '';
      // GeoJSON 里都是简称（如「合肥」），接口可能返回「合肥市」，需去尾
      if (name.endsWith('市') || name.endsWith('区')) {
        name = name.substring(0, name.length - 1);
      }
      return {
        'name': name,
        'value': c['value'] ?? 0,
      };
    }).toList();

    final maxValue = cityMapData.isEmpty
        ? 10
        : cityMapData
            .map((c) => c['value'] as int)
            .reduce((a, b) => a > b ? a : b);

    // ── 地图主题色彩变量区 ──────────────────────────────────────────
    // 所有颜色变量均在此提前计算，避免 ECharts option 内嵌套引号导致 JSON 解析失败

    // 地图容器背景色
    final _bgColor = _cityMapDarkGold ? '#0D0D0D' : '#FFFFFF';
    // 标题文字颜色（黑金=金色 / 白天=深蓝）
    final _titleColor = _cityMapDarkGold ? '#D4A843' : '#1E3A8A';
    // 副标题文字颜色（均为灰色）
    final _subtitleColor = _cityMapDarkGold ? '#888' : '#999';

    // ── 标题文字预计算（避免 option 内单引号冲突） ────────────────────
    final _brandName   = _selectedBrand?.name ?? '';
    final _brandCode   = _selectedBrand?.code ?? '';
    final _storeCount  = _selectedBrand?.storeCount ?? '-';
    final _updatedDate = (_selectedBrand?.updatedAt ?? '').toString().split('T').first;
    // 主标题：品牌名 + 门店分布图
    final _mainTitle = '$_brandName 门店分布图';
    // 副标题：品牌编码 + 已收录数量 + 收录日期
    final _subTitle  = '$_brandCode (已收录${_storeCount}个 收录日期 $_updatedDate)';

    // ── Tooltip 颜色 ───────────────────────────────────────────────────
    final _tooltipBg     = _cityMapDarkGold ? 'rgba(10,8,0,0.9)'     : 'rgba(255,255,255,0.95)';
    final _tooltipBorder = _cityMapDarkGold ? '#D4A843'              : '#4E65FF';
    final _tooltipText   = _cityMapDarkGold ? '#F5DFA0'              : '#4E65FF';

    // ── 颜色覆盖模式专用颜色 ────────────────────────────────────────────
    // visualMap 渐变色板：黑金=金色系 / 白天=靛蓝色系（无数据白色→深蓝）
    final _visualColors = _cityMapDarkGold
        ? "['#1a1200','#5C3D00','#A0640A','#D4A843','#FFD700']"
        : "['#FFFFFF','#C8E0FF','#6AABF7','#1E6FD9','#0033AA']";
    // visualMap 文字和边框颜色
    final _visualTextColor   = _cityMapDarkGold ? '#B8A060'               : '#4E65FF';
    final _visualBorderColor = _cityMapDarkGold ? 'rgba(212,168,67,0.25)' : 'rgba(78,101,255,0.25)';
    // 无数据区域底色、边框、阴影（黑金=深棕黑 / 白天=纯白）
    final _areaColor   = _cityMapDarkGold ? '#1a1200'                : '#FFFFFF';
    final _borderColor = _cityMapDarkGold ? '#bbb599'               : '#fff';
    final _shadowColor = _cityMapDarkGold ? 'rgba(232,200,74,0.15)' : 'rgba(70,10,25,0.1)';
    // 地图标签文字颜色和阴影
    final _labelColor  = _cityMapDarkGold ? '#E8C84A'           : '#4E65FF';
    final _labelShadow = _cityMapDarkGold ? 'rgba(0,0,0,0.95)'  : 'rgba(255,255,255,0.8)';
    // 鼠标悬停强调效果：标签、区域填充、边框颜色
    final _emphasisLabelColor = _cityMapDarkGold ? '#FFD700' : '#4E65FF';
    final _emphasisArea       = _cityMapDarkGold ? '#5C3D00' : '#D0D8FF';
    final _emphasisBorder     = _cityMapDarkGold ? '#FFD700' : '#4E65FF';

    // ── 气泡模式专用颜色 ────────────────────────────────────────────────
    // geo 底图：黑金=深黑底 / 白天=纯白底
    final _geoArea       = _cityMapDarkGold ? '#0D0D0D' : '#fff';
    final _geoBorder     = _cityMapDarkGold ? '#3A3020' : '#e3e3e3';
    final _geoEmphArea   = _cityMapDarkGold ? '#2A2000' : '#D0D8FF';
    final _geoEmphBorder = _cityMapDarkGold ? '#D4A843' : '#4E65FF';
    // 气泡光晕带大小和颜色：黑金=金色发光 / 白天=蓝色发光
    final _bubbleShadowBlur  = _cityMapDarkGold ? 15 : 18;
    final _bubbleShadowColor = _cityMapDarkGold ? 'rgba(212,168,67,0.7)' : 'rgba(78,101,255,0.6)';
    // ─────────────────────────────────────────────────────────────────────

    return Stack(
      children: [
        // 地图区域（占满全部空间）
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: _cityMapDarkGold ? const Color(0xFF0D0D0D) : const Color(0xFFFFFFFF),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Listener(
          onPointerDown: (_) {
            if (_tabController?.index == 1) {
              setState(() => _tabSwipeLocked = true);
            }
          },
          onPointerUp: (_) {
            if (_tabController?.index == 1) {
              setState(() => _tabSwipeLocked = false);
            }
          },
          onPointerCancel: (_) {
            if (_tabController?.index == 1) {
              setState(() => _tabSwipeLocked = false);
            }
          },
          child: Echarts(
          key: ValueKey('city_map_${_allCityData.length}_${_cityMapShowLabel}_${_cityMapShowCount}_${_cityMapBubbleMode}_${_cityMapDarkGold}'),
          option: _cityMapBubbleMode ? '''
          {
            backgroundColor: '$_bgColor',
            title: [
              {
                text: '$_mainTitle',
                subtext: '$_subTitle',
                left: 'center', top: 10,
                textStyle: { color: '$_titleColor', fontSize: 18, fontWeight: 'bold' },
                subtextStyle: { color: '$_subtitleColor', fontSize: 12 }
              }
            ],
            tooltip: {
              trigger: 'item',
              backgroundColor: '$_tooltipBg',
              borderColor: '$_tooltipBorder', borderWidth: 1,
              textStyle: { color: '$_tooltipText', fontSize: 13 },
              formatter: function(p) {
                if (!p.value || (Array.isArray(p.value) && (isNaN(p.value[2]) || p.value[2] <= 0))) return '';
                var val = Array.isArray(p.value) ? p.value[2] : p.value;
                return p.name + '<br/>门店数量：<b>' + val + '</b> 家';
              }
            },
            geo: {
              map: 'china_cities', roam: true, zoom: 1.5,
              label: { show: false },
              itemStyle: {
                areaColor: '$_geoArea',
                borderColor: '$_geoBorder',
                borderWidth: 0.8
              },
              emphasis: {
                label: { show: false },
                itemStyle: {
                  areaColor: '$_geoEmphArea',
                  borderColor: '$_geoEmphBorder',
                  borderWidth: 1
                }
              }
            },
            series: [
              {
                name: '门店分布', type: 'map', map: 'china_cities',
                geoIndex: 0, roam: true, zoom: 1.5,
                label: { show: false }, itemStyle: { opacity: 0 },
                emphasis: { itemStyle: { opacity: 0 } },
                data: ${json.encode(cityMapData)}
              },
              {
                name: '门店散点', type: 'effectScatter',
                coordinateSystem: 'geo', geoIndex: 0,
                data: (function() {
                  var rawData = ${json.encode(cityMapData)};
                  var geoData = []; var geoCoordMap = {};
                  try {
                    var mapData = echarts.getMap('china_cities');
                    if (mapData && mapData.geoJSON && mapData.geoJSON.features) {
                      mapData.geoJSON.features.forEach(function(f) {
                        var name = f.properties && f.properties.name;
                        var center = f.properties && f.properties.cp;
                        if (!center && f.geometry) {
                          var coords = f.geometry.type === 'Polygon' ? f.geometry.coordinates[0] :
                            (f.geometry.type === 'MultiPolygon' ? f.geometry.coordinates[0][0] : null);
                          if (coords && coords.length) {
                            var lngs = coords.map(function(c){return c[0];});
                            var lats = coords.map(function(c){return c[1];});
                            center = [(Math.min.apply(null,lngs)+Math.max.apply(null,lngs))/2,
                                      (Math.min.apply(null,lats)+Math.max.apply(null,lats))/2];
                          }
                        }
                        if (name && center) geoCoordMap[name] = center;
                      });
                    }
                  } catch(e) {}
                  rawData.forEach(function(item) {
                    var coord = geoCoordMap[item.name];
                    if (coord && item.value > 0)
                      geoData.push({ name: item.name, value: [coord[0], coord[1], item.value] });
                  });
                  return geoData;
                })(),
                symbolSize: function(val) {
                  var v = Array.isArray(val) ? val[2] : val;
                  return Math.max(4, Math.min(14, 4 + v * 1.2));
                },
                rippleEffect: { brushType: 'stroke', scale: 3.5, period: 3 },
                label: {
                  show: ${_cityMapShowLabel || _cityMapShowCount},
                  position: 'right', fontSize: 10,
                  color: '$_labelColor',
                  textShadowColor: '$_labelShadow',
                  textShadowBlur: 4,
                  formatter: function(p) {
                    if (!p.value || isNaN(p.value[2]) || p.value[2] <= 0) return '';
                    var showName = ${_cityMapShowLabel}; var showCount = ${_cityMapShowCount};
                    if (showName && showCount) return p.name + ' ' + p.value[2];
                    if (showName) return p.name;
                    if (showCount) return '' + p.value[2];
                    return '';
                  }
                },
                itemStyle: {
                  color: function(p) {
                    var v = Array.isArray(p.value) ? p.value[2] : p.value;
                    var ratio = v / ($maxValue || 1);
                    var isDark = ${_cityMapDarkGold};
                    if (isDark) {
                      // 黑金模式：金橙色系
                      if (ratio > 0.7) return '#FF8C00';
                      if (ratio > 0.4) return '#D4A843';
                      if (ratio > 0.2) return '#C8B560';
                      return '#A89030';
                    } else {
                      // 白天模式：红色热力图（低→蓝紫→绿→黄→橙→红）
                      if (ratio > 0.8) return '#FF0000';
                      if (ratio > 0.6) return '#FF4500';
                      if (ratio > 0.4) return '#FF8C00';
                      if (ratio > 0.25) return '#FFFF00';
                      if (ratio > 0.1) return '#00FF88';
                      return '#4169E1';
                    }
                  },
                  shadowBlur: $_bubbleShadowBlur,
                  shadowColor: '$_bubbleShadowColor'
                },
                zlevel: 2
              }
            ]
          }
          ''' : '''
          {
            backgroundColor: '$_bgColor',
            title: [
              {
                text: '$_mainTitle',
                subtext: '$_subTitle',
                left: 'center', top: 10,
                textStyle: { color: '$_titleColor', fontSize: 18, fontWeight: 'bold' },
                subtextStyle: { color: '$_subtitleColor', fontSize: 12 }
              }
            ],
            tooltip: {
              trigger: 'item',
              backgroundColor: '$_tooltipBg',
              borderColor: '$_tooltipBorder', borderWidth: 1,
              textStyle: { color: '$_tooltipText', fontSize: 13 },
              formatter: function(p) {
                if (!p.value || isNaN(p.value) || p.value <= 0) return '';
                return p.name + '<br/>门店数量：<b>' + p.value + '</b> 家';
              }
            },
            visualMap: {
              min: -${(maxValue * 0.3).round()}, max: $maxValue,
              left: 'left', bottom: 20,
              text: ['高', '低'], calculable: true,
              inRange: { color: $_visualColors },
              textStyle: { color: '$_visualTextColor', fontSize: 11 },
              itemWidth: 14, itemHeight: 90,
              borderColor: '$_visualBorderColor', borderWidth: 1
            },
            series: [{
              name: '门店分布', type: 'map', map: 'china_cities',
              roam: true, zoom: 1.5,
              label: {
                show: ${_cityMapShowLabel || _cityMapShowCount},
                fontSize: 10, color: '$_labelColor',
                textShadowColor: '$_labelShadow', textShadowBlur: 4,
                formatter: function(p) {
                  if (!p.value || isNaN(p.value) || p.value <= 0) return '';
                  var showName = ${_cityMapShowLabel}; var showCount = ${_cityMapShowCount};
                  if (showName && showCount) return p.name + ' ' + p.value;
                  if (showName) return p.name;
                  if (showCount) return '' + p.value;
                  return '';
                }
              },
              emphasis: {
                label: { show: true, fontSize: 11, color: '$_emphasisLabelColor', fontWeight: 'bold' },
                itemStyle: { areaColor: '$_emphasisArea', borderColor: '$_emphasisBorder', borderWidth: 1.5 }
              },
              itemStyle: {
                borderColor: '$_borderColor', borderWidth: 0.8,
                areaColor: '$_areaColor',
                shadowColor: '$_shadowColor', shadowBlur: 8
              },
              data: ${json.encode(cityMapData)}
            }]
          }
          ''',
          extraScript: '''
          try {
            var citiesGeoJson = ${_citiesJsonString!};
            echarts.registerMap('china_cities', citiesGeoJson);
          } catch(e) {
            console.error('市级地图注册失败:', e);
          }
          ''',
                ),
              ),
            ),
          ),
        ),
        // 右上角浮动设置按鈕
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                barrierColor: Colors.transparent,
                builder: (ctx) => StatefulBuilder(
                  builder: (ctx, setDialogState) => Stack(
                    children: [
                      Positioned(
                        top: 60,
                        right: 16,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 200,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _cityMapDarkGold ? const Color(0xFF1A1000) : const Color(0xFFF8F8FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _cityMapDarkGold
                                    ? const Color(0xFFD4A843).withOpacity(0.4)
                                    : const Color(0xFF1E3A8A).withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _cityMapDarkGold
                                      ? const Color(0xFFD4A843).withOpacity(0.15)
                                      : const Color(0xFF1E3A8A).withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '地图设置',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _cityMapDarkGold ? const Color(0xFFD4A843) : const Color(0xFF1E3A8A),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // 渲染模式选择
                                Text(
                                  '渲染模式',
                                  style: TextStyle(fontSize: 11, color: _cityMapDarkGold ? const Color(0xFF888888) : const Color(0xFF999999)),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _buildModeChip(
                                      label: '颜色覆盖',
                                      selected: !_cityMapBubbleMode,
                                      isDark: _cityMapDarkGold,
                                      onTap: () {
                                        setState(() => _cityMapBubbleMode = false);
                                        setDialogState(() {});
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _buildModeChip(
                                      label: '气泡',
                                      selected: _cityMapBubbleMode,
                                      isDark: _cityMapDarkGold,
                                      onTap: () {
                                        setState(() => _cityMapBubbleMode = true);
                                        setDialogState(() {});
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // 地图主题选择
                                Text(
                                  '地图主题',
                                  style: TextStyle(fontSize: 11, color: _cityMapDarkGold ? const Color(0xFF888888) : const Color(0xFF999999)),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _buildModeChip(
                                      label: '黑金',
                                      selected: _cityMapDarkGold,
                                      isDark: _cityMapDarkGold,
                                      onTap: () {
                                        setState(() => _cityMapDarkGold = true);
                                        setDialogState(() {});
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _buildModeChip(
                                      label: '白天',
                                      selected: !_cityMapDarkGold,
                                      isDark: _cityMapDarkGold,
                                      onTap: () {
                                        setState(() => _cityMapDarkGold = false);
                                        setDialogState(() {});
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(color: _cityMapDarkGold ? const Color(0x33D4A843) : const Color(0x331E3A8A), height: 1),
                                const SizedBox(height: 12),
                                // 显示名称开关
                                _buildDialogSwitch(
                                  label: '显示城市名称',
                                  value: _cityMapShowLabel,
                                  isDark: _cityMapDarkGold,
                                  onTap: () {
                                    setState(() => _cityMapShowLabel = !_cityMapShowLabel);
                                    setDialogState(() {});
                                  },
                                ),
                                const SizedBox(height: 10),
                                // 显示数量开关
                                _buildDialogSwitch(
                                  label: '显示门店数量',
                                  value: _cityMapShowCount,
                                  isDark: _cityMapDarkGold,
                                  onTap: () {
                                    setState(() => _cityMapShowCount = !_cityMapShowCount);
                                    setDialogState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _cityMapDarkGold ? const Color(0xFF0D0800) : const Color(0xFFF0F4FF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _cityMapDarkGold
                      ? const Color(0xFFD4A843).withOpacity(0.6)
                      : const Color(0xFF1E3A8A).withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _cityMapDarkGold
                        ? const Color(0xFFD4A843).withOpacity(0.35)
                        : const Color(0xFF1E3A8A).withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.tune,
                size: 18,
                color: _cityMapDarkGold ? const Color(0xFFD4A843) : const Color(0xFF1E3A8A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 新增：城市-商场列表视图（左侧城市，右侧商场）
  Widget _buildCityMallListView() {
    // 过滤掉门店数量为0的城市
    final filteredCityData = _columnCityData.where((city) => (city['value'] as int) > 0).toList();
    
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
      child: _allCityLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
              ),
            )
          : Row(
              children: [
                // 左侧：城市列表
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_city,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '城市 (${filteredCityData.length})',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 30),
                            primary: false,
                            itemCount: filteredCityData.length,
                            itemBuilder: (context, index) {
                              final city = filteredCityData[index];
                              final cityId = city['id'];
                              final cityName = city['name'];
                              final storeCount = city['value'] as int;
                              final isSelected = _selectedCityIdForMalls == cityId;

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedCityIdForMalls = cityId;
                                    });
                                    fetchMallsByCity(cityId);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF1E3A8A).withOpacity(0.1)
                                          : Colors.transparent,
                                      border: Border(
                                        left: BorderSide(
                                          color: isSelected
                                              ? const Color(0xFF1E3A8A)
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            cityName,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? const Color(0xFF1E3A8A)
                                                  : const Color(0xFF1F2937),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF1E3A8A)
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            storeCount.toString(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 右侧：商场列表
                Expanded(
                  flex: 4,
                  child: Container(
                    color: Colors.grey.shade50,
                    child: _selectedCityIdForMalls == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.store,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '请选择一个城市查看商场',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.store,
                                      color: Color(0xFF1E3A8A),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '商场列表 (${_mallsForSelectedCity.length})',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: _mallsLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF1E3A8A)),
                                        ),
                                      )
                                    : _mallsForSelectedCity.isEmpty
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  size: 60,
                                                  color: Colors.grey.shade400,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  '该城市暂无商场数据',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.all(16),
                                            itemCount: _mallsForSelectedCity.length,
                                            itemBuilder: (context, index) {
                                              final mall =
                                                  _mallsForSelectedCity[index];
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.06),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                    onTap: () {
                                                      // 点击商场，跳转到商场详情
                                                      // context.go(
                                                      //     '/mall-brand/${mall['_id']}');
                                                      Navigator.of(context, rootNavigator: true).push(
                                                        MaterialPageRoute(
                                                          builder: (context) => MallBrandPage(mallId: mall['_id']),
                                                        ),
                                                      );
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(16),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  mall['name'] ??
                                                                      '',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize: 16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Color(
                                                                        0xFF1F2937),
                                                                  ),
                                                                ),
                                                              ),
                                                              // Container(
                                                              //   padding:
                                                              //       const EdgeInsets
                                                              //           .symmetric(
                                                              //     horizontal: 8,
                                                              //     vertical: 4,
                                                              //   ),
                                                              //   decoration:
                                                              //       BoxDecoration(
                                                              //     color: (mall['isActive'] ==
                                                              //                 true ||
                                                              //             mall['isActive'] ==
                                                              //                 1)
                                                              //         ? Colors.green
                                                              //             .withOpacity(
                                                              //                 0.1)
                                                              //         : Colors.grey
                                                              //             .withOpacity(
                                                              //                 0.1),
                                                              //     borderRadius:
                                                              //         BorderRadius
                                                              //             .circular(
                                                              //                 4),
                                                              //   ),
                                                              //   child: Text(
                                                              //     (mall['isActive'] ==
                                                              //                 true ||
                                                              //             mall['isActive'] ==
                                                              //                 1)
                                                              //         ? '营业中'
                                                              //         : '暂停营业',
                                                              //     style: TextStyle(
                                                              //       fontSize: 12,
                                                              //       fontWeight:
                                                              //           FontWeight
                                                              //               .w500,
                                                              //       color: (mall['isActive'] ==
                                                              //                   true ||
                                                              //               mall['isActive'] ==
                                                              //                   1)
                                                              //           ? Colors
                                                              //               .green
                                                              //           : Colors
                                                              //               .grey,
                                                              //     ),
                                                              //   ),
                                                              // ),
                                                            ],
                                                          ),
                                                        
                                                          if (mall['totalArea'] != null && mall['totalArea'] > 0) ...[
                                                            const SizedBox(height: 8),
                                                            Row(
                                                              children: [
                                                                Icon(
                                                                  Icons.crop_square,
                                                                  size: 16,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade600,
                                                                ),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Text(
                                                                  '面积: ${mall['totalArea']} m²',
                                                                  style: TextStyle(
                                                                    fontSize: 13,
                                                                    color: Colors
                                                                        .grey
                                                                        .shade600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
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
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                             Color(0xFF1E3A8A),
                             Color(0xFF3B82F6),
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
                    const SizedBox(width: 10),
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
                                isScrollable: true,
                                padding: EdgeInsets.zero,
                                tabAlignment: TabAlignment.start,
                                indicator: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                       Color(0xFF1E3A8A),
                                       Color(0xFF3B82F6),
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
                                labelPadding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                tabs: const [
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.info_outline, size: 18),
                                        SizedBox(width: 6),
                                        Text('介绍'),
                                      ],
                                    ),
                                  ),
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.location_city, size: 18),
                                        SizedBox(width: 6),
                                        Text('市级'),
                                      ],
                                    ),
                                  ),
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.map, size: 18),
                                        SizedBox(width: 6),
                                        Text('省级'),
                                      ],
                                    ),
                                  ),
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.table_chart, size: 18),
                                        SizedBox(width: 6),
                                        Text('表格'),
                                      ],
                                    ),
                                  ),
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.store, size: 18),
                                        SizedBox(width: 6),
                                        Text('列表'),
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
                                        Text('省级'),
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
                        physics: (_tabController?.index == 1 && _tabSwipeLocked)
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(),
                        children: [
                          _buildIntroView(),
                          _buildCityMapView(),
                          _buildMapView(),
                          _buildListView(),
                          _buildCityMallListView(),
                          _buildProvinceOverviewView(),
                        ],
                      ),
              ),
              // 省份视图时的返回按钮 - 只在地图视图显示
              if (_isProvince && _tabController?.index != 2 && _tabController?.index != 3 && _tabController?.index != 4)
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
          // 悬浮的红色感叹号按钮 - 导航到反馈页面
          Positioned(
            right: 20,
            bottom: 60,
            child: FloatingActionButton(
              // shape: CircleBorder(),
              mini: true,
              onPressed: () {
                // 导航到新的反馈页面
                // context.push('/feedback');
                Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute(
                  builder: (context) => FeedbackPage(),
                ));
              },
              backgroundColor: Colors.red,
              child: const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      return iso.split('T').first;
    } catch (_) {
      return iso;
    }
  }

  Widget _buildIntroView() {
    final String name = _selectedBrand?.name?.toString() ?? '未命名品牌';
    final String code = _selectedBrand?.code?.toString() ?? '';
    final int storeCount = _selectedBrand?.storeCount ?? 0;
    final String createdAt = _formatDate(_selectedBrand?.createdAt);
    final String updatedAt = _formatDate(_selectedBrand?.updatedAt);
    final String description = _selectedBrand?.description ?? '暂无介绍';

    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                    image: (_selectedBrand?.logo != null &&
                            (_selectedBrand?.logo as String).isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(
                                _selectedBrand?.logo as String),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (_selectedBrand?.logo == null ||
                          (_selectedBrand?.logo as String).isEmpty)
                      ? const Icon(Icons.image_not_supported,
                          color: Colors.grey, size: 28)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        code.isNotEmpty ? code : '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.store, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text('收录门店数: $storeCount',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                // Icon(Icons.event, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 6),
                // Text('收录: $createdAt',
                //     style: const TextStyle(fontSize: 12)),
                // const SizedBox(width: 16),
                Icon(Icons.update, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text('更新: $updatedAt',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              '品牌介绍',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
