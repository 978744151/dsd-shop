import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import '../utils/http_client.dart';
import '../widgets/red_book_card.dart';
import '../widgets/custom_refresh_widget.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with TickerProviderStateMixin {
  Map<dynamic, dynamic> userInfo = {};
  List<Map<String, dynamic>> userBlogsList = [];
  bool isLoading = true;
  bool isFollowing = false;

  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showTitle = false;
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_updateScrollState);

    fetchUserInfo();
    fetchUserBlogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 获取用户信息
  Future<void> fetchUserInfo() async {
    if (!mounted) return;
    try {
      final response = await HttpClient.get('user/look/${widget.userId}');
      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          userInfo = response['data'] ?? {};
          isFollowing = userInfo['isFollowing'] ?? false;
          isLoading = false;
        });
      }
    } catch (e) {
      print('获取用户信息失败: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // 获取用户发帖内容
  Future<void> fetchUserBlogs() async {
    if (!mounted) return;
    try {
      final response = await HttpClient.get('blogs/all', params: {
        'userId': widget.userId,
      });
      if (!mounted) return;

      if (response['success'] == true) {
        final List<dynamic> list = response['data']['blogs'] ?? [];
        setState(() {
          userBlogsList =
              list.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      }
    } catch (e) {
      print('获取用户发帖失败: $e');
    }
  }

  // 关注/取消关注
  Future<void> toggleFollow() async {
    try {
      final response = isFollowing
          ? await HttpClient.delete('follow/${widget.userId}')
          : await HttpClient.post('follow/${widget.userId}');

      if (response['success'] == true) {
        setState(() {
          isFollowing = !isFollowing;
          // 更新关注数
          if (isFollowing) {
            userInfo['followersCount'] = (userInfo['followersCount'] ?? 0) + 1;
          } else {
            userInfo['followersCount'] = (userInfo['followersCount'] ?? 1) - 1;
          }
        });
      }
    } catch (e) {
      print('关注操作失败: $e');
    }
  }

  // 拉黑用户
  Future<void> blockUser() async {
    try {
      final response = await HttpClient.post('blacklist/${widget.userId}');
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已拉黑该用户')),
        );
        context.pop();
      }
    } catch (e) {
      print('拉黑用户失败: $e');
    }
  }

  // 更新滚动状态
  void _updateScrollState() {
    final scrollProgress = _scrollController.position.pixels / 150.0;
    final shouldShowTitle = scrollProgress > 0.5;

    if (_showTitle != shouldShowTitle ||
        _scrollProgress != scrollProgress.clamp(0.0, 1.0)) {
      setState(() {
        _scrollProgress = scrollProgress.clamp(0.0, 1.0);
        _showTitle = shouldShowTitle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFB2CBF6),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: CustomRefreshWidget(
        onRefresh: () async {
          await Future.wait([
            fetchUserInfo(),
            fetchUserBlogs(),
          ]);
        },
        child: SafeArea(
          top: false,
          child: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // 顶部信息区域 SliverAppBar
                SliverAppBar(
                  elevation: 0,
                  backgroundColor: const Color(0xFFB2CBF6),
                  expandedHeight: 180.0,
                  toolbarHeight: 56.0,
                  collapsedHeight: 56.0,
                  pinned: true,
                  floating: true,
                  snap: false,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => context.pop(),
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.black),
                      onSelected: (value) {
                        switch (value) {
                          case 'block':
                            _showBlockDialog();
                            break;
                          case 'report':
                            // 举报功能
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block, color: Colors.red),
                              SizedBox(width: 8),
                              Text('拉黑'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.report, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('举报'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  title: AnimatedOpacity(
                    opacity: _showTitle ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      userInfo['username'] ?? '用户',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    expandedTitleScale: 1.0,
                    stretchModes: [
                      StretchMode.zoomBackground,
                      StretchMode.blurBackground,
                    ],
                    collapseMode: CollapseMode.pin,
                    background: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 56,
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFB2CBF6),
                            Color(0xFFFFFFFF),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          // 用户信息
                          Row(
                            children: [
                              // 用户头像
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: ClipOval(
                                  child: userInfo['avatar']?.isNotEmpty == true
                                      ? (userInfo['avatar'].endsWith('.svg')
                                          ? SvgPicture.network(
                                              userInfo['avatar'],
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            )
                                          : SvgPicture.network(
                                              userInfo['avatar'],
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ))
                                      : Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.person,
                                              size: 30),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 用户名和简介
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userInfo['username'] ?? '用户',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (userInfo['bio']?.isNotEmpty ==
                                        true) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        userInfo['bio'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    // 统计信息
                                    Row(
                                      children: [
                                        _StatItem(
                                          count: userInfo['followingCount']
                                                  ?.toString() ??
                                              '0',
                                          label: '关注',
                                        ),
                                        const SizedBox(width: 16),
                                        _StatItem(
                                          count: userInfo['followersCount']
                                                  ?.toString() ??
                                              '0',
                                          label: '粉丝',
                                        ),
                                        const SizedBox(width: 16),
                                        // _StatItem(
                                        //   count:
                                        //       userBlogsList.length.toString(),
                                        //   label: '笔记',
                                        // ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // 关注按钮
                          // SizedBox(
                          //   width: double.infinity,
                          //   child: ElevatedButton(
                          //     onPressed: toggleFollow,
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: isFollowing
                          //           ? Colors.grey[300]
                          //           : Colors.blue,
                          //       foregroundColor:
                          //           isFollowing ? Colors.black : Colors.white,
                          //       padding:
                          //           const EdgeInsets.symmetric(vertical: 12),
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(8),
                          //       ),
                          //       elevation: 0,
                          //     ),
                          //     child: Text(
                          //       isFollowing ? '已关注' : '关注',
                          //       style: const TextStyle(
                          //         fontSize: 16,
                          //         fontWeight: FontWeight.w600,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Tab栏
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    // 靠左显示align
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue,
                      indicatorWeight: 2,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: const [
                        Tab(text: '笔记'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // 笔记列表
                _buildBlogsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建笔记列表
  Widget _buildBlogsList() {
    if (userBlogsList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '暂无笔记',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        padding: const EdgeInsets.all(16),
        itemCount: userBlogsList.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 375),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: RedBookCard(
                  id: userBlogsList[index]['_id'] ?? '',
                  title: userBlogsList[index]['title'] ?? '',
                  content: userBlogsList[index]['content'] ?? '',
                  time: userBlogsList[index]['createdAt'] ?? '',
                  type: userBlogsList[index]['type'] ?? '',
                  defaultImage: userBlogsList[index]['defaultImage'] ?? '',
                  likes: userBlogsList[index]['likeCount'] ?? 0,
                  comments: userBlogsList[index]['commentCount'] ?? 0,
                  user: userBlogsList[index]['user'],
                  name: userBlogsList[index]['user']?['username'] ?? '',
                  avatar: userBlogsList[index]['user']?['avatar'] ?? '',
                  onTap: () {
                    context.push('/blog/${userBlogsList[index]['_id']}');
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 显示拉黑确认对话框
  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认拉黑'),
        content: Text('确定要拉黑用户 "${userInfo['username']}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              blockUser();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

// 统计信息组件
class _StatItem extends StatelessWidget {
  final String count;
  final String label;

  const _StatItem({
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// Tab栏代理
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}