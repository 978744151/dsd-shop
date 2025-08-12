import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 品牌列表数组
  final List<Map<String, dynamic>> brandList = [
    {
      'id': 1,
      'brandName': 'COACH',
      'image': 'assets/brand/coach.png',
    },
    {
      'id': 2,
      'brandName': 'ARC ERYX',
      'image': 'assets/brand/arc.png',
    },
    {
      'id': 3,
      'brandName': 'MCM',
      'image': 'assets/brand/mcm.png',
    },
    {
      'id': 4,
      'brandName': 'Ferragamo',
      'image': 'assets/brand/flgm.png',
    },
    {
      'id': 5,
      'brandName': 'Lululemon',
      'image': 'assets/brand/lululemon.png',
    },
  ];
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
            onRefresh: () => Future.delayed(const Duration(seconds: 2)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 70, // 为浮空搜索栏留出空间
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 测试按钮
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.go('/test-map'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('测试ECharts地图'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.go('/simple-map'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('简单地图测试'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 第一个Section - 圆形图标网格
                  _buildSectionHeader('品牌'),
                  const SizedBox(height: 8),
                  _buildCircularIconGrid(),
                  const SizedBox(height: 32),

                  // 第二个Section - 大图卡片
                  _buildSectionHeader('购物中心'),
                  const SizedBox(height: 16),
                  _buildLargeCard(),
                  const SizedBox(height: 32),

                  // 第三个Section - 小图标网格
                  _buildSectionHeader('分类'),
                  const SizedBox(height: 16),
                  _buildSmallIconGrid(),
                  const SizedBox(height: 32),

                  // 第四个Section - 音乐卡片网格
                  _buildSectionHeader('Section title'),
                  const SizedBox(height: 16),
                  _buildMusicCardGrid(),
                  const SizedBox(height: 32),

                  // 第五个Section - 新闻列表
                  _buildSectionHeader('Section title'),
                  const SizedBox(height: 16),
                  _buildNewsList(),
                  const SizedBox(height: 32),

                  // 最后一个Section - More like
                  _buildMoreLikeSection(),
                  const SizedBox(height: 16),
                  _buildBottomIconGrid(),
                  const SizedBox(height: 16),
                  _buildBottomText(),
                  const SizedBox(height: 32),

                  // 底部导航图标
                  _buildBottomNavigation(),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0, // 状态栏高度 + 间距
            left: 0,
            right: 0,
            child: _buildFloatingSearchBar(),
          ),
        ],
      ),
    );
  }

  // 浮空搜索框
  Widget _buildFloatingSearchBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 178, 203, 246),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '搜索...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
                // 可以添加其他图标
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
          brandList.length, (index) => _buildCircularIcon(brandList[index])),
    );
  }

  Widget _buildCircularIcon(Map<String, dynamic> brand) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(brand['image']),
                fit: BoxFit.contain,
              )),
        ),
        const SizedBox(height: 8),
        Text(
          brand['brandName'],
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildLargeCard() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow,
                  size: 40,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Icon(
                  Icons.star,
                  size: 24,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Icon(
                  Icons.stop,
                  size: 24,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, color: Colors.grey),
                      SizedBox(height: 4),
                      Icon(Icons.star, color: Colors.grey, size: 16),
                      Icon(Icons.stop, color: Colors.grey, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, color: Colors.grey),
                      SizedBox(height: 4),
                      Icon(Icons.star, color: Colors.grey, size: 16),
                      Icon(Icons.stop, color: Colors.grey, size: 16),
                    ],
                  ),
                ),
              ),
            ],
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
