import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/mall.dart';
import '../api/brand.dart';
import '../utils/http_client.dart';
import '../utils/toast_util.dart';
import '../models/province.dart';
import '../models/city.dart';
import '../utils/storage.dart';
import '../widgets/custom_refresh_widget.dart';

class MallDetailPage extends StatefulWidget {
  const MallDetailPage({Key? key}) : super(key: key);

  @override
  State<MallDetailPage> createState() => _MallDetailPageState();
}

class _MallDetailPageState extends State<MallDetailPage> {
  List<MallData> mallList = [];
  bool isLoading = false;
  int currentPage = 1;
  final int pageSize = 99;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  // 省市筛选相关状态
  List<dynamic> provinces = [];
  List<dynamic> cities = [];
  String? selectedProvinceId;
  String? selectedCityId;
  String selectedProvinceName = '全部省份';
  String selectedCityName = '全部城市';
  bool isLoadingProvinces = false;
  bool isLoadingCities = false;

  // 缓存相关变量
  ProvinceModel? cachedProvince;
  CityModel? cachedCity;

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

  @override
  void initState() {
    super.initState();
    fetchProvinces();
    loadCachedProvinceCity(); // 先加载缓存数据
    fetchMall(); // 然后获取商城数据（会使用缓存的省市信息）
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 加载缓存的省市信息
  Future<void> loadCachedProvinceCity() async {
    try {
      final cachedProvinceName = await Storage.getString('selected_province');
      final cachedCityName = await Storage.getString('selected_city');

      if (cachedProvinceName != null && cachedCityName != null) {
        final provinceMap = await Storage.getJson('selected_province_data');
        final cityMap = await Storage.getJson('selected_city_data');

        if (provinceMap != null && cityMap != null) {
          setState(() {
            // cachedProvince = ProvinceModel.fromJson(provinceMap);
            // cachedCity = CityModel.fromJson(cityMap);

            // // 设置选中的省市ID和名称
            // selectedProvinceId = cachedProvince!.code;
            // selectedCityId = cachedCity!.code;
            // selectedProvinceName = cachedProvince!.name;
            // selectedCityName = cachedCity!.name;
          });

          print('已加载缓存位置：${cachedProvince!.name} ${cachedCity!.name}');
        }
      }
    } catch (e) {
      print('加载缓存省市信息失败: $e');
      // 缓存加载失败，忽略错误，使用默认值
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!isLoading && hasMore) {
        _loadMore();
      }
    }
  }

  // 获取省份数据
  Future<void> fetchProvinces() async {
    if (isLoadingProvinces) return;

    setState(() {
      isLoadingProvinces = true;
    });

    try {
      final response = await HttpClient.get(brandApi.getBrandTree, params: {
        'level': 1,
      });

      if (response['success']) {
        final List<dynamic> provincesData = response['data']['provinces'] ?? [];

        setState(() {
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
          }).toList();
          isLoadingProvinces = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingProvinces = false;
      });
      ToastUtil.showError('获取省份数据失败');
    }
  }

  // 获取城市数据
  Future<void> fetchCities(String provinceId) async {
    if (isLoadingCities) return;

    setState(() {
      isLoadingCities = true;
      cities = [];
      selectedCityId = null;
      selectedCityName = '全部城市';
    });

    try {
      final response = await HttpClient.get(brandApi.getBrandTree, params: {
        'level': 2,
        'provinceId': provinceId,
      });

      if (response['success']) {
        final List<dynamic> cityData =
            response['data']['provinces'][0]['cities'] ?? [];

        setState(() {
          cities = cityData.map((city) {
            return {
              'name': city['name'],
              'id': city['_id'],
            };
          }).toList();
          isLoadingCities = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingCities = false;
      });
      ToastUtil.showError('获取城市数据失败');
    }
  }

  Future<void> fetchMall(
      {bool useCache = true, bool fallbackToAll = true}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      Map<String, dynamic> params = {};

      // 如果启用缓存且当前没有选择省市，则使用缓存的数据
      if (useCache && selectedProvinceId == null && selectedCityId == null) {
        if (cachedProvince != null) {
          params['provinceId'] = cachedProvince!.code;
        }
        if (cachedCity != null) {
          params['cityId'] = cachedCity!.code;
        }
      } else {
        // 使用当前选择的省市
        if (selectedProvinceId != null) {
          params['provinceId'] = selectedProvinceId;
        }
        if (selectedCityId != null) {
          params['cityId'] = selectedCityId;
        }
      }

      params['limit'] = 999;

      final response = await HttpClient.get(brandApi.getMalls, params: params);
      if (response['success'] == true) {
        final List<dynamic> data = response['data']['malls'] ?? [];
        final List<MallData> newMalls =
            data.map((item) => MallData.fromJson(item)).toList();

        // 如果筛选结果为空且启用回退，则查询全部数据
        if (newMalls.isEmpty &&
            fallbackToAll &&
            params.containsKey('provinceId')) {
          print('筛选结果为空，回退到查询全部商城数据');
          await fetchMall(useCache: false, fallbackToAll: false);
          return;
        }

        setState(() {
          if (currentPage == 1) {
            mallList = newMalls;
          } else {
            mallList.addAll(newMalls);
          }
          hasMore = newMalls.length == pageSize;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ToastUtil.showError('获取购物中心数据失败');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // ToastUtil.showError('网络错误，请稍后重试');
    }
  }

  Future<void> _loadMore() async {
    currentPage++;
    await fetchMall(useCache: false); // 加载更多时不使用缓存，使用当前筛选条件
  }

  Future<void> _onRefresh() async {
    currentPage = 1;
    hasMore = true;
    await fetchMall(useCache: false); // 刷新时不使用缓存，使用当前筛选条件
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildCustomHeader(),
          _buildFilterBar(),
          Expanded(
            child: CustomRefreshWidget(
              onRefresh: _onRefresh,
              child: mallList.isEmpty && !isLoading
                  ? const Center(
                      child: Text(
                        '暂无购物中心数据',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: mallList.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == mallList.length) {
                          return _buildLoadingIndicator();
                        }
                        return _buildMallCard(mallList[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建自定义标题区域
  Widget _buildCustomHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 120, 160, 230), // 更深的蓝色
            Color.fromARGB(255, 120, 160, 230), // 更深的蓝色
          ],
          stops: [0.0, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 自定义导航栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      '购物中心',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // 平衡左侧按钮
                ],
              ),
            ),
            // 统计信息区域
            // Container(
            //   margin: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            //   padding: const EdgeInsets.all(20),
            //   decoration: BoxDecoration(
            //     color: Colors.white.withOpacity(0.15),
            //     borderRadius: BorderRadius.circular(20),
            //     border: Border.all(
            //       color: Colors.white.withOpacity(0.3),
            //       width: 1,
            //     ),
            //   ),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceAround,
            //     children: [
            //       _buildStatItem('购物中心', '${mallList.length}'),
            //       _buildStatItem('省份', '${provinces.length}'),
            //       _buildStatItem('城市', '${cities.length}'),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  // 构建筛选栏
  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterItem(
              label: '省份',
              value: selectedProvinceName,
              items: ['全部省份', ...provinces.map((p) => p['name'] as String)],
              onTap: () => _showFilterDialog(
                title: '选择省份',
                items: ['全部省份', ...provinces.map((p) => p['name'] as String)],
                selectedValue: selectedProvinceName,
                onSelected: (value) {
                  if (value == '全部省份') {
                    setState(() {
                      selectedProvinceId = null;
                      selectedProvinceName = '全部省份';
                      selectedCityId = null;
                      selectedCityName = '全部城市';
                      cities = [];
                    });
                  } else {
                    final province =
                        provinces.firstWhere((p) => p['name'] == value);
                    setState(() {
                      selectedProvinceId = province['id'];
                      selectedProvinceName = value;
                    });
                    fetchCities(province['id']);
                  }
                  _onRefresh();
                },
              ),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.grey.withOpacity(0.2),
          ),
          Expanded(
            child: _buildFilterItem(
              label: '城市',
              value: selectedCityName,
              items: selectedProvinceId == null
                  ? ['全部城市']
                  : ['全部城市', ...cities.map((c) => c['name'] as String)],
              onTap: selectedProvinceId == null
                  ? null
                  : () => _showFilterDialog(
                        title: '选择城市',
                        items: selectedProvinceId == null
                            ? ['全部城市']
                            : [
                                '全部城市',
                                ...cities.map((c) => c['name'] as String)
                              ],
                        selectedValue: selectedCityName,
                        onSelected: (value) {
                          if (value == '全部城市') {
                            setState(() {
                              selectedCityId = null;
                              selectedCityName = '全部城市';
                            });
                          } else {
                            final city =
                                cities.firstWhere((c) => c['name'] == value);
                            setState(() {
                              selectedCityId = city['id'];
                              selectedCityName = value;
                            });
                          }
                          _onRefresh();
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建筛选项
  Widget _buildFilterItem({
    required String label,
    required String value,
    required List<String> items,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   label,
            //   style: TextStyle(
            //     fontSize: 12,
            //     color: Colors.grey[600],
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDisabled ? Colors.grey[400] : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: isDisabled ? Colors.grey[400] : Colors.grey[600],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 显示筛选对话框
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
            // 选项列表
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
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: Colors.blue.withOpacity(0.3), width: 1)
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
                                    ? Colors.blue[700]
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
                              color: Colors.blue[700],
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

  Widget _buildMallCard(MallData mall) {
    return GestureDetector(
      onTap: () {
        context.push('/mall-brand/${mall.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: mall.isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      mall.isActive ? '营业中' : '暂停营业',
                      style: TextStyle(
                        color: mall.isActive ? Colors.green : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  Text(
                    '${mall.province.name} ${mall.city.name}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                mall.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                mall.address,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // 取出当前商场的所有品牌的 brandId（过滤空值），作为预选项

                      // 只要有一个品牌就带入预选并自动打开选择弹窗
                      final query =
                          'mallId=${mall.id}&open=true&mallName=${mall.name}';
                      print(query);
                      context.go('/compare?$query');
                    },
                    icon: const Icon(Icons.compare_arrows, size: 16),
                    label: const Text('去对比'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      minimumSize: const Size(0, 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '查看品牌',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.blue[700],
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: isLoading
          ? const CircularProgressIndicator()
          : const Text(
              '没有更多数据了',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
    );
  }
}
