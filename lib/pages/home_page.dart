import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api/brand.dart';
import '../utils/http_client.dart';
import '../models/brand.dart';
import '../models/mall.dart';

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
  final TextEditingController _searchController =
      TextEditingController(); // 添加搜索控制器

  @override
  void initState() {
    super.initState();
    fetchBrand();
    fetchMall();
  }

  @override
  void dispose() {
    _searchController.dispose(); // 只在dispose时释放控制器
    super.dispose();
  }

  Future<void> fetchMall() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await HttpClient.get(brandApi.getMalls);

      if (!mounted) return;
      if (response['success']) {
        final List<dynamic> mallData = response['data']['malls'] ?? [];
        setState(() {
          mallList = mallData.map((item) => MallData.fromJson(item)).toList();
          isLoading = false;
        });
        print('MallData: $mallList');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      // 添加错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刷新失败：${e.toString()}')),
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
        SnackBar(content: Text('刷新失败：${e.toString()}')),
      );
    }
    // 返回 Future 完成
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFfffff),
      // 移除appBar,让内容区域扩展到状态栏
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // 浮空搜索栏

          RefreshIndicator(
            onRefresh: () async {
              await fetchBrand();
              await fetchMall();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 120, // 为浮空搜索栏留出空间
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // 第一个Section - 圆形图标网格
                  _buildSectionHeader('品牌'),
                  const SizedBox(height: 16),
                  _buildCircularIconGrid(),
                  const SizedBox(height: 20),

                  // 第二个Section - 大图卡片
                  _buildSectionHeader('购物中心'),
                  const SizedBox(height: 20),
                  _buildLargeCard(),
                  const SizedBox(height: 20),

                  // 第三个Section - 小图标网格
                  _buildSectionHeader('分类'),
                  const SizedBox(height: 20),
                  _buildSmallIconGrid(),
                  const SizedBox(height: 20),

                  // 第四个Section - 音乐卡片网格
                  _buildSectionHeader('Section title'),
                  // const SizedBox(height: 20),
                  _buildMusicCardGrid(),
                  const SizedBox(height: 20),

                  // 第五个Section - 新闻列表
                  _buildSectionHeader('Section title'),
                  const SizedBox(height: 20),
                  _buildNewsList(),
                  const SizedBox(height: 20),

                  // 最后一个Section - More like
                  _buildMoreLikeSection(),
                  const SizedBox(height: 20),
                  _buildBottomIconGrid(),
                  const SizedBox(height: 20),
                  _buildBottomText(),
                  const SizedBox(height: 20),

                  // 底部导航图标
                  _buildBottomNavigation(),
                ],
              ),
            ),
          ),
          // 浮空搜索栏 - 修改Positioned部分
          Positioned(
            top: 0, // 从屏幕最顶部开始
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 70, // 状态栏高度 + 搜索框高度
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
        ],
      ),
    );
  }

// 浮空搜索框 - 移除渐变装饰
  Widget _buildFloatingSearchBar() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '搜索...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
                isDense: true,
              ),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
              maxLines: 1,
              textAlignVertical: TextAlignVertical.center, // 添加文本垂直居中
              onChanged: (value) {
                // 实时搜索功能
                // _performSearch(value);
              },
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
          context.go('/mall-detail');
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
        context.go('/brandMap/${brand.id}');
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
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mallList.length,
        itemBuilder: (context, index) {
          final mall = mallList[index];
          return Container(
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
          );
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
}
