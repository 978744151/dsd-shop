import 'package:business_savvy/pages/brand_settings_page.dart';
import 'package:business_savvy/pages/feedback_page.dart';
import 'package:business_savvy/utils/screenshot_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:screenshot/screenshot.dart';

import '../api/brand.dart';
import '../models/brand.dart';
import '../utils/http_client.dart';
import '../models/mall.dart';
import '../api/feedback_api.dart';
import '../widgets/comparison_table_widget.dart';
import '../widgets/comparison_filter_panel.dart';
import '../services/screenshot_service.dart';
import '../utils/screenshot_util.dart';

// 全局颜色常量定义
const Color kHeaderBackgroundColor = Color(0xFFF4F8FF);
const tableLableWidth = 150;

class ComparisonStyle {
  final Color headerColor; // 表头背景色
  final Color firstColumnColor; // 第一列背景色
  final Color textColor; // 文字颜色（表头/单元格）
  final Color borderColor; // 边框颜色
  final Color firstColumnTextColor;
  final List<Color> columnColors; // 动态列背景色列表

  const ComparisonStyle({
    this.firstColumnTextColor = Colors.white,
    required this.headerColor,
    required this.firstColumnColor,
    required this.textColor,
    required this.borderColor,
    required this.columnColors,
  });
}

class ComparePage extends StatefulWidget {
  final String? mallId;
  final String? mallName;
  final bool autoOpenSelection;

  const ComparePage(
      {super.key,
      this.mallId,
      this.mallName,
      this.autoOpenSelection = false}); // 添加参数

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  String _selectedType = 'mall'; // 'mall' or 'city'
  List<MallData> _malls = [];
  List<City> _cities = [];

  // 商场对比独立状态
  List<String> _mallSelectedIds = [];
  List<Map<String, dynamic>> _mallComparisonData = [];
  List<String> _mallSelectedNames = [];

  // 城市对比独立状态
  List<String> _citySelectedIds = [];
  List<Map<String, dynamic>> _cityComparisonData = [];
  List<String> _citySelectedNames = [];

  bool _isLoading = false;
  bool _isLoadingData = false;
  bool _isSelectionSheetOpen = false;
  int _styleIndex = 1; // 0=暗黑, 1=标准(彩色), 2=商务

  // 反馈相关状态
  bool _isFeedbackSheetOpen = false;
  final TextEditingController _feedbackController = TextEditingController();
  String _selectedFeedbackType = 'bug'; // 默认选择错误报告
  final ValueNotifier<String> _feedbackLabelNotifier =
      ValueNotifier<String>('错误报告');
  bool _isFeedbackTypeDialogOpen = false; // 控制反馈类型选择弹框

  // 添加截图控制器用于访问ComparisonTableWidget的截图功能
  final ScreenshotController _comparisonTableController =
      ScreenshotController();

  // 反馈类型选项 - 使用label-value形式
  final List<Map<String, String>> _feedbackTypes = [
    {'value': 'bug', 'label': '错误报告'},
    {'value': 'feature', 'label': '功能建议'},
    {'value': 'improvement', 'label': '改进建议'},
    {'value': 'question', 'label': '问题咨询'},
    {'value': 'complaint', 'label': '投诉建议'},
    {'value': 'other', 'label': '其他'},
  ];

  // Screenshot controller
  ScreenshotController screenshotController = ScreenshotController();

  // 省市数据
  List<Map<String, dynamic>> provinces = [];
  List<Map<String, dynamic>> cities = [];
  String? selectedProvinceId;
  String selectedProvinceName = '全部省份';
  String? selectedCityId;
  String selectedCityName = '全部城市';

  // 品牌筛选数据
  List<Map<String, dynamic>> brands = [];
  List<String> selectedBrandIds = [];
  List<String> selectedBrandNames = [];
  Map<String, String> brandScores = {}; // 品牌分值输入

  // 获取当前类型的选中ID列表
  List<String> get _selectedIds =>
      _selectedType == 'mall' ? _mallSelectedIds : _citySelectedIds;

  // 获取当前类型的对比数据
  List<Map<String, dynamic>> get _comparisonData =>
      _selectedType == 'mall' ? _mallComparisonData : _cityComparisonData;

  // 获取当前类型的选中名称列表
  List<String> get _selectedNames =>
      _selectedType == 'mall' ? _mallSelectedNames : _citySelectedNames;

  // 为不同列分配颜色的方法

  ComparisonStyle _getStyle() {
    switch (_styleIndex) {
      case 0: // 暗黑
        return ComparisonStyle(
          headerColor: Colors.black,
          firstColumnColor: Colors.black,
          textColor: Colors.white,
          borderColor: const Color(0xFF374151),
          columnColors: const [Colors.black],
        );
      case 2: // 商务
        return ComparisonStyle(
          headerColor: Colors.white,
          firstColumnColor: Colors.white,
          textColor: Colors.black,
          borderColor: const Color(0xFFE2E8F0),
          columnColors: const [Colors.white],
        );
      default: // 标准（彩色）
        return ComparisonStyle(
          headerColor: Colors.grey.shade100,
          firstColumnColor: Colors.grey.shade50,
          textColor: Colors.black,
          firstColumnTextColor: Colors.black,
          borderColor: Colors.grey.shade300,
          columnColors: const [
            Colors.blue,
            Colors.purple,
            Colors.green,
            Colors.yellow,
            Colors.teal,
            Colors.red,
            Colors.deepOrange,
            Colors.pink,
            Colors.grey,
            Colors.amber,
            Colors.cyan,
            Colors.brown,
            Colors.blueGrey,
            Colors.deepPurple,
          ],
        );
    }
  }

  // 获取所有列的颜色列表
  List<Color> _getColumnColors() {
    final style = _getStyle();
    final palette = style.columnColors;
    return List.generate(
      _comparisonData.length,
      (index) => palette[index % palette.length],
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.mallId != null && widget.mallId!.isNotEmpty) {
      setState(() {
        _mallSelectedIds = widget.mallId!.split(',');
      });
    }
    if (widget.mallName != null && widget.mallName!.isNotEmpty) {
      setState(() {
        _mallSelectedNames = widget.mallName!.split(',');
      });
    }

    _loadInitialData();
  }

  @override
  void didUpdateWidget(ComparePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool needUpdate = false;

    if (widget.mallId != oldWidget.mallId) {
      _mallSelectedIds = (widget.mallId != null && widget.mallId!.isNotEmpty)
          ? widget.mallId!.split(',')
          : [];
      needUpdate = true;
    }

    if (widget.mallName != oldWidget.mallName) {
      _mallSelectedNames =
          (widget.mallName != null && widget.mallName!.isNotEmpty)
              ? widget.mallName!.split(',')
              : [];
      needUpdate = true;
    }

    if (needUpdate) {
      _selectedType = 'mall';
      setState(() {});

      if (widget.autoOpenSelection) {
        _openSelectionDialogSafely();
      }
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 加载商场数据
      final mallResponse = await HttpClient.get(brandApi.getMalls);
      if (mallResponse['success'] == true) {
        final List<dynamic> mallList = mallResponse['data']['malls'] ?? [];
        _malls = mallList.map((json) => MallData.fromJson(json)).toList();

        // 提取城市数据
        final Set<String> cityIds = {};
        final List<City> cityList = [];
        for (var mall in _malls) {
          if (!cityIds.contains(mall.city.id)) {
            cityIds.add(mall.city.id);
            cityList.add(mall.city);
          }
        }
        _cities = cityList;
      }

      // 加载省份数据
      await _loadProvinces();

      // 加载城市数据
      await _loadCities();

      // 加载品牌数据
      await _loadBrands();
      // _showSelectionDialog();
    } catch (e) {
      print('加载数据失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      if (widget.autoOpenSelection) {
        Future.microtask(() => _showSelectionDialog());
      }
    }
  }

  List<Map<String, dynamic>> _getCitiesByProvince(String? provinceId) {
    if (provinceId == null) return cities;
    return cities;
  }

  List<MallData> _getMallsByCity(String? cityId) {
    if (cityId == null) return _malls;
    return _malls.where((mall) => mall.city.id == cityId).toList();
  }

  // 根据省份ID重新加载商场数据
  Future<void> _loadMallsByProvince(
      String? provinceId, StateSetter? setModalState) async {
    try {
      Map<String, dynamic> params = {};
      if (provinceId != null) {
        params['provinceId'] = provinceId;
      }

      final response = await HttpClient.get(brandApi.getMalls, params: params);
      if (response['success'] == true) {
        final List<dynamic> mallList = response['data']['malls'] ?? [];
        final newMalls =
            mallList.map((json) => MallData.fromJson(json)).toList();

        setState(() {
          _malls = newMalls;
        });

        if (setModalState != null) {
          setModalState(() {
            // 更新弹框中的商场数据
          });
        }
      }
    } catch (e) {
      print('加载商场数据失败: $e');
    }
  }

  Future<void> _loadProvinces() async {
    try {
      final response = await HttpClient.get(brandApi.getProvinces);
      if (response['success'] == true) {
        final List<dynamic> provinceList = response['data']['provinces'] ?? [];
        setState(() {
          provinces = provinceList
              .map((province) => {
                    'id': province['_id'].toString(),
                    'name': province['name'].toString(),
                  })
              .toList();
        });
      }
    } catch (e) {
      print('加载省份数据失败: $e');
    }
  }

  Future<void> _loadCities() async {
    try {
      final response = await HttpClient.get(brandApi.getCities);
      if (response['success'] == true) {
        final List<dynamic> cityList = response['data']['cities'] ?? [];
        setState(() {
          cities = cityList
              .map((city) => {
                    'id': city['_id'].toString(),
                    'name': city['name'].toString(),
                    'provinceId': city['provinceId'].toString(),
                  })
              .toList();
        });
      }
    } catch (e) {
      print('加载城市数据失败: $e');
    }
  }

  Future<void> _loadCitiesByProvince(
      String? provinceId, StateSetter setModalState) async {
    try {
      String url = brandApi.getCities;
      if (provinceId != null) {
        url += '?provinceId=$provinceId';
      }
      final response = await HttpClient.get(url);
      if (response['success'] == true) {
        final List<dynamic> cityList = response['data']['cities'] ?? [];
        setModalState(() {
          cities = cityList
              .map((city) => {
                    'id': city['_id'].toString(),
                    'name': city['name'].toString(),
                    'provinceId': city['provinceId'].toString(),
                  })
              .toList();
          print('cities: $cities');
        });
        setState(() {}); // 同时更新主页面状态
      }
    } catch (e) {
      print('加载省份城市数据失败: $e');
    }
  }

  Future<void> _loadBrands() async {
    try {
      final response = await HttpClient.get(brandApi.getBrand);
      if (response['success'] == true) {
        final List<dynamic> brandList = response['data']['brands'] ?? [];
        brands = brandList
            .map((brand) => {
                  'id': brand['_id'].toString(),
                  'name': brand['name'].toString(),
                  // 默认附带后端返回的分数（若有）
                  'score': brand['score']?.toString(),
                })
            .toList();
        // 默认给 brandScores 赋值为品牌 id -> score
        brandScores.clear();
        for (final b in brands) {
          brandScores[b['id']] = b['score']?.toString() ?? '';
        }
      }
    } catch (e) {
      print('加载品牌数据失败: $e');
    }
  }

  void _openSelectionDialogSafely() {
    _loadBrands();
    if (_isSelectionSheetOpen) {
      Navigator.of(context).pop();
      Future.microtask(() => _showSelectionDialog());
      return;
    }
    Future.microtask(() => _showSelectionDialog());
  }

  void _showSelectionDialog() {
    _isSelectionSheetOpen = true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 顶部拖拽条
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '选择${_selectedType == 'mall' ? '商场' : '城市'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            _isSelectionSheetOpen = false;
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedNames.isNotEmpty) ...[
                      Text(
                        '已选择 ${_selectedNames.length} 个${_selectedType == 'mall' ? '商场' : '城市'}:',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _selectedNames
                            .map(
                              (name) => Chip(
                                label: Text(name,
                                    style: const TextStyle(fontSize: 10)),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(
                                    horizontal: -4, vertical: -4),
                                backgroundColor: const Color(0xFFF5F5F5),
                                deleteIcon: const Icon(Icons.close, size: 12),
                                onDeleted: () {
                                  final idx = _selectedNames.indexOf(name);
                                  if (idx >= 0) {
                                    if (_selectedType == 'mall') {
                                      _mallSelectedIds.removeAt(idx);
                                      _mallSelectedNames.removeAt(idx);
                                      _mallComparisonData.clear();
                                    } else {
                                      _citySelectedIds.removeAt(idx);
                                      _citySelectedNames.removeAt(idx);
                                      _cityComparisonData.clear();
                                    }
                                  }
                                  setModalState(() {});
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // 省市选择区域（仅商场对比时显示）
              // if (_selectedType == 'mall')
              _buildProvinceAndCitySelector(setModalState),

              // 品牌筛选区域

              // 选项列表
              Expanded(
                child: _buildDialogSelectionList(setModalState),
              ),

              // 底部确认按钮
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            if (_selectedType == 'mall') {
                              _mallSelectedIds.clear();
                              _mallSelectedNames.clear();
                              _mallComparisonData.clear();
                            } else {
                              _citySelectedIds.clear();
                              _citySelectedNames.clear();
                              _cityComparisonData.clear();
                            }
                            // 清空品牌筛选
                            selectedBrandIds.clear();
                            selectedBrandNames.clear();
                          });
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                          side:
                              BorderSide(color: Theme.of(context).primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('清空选择'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _selectedIds.length >= 2
                            ? () {
                                Navigator.pop(context);
                                // 确认选择后直接执行对比
                                _fetchComparisonData();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('执行对比 (${_selectedIds.length})'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      _isSelectionSheetOpen = false;
    });
  }

  Widget _buildProvinceAndCitySelector(StateSetter setModalState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterItem(
              label: '省份',
              value: selectedProvinceName,
              onTap: () => _showFilterDialog(
                title: '选择省份',
                items: ['全部省份', ...provinces.map((p) => p['name'] as String)],
                selectedValue: selectedProvinceName,
                onSelected: (value) async {
                  if (value == '全部省份') {
                    selectedProvinceId = null;
                    selectedProvinceName = '全部省份';
                    selectedCityId = null;
                    selectedCityName = '全部城市';
                    // 加载所有城市
                    await _loadCitiesByProvince(null, setModalState);
                    // 加载所有商场
                    await _loadMallsByProvince(null, setModalState);
                  } else {
                    final province =
                        provinces.firstWhere((p) => p['name'] == value);
                    selectedProvinceId = province['id'];
                    selectedProvinceName = value;
                    selectedCityId = null;
                    selectedCityName = '全部城市';
                    // 根据省份加载城市
                    await _loadCitiesByProvince(
                        selectedProvinceId, setModalState);
                    // 根据省份加载商场
                    await _loadMallsByProvince(
                        selectedProvinceId, setModalState);
                  }
                },
              ),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey.withOpacity(0.2),
          ),
          if (_selectedType == 'mall')
            Expanded(
              child: _buildFilterItem(
                label: '城市',
                value: selectedCityName,
                onTap: () => _showFilterDialog(
                  title: '选择城市',
                  items: [
                    '全部城市',
                    ..._getCitiesByProvince(selectedProvinceId)
                        .map((c) => c['name'] as String)
                  ],
                  selectedValue: selectedCityName,
                  onSelected: (value) {
                    if (value == '全部城市') {
                      selectedCityId = null;
                      selectedCityName = '全部城市';
                    } else {
                      final city = _getCitiesByProvince(selectedProvinceId)
                          .firstWhere((c) => c['name'] == value);
                      selectedCityId = city['id'];
                      selectedCityName = value;
                    }
                    // 更新主弹框状态
                    setModalState(() {});
                    setState(() {}); // 同时更新主页面状态
                  },
                ),
              ),
            ),
          if (_selectedType == 'mall')
            Container(
              width: 1,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.grey.withOpacity(0.2),
            ),
          Expanded(
            child: _buildFilterItem(
              label: '品牌',
              value: '品牌',
              onTap: () => _showBrandFilterDialog(setModalState),
            ),
          ),
          // _buildBrandSelector(setModalState),
        ],
      ),
    );
  }

  Widget _buildFilterItem({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(
                  //   label,
                  //   style: TextStyle(
                  //     fontSize: 12,
                  //     color: Colors.grey[600],
                  //   ),
                  // ),
                  // const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey[600],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandSelector(StateSetter setModalState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '品牌筛选',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showBrandFilterDialog(setModalState),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedBrandNames.isEmpty
                          ? '选择品牌'
                          : selectedBrandNames.length > 2
                              ? '${selectedBrandNames.take(2).join('、')}等${selectedBrandNames.length}个品牌'
                              : selectedBrandNames.join('、'),
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedBrandNames.isEmpty
                            ? Colors.grey[600]
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog({
    required String title,
    required List<String> items,
    required String selectedValue,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = item == selectedValue;
                  return GestureDetector(
                    onTap: () {
                      onSelected(item);
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3),
                                width: 1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showBrandFilterDialog(StateSetter setModalState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setBrandModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      '选择品牌',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setBrandModalState(() {
                          selectedBrandIds.clear();
                          selectedBrandNames.clear();
                          brandScores.clear();
                        });
                      },
                      child: Text(
                        '清空',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        setBrandModalState(() {
                          selectedBrandIds.clear();
                          selectedBrandNames.clear();
                          for (final b in brands) {
                            selectedBrandIds.add(b['id']);
                            selectedBrandNames.add(b['name']);
                            // 若 brandScores 缺失或为空，填充为默认 score
                            final cur = brandScores[b['id']];
                            if (cur == null || cur.toString().trim().isEmpty) {
                              brandScores[b['id']] =
                                  b['score']?.toString() ?? '';
                            }
                          }
                        });
                      },
                      child: Text(
                        '全选',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    final brand = brands[index];
                    final isSelected = selectedBrandIds.contains(brand['id']);
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setBrandModalState(() {
                                if (value == true) {
                                  selectedBrandIds.add(brand['id']);
                                  selectedBrandNames.add(brand['name']);
                                } else {
                                  selectedBrandIds.remove(brand['id']);
                                  selectedBrandNames.remove(brand['name']);
                                  brandScores.remove(brand['id']);
                                }
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              brand['name'],
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: TextFormField(
                              initialValue: brandScores[brand['id']] ??
                                  (brand['score']?.toString() ?? ''),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                hintText: '分值',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                setBrandModalState(() {
                                  final v = val.trim();
                                  brandScores[brand['id']] = v.isEmpty
                                      ? (brand['score']?.toString() ?? '')
                                      : v;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // 如果存在任一分数输入，则所有选中的品牌必须填写分数且为数字
                      final bool hasAnyScore = selectedBrandIds.any((id) {
                        final v = brandScores[id];
                        return v != null && v.toString().trim().isNotEmpty;
                      });

                      if (hasAnyScore) {
                        // 检查是否所有选中的品牌都填写了分数
                        final bool allFilled = selectedBrandIds.every((id) {
                          final v = brandScores[id];
                          return v != null && v.toString().trim().isNotEmpty;
                        });
                        if (!allFilled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('请为所有已选品牌填写分数')),
                          );
                          return;
                        }
                        // 检查分数是否为数字
                        final bool allNumeric = selectedBrandIds.every((id) {
                          final v = brandScores[id]!;
                          return double.tryParse(v.toString().trim()) != null;
                        });
                        if (!allNumeric) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('分数需为数字')),
                          );
                          return;
                        }
                      }

                      Navigator.pop(context);
                      setModalState(() {});
                      setState(() {
                        // 品牌选择变化时清空对比数据
                        if (_selectedType == 'mall') {
                          _mallComparisonData.clear();
                        } else {
                          _cityComparisonData.clear();
                        }
                      });
                    },
                    child: Text('确定（已选${selectedBrandIds.length}个品牌）'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogSelectionList(StateSetter setModalState) {
    List<dynamic> items;
    if (_selectedType == 'mall') {
      items = _getMallsByCity(selectedCityId);
    } else {
      items = cities;
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        if (_selectedType == 'mall') {
          final mall = items[index] as MallData;
          final isSelected = _selectedIds.contains(mall.id);
          return GestureDetector(
            onTap: () {
              setModalState(() {
                if (isSelected) {
                  _mallSelectedIds.remove(mall.id);
                  _mallSelectedNames.remove(mall.name);
                } else {
                  _mallSelectedIds.add(mall.id);
                  _mallSelectedNames.add(mall.name);
                }
                _mallComparisonData.clear();
              });
              setState(() {}); // 同时更新主页面状态
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 1)
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mall.name,
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.black87,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${mall.city.name} - ${mall.address}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        } else {
          final city = items[index] as Map<String, dynamic>;
          final cityId = city['id'] as String;
          final cityName = city['name'] as String;
          final isSelected = _selectedIds.contains(cityId);
          return GestureDetector(
            onTap: () {
              setModalState(() {
                if (isSelected) {
                  _citySelectedIds.remove(cityId);
                  _citySelectedNames.remove(cityName);
                } else {
                  _citySelectedIds.add(cityId);
                  _citySelectedNames.add(cityName);
                }
                _cityComparisonData.clear();
              });
              setState(() {}); // 同时更新主页面状态
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 1)
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      cityName,
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _fetchComparisonData({saveReport = false}) async {
    if (_selectedIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择2个项目进行对比')),
      );
      return;
    }

    setState(() {
      _isLoadingData = true;
    });

    try {
      final response = await HttpClient.post(brandApi.getComparison, body: {
        'ids': _selectedIds,
        'type': _selectedType,
        'brandIds': selectedBrandIds,
        'brandScores': brandScores,
        'saveReport': saveReport,
      });

      if (response['success'] == true) {
        setState(() {
          if (_selectedType == 'mall') {
            _mallComparisonData = List<Map<String, dynamic>>.from(
                response['data']['results'] ?? []);
          } else {
            _cityComparisonData = List<Map<String, dynamic>>.from(
                response['data']['results'] ?? []);
          }
        });
      }
      if (saveReport) {
        Fluttertoast.showToast(msg: '保存成功');
      }
    } catch (e) {
      print('获取对比数据失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取对比数据失败: $e')),
      );
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
        child: SafeArea(
          child: ComparisonFilterPanel(
            onClose: () => Navigator.of(context).pop(),
            onStyleChanged: (i) => setState(() => _styleIndex = i),
            initialStyleIndex: _styleIndex,
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildCustomHeader(),
          // 悬浮的红色感叹号按钮 - 导航到反馈页面
          Positioned(
            right: 0,
            bottom: 10,
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

  Widget _buildCustomHeader() {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // 对比类型选择
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      // color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = 'mall';
                                // 保留状态，不清空选择和对比数据
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedType == 'mall'
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '商场对比',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = 'city';
                                // 保留状态，不清空选择和对比数据
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedType == 'city'
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '城市对比',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: '筛选',
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () => _openFilterPanel(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildSelectionArea(),
                    if (_comparisonData.isNotEmpty) _buildComparisonTable(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSelectionArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   '${_selectedType == 'mall' ? '商场' : '城市'}对比',
          //   style: const TextStyle(
          //     fontSize: 18,
          //     fontWeight: FontWeight.bold,
          //   ),
          // ),
          // const SizedBox(height: 16),

          // 已选择的项目显示
          // if (_selectedNames.isNotEmpty) ...[
          //   Container(
          //     width: double.infinity,
          //     padding: const EdgeInsets.all(12),
          //     decoration: BoxDecoration(
          //       color: Colors.blue.withOpacity(0.1),
          //       borderRadius: BorderRadius.circular(8),
          //       border: Border.all(color: Colors.blue.withOpacity(0.3)),
          //     ),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         Text(
          //           '已选择 ${_selectedNames.length} 个${_selectedType == 'mall' ? '商场' : '城市'}:',
          //           style: TextStyle(
          //             fontSize: 14,
          //             fontWeight: FontWeight.w600,
          //             color: Colors.blue[700],
          //           ),
          //         ),
          //         const SizedBox(height: 8),
          //         Wrap(
          //           spacing: 8,
          //           runSpacing: 4,
          //           children: _selectedNames
          //               .map((name) => Chip(
          //                 label: Text(name,
          //                     style: const TextStyle(fontSize: 10)),
          //                 materialTapTargetSize:
          //                     MaterialTapTargetSize.shrinkWrap,
          //                 visualDensity: const VisualDensity(
          //                     horizontal: -4, vertical: -4),
          //                 backgroundColor: const Color(0xFFF5F5F5),
          //                 deleteIcon: const Icon(Icons.close, size: 12),
          //                 onDeleted: () {
          //                   final idx = _selectedNames.indexOf(name);
          //                   if (idx >= 0) {
          //                     if (_selectedType == 'mall') {
          //                       _mallSelectedIds.removeAt(idx);
          //                       _mallSelectedNames.removeAt(idx);
          //                       _mallComparisonData.clear();
          //                     } else {
          //                       _citySelectedIds.removeAt(idx);
          //                       _citySelectedNames.removeAt(idx);
          //                       _cityComparisonData.clear();
          //                     }
          //                   }
          //                   setState(() {});
          //                 },
          //                 shape: RoundedRectangleBorder(
          //                   borderRadius: BorderRadius.circular(14),
          //                 ),
          //               ),
          //               .toList(),
          //         ),
          //       ],
          //     ),
          //   ),
          //   const SizedBox(height: 16),
          // ],

          // 按钮区域
          Row(
            children: [
              // 开始对比/重新选择按钮
              Expanded(
                child: ElevatedButton(
                  onPressed: !_isLoadingData
                      ? () => _openSelectionDialogSafely()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _selectedIds.isEmpty ? '点击选择' : '重新选择',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),

              // 执行对比按钮
              // if (_selectedIds.length >= 2) ...[
              //   const SizedBox(width: 8),
              //   Expanded(
              //     child: ElevatedButton(
              //       onPressed: !_isLoadingData ? _fetchComparisonData : null,
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: Theme.of(context).primaryColor,
              //         foregroundColor: Colors.white,
              //         padding: const EdgeInsets.symmetric(vertical: 16),
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(8),
              //         ),
              //       ),
              //       child: _isLoadingData
              //           ? const SizedBox(
              //               height: 20,
              //               width: 20,
              //               child: CircularProgressIndicator(
              //                 strokeWidth: 2,
              //                 valueColor:
              //                     AlwaysStoppedAnimation<Color>(Colors.white),
              //               ),
              //             )
              //           : const Text('执行对比'),
              //     ),
              //   ),
              // ],
              const SizedBox(width: 8),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (context) => const BrandSettingsPage(),
                    ),
                  ),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text(
                    '定义分值',
                    style: TextStyle(fontSize: 12),
                  ),
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
              // 生成表格图片按钮
              if (_comparisonData.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _captureAndShowImage,
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text(
                      '生成图片',
                      style: TextStyle(fontSize: 12),
                    ),
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
              if (_comparisonData.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _fetchComparisonData(saveReport: true),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text(
                      '保存报告',
                      style: TextStyle(fontSize: 12),
                    ),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    if (_comparisonData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(0),
        child: ComparisonTableWidget(
          comparisonData: _comparisonData,
          title: '对比分析',
          showScreenshotButton: false, // 因为上面已经有截图按钮了
          screenshotController: _comparisonTableController,
          columnColors: _getColumnColors(),
          isCity: _selectedType == 'city',
          headerBackgroundColor: _getStyle().headerColor,
          firstColumnColor: _getStyle().firstColumnColor,
          headerTextColor: _getStyle().textColor,
          borderColor: _getStyle().borderColor,
          cellTextColor: _getStyle().textColor,
        ),
      ),
    );
  }

  /// 生成表格截图
  Future<void> _captureAndShowImage() async {
    if (!mounted) return;
    try {
      await ScreenshotUtil.captureAndShowImage(
        context: context,
        controller: _comparisonTableController,
        errorMessage: '表格截图生成失败，请重试',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('截图失败: ${e.toString()}')),
        );
      }
    }
  }

  List<Widget> _buildFixedColumnRows() {
    if (_comparisonData.isEmpty) return [];

    List<Widget> rows = [];

    // 获取所有品牌
    Set<String> allBrands = {};
    for (var data in _comparisonData) {
      List<dynamic> brands = data['brands'] ?? [];
      for (var brand in brands) {
        String brandName =
            brand['brand']?['name'] ?? brand['brand']?['code'] ?? '未知品牌';
        allBrands.add(brandName);
      }
    }

    return rows;
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

  void _openFilterPanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: '筛选',
      barrierColor: Colors.black45,
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset =
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: offset,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ComparisonFilterPanel(
                    onClose: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    onStyleChanged: (i) => setState(() => _styleIndex = i),
                    initialStyleIndex: _styleIndex,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

class _SyncScrollTable extends StatefulWidget {
  final List<dynamic> comparisonData;
  final List<Widget> Function() buildFixedColumnRows;
  final List<Widget> Function() buildScrollableColumnRows;

  const _SyncScrollTable({
    required this.comparisonData,
    required this.buildFixedColumnRows,
    required this.buildScrollableColumnRows,
  });

  @override
  _SyncScrollTableState createState() => _SyncScrollTableState();
}

class _SyncScrollTableState extends State<_SyncScrollTable> {
  late ScrollController _leftScrollController;
  late ScrollController _rightScrollController;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _leftScrollController = ScrollController();
    _rightScrollController = ScrollController();

    _leftScrollController.addListener(_syncFromLeft);
    _rightScrollController.addListener(_syncFromRight);
  }

  void _syncFromLeft() {
    if (_isSyncing) return;
    if (!_rightScrollController.hasClients || !_leftScrollController.hasClients)
      return;

    _isSyncing = true;
    _rightScrollController.jumpTo(_leftScrollController.offset);
    Future.microtask(() => _isSyncing = false);
  }

  void _syncFromRight() {
    if (_isSyncing) return;
    if (!_leftScrollController.hasClients || !_rightScrollController.hasClients)
      return;

    _isSyncing = true;
    _leftScrollController.jumpTo(_rightScrollController.offset);
    Future.microtask(() => _isSyncing = false);
  }

  @override
  void dispose() {
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 固定的名称列
        Container(
          width: 120,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Column(
            children: [
              // 表头
              Container(
                height: 56,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kHeaderBackgroundColor,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: const Text(
                  '品牌/对象',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              // 数据行
              Expanded(
                child: SingleChildScrollView(
                  controller: _leftScrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: widget.buildFixedColumnRows(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
