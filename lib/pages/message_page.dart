import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nft_once/pages/blog_detail_page.dart';
import 'package:nft_once/pages/search_blog_page.dart';
import '../utils/http_client.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/event_bus.dart';
import 'dart:async';
import '../widgets/loading_indicator_widget.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/custom_refresh_widget.dart';

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
      user: json['user'], // 直接使用 Map
    );
  }
}

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage>
    with AutomaticKeepAliveClientMixin {
  List<Blog> blogs = [];
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();
  late StreamSubscription _subscription;
  late StreamSubscription _refreshSubscription; // 添加刷新事件订阅 // 添加这一行
  String currentTab = '推荐'; // 添加当前标签状态
  int page = 1;
  bool hasMore = true;
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();

    fetchBlogs();

    _scrollController.addListener(_onScrollLoadMore);

    // 监听笔记创建事件
    _subscription = eventBus.on<BlogCreatedEvent>().listen((_) {
      fetchBlogs();
    });

    // 监听社区页面刷新事件
    _refreshSubscription = eventBus.on<MessagePageRefreshEvent>().listen((_) {
      _refreshMessagePage();
    });
  }

  @override
  void dispose() {
    _subscription.cancel(); // 取消订阅
    _refreshSubscription.cancel(); // 取消刷新事件订阅
    _scrollController.dispose();
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
      isLoading = true;
    });

    try {
      // 根据当前标签获取不同的数据
      String endpoint = 'blogs/all?page=$page&sortByLatest=false';

      if (currentTab == '关注') {
        endpoint = 'blogs/following?page=$page';
      } else if (currentTab == '最新') {
        endpoint = 'blogs/all?page=$page&sortByLatest=true';
      }

      final response = await HttpClient.get(endpoint);

      if (!mounted) return;
      if (response['success']) {
        final List<dynamic> blogsData = response['data']['blogs'] ?? [];
        setState(() {
          blogs = blogsData.map((item) => Blog.fromJson(item)).toList();
          isLoading = false;
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

  // 刷新社区页面的方法
  Future<void> _refreshMessagePage() async {
    setState(() {
      page = 1;
      hasMore = true;
    });
    await fetchBlogs();
  }

  Future<void> loadMore() async {
    if (!mounted || isLoadingMore || !hasMore) return;
    setState(() {
      isLoadingMore = true;
    });
    try {
      final nextPage = page + 1;
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
          blogs.addAll(blogsData.map((item) => Blog.fromJson(item)));
          hasMore = response['data']['pagination']['page'] <
              response['data']['pagination']['pages'];
          page = nextPage;
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

  void _onScrollLoadMore() {
    if (!hasMore || isLoadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
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
                  padding:
                      EdgeInsets.only(top: MediaQuery.of(context).padding.top),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      currentTab = '关注';
                                      page = 1;
                                      hasMore = true;
                                      blogs.clear();
                                    });
                                    fetchBlogs();
                                  },
                                  child: _TabItem(
                                      text: '关注', isActive: currentTab == '关注'),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      currentTab = '推荐';
                                      page = 1;
                                      hasMore = true;
                                      blogs.clear();
                                    });
                                    fetchBlogs();
                                  },
                                  child: _TabItem(
                                      text: '推荐', isActive: currentTab == '推荐'),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      currentTab = '最新';
                                      page = 1;
                                      hasMore = true;
                                      blogs.clear();
                                    });
                                    fetchBlogs();
                                  },
                                  child: _TabItem(
                                      text: '最新', isActive: currentTab == '最新'),
                                ),
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
                  child: isLoading
                      ? const LoadingIndicatorWidget()
                      : CustomRefreshWidget(
                          onRefresh: () async {
                            setState(() {
                              page = 1;
                              hasMore = true;
                            });
                            await fetchBlogs();
                          }, // 确保这里连接到 fetchBlogs
                          child: blogs.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  // 将 Center 改为 ListView 以支持下拉刷新
                                  children: [
                                    Center(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 100),
                                        child: Text(
                                          getEmptyStateText(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFF8C8C8C),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : CustomScrollView(
                                  controller: _scrollController, // 添加控制器
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  slivers: [
                                    SliverToBoxAdapter(
                                        child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight:
                                            MediaQuery.of(context).size.height *
                                                0.9, // 修改这里
                                      ),
                                      child: Column(
                                        children: [
                                          MasonryGridView.count(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            key: const PageStorageKey(
                                              'message_grid',
                                            ), // 添加 key 保存状态
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 8,
                                            crossAxisSpacing: 8,
                                            padding: const EdgeInsets.all(8),
                                            itemCount: blogs.length,
                                            itemBuilder: (context, index) {
                                              final blog = blogs[index];
                                              // 根据内容长度动态计算高度
                                              final contentLength =
                                                  blog.title.length +
                                                      blog.content.length;
                                              final randomHeight = 180.0 +
                                                  (contentLength % 3) * 40;

                                              return RedBookCard(
                                                avatar: '',
                                                name: blog.createName,
                                                title: blog.title,
                                                content: blog.content,
                                                time: blog.createdAt,
                                                type: blog.type,
                                                defaultImage: blog.defaultImage,
                                                likes: blog.favoriteCount,
                                                comments: 0,
                                                height: randomHeight,
                                                id: blog.id,
                                                user: blog.user,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    )),
                                    SliverToBoxAdapter(
                                      child: SizedBox(
                                        height: isLoadingMore ? 56 : 0,
                                        child: isLoadingMore
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ],
                                )),
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
    );
  }
}

class _TabItem extends StatelessWidget {
  final String text;
  final bool isActive;

  const _TabItem({required this.text, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive
              ? Theme.of(context).primaryColor
              : const Color(0xFF8C8C8C),
          fontSize: isActive ? 18 : 15,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class MessageCard extends StatelessWidget {
  final String id; // 添加 id 参数
  final String avatar;
  final String name;
  final String title;
  final String content;
  final String time;
  final String type;
  final int likes;
  final int comments;

  const MessageCard({
    super.key,
    required this.avatar,
    required this.name,
    required this.title,
    required this.content,
    required this.time,
    required this.type,
    required this.likes,
    required this.comments,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        context.go('/message/detail/$id');
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE6F7FF),
                    child: avatar.isEmpty
                        ? const Icon(Icons.person, color: Color(0xFF1890FF))
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
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Color(0xFF1890FF),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(content, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.thumb_up_outlined,
                    count: likes,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 24),
                  _ActionButton(
                    icon: Icons.comment_outlined,
                    count: comments,
                    onPressed: () {},
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.more_horiz,
                      color: Color(0xFF8C8C8C),
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
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
        // 获取屏幕尺寸
        final screenSize = MediaQuery.of(context).size;

        // 获取点击位置（全局坐标）
        final tapX = details.globalPosition.dx;
        final tapY = details.globalPosition.dy;

        // context.go('/message/messageDetail/$id');
        // ... existing code ...
        // context.go('/message/messageDetail/$id');
        // ... existing code ...
        // context.go('/message/messageDetail/$id');
        // ... existing code ...
        Navigator.of(context, rootNavigator: true).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              // 使用 CupertinoPageScaffold 并启用滑动返回
              return CupertinoPageScaffold(
                child: BlogDetailPage(id: id),
              );
            },
            allowSnapshotting: false,
            settings: RouteSettings(
              name: '/blog_detail',
              arguments: {'id': id},
            ),
            maintainState: true,
            fullscreenDialog: false,
            barrierDismissible: false,
            opaque: true,
            // 添加这个属性启用滑动返回
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              // 检测是否为滑动返回
              if (secondaryAnimation.status == AnimationStatus.forward) {
                // 滑动返回时使用简单动画
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              }

              // 正常进入时使用你的自定义动画
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final progress = animation.value;
                  final isRight = tapX > screenSize.width / 2;
                  final isBottom = tapY > screenSize.height / 2;

                  Alignment scaleAlignment;
                  double startDx, startDy;

                  if (isRight && isBottom) {
                    scaleAlignment = Alignment.bottomRight;
                    startDx = 80.0;
                    startDy = 120.0;
                  } else if (!isRight && isBottom) {
                    scaleAlignment = Alignment.bottomLeft;
                    startDx = -80.0;
                    startDy = 120.0;
                  } else if (isRight && !isBottom) {
                    scaleAlignment = Alignment.topRight;
                    startDx = 80.0;
                    startDy = -120.0;
                  } else {
                    scaleAlignment = Alignment.topLeft;
                    startDx = -80.0;
                    startDy = -120.0;
                  }

                  final scale = Tween(begin: 0.7, end: 1.0)
                      .transform(Curves.easeOutQuart.transform(progress));
                  final dx = Tween(begin: startDx, end: 0.0)
                      .transform(Curves.easeOutQuart.transform(progress));
                  final dy = Tween(begin: startDy, end: 0.0)
                      .transform(Curves.easeOutQuart.transform(progress));
                  final opacity = Tween(begin: 0.0, end: 1.0)
                      .transform(Curves.easeOutQuart.transform(progress));

                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: Transform.scale(
                      scale: scale,
                      alignment: scaleAlignment,
                      child: Opacity(
                        opacity: opacity,
                        child: child,
                      ),
                    ),
                  );
                },
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 250),
          ),
        );
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
                      SvgPicture.network(
                        user!['avatar'],
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
