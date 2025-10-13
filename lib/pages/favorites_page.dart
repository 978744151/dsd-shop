import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nft_once/pages/blog_detail_page.dart';
import '../utils/http_client.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/event_bus.dart';
import 'dart:async';
import '../widgets/loading_indicator_widget.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/custom_refresh_widget.dart';

class FavoritesBlog {
  final String id;
  final String title;
  final String content;
  final String createName;
  final String createdAt;
  final String type;
  final String defaultImage;
  final String user;
  final String? viewedAt; // 浏览时间
  final Map<String, dynamic>? blog;

  FavoritesBlog({
    required this.id,
    required this.title,
    required this.content,
    required this.createName,
    required this.createdAt,
    required this.type,
    required this.defaultImage,
    required this.user,
    this.viewedAt,
    this.blog,
  });

  factory FavoritesBlog.fromJson(Map<String, dynamic> json) {
    return FavoritesBlog(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createName: json['createName'] ?? '',
      createdAt: json['createdAt'] ?? '',
      type: json['type'] ?? '',
      defaultImage: json['defaultImage'] ?? '',
      user: json['user'] ?? '',
      viewedAt: json['viewedAt'],
      blog: json['blog'],
    );
  }
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with AutomaticKeepAliveClientMixin {
  List<FavoritesBlog> favoritesBlogs = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  final int pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    fetchFavoritesBlogs();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (isLoadingMore || !hasMore) return;

    setState(() {
      isLoadingMore = true;
    });

    await fetchFavoritesBlogs(isLoadMore: true);

    setState(() {
      isLoadingMore = false;
    });
  }

  Future<void> fetchFavoritesBlogs({bool isLoadMore = false}) async {
    if (!mounted) return;

    if (!isLoadMore) {
      setState(() {
        isLoading = true;
        currentPage = 1;
        hasMore = true;
      });
    }

    try {
      final response = await HttpClient.get(
        'blogs/favorites?page=$currentPage&limit=$pageSize',
      );

      if (!mounted) return;
      if (response['success']) {
        final List<dynamic> blogsData = response['data']['favorites'] ?? [];
        final List<FavoritesBlog> newBlogs =
            blogsData.map((item) => FavoritesBlog.fromJson(item)).toList();

        setState(() {
          if (isLoadMore) {
            favoritesBlogs.addAll(newBlogs);
          } else {
            favoritesBlogs = newBlogs;
          }

          hasMore = newBlogs.length == pageSize;
          currentPage++;
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败：${e.toString()}')),
      );
    }
    return Future.value();
  }

  String _timeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF9f9f9),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: GestureDetector(
            onTap: () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: AppBar(
              elevation: 0,
              backgroundColor: const Color(0xFFFFFFFF),
              title: const Text(
                '收藏',
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
          ),
        ),
        body: isLoading
            ? const LoadingIndicatorWidget()
            : CustomRefreshWidget(
                onRefresh: () async {
                  await fetchFavoritesBlogs();
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: favoritesBlogs.isEmpty
                    ? ListView(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 100),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.favorite_border,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    '暂无收藏\n快去看看有趣的内容吧！',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF8C8C8C),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(8),
                            sliver: SliverMasonryGrid.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childCount: favoritesBlogs.length,
                              itemBuilder: (context, index) {
                                final blog = favoritesBlogs[index];
                                final contentLength =
                                    (blog.blog?['title']?.length ?? 0) +
                                        (blog.blog?['content']?.length ?? 0);
                                final baseHeight = 180.0;
                                final variableHeight =
                                    (contentLength % 5) * 30.0;
                                final randomVariation = (index % 3) * 20.0;
                                final finalHeight = baseHeight +
                                    variableHeight +
                                    randomVariation;

                                return FavoritesRedBookCard(
                                  avatar: '',
                                  name: blog.createName,
                                  title: blog.blog?['title'] ?? '',
                                  content: blog.blog?['content'] ?? '',
                                  time: blog.createdAt,
                                  type: blog.type,
                                  defaultImage:
                                      blog.blog?['defaultImage'] ?? '',
                                  likes: blog.blog?['likeCount'] ?? 0,
                                  comments: 0,
                                  height: finalHeight,
                                  id: blog.blog?['_id'] ?? '',
                                  user: blog.blog?['user'] ?? {},
                                  viewedAt: blog.viewedAt,
                                );
                              },
                            ),
                          ),
                          if (isLoadingMore)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF1890FF),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (!hasMore && favoritesBlogs.isNotEmpty)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    '没有更多内容了',
                                    style: TextStyle(
                                      color: Color(0xFF8C8C8C),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
      ),
    );
  }
}

class FavoritesRedBookCard extends StatelessWidget {
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
  final double height;
  final Map<String, dynamic>? user;
  final String? viewedAt;

  const FavoritesRedBookCard({
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
    this.height = 200,
    this.viewedAt,
  });

  String _formatViewedTime() {
    if (viewedAt == null) return '';

    try {
      final viewTime = DateTime.parse(viewedAt!);
      final now = DateTime.now();
      final difference = now.difference(viewTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}天前收藏';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前收藏';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前收藏';
      } else {
        return '刚刚收藏';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
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
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
            },
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 250),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片部分
            Container(
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
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
            // 内容部分
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (user?['avatar'] != null)
                        SvgPicture.network(
                          user!['avatar'],
                          height: 16,
                          width: 16,
                        )
                      else
                        const CircleAvatar(
                          radius: 8,
                          backgroundColor: Color(0xFFE6F7FF),
                          child: Icon(
                            Icons.person,
                            color: Color(0xFF1890FF),
                            size: 12,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.favorite,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        likes.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  if (viewedAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatViewedTime(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
