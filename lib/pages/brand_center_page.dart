import 'package:flutter/material.dart';
import 'package:business_savvy/pages/simple_map_page.dart';
import '../models/brand.dart';
import '../api/brand.dart';
import '../utils/http_client.dart';
import '../utils/toast_util.dart';

class BrandCenterPage extends StatefulWidget {
  final bool autoFocus;

  const BrandCenterPage({Key? key, this.autoFocus = false}) : super(key: key);

  @override
  State<BrandCenterPage> createState() => _BrandCenterPageState();
}

class _BrandCenterPageState extends State<BrandCenterPage> {
  bool isLoading = false;
  bool isCategoryLoading = false;
  List<BrandModel> allBrands = [];
  List<BrandModel> filteredBrands = [];
  List<Map<String, dynamic>> categories = [];

  String searchQuery = '';
  String selectedCategoryId = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // 添加FocusNode

  @override
  void initState() {
    super.initState();
    fetchBrands();
    fetchCategories();

    // 如果需要自动聚焦，延迟一帧后聚焦搜索框
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose(); // 释放FocusNode
    super.dispose();
  }

  // 获取所有品牌数据
  Future<void> fetchBrands() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await HttpClient.get(brandApi.getBrand, params: {
        'page': 1,
        'limit': 20,
        'category': selectedCategoryId,
        'search': searchQuery,
      });

      if (response['success'] == true) {
        final List<dynamic> brandsData = response['data']['brands'] ?? [];

        setState(() {
          allBrands =
              brandsData.map((item) => BrandModel.fromJson(item)).toList();
          filteredBrands = List.from(allBrands);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ToastUtil.showError('获取品牌数据失败');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ToastUtil.showError('网络错误，请稍后重试');
    }
  }

  // 获取品牌分类数据
  Future<void> fetchCategories() async {
    setState(() {
      isCategoryLoading = true;
    });

    try {
      final response = await HttpClient.get(
          'admin/dictionaries?page=1&limit=20&type=brand_category');

      if (response['success'] == true) {
        final List<dynamic> categoriesData =
            response['data']['dictionaries'] ?? [];

        setState(() {
          categories = categoriesData.cast<Map<String, dynamic>>();
          isCategoryLoading = false;
        });
      } else {
        setState(() {
          isCategoryLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isCategoryLoading = false;
      });
    }
  }

  // 筛选品牌
  void _filterBrands() {
    setState(() {
      filteredBrands = allBrands.where((brand) {
        bool matchesSearch = searchQuery.isEmpty ||
            (brand.name?.toLowerCase().contains(searchQuery.toLowerCase()) ??
                false);

        bool matchesCategory =
            selectedCategoryId.isEmpty || brand.type == selectedCategoryId;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  // 搜索品牌
  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  // 执行搜索
  void _performSearch() {
    fetchBrands();
  }

  // 选择分类
  void _onCategorySelected(String categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
    });
    // _filterBrands();
    fetchBrands();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color.fromARGB(255, 120, 160, 230),
        title: const Text(
          '品牌中心',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBrands.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '暂无品牌数据',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredBrands.length,
                        itemBuilder: (context, index) {
                          return _buildBrandItem(filteredBrands[index]);
                        },
                      ),
          ),
          // 底部声明
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                '品牌统计源于网络统计，如有错误，请联系管理员',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 筛选区域
  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 搜索框
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode, // 添加focusNode
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _performSearch(), // 点击确认时执行搜索
              textInputAction: TextInputAction.search, // 设置键盘确认按钮为搜索图标
              decoration: InputDecoration(
                hintText: '搜索品牌名称',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.blue),
                  onPressed: _performSearch, // 点击搜索图标执行搜索
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 分类筛选
          if (categories.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '品牌分类',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCategoryChip(
                        '全部', '', selectedCategoryId.isEmpty);
                  }
                  final category = categories[index - 1];
                  final categoryId = category['value'] ?? '';
                  final categoryName = category['label'] ?? '';
                  return _buildCategoryChip(
                    categoryName,
                    categoryId,
                    selectedCategoryId == categoryId,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 分类筛选标签
  Widget _buildCategoryChip(String label, String categoryId, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _onCategorySelected(categoryId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // 品牌项目组件（参考MallBrandPage的_buildBrandItem样式）
  Widget _buildBrandItem(BrandModel brand) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SimpleMapPage(
                brandId: brand.id,
              ),
            ),
          )
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(brand.logo ?? ''),
                  fit: BoxFit.contain,
                  onError: (exception, stackTrace) =>
                      const AssetImage('assets/brand/default.png'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                brand.name ?? '未命名品牌',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
