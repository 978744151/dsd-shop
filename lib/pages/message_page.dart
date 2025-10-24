import 'package:business_savvy/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:business_savvy/pages/blog_detail_page.dart';
import 'package:business_savvy/pages/search_blog_page.dart';
import '../utils/http_client.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/event_bus.dart';
import 'dart:async';
import '../widgets/loading_indicator_widget.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/custom_refresh_widget.dart';
import '../widgets/tab_content_widget.dart';

class Blog {
  final String id;
  final String title;
  final String content;
  final String createName;
  final String createdAt;
  final String type;
  final String defaultImage;
  final Map<String, dynamic>? user; // 直接使用 Map
  final int favoriteCount;

  Blog({
    required this.id,
    required this.title,
    required this.content,
    required this.createName,
    required this.createdAt,
    required this.type,
    this.favoriteCount = 0,
    required this.defaultImage,
    this.user,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createName: json['createName'] ?? '',
      createdAt: json['createdAt'] ?? '',
      type: json['type'] ?? '',
      defaultImage: json['defaultImage'] ?? '',
      favoriteCount: json['favoriteCount'] ?? 0,
      user: json['user'] ?? {}, // 直接使用 Map
    );
  }
}

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  // 用于强制重建TabContentWidget的key
  Key _refreshKey = UniqueKey();

  // 移除复杂的滚动控制器映射
  // final Map<String, ScrollController> _tabScrollControllers = {
  //   '关注': ScrollController(),
  //   '推荐': ScrollController(),
  //   '最新': ScrollController(),
  // };

  // 为每个标签页创建独立的数据存储
  final Map<String, List<Blog>> _tabBlogs = {
    '关注': [],
    '推荐': [],
    '最新': [],
  };
  final Map<String, bool> _tabLoading = {
    '关注': false,
    '推荐': true,
    '最新': false,
  };
  final Map<String, int> _tabPage = {
    '关注': 1,
    '推荐': 1,
    '最新': 1,
  };
  final Map<String, bool> _tabHasMore = {
    '关注': true,
    '推荐': true,
    '最新': true,
  };

  final ScrollController _scrollController = ScrollController();
  late StreamSubscription _subscription;
  late StreamSubscription _refreshSubscription; // 添加刷新事件订阅 // 添加这一行
  String currentTab = '推荐'; // 添加当前标签状态
  bool isLoadingMore = false;

  // 添加TabController
  late TabController _tabController;

  // 记录每个标签页是否已经加载过数据
  final Set<String> _loadedTabs = <String>{};

  // 移除复杂的滚动位置保存逻辑
  // final Map<String, double> _tabScrollPositions = {
  //   '关注': 0.0,
  //   '推荐': 0.0,
  //   '最新': 0.0,
  // };

  @override
  void initState() {
    super.initState();

    // 初始化TabController
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 1,
      animationDuration: const Duration(milliseconds: 100), // 加快切换速度
    ); // 默认选中推荐

    // 监听笔记创建事件
    _subscription = eventBus.on<BlogCreatedEvent>().listen((_) {
      // 强制重建所有TabContentWidget以刷新数据
      setState(() {
        // 通过改变key来强制重建Widget
        _refreshKey = UniqueKey();
      });
    });

    // 监听社区页面刷新事件
    _refreshSubscription = eventBus.on<MessagePageRefreshEvent>().listen((_) {
      // 强制重建所有TabContentWidget以刷新数据
      setState(() {
        // 通过改变key来强制重建Widget
        _refreshKey = UniqueKey();
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel(); // 取消订阅
    _refreshSubscription.cancel(); // 取消刷新事件订阅
    _tabController.dispose(); // 释放TabController
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  // 添加获取空状态文本的方法
  String getEmptyStateText() {
    switch (currentTab) {
      case '关注':
        return '暂无关注的内容\n快去关注一些有趣的用户吧！';
      case '最新':
        return '暂无最新内容';
      default:
        return '暂无推荐内容';
    }
  }

  Future<void> fetchBlogs() async {
    if (!mounted) return;

    setState(() {
      _tabLoading[currentTab] = true;
    });

    try {
      // 根据当前标签获取不同的数据
      String endpoint =
          'blogs/all?page=${_tabPage[currentTab]}&sortByLatest=false';

      if (currentTab == '关注') {
        endpoint = 'blogs/following?page=${_tabPage[currentTab]}';
      } else if (currentTab == '最新') {
        endpoint = 'blogs/all?page=${_tabPage[currentTab]}&sortByLatest=true';
      }

      final response = await HttpClient.get(endpoint);

      if (!mounted) return;
      if (response['success']) {
        final List<dynamic> blogsData = response['data']['blogs'] ?? [];
        setState(() {
          // 只有在第一页或者刷新时才替换数据，否则追加数据
          if (_tabPage[currentTab] == 1) {
            _tabBlogs[currentTab] =
                blogsData.map((item) => Blog.fromJson(item)).toList();
          } else {
            _tabBlogs[currentTab]!
                .addAll(blogsData.map((item) => Blog.fromJson(item)));
          }
          _tabLoading[currentTab] = false;
        });
        // 若内容未铺满屏幕且还有更多，自动尝试加载下一页
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // if (hasMore && _scrollController.position.maxScrollExtent <= 0) {
          //   loadMore();
          // }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tabLoading[currentTab] = false;
      });
      // 添加错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刷新失败：${e.toString()}')),
      );
    }
    // 返回 Future 完成
    return Future.value();
  }

  // 刷新社区页面的方法
  Future<void> _refreshMessagePage() async {
    setState(() {
      _tabPage[currentTab] = 1;
      _tabHasMore[currentTab] = true;
      // 刷新时清空当前标签页的数据
      _tabBlogs[currentTab]!.clear();
    });
    await fetchBlogs();
  }

  Future<void> loadMore() async {
    if (!mounted || isLoadingMore || !_tabHasMore[currentTab]!) return;
    setState(() {
      isLoadingMore = true;
    });
    try {
      final nextPage = _tabPage[currentTab]! + 1;
      String endpoint = 'blogs/all?page=$nextPage&sortByLatest=false';

      if (currentTab == '关注') {
        endpoint = 'blogs/following?page=$nextPage';
      } else if (currentTab == '最新') {
        endpoint = 'blogs/all?page=$nextPage&sortByLatest=true';
      }
      final response = await HttpClient.get(endpoint);
      if (!mounted) return;
      if (response['success']) {
        final List<dynamic> blogsData = response['data']['blogs'] ?? [];

        setState(() {
          _tabBlogs[currentTab]!
              .addAll(blogsData.map((item) => Blog.fromJson(item)));
          _tabHasMore[currentTab] = response['data']['pagination']['page'] <
              response['data']['pagination']['pages'];
          _tabPage[currentTab] = nextPage;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          isLoadingMore = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Widget _buildTabContent(String tabName) {
    String endpoint;
    switch (tabName) {
      case '关注':
        endpoint = 'blogs/following?sortByLatest=true';
        break;
      case '最新':
        endpoint = 'blogs/all?sortByLatest=true';
        break;
      default:
        endpoint = 'blogs/all?sortByLatest=false';
    }

    return TabContentWidget(
      key: ValueKey('${tabName}_$_refreshKey'),
      tabName: tabName,
      endpoint: endpoint,
    );
  }

  String _getEmptyStateTextForTab(String tabName) {
    switch (tabName) {
      case '关注':
        return '还没有关注任何人\n快去关注一些有趣的人吧';
      case '推荐':
        return '暂无推荐内容\n稍后再来看看吧';
      case '最新':
        return '暂无最新内容\n稍后再来看看吧';
      default:
        return '暂无内容';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PageStorage(
      bucket: PageStorageBucket(),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(children: [
          Scaffold(
              resizeToAvoidBottomInset: false, // 添加此行防止键盘弹出导致布局问题

              // backgroundColor:
              // const Color.fromARGB(110, 238, 232, 230), // 取消注释并设置为白色
              backgroundColor: const Color(0xFFF9f9f9),
              body: Column(
                children: [
                  // 自定义AppBar
                  Container(
                    height: kToolbarHeight + MediaQuery.of(context).padding.top,
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top),
                    decoration: const BoxDecoration(
                      color: Color(0xFFffffff),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        height: kToolbarHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TabBar(
                                controller: _tabController,
                                indicatorColor: Theme.of(context).primaryColor,
                                labelColor: const Color(0xFF333333),
                                unselectedLabelColor: const Color(0xFF8C8C8C),
                                labelStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                unselectedLabelStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                                indicatorSize: TabBarIndicatorSize.label,
                                dividerColor: Colors.transparent,
                                tabs: const [
                                  Tab(text: '关注'),
                                  Tab(text: '推荐'),
                                  Tab(text: '最新'),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.search,
                                    color: Color(0xFF8C8C8C)),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SearchBlogPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 页面内容
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        Container(
                          key: const PageStorageKey('关注_tab'),
                          child: _buildTabContent('关注'),
                        ), // 关注
                        Container(
                          key: const PageStorageKey('推荐_tab'),
                          child: _buildTabContent('推荐'),
                        ), // 推荐
                        Container(
                          key: const PageStorageKey('最新_tab'),
                          child: _buildTabContent('最新'),
                        ), // 最新
                      ],
                    ),
                  ),
                ],
              )),
          Positioned(
            right: 10,
            bottom: 20,
            child: RawMaterialButton(
              onPressed: () {
                context.go('/message/create');
              },
              elevation: 4.0,
              fillColor: Colors.white,
              shape: const CircleBorder(),
              constraints: const BoxConstraints.tightFor(
                width: 60,
                height: 60,
              ),
              child: Icon(
                Icons.add_photo_alternate,
                color: Theme.of(context).primaryColor,
                size: 35,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8C8C8C)),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: const TextStyle(color: Color(0xFF8C8C8C), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class RedBookCard extends StatelessWidget {
  final String avatar;
  final String name;
  final String title;
  final String content;
  final String time;
  final String id;
  final String type;
  final String defaultImage;
  final int likes;
  final int comments;
  final double height; // Add this parameter
  final Map<String, dynamic>? user; // 直接使用 Map

  const RedBookCard({
    super.key,
    required this.avatar,
    this.user,
    required this.id,
    required this.name,
    required this.defaultImage,
    required this.title,
    required this.content,
    required this.time,
    required this.type,
    required this.likes,
    required this.comments,
    this.height = 200, // Default height
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (TapUpDetails details) {
        if (user == null) {
          ToastUtil.showPrimary('此文章已被删除');
          return;
        }
        // 获取屏幕尺寸
        final screenSize = MediaQuery.of(context).size;

        // 获取点击位置（全局坐标）
        final tapX = details.globalPosition.dx;
        final tapY = details.globalPosition.dy;
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => BlogDetailPage(
              id: id,
              commentId: '',
            ),
          ),
        );
        // Navigator.of(context, rootNavigator: true).push(
        //   PageRouteBuilder(
        //     pageBuilder: (context, animation, secondaryAnimation) {
        //       // 使用 CupertinoPageScaffold 包装以启用滑动返回
        //       return CupertinoPageScaffold(
        //         child: BlogDetailPage(id: id),
        //       );
        //     },
        //     maintainState: true,
        //     transitionsBuilder:
        //         (context, animation, secondaryAnimation, child) {
        //       // 检测是否为滑动返回（当secondaryAnimation有值时表示正在返回）
        //       if (secondaryAnimation.status == AnimationStatus.forward) {
        //         // 滑动返回时使用简单的滑动动画
        //         return SlideTransition(
        //           position: Tween<Offset>(
        //             begin: const Offset(1.0, 0.0),
        //             end: Offset.zero,
        //           ).animate(CurvedAnimation(
        //             parent: animation,
        //             curve: Curves.easeOutCubic,
        //           )),
        //           child: child,
        //         );
        //       }

        //       // 正常进入时使用自定义动画特效
        //       return AnimatedBuilder(
        //         animation: animation,
        //         builder: (context, child) {
        //           final progress = animation.value;
        //           final isRight = tapX > screenSize.width / 2;
        //           final isBottom = tapY > screenSize.height / 2;

        //           Alignment scaleAlignment;
        //           double startDx, startDy;

        //           if (isRight && isBottom) {
        //             scaleAlignment = Alignment.bottomRight;
        //             startDx = 80.0;
        //             startDy = 120.0;
        //           } else if (!isRight && isBottom) {
        //             scaleAlignment = Alignment.bottomLeft;
        //             startDx = -80.0;
        //             startDy = 120.0;
        //           } else if (isRight && !isBottom) {
        //             scaleAlignment = Alignment.topRight;
        //             startDx = 80.0;
        //             startDy = -120.0;
        //           } else {
        //             scaleAlignment = Alignment.topLeft;
        //             startDx = -80.0;
        //             startDy = -120.0;
        //           }

        //           final scale = Tween(begin: 0.7, end: 1.0)
        //               .transform(Curves.easeOutQuart.transform(progress));
        //           final dx = Tween(begin: startDx, end: 0.0)
        //               .transform(Curves.easeOutQuart.transform(progress));
        //           final dy = Tween(begin: startDy, end: 0.0)
        //               .transform(Curves.easeOutQuart.transform(progress));
        //           final opacity = Tween(begin: 0.0, end: 1.0)
        //               .transform(Curves.easeOutQuart.transform(progress));

        //           return Transform.translate(
        //             offset: Offset(dx, dy),
        //             child: Transform.scale(
        //               scale: scale,
        //               alignment: scaleAlignment,
        //               child: Opacity(
        //                 opacity: opacity,
        //                 child: child,
        //               ),
        //             ),
        //           );
        //         },
        //         child: child,
        //       );
        //     },
        //     transitionDuration: const Duration(milliseconds: 300),
        //     reverseTransitionDuration: const Duration(milliseconds: 250),
        //   ),
        // );
// ... existing code ...
      },
      child: Card(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                image: defaultImage.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(defaultImage),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: defaultImage.isEmpty
                  ? const Center(
                      child: Icon(Icons.image, size: 40, color: Colors.grey),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (user != null)
                        SvgPicture.network(
                          user!['avatar'] ?? '',
                          height: 15, // 根据是否为回复设置不同高度
                          width: 15, // 根据是否为回复设置不同宽度
                        ),
                      // CircleAvatar(
                      //   radius: 10,
                      //   backgroundColor: const Color(0xFFE6F7FF),
                      //   child: avatar.isEmpty
                      //       ? const Icon(
                      //           Icons.person,
                      //           color: Color(0xFF1890FF),
                      //           size: 14,
                      //         )
                      //       : null,
                      // ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const Icon(Icons.favorite_border, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        likes.toString(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
