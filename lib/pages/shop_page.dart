import 'package:flutter/material.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Colors.black),
        title: const Text(
          'Label',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一个Section - 圆形图标网格
            _buildSectionHeader('Section title'),
            const SizedBox(height: 16),
            _buildCircularIconGrid(),
            const SizedBox(height: 32),
            
            // 第二个Section - 大图卡片
            _buildSectionHeader('Section title'),
            const SizedBox(height: 16),
            _buildLargeCard(),
            const SizedBox(height: 32),
            
            // 第三个Section - 小图标网格
            _buildSectionHeader('Section title'),
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
  
  Widget _buildCircularIconGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) => _buildCircularIcon()),
    );
  }
  
  Widget _buildCircularIcon() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.star,
            color: Colors.grey,
            size: 24,
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