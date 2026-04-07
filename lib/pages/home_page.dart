import 'package:business_savvy/pages/mall_brand_page.dart';
import 'package:business_savvy/pages/mall_detail_page.dart';
import 'package:business_savvy/pages/simple_map_page.dart';
import 'package:business_savvy/pages/spring_festival_stats_page.dart';
import 'package:business_savvy/widgets/loading_indicator_widget.dart';
import 'package:business_savvy/widgets/ai_floating_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:business_savvy/pages/brand_center_page.dart';
import '../api/brand.dart';
import '../utils/http_client.dart';
import '../models/brand.dart';
import '../models/mall.dart';
import '../models/address.dart';
import '../models/province.dart';
import '../models/city.dart';
import '../utils/location_helper.dart';
import '../utils/storage.dart';
import '../widgets/custom_refresh_widget.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:business_savvy/pages/message_page.dart';
import '../utils/event_bus.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 品牌列表数组
  List<BrandModel> brandList = [];
  List<dynamic> mallList = [];
  bool isLoading = true;
  // 交流-推荐列表
  List<Map<String, dynamic>> recommendBlogs = [];
  bool isLoadingRecommend = true;
  final TextEditingController _searchController =
      TextEditingController(); // 添加搜索控制器
  int recommendPage = 1;
  bool recommendHasMore = true;
  bool recommendLoadingMore = false;
  final ScrollController _recommendScrollController = ScrollController();
  late StreamSubscription _refreshSubscription; // 添加刷新事件订阅
  late StreamSubscription<List<ConnectivityResult>>
      _connectivitySubscription; // 网络状态订阅
  bool _hasNetworkConnection = false; // 网络连接状态
  bool _initialDataLoaded = false; // 是否已加载初始数据

  // 地址相关状态
  List<AddressModel> addressList = [];
  AddressModel? defaultAddress;
  bool isLoadingAddress = false;

  // 省市选择相关状态
  List<ProvinceModel> provinceList = [];
  List<CityModel> cityList = [];
  ProvinceModel? selectedProvince;
  CityModel? selectedCity;
  bool isLoadingProvinces = false;
  bool isLoadingCities = false;

  @override
  void initState() {
    super.initState();
    _recommendScrollController.addListener(_onRecommendScroll);

    // 监听首页刷新事件
    _refreshSubscription = eventBus.on<HomePageRefreshEvent>().listen((_) {
      _refreshHomePage();
    });

    // 初始化网络状态监听
    // _initConnectivity();
    // _connectivitySubscription =
    //     Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
      _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose(); // 只在dispose时释放控制器
    _recommendScrollController.dispose();
    _refreshSubscription.cancel(); // 取消刷新事件订阅
    // _connectivitySubscription.cancel(); // 取消网络状态订阅
    super.dispose();
  }

  Future<void> fetchMall({String? provinceId, String? cityId}) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // 构建请求参数
      Map<String, dynamic> params = {};
      if (provinceId != null) {
        params['provinceId'] = provinceId;
      }
      if (cityId != null) {
        params['cityId'] = cityId;
      }

      final response = await HttpClient.get(brandApi.getMalls, params: params);

      if (!mounted) return;
      if (response['success']) {
        final List<dynamic> mallData = response['data']['malls'] ?? [];

        // 如果筛选后的列表为空，且有筛选条件，则获取全部商城列表
        // if (mallData.isEmpty) {
        //   // 递归调用获取全部商城列表
        //   await fetchMall();
        //   return;
        // }

        setState(() {
          mallList = mallData.map((item) => MallData.fromJson(item)).toList();
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
        SnackBar(content: Text('刷新失败')),
      );
    }
    // 返回 Future 完成
    return Future.value();
  }

  Future<void> fetchBrand() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await HttpClient.get(brandApi.getBrand);

      if (!mounted) return;
      if (response['success']) {
        final List<dynamic> brandData = response['data']['brands'] ?? [];
        setState(() {
          brandList =
              brandData.map((item) => BrandModel.fromJson(item)).toList();
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
        SnackBar(content: Text('刷新失败')),
      );
    }
    // 返回 Future 完成
    return Future.value();
  }

  Future<void> fetchRecommendBlogs() async {
    if (!mounted) return;
    setState(() {
      isLoadingRecommend = true;
    });
    try {
      final response = await HttpClient.get('blogs/all?page=$recommendPage');
      if (!mounted) return;
      if (response['success'] == true) {
        final List<dynamic> blogsData = response['data']['blogs'] ?? [];
        final pagination = response['data']['pagination'] ?? {};
        setState(() {
          if (recommendPage == 1) {
            recommendBlogs = blogsData.cast<Map<String, dynamic>>();
          } else {
            recommendBlogs.addAll(blogsData.cast<Map<String, dynamic>>());
          }
          // 修正 recommendHasMore 的逻辑

          recommendHasMore = response['data']['pagination']['page'] <
              response['data']['pagination']['pages'];
          isLoadingRecommend = false;
        });
      } else {
        setState(() {
          isLoadingRecommend = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingRecommend = false;
      });
    }
  }

  Future<void> loadMoreRecommend() async {
    if (!mounted || recommendLoadingMore || !recommendHasMore) return;

    print('开始加载更多推荐内容，当前页：$recommendPage');

    setState(() {
      recommendLoadingMore = true;
    });
    try {
      final nextPage = recommendPage + 1;
      final response = await HttpClient.get('blogs/all?page=$nextPage');
      if (!mounted) return;
      if (response['success'] == true) {
        final data = response['data'] as Map? ?? const {};
        final List<dynamic> blogsData = data['blogs'] ?? [];
        final pagination = data['pagination'] ?? {};
        setState(() {
          recommendBlogs.addAll(blogsData.cast<Map<String, dynamic>>());
          recommendPage = nextPage;
          // 修正 recommendHasMore 的逻辑
          recommendHasMore = response['data']['pagination']['page'] <
              response['data']['pagination']['pages'];
          recommendLoadingMore = false;
        });
      } else {
        setState(() {
          recommendLoadingMore = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        recommendLoadingMore = false;
      });
    }
  }

  // 加载缓存的省市信息
  Future<void> loadCachedProvinceCity() async {
    try {
      final cachedProvince = await Storage.getString('selected_province');
      final cachedCity = await Storage.getString('selected_city');

      if (cachedProvince != null && cachedCity != null) {
        final provinceMap = await Storage.getJson('selected_province_data');
        final cityMap = await Storage.getJson('selected_city_data');

        if (provinceMap != null && cityMap != null) {
          setState(() {
            selectedProvince = ProvinceModel.fromJson(provinceMap);
            selectedCity = CityModel.fromJson(cityMap);

            // 根据缓存的省市信息创建默认地址
            if (defaultAddress == null) {
              defaultAddress = AddressModel(
                id: 'cached_location',
                name: '选择的位置',
                province: selectedProvince!.name,
                city: selectedCity!.name,
                district: '',
                detail: '',
                phone: '',
                isDefault: false,
                provinceId: selectedProvince!.id,
                cityId: selectedCity!.id,
              );
            }
          });
          // print('已选择位置：${selectedProvince!.code} ${selectedCity!.id}');
          // 根据缓存的省市信息获取商城数据
          await fetchMall(
            provinceId: selectedProvince!.code,
            cityId: selectedCity!.code,
          );
        }
      }
    } catch (e) {
      // 缓存加载失败，忽略错误
    }
  }

  // 获取省份列表
  Future<void> fetchProvinces() async {
    setState(() {
      isLoadingProvinces = true;
    });

    try {
      final response = await HttpClient.get(brandApi.getProvinces);
      if (!mounted) return;

      if (response['success']) {
        final List<dynamic> provinceData = response['data']['provinces'] ?? [];
        setState(() {
          provinceList =
              provinceData.map((item) => ProvinceModel.fromJson(item)).toList();
          isLoadingProvinces = false;
        });
      } else {
        setState(() {
          isLoadingProvinces = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingProvinces = false;
      });
    }
  }

  // 获取城市列表
  Future<void> fetchCities(String provinceId) async {
    setState(() {
      isLoadingCities = true;
      cityList = [];
      selectedCity = null;
    });

    try {
      final response =
          await HttpClient.get('${brandApi.getCities}?provinceId=$provinceId');
      if (!mounted) return;

      if (response['success']) {
        final List<dynamic> cityData = response['data']['cities'] ?? [];
        setState(() {
          cityList = cityData.map((item) => CityModel.fromJson(item)).toList();
          isLoadingCities = false;
        });
      } else {
        setState(() {
          isLoadingCities = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingCities = false;
      });
    }
  }

  // 保存选择的省市到缓存
  Future<void> saveCachedProvinceCity() async {
    if (selectedProvince != null && selectedCity != null) {
      await Storage.setString('selected_province', selectedProvince!.name);
      await Storage.setString('selected_city', selectedCity!.name);
      await Storage.setJson(
          'selected_province_data', selectedProvince!.toJson());
      await Storage.setJson('selected_city_data', selectedCity!.toJson());
    }
  }

  Future<void> fetchDefaultAddress() async {
    if (!mounted) return;

    setState(() {
      isLoadingAddress = true;
    });

    try {
      await _tryGetCurrentLocation();
      // final response = await HttpClient.get(brandApi.getDefaultAddress);
      // if (!mounted) return;

      // if (response['success']) {
      //   final addressData = response['data'];
      //   if (addressData != null) {
      //     setState(() {
      //       defaultAddress = AddressModel.fromJson(addressData);
      //       isLoadingAddress = false;
      //     });
      //   } else {
      //     // 如果没有默认地址，尝试获取当前位置

      //   }
      // } else {
      //   // API调用失败，尝试获取当前位置
      //   await _tryGetCurrentLocation();
      // }
    } catch (e) {
      if (!mounted) return;
      // 发生异常，尝试获取当前位置
      await _tryGetCurrentLocation();
    }
  }

  // 尝试获取当前位置
  Future<void> _tryGetCurrentLocation() async {
    try {
      AddressModel? currentAddressModel =
          await LocationHelper.getCurrentDetailedAddress();
      if (!mounted) return;
      await fetchMall(
          provinceId: currentAddressModel?.province,
          cityId: currentAddressModel?.city);

      if (currentAddressModel != null) {
        setState(() {
          defaultAddress = currentAddressModel;
          isLoadingAddress = false;
        });
      } else {
        setState(() {
          defaultAddress = null;
          isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        defaultAddress = null;
        isLoadingAddress = false;
      });
    }
  }

  // 获取地址列表
  Future<void> fetchAddressList() async {
    if (!mounted) return;

    try {
      final response = await HttpClient.get(brandApi.getAddressList);
      if (!mounted) return;

      if (response['success']) {
        final List<dynamic> addressData = response['data'] ?? [];
        setState(() {
          addressList =
              addressData.map((item) => AddressModel.fromJson(item)).toList();
        });
      }
    } catch (e) {
      if (!mounted) return;
      // 处理错误
    }
  }

  // 获取城市列表（用于弹窗）
  Future<void> _fetchCitiesForModal(
      String provinceId, void Function(void Function()) setModalState) async {
    try {
      final response =
          await HttpClient.get('${brandApi.getCities}?provinceId=$provinceId');
      if (response['success'] && response['data'] != null) {
        final cityData = response['data']['cities'] as List<dynamic>;
        setModalState(() {
          cityList = cityData.map((item) => CityModel.fromJson(item)).toList();
          isLoadingCities = false;
        });
        setState(() {
          cityList = cityData.map((item) => CityModel.fromJson(item)).toList();
          isLoadingCities = false;
        });
      } else {
        setModalState(() {
          cityList = [];
          isLoadingCities = false;
        });
        setState(() {
          cityList = [];
          isLoadingCities = false;
        });
      }
    } catch (e) {
      // print('获取城市列表失败: $e');
      setModalState(() {
        cityList = [];
        isLoadingCities = false;
      });
      setState(() {
        cityList = [];
        isLoadingCities = false;
      });
    }
  }

  // 显示省市选择弹窗
  void _showProvinceCitySelector() async {
    await fetchProvinces();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '选择省市',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    // 省份列表
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                              right:
                                  BorderSide(color: Colors.grey, width: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                '省份',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(
                              child: isLoadingProvinces
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : ListView.builder(
                                      itemCount: provinceList.length,
                                      itemBuilder: (context, index) {
                                        final province = provinceList[index];
                                        final isSelected =
                                            selectedProvince?.id == province.id;

                                        return ListTile(
                                          title: Text(
                                            province.name,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.blue
                                                  : Colors.black87,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          selected: isSelected,
                                          selectedTileColor:
                                              Colors.blue.withOpacity(0.1),
                                          onTap: () async {
                                            setModalState(() {
                                              selectedProvince = province;
                                              selectedCity = null;
                                              isLoadingCities = true;
                                              cityList = [];
                                            });
                                            setState(() {
                                              selectedProvince = province;
                                              selectedCity = null;
                                            });

                                            // 获取城市列表
                                            await _fetchCitiesForModal(
                                                province.id, setModalState);
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 城市列表
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              '城市',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            child: selectedProvince == null
                                ? const Center(
                                    child: Text(
                                      '请先选择省份',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : isLoadingCities
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : cityList.isEmpty
                                        ? const Center(
                                            child: Text(
                                              '暂无城市数据',
                                              style:
                                                  TextStyle(color: Colors.grey),
                                            ),
                                          )
                                        : ListView.builder(
                                            itemCount: cityList.length,
                                            itemBuilder: (context, index) {
                                              final city = cityList[index];
                                              final isSelected =
                                                  selectedCity?.id == city.id;

                                              return ListTile(
                                                title: Text(
                                                  city.name,
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? Colors.blue
                                                        : Colors.black87,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                selected: isSelected,
                                                selectedTileColor: Colors.blue
                                                    .withOpacity(0.1),
                                                onTap: () async {
                                                  setModalState(() {
                                                    selectedCity = city;
                                                  });
                                                  setState(() {
                                                    selectedCity = city;
                                                    // 更新默认地址
                                                    defaultAddress =
                                                        AddressModel(
                                                      id: 'selected_location',
                                                      name: '选择的位置',
                                                      province:
                                                          selectedProvince!
                                                              .name,
                                                      city: selectedCity!.name,
                                                      district: '',
                                                      detail: '',
                                                      phone: '',
                                                      isDefault: false,
                                                      provinceId:
                                                          selectedProvince!.id,
                                                      cityId: selectedCity!.id,
                                                    );
                                                  });

                                                  // 保存到缓存
                                                  saveCachedProvinceCity();

                                                  // 关闭弹窗
                                                  Navigator.pop(context);

                                                  // 重新获取商城数据
                                                  await fetchMall(
                                                    provinceId:
                                                        selectedProvince!.id,
                                                    cityId: selectedCity!.id,
                                                  );
                                                },
                                              );
                                            },
                                          ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddressSelector() async {
    await fetchAddressList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '选择地址',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _getCurrentLocationAddress,
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text('定位'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: addressList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_off,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('暂无地址',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _getCurrentLocationAddress,
                            icon: const Icon(Icons.my_location),
                            label: const Text('获取当前位置'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: addressList.length +
                          1, // +1 for current location option
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // 当前位置选项
                          return ListTile(
                            leading: const Icon(Icons.my_location,
                                color: Colors.blue),
                            title: const Text('使用当前位置'),
                            subtitle: const Text('点击获取您的当前位置'),
                            onTap: _getCurrentLocationAddress,
                          );
                        }

                        final address = addressList[index - 1];
                        return ListTile(
                          leading: Icon(
                            address.isDefault
                                ? Icons.location_on
                                : Icons.location_on_outlined,
                            color:
                                address.isDefault ? Colors.blue : Colors.grey,
                          ),
                          title: Text(address.name),
                          subtitle: Text(address.shortAddress),
                          trailing: address.isDefault
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '默认',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              defaultAddress = address;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 获取当前位置地址
  void _getCurrentLocationAddress() async {
    Navigator.pop(context); // 关闭弹窗

    setState(() {
      isLoadingAddress = true;
    });

    try {
      // 检查并请求位置权限
      bool hasPermission =
          await LocationHelper.checkAndRequestLocationPermission();

      if (!hasPermission) {
        if (!mounted) return;
        setState(() {
          isLoadingAddress = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('需要位置权限才能获取当前地址，请在设置中开启位置权限'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // 获取当前位置地址
      String? currentAddress = await LocationHelper.getCurrentAddress();

      if (!mounted) return;

      if (currentAddress != null) {
        // 获取详细地址信息
        AddressModel? detailedAddress =
            await LocationHelper.getCurrentDetailedAddress();

        if (detailedAddress != null) {
          setState(() {
            defaultAddress = detailedAddress;
            isLoadingAddress = false;
          });

          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('已获取当前位置：${detailedAddress.displayAddress}'),
          //     duration: const Duration(seconds: 2),
          //   ),
          // );
        } else {
          setState(() {
            isLoadingAddress = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('获取当前位置失败，请检查网络连接或稍后重试'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingAddress = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('获取位置时发生错误：${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // 刷新首页的方法
  Future<void> _refreshHomePage() async {
    setState(() {
      recommendPage = 1;
    });
    await fetchBrand();
    await fetchMall();
    await fetchRecommendBlogs();

    // 刷新完成后，将滚动位置重置到顶部
    if (_recommendScrollController.hasClients) {
      _recommendScrollController.jumpTo(0);
    }
  }

  void _onRecommendScroll() {
    if (!recommendHasMore || recommendLoadingMore) return;

    final position = _recommendScrollController.position;

    // 当滚动到距离底部 200px 时开始加载
    if (position.pixels >= position.maxScrollExtent - 200) {
      loadMoreRecommend();
    }
  }

  // 初始化网络连接状态
  Future<void> _initConnectivity() async {
    
    try {
    
      final List<ConnectivityResult> results =
          await Connectivity().checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
       
      // print('检查网络状态失败: $e');
    }
  }

  // 更新网络连接状态
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    try {
      if (!mounted) return;
          // 检查是否有网络连接
    final bool hasConnection =
        results.any((result) => result != ConnectivityResult.none);

    // print('网络状态更新: $results, 有网络: $hasConnection');

    // 如果从无网络变为有网络，且还未加载初始数据
    if (hasConnection && !_hasNetworkConnection && !_initialDataLoaded) {
      setState(() {
        _hasNetworkConnection = true;
      });
      // 网络可用后加载数据
      _loadInitialData();
    } else {
      
        _loadInitialData();
      setState(() {
        _hasNetworkConnection = hasConnection;
      });
    }
    } catch (e) {
           print(134);
        _loadInitialData();
      print('检查网络状态失败: $e');
    }


  }

  // 加载初始数据
  Future<void> _loadInitialData() async {
    if (_initialDataLoaded) return;

    _initialDataLoaded = true;

    await fetchBrand();
    await fetchRecommendBlogs();
    await fetchDefaultAddress();
    await loadCachedProvinceCity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFfffff),
      // 移除appBar,让内容区域扩展到状态栏
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            CustomRefreshWidget(
              onRefresh: () async {
                // setState(() {
                //   recommendPage = 1;
                // });
                // // await fetchBrand();
                // // await fetchMall();
                // await fetchRecommendBlogs();
                await _refreshHomePage();
                // 刷新完成后，将滚动位置重置到顶部
                if (_recommendScrollController.hasClients) {
                  _recommendScrollController.jumpTo(0);
                }
              },
              child: SingleChildScrollView(
                controller: _recommendScrollController,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: MediaQuery.of(context).padding.top + 50, // 为浮空搜索栏留出空间
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 第一个Section - 圆形图标网格
                    _buildSectionHeader('品牌'),
                    const SizedBox(height: 16),
                    _buildCircularIconGrid(),
                    const SizedBox(height: 20),

                    // 第二个Section - 大图卡片
                    _buildSectionHeader('购物中心'),
                    const SizedBox(height: 10),
                    _buildLargeCard(),
                    const SizedBox(height: 20),

                    // 经济数据引导层
                    _buildSectionHeader('经济数据'),
                    const SizedBox(height: 10),
                    _buildEconomicDataSection(),
                    const SizedBox(height: 20),

                    // 第三个Section - 小图标网格
                    // _buildSectionHeader('分类'),
                    // const SizedBox(height: 20),
                    // _buildSmallIconGrid(),
                    // const SizedBox(height: 20),

                    // 第四个Section - 音乐卡片网格
                    _buildSectionHeader('交流'),
                    // const SizedBox(height: 20),
                    isLoading
                        ? const LoadingIndicatorWidget()
                        : _buildMessageRecommendSection(),
                    if (recommendLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    const SizedBox(height: 20),

                    // // 第五个Section - 新闻列表
                    // _buildSectionHeader('Section title'),
                    // const SizedBox(height: 20),
                    // _buildNewsList(),
                    // const SizedBox(height: 20),

                    // // 最后一个Section - More like
                    // _buildMoreLikeSection(),
                    // const SizedBox(height: 20),
                    // _buildBottomIconGrid(),
                    // const SizedBox(height: 20),
                    // _buildBottomText(),
                    // const SizedBox(height: 20),

                    // // 底部导航图标
                    // _buildBottomNavigation(),
                  ],
                ),
              ),
            ),
            // 浮空搜索栏 - 修改Positioned部分
            Positioned(
              top: 0, // 从屏幕最顶部开始
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                          builder: (context) =>
                              const BrandCenterPage(autoFocus: true)));
                },
                child: Container(
                  height:
                      MediaQuery.of(context).padding.top + 50, // 状态栏高度 + 搜索框高度
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromARGB(255, 120, 160, 230), // 更深的蓝色
                        Color.fromARGB(255, 255, 255, 255), // 半透明白色
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8), // 避免贴近灵动岛
                      child: _buildFloatingSearchBar(),
                    ),
                  ),
                ),
              ),
            ),

            // 右下角AI悬浮按钮
            const AiFloatingButton(
              initialRight: 16,
              initialBottom: 50,
            ),
          ],
        ),
      ),
    );
  }

// 浮空搜索框 - 移除渐变装饰
  Widget _buildFloatingSearchBar() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 搜索图标和搜索文本
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(),
              child: const Text(
                '搜索...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          // 地址选择区域
          GestureDetector(
            onTap: _showProvinceCitySelector,
            child: Container(
              decoration: BoxDecoration(
                // color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                // border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: defaultAddress != null ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  if (isLoadingAddress)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      defaultAddress?.displayAddress ?? '选择地址',
                      style: TextStyle(
                        fontSize: 12,
                        color: defaultAddress != null
                            ? Colors.black87
                            : Colors.grey,
                        fontWeight: defaultAddress != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return GestureDetector(
      onTap: () {
        if (title == '购物中心') {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => const MallDetailPage(),
            ),
          );
        }
        if (title == '交流') {
          context.go('/message');
        }
        if (title == '品牌') {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => const BrandCenterPage(),
            ),
          );
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Icon(
            Icons.arrow_forward,
            size: 20,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  // 搜索框
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
                // padding: const EdgeInsets.all(5),
                // decoration: BoxDecoration(
                //   color: Colors.black,
                //   borderRadius: BorderRadius.circular(15),
                // ),
                // child: const Icon(Icons.density_medium,
                //     color: Colors.white, size: 16),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularIconGrid() {
    return SizedBox(
      height: 88, // 设置固定高度
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // 水平滚动
        itemCount: brandList.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: _buildCircularIcon(brandList[index]),
        ),
      ),
    );
  }

  Widget _buildCircularIcon(BrandModel brand) {
    return GestureDetector(
      onTap: () {
        // Navigator.pushNamed(context, '/brand', arguments: brand);
        // context.go('/brandMap/${brand.id}');
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => SimpleMapPage(brandId: brand.id),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(brand.logo ?? ''),
                  fit: BoxFit.contain,
                )),
          ),
          const SizedBox(height: 8),
          Text(
            brand.name ?? '未命名品牌',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeCard() {
    if (mallList.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            '暂无购物中心数据',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mallList.length,
        itemBuilder: (context, index) {
          final mall = mallList[index];
          return GestureDetector(
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (context) => MallBrandPage(mallId: mall.id),
                  ),
                );
                // context.go('/mall-brand/${mall.id}');
                // Navigator.of(context, rootNavigator: true).push(
                //   // 添加 rootNavigator: true
                //   PageRouteBuilder(
                //     pageBuilder: (context, animation, secondaryAnimation) =>
                //         MallBrandPage(mallId: mall.id),
                //     transitionsBuilder:
                //         (context, animation, secondaryAnimation, child) {
                //       // 从中心点放大的动画效果
                //       return AnimatedBuilder(
                //         animation: animation,
                //         builder: (context, child) {
                //           // 动画进度
                //           final progress = animation.value;

                //           // 缩放效果：从0.0开始，放大到1.0
                //           final scale = Tween(begin: 0.0, end: 1.0).transform(
                //               Curves.easeOutBack.transform(progress));

                //           // 透明度：快速显现
                //           final opacity = Tween(begin: 0.0, end: 1.0)
                //               .transform(Curves.easeOut.transform(progress));

                //           return Transform.scale(
                //             scale: scale,
                //             alignment: Alignment.center, // 从中心点缩放
                //             child: Opacity(
                //               opacity: opacity,
                //               child: child,
                //             ),
                //           );
                //         },
                //         child: child,
                //       );
                //     },
                //     transitionDuration: const Duration(milliseconds: 300),
                //     reverseTransitionDuration:
                //         const Duration(milliseconds: 300),
                //   ),
                // );
              },
              child: Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
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
                                color:
                                    mall.isActive ? Colors.green : Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // ElevatedButton.icon(
                          //   onPressed: () {
                          //     // 取出当前商场的所有品牌的 brandId（过滤空值），作为预选项

                          //     // 只要有一个品牌就带入预选并自动打开选择弹窗
                          //     final query =
                          //         'mallId=${mall.id}&open=true&mallName=${mall.name}';
                          //     print(query);
                          //     context.go('/compare?$query');
                          //   },
                          //   icon: const Icon(Icons.compare_arrows, size: 16),
                          //   label: const Text('去对比'),
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Colors.transparent,
                          //     foregroundColor: Colors.black87,
                          //     elevation: 0,
                          //     shadowColor: Colors.transparent,
                          //     padding: const EdgeInsets.symmetric(
                          //         horizontal: 8, vertical: 2),
                          //     minimumSize: const Size(0, 28),
                          //     shape: RoundedRectangleBorder(
                          //       borderRadius: BorderRadius.circular(15),
                          //     ),
                          //   ),
                          // ),
                          Icon(
                            Icons.compare_arrows,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          GestureDetector(
                            onTap: () {
                              // 取出当前商场的所有品牌的 brandId（过滤空值），作为预选项

                              // 只要有一个品牌就带入预选并自动打开选择弹窗
                              final query =
                                  'mallId=${mall.id}&open=true&mallName=${mall.name}';
                              context.go('/compare?$query');
                            },
                            child: Text(
                              '去对比',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        mall.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // const SizedBox(height: 8),
                      // Text(
                      //   mall.address,
                      //   style: TextStyle(
                      //     color: Colors.grey[600],
                      //     fontSize: 14,
                      //   ),
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      // ),
                      const Spacer(),
                      // Row(
                      //   children: [
                      //     _buildInfoItem(
                      //       icon: Icons.layers,
                      //       label: '楼层',
                      //       value: '${mall.floorCount}层',
                      //     ),
                      //     const SizedBox(width: 16),
                      //     _buildInfoItem(
                      //       icon: Icons.square_foot,
                      //       label: '面积',
                      //       value: '${mall.totalArea}㎡',
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ));
        },
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallIconGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) => _buildSmallIcon()),
    );
  }

  Widget _buildSmallIcon() {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow, color: Colors.grey, size: 16),
              Icon(Icons.star, color: Colors.grey, size: 12),
              Icon(Icons.stop, color: Colors.grey, size: 12),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Label',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildMusicCardGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: List.generate(4, (index) => _buildMusicCard()),
    );
  }

  Widget _buildMessageRecommendSection() {
    if (isLoadingRecommend) {
      return const Center(child: CircularProgressIndicator());
    }
    if (recommendBlogs.isEmpty) {
      return const SizedBox.shrink();
    }
    // 使用与 message_page 相同的瀑布流卡片样式（RedBookCard）
    return MasonryGridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      itemCount: recommendBlogs.length,
      itemBuilder: (context, index) {
        final item = recommendBlogs[index];
        // 与 message_page 中的 Blog.fromJson 字段对应
        final String id = (item['_id'] ?? '').toString();
        final String title = (item['title'] ?? '').toString();
        final String content = (item['content'] ?? '').toString();
        final String createName = (item['createName'] ?? '').toString();
        final String createdAt = (item['createdAt'] ?? '').toString();
        final String type = (item['type'] ?? '').toString();
        final String defaultImage = (item['defaultImage'] ?? '').toString();
        final Map<String, dynamic>? user =
            item['user'] is Map<String, dynamic> ? item['user'] : null;

        final contentLength = title.length + content.length;
        final double randomHeight = 180.0 + (contentLength % 3) * 40;

        return RedBookCard(
          avatar: '',
          name: createName,
          title: title,
          content: content,
          time: createdAt,
          type: type,
          defaultImage: defaultImage,
          likes: 0,
          comments: 0,
          height: randomHeight,
          id: id,
          user: user,
        );
      },
      // 移除 controller 参数，避免与 SingleChildScrollView 的 controller 冲突
    );
  }

  Widget _buildMusicCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_arrow,
            size: 32,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.grey, size: 16),
              SizedBox(width: 8),
              Icon(Icons.stop, color: Colors.grey, size: 16),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Artist',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            'Song',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList() {
    return Column(
      children: List.generate(2, (index) => _buildNewsItem()),
    );
  }

  Widget _buildNewsItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, color: Colors.grey),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.grey, size: 12),
                    SizedBox(width: 4),
                    Icon(Icons.stop, color: Colors.grey, size: 12),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Headline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Description duis aute irure dolor in reprehenderit in voluptate velit.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Today • 23 min',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.play_arrow,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreLikeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'More like',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Text(
              'Title',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward,
              size: 20,
              color: Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomIconGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) => _buildSmallIcon()),
    );
  }

  Widget _buildBottomText() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore...',
        style: TextStyle(
          fontSize: 14,
          color: Colors.black54,
          height: 1.5,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildBottomNavItem(Icons.star_outline, 'Label'),
        _buildBottomNavItem(Icons.star_outline, 'Label'),
        _buildBottomNavItem(Icons.star_outline, 'Label'),
      ],
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.purple[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.purple[400],
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.purple[400],
          ),
        ),
      ],
    );
  }

  // 经济数据引导层
  Widget _buildEconomicDataSection() {
    final economicData = [
      {
        'title': '春节数据',
        'subtitle': '春节消费',
        'icon': Icons.celebration,
        'color': const Color(0xFFFF6B6B),
        'gradient': const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
        ),
      },
      {
        'title': '五一数据',
        'subtitle': '劳动节消费',
        'icon': Icons.work_outline,
        'color': const Color(0xFF4ECDC4),
        'gradient': const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF6FE7DD)],
        ),
      },
      {
        'title': '国庆数据',
        'subtitle': '国庆黄金周',
        'icon': Icons.flag,
        'color': const Color(0xFFFFBE0B),
        'gradient': const LinearGradient(
          colors: [Color(0xFFFFBE0B), Color(0xFFFFD93D)],
        ),
      },
      {
        'title': '双十一',
        'subtitle': '购物狂欢节',
        'icon': Icons.shopping_bag,
        'color': const Color(0xFFB565D8),
        'gradient': const LinearGradient(
          colors: [Color(0xFFB565D8), Color(0xFFCE93E8)],
        ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题

        const SizedBox(height: 12),

        // 横向滚动的数据卡片
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: economicData.length,
            itemBuilder: (context, index) {
              final data = economicData[index];
              return Container(
                width: 160,
                margin: EdgeInsets.only(
                  right: index < economicData.length - 1 ? 12 : 0,
                ),
                child: _buildEconomicDataCard(
                  title: data['title'] as String,
                  subtitle: data['subtitle'] as String,
                  icon: data['icon'] as IconData,
                  gradient: data['gradient'] as LinearGradient,
                  onTap: () {
                    // 跳转到对应的数据详情页
                    if (data['title'] == '春节数据') {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (context) => SpringFestivalStatsPage(),
                        ),
                      );
                    } else {
                      print('点击了 ${data['title']} - 功能开发中');
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 经济数据卡片
  Widget _buildEconomicDataCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 背景装饰图案
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                icon,
                size: 100,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),

            // 内容
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 图标
                  // Container(
                  //   padding: const EdgeInsets.all(8),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white.withValues(alpha: 0.3),
                  //     borderRadius: BorderRadius.circular(8),
                  //   ),
                  //   child: Icon(
                  //     icon,
                  //     color: Colors.white,
                  //     size: 24,
                  //   ),
                  // ),

                  // 文字信息
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 右上角箭头
            Positioned(
              right: 12,
              top: 12,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
