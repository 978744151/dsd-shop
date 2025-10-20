import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:business_savvy/pages/blog_detail_page.dart';
import '../utils/http_client.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/event_bus.dart';
import 'dart:async';
import '../widgets/loading_indicator_widget.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/custom_refresh_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HistoryBlog {
  final String id;
  final String title;
  final String content;
  final String createName;
  final String createdAt;
  final String type;
  final String defaultImage;
  final Map<String, dynamic>? user;
  final String? viewedAt; // 浏览时间
  final Map<String, dynamic>? blog;

  HistoryBlog({
    required this.id,
    required this.title,
    required this.content,
    required this.createName,
    required this.createdAt,
    required this.type,
    required this.defaultImage,
    this.user,
    this.viewedAt,
    this.blog,
  });

  factory HistoryBlog.fromJson(Map<String, dynamic> json) {
    return HistoryBlog(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createName: json['createName'] ?? '',
      createdAt: json['createdAt'] ?? '',
      type: json['type'] ?? '',
      defaultImage: json['defaultImage'] ?? '',
      user: json['user'],
      viewedAt: json['viewedAt'],
      blog: json['blog'],
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with AutomaticKeepAliveClientMixin {
  List<HistoryBlog> historyBlogs = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  final int pageSize = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchHistoryBlogs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  // 滚动监听器
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      _loadMore();
    }
  }

  // 加载更多数据
  Future<void> _loadMore() async {
    if (isLoadingMore || !hasMore) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      currentPage++;
      await fetchHistoryBlogs(isLoadMore: true);
    } catch (e) {
      currentPage--; // 失败时回退页码
    } finally {
      if (mounted) {
        setState(() {
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> fetchHistoryBlogs({bool isLoadMore = false}) async {
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
          'blogs/history?page=$currentPage&limit=$pageSize');

      if (!mounted) return;
      if (response['success']) {
        final List<dynamic> blogsData = response['data']['histories'] ?? [];
        final newBlogs =
            blogsData.map((item) => HistoryBlog.fromJson(item)).toList();

        setState(() {
          if (isLoadMore) {
            historyBlogs.addAll(newBlogs);
          } else {
            historyBlogs = newBlogs;
          }

          // 判断是否还有更多数据
          hasMore = newBlogs.length >= pageSize;

          if (!isLoadMore) {
            isLoading = false;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!isLoadMore) {
          isLoading = false;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败：${e.toString()}')),
      );
    }
    return Future.value();
  }

  // 清空历史记录
  Future<void> _clearHistory() async {
    // showDialog(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return showModalActionSheet<int>(
    //         context: context,
    //         title: const Text('清空历史记录'),
    //         message: const Text('确定要清空所有浏览历史吗？\n此操作无法撤销'),

    //     //  Dialog(
    //     //   shape: RoundedRectangleBorder(
    //     //     borderRadius: BorderRadius.circular(16),
    //     //   ),
    //     //   child: Container(
    //     //     padding: const EdgeInsets.all(24),
    //     //     child: Column(
    //     //       mainAxisSize: MainAxisSize.min,
    //     //       children: [
    //     //         const Icon(
    //     //           Icons.delete_outline,
    //     //           color: Colors.red,
    //     //           size: 48,
    //     //         ),
    //     //         const SizedBox(height: 16),
    //     //         const Text(
    //     //           '清空历史记录',
    //     //           style: TextStyle(
    //     //             fontSize: 18,
    //     //             fontWeight: FontWeight.w600,
    //     //           ),
    //     //         ),
    //     //         const SizedBox(height: 8),
    //     //         const Text(
    //     //           '确定要清空所有浏览历史吗？\n此操作无法撤销',
    //     //           textAlign: TextAlign.center,
    //     //           style: TextStyle(
    //     //             fontSize: 14,
    //     //             color: Colors.grey,
    //     //           ),
    //     //         ),
    //     //         const SizedBox(height: 24),
    //     //         Row(
    //     //           children: [
    //     //             Expanded(
    //     //               child: TextButton(
    //     //                 onPressed: () => Navigator.of(context).pop(),
    //     //                 style: TextButton.styleFrom(
    //     //                   padding: const EdgeInsets.symmetric(vertical: 12),
    //     //                   shape: RoundedRectangleBorder(
    //     //                     borderRadius: BorderRadius.circular(8),
    //     //                     side: const BorderSide(color: Colors.grey),
    //     //                   ),
    //     //                 ),
    //     //                 child: const Text(
    //     //                   '取消',
    //     //                   style: TextStyle(color: Colors.grey),
    //     //                 ),
    //     //               ),
    //     //             ),
    //     //             const SizedBox(width: 12),
    //     //             Expanded(
    //     //               child: Container(
    //     //                 decoration: BoxDecoration(
    //     //                   gradient: const LinearGradient(
    //     //                     colors: [Colors.red, Colors.redAccent],
    //     //                   ),
    //     //                   borderRadius: BorderRadius.circular(8),
    //     //                 ),
    //     //                 child: TextButton(
    //     //                   onPressed: () async {
    //     //                     Navigator.of(context).pop();
    //     //                     try {
    //     //                       await HttpClient.delete('blogs/history');
    //     //                       setState(() {
    //     //                         historyBlogs.clear();
    //     //                         currentPage = 1;
    //     //                         hasMore = true;
    //     //                       });
    //     //                       if (mounted) {
    //     //                         ScaffoldMessenger.of(context).showSnackBar(
    //     //                           const SnackBar(content: Text('历史记录已清空')),
    //     //                         );
    //     //                       }
    //     //                     } catch (e) {
    //     //                       if (mounted) {
    //     //                         ScaffoldMessenger.of(context).showSnackBar(
    //     //                           SnackBar(
    //     //                               content: Text('清空失败：${e.toString()}')),
    //     //                         );
    //     //                       }
    //     //                     }
    //     //                   },
    //     //                   style: TextButton.styleFrom(
    //     //                     padding: const EdgeInsets.symmetric(vertical: 12),
    //     //                   ),
    //     //                   child: const Text(
    //     //                     '确定',
    //     //                     style: TextStyle(color: Colors.white),
    //     //                   ),
    //     //                 ),
    //     //               ),
    //     //             ),
    //     //           ],
    //     //         ),
    //     //       ],
    //     //     ),
    //     //   ),
    //     // );
    //   },
    // );
    final result = await showModalActionSheet<int>(
      context: context,
      title: '清空历史记录',
      message: '确定要清空所有浏览历史吗？\n此操作无法撤销',
      actions: [
        SheetAction(
          label: '确定',
          key: 1,
          isDestructiveAction: true,
        ),
      ],
      cancelLabel: '取消',
    );
    if (result == 1) {
      try {
        await HttpClient.delete('blogs/history');
        setState(() {
          historyBlogs.clear();
          currentPage = 1;
          hasMore = true;
        });
        if (mounted) {
          Fluttertoast.showToast(msg: '历史记录已清空');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('清空失败：${e.toString()}')),
          );
        }
      }
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
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AppBar(
              elevation: 0,
              backgroundColor: const Color(0xFFFFFFFF),
              title: const Text(
                '浏览历史',
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
              actions: [
                if (historyBlogs.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _clearHistory,
                  ),
              ],
            ),
          ),
        ),
        body: isLoading
            ? const LoadingIndicatorWidget()
            : CustomRefreshWidget(
                onRefresh: () => fetchHistoryBlogs(isLoadMore: false),
                child: historyBlogs.isEmpty
                    ? ListView(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 100),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    '暂无浏览历史\n快去看看有趣的内容吧！',
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
                              childCount:
                                  historyBlogs.length + (isLoadingMore ? 2 : 0),
                              itemBuilder: (context, index) {
                                // 显示加载更多指示器
                                if (index >= historyBlogs.length) {
                                  return Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: CupertinoActivityIndicator(),
                                    ),
                                  );
                                }
                                final blog = historyBlogs[index];
                                // 改进高度计算逻辑，基于内容长度和图片比例
                                final contentLength =
                                    (blog.blog?['title']?.length ?? 0) +
                                        (blog.blog?['content']?.length ?? 0);
                                // 使用更自然的高度变化
                                final baseHeight = 200.0;
                                final contentHeight = (contentLength / 10)
                                    .clamp(0, 80)
                                    .toDouble();
                                final randomVariation = (index % 5) * 15.0;
                                final totalHeight = baseHeight +
                                    contentHeight +
                                    randomVariation;

                                return HistoryRedBookCard(
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
                                  height: totalHeight,
                                  id: blog.blog?['_id'] ?? '',
                                  user: blog.blog?['user'] ?? {},
                                  viewedAt: blog.viewedAt,
                                );
                              },
                            ),
                          ),
                          // 添加底部加载指示器
                          if (isLoadingMore)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CupertinoActivityIndicator(),
                                ),
                              ),
                            ),
                          // 添加"没有更多"提示
                          if (!hasMore && historyBlogs.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    '没有更多历史记录了',
                                    style: TextStyle(
                                      color: Colors.grey[500],
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

class HistoryRedBookCard extends StatelessWidget {
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

  const HistoryRedBookCard({
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
        return '${difference.inDays}天前浏览';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前浏览';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前浏览';
      } else {
        return '刚刚浏览';
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
              color: Colors.black.withOpacity(0.08),
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
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
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
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (user?['avatar'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SvgPicture.network(
                            user!['avatar'],
                            height: 20,
                            width: 20,
                          ),
                        )
                      else
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
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
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        likes.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  // 添加浏览时间显示
                  if (viewedAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatViewedTime(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
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
