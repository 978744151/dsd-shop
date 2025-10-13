import 'package:flutter/material.dart';
import '../utils/http_client.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/loading_indicator_widget.dart';
import 'blog_detail_page.dart';
import '../widgets/bottom_navigation.dart';
import '../utils/event_bus.dart';
import 'dart:async';

class AppNotification {
  final String id;
  final String title;
  final String content;
  final String createdAt;
  final Map<String, dynamic>? sender;
  final Map<String, dynamic>? relatedBlog;
  final Map<String, dynamic>? relatedComment;
  final String type; // like, comment, follow, system
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.type,
    this.sender,
    this.relatedBlog,
    this.relatedComment,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] ?? '',
      type: json['type'] ?? 'system',
      sender: json['sender'],
      relatedBlog: json['relatedBlog'],
      relatedComment: json['relatedComment'],
      isRead: json['isRead'] ?? false,
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with AutomaticKeepAliveClientMixin {
  List<AppNotification> notifications = [];
  bool isLoading = true;
  int page = 1;
  bool hasMore = true;
  late StreamSubscription _refreshSubscription; // 添加刷新事件订阅

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    
    // 监听通知页面刷新事件
    _refreshSubscription = eventBus.on<NotificationsRefreshEvent>().listen((_) {
      _refreshNotifications();
    });
  }

  @override
  void dispose() {
    _refreshSubscription.cancel();
    super.dispose();
  }

  // 刷新通知数据的方法
  Future<void> _refreshNotifications() async {
    setState(() {
      page = 1;
      hasMore = true;
      notifications.clear();
    });
    await fetchNotifications();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> fetchNotifications() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      final response = await HttpClient.get('notifications', params: {
        'page': page.toString(),
        'limit': '20',
      });
      if (!mounted) return;
      if (response['success'] == true) {
        isLoading = false;

        final List<dynamic> data = response['data']['notifications'] ?? [];
        final List<AppNotification> newItems =
            data.map((e) => AppNotification.fromJson(e)).toList();
        setState(() {
          if (page == 1) {
            notifications = newItems;
          } else {
            notifications.addAll(newItems);
          }
          hasMore = newItems.length >= 20;
          page++;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载通知失败：$e')),
      );
    }
  }

  Future<void> refreshList() async {
    setState(() {
      page = 1;
      hasMore = true;
      notifications.clear();
    });
    await fetchNotifications();
  }

  // 标记单个通知为已读
  Future<void> markAsRead(String notificationId) async {
    try {
      final response =
          await HttpClient.post('notifications/read/$notificationId', body: {});
      if (response['success'] == true) {
        setState(() {
          // 更新本地状态，将对应通知标记为已读
          final index = notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            notifications[index] = AppNotification(
              id: notifications[index].id,
              title: notifications[index].title,
              content: notifications[index].content,
              createdAt: notifications[index].createdAt,
              type: notifications[index].type,
              sender: notifications[index].sender,
              relatedBlog: notifications[index].relatedBlog,
              relatedComment: notifications[index].relatedComment,
              isRead: true, // 标记为已读
            );
          }
        });
        // 发送事件通知底部导航栏更新未读数量
        eventBus.fire(UnreadCountUpdateEvent());
      }
    } catch (e) {
      print('标记通知为已读失败: $e');
    }
  }

  // 一键已读所有通知
  Future<void> markAllAsRead() async {
    try {
      final response = await HttpClient.post('notifications/read-all',
          body: {'type': 'all'});
      if (response['success'] == true) {
        setState(() {
          // 将所有通知标记为已读
          notifications = notifications
              .map((n) => AppNotification(
                    id: n.id,
                    title: n.title,
                    content: n.content,
                    createdAt: n.createdAt,
                    type: n.type,
                    sender: n.sender,
                    relatedBlog: n.relatedBlog,
                    relatedComment: n.relatedComment,
                    isRead: true, // 全部标记为已读
                  ))
              .toList();
        });
        // 发送事件通知底部导航栏更新未读数量
        eventBus.fire(UnreadCountUpdateEvent());
      }
    } catch (e) {
      print('一键已读失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 顶部栏
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 8,
            ),
            color: Colors.white,
            child: Row(
              children: [
                // GestureDetector(
                //   onTap: () => Navigator.of(context).pop(),
                //   child: const Padding(
                //     padding: EdgeInsets.all(8),
                //     child: Icon(Icons.arrow_back_ios,
                //         size: 18, color: Color(0xFF333333)),
                //   ),
                // ),
                const SizedBox(width: 8),
                const Text(
                  '消息通知',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const Spacer(),
                // 一键已读按钮
                if (notifications.any((n) => !n.isRead))
                  TextButton(
                    onPressed: markAllAsRead,
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      // backgroundColor: const Color(0xFFF0F0F0),
                    ),
                    child: const Text(
                      '一键已读',
                      style: TextStyle(
                        fontSize: 12,
                        // color: Color(0xFF666666),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 列表
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshList,
              color: Theme.of(context).primaryColor,
              child: NotificationListener<ScrollNotification>(
                onNotification: (scroll) {
                  if (scroll.metrics.pixels >=
                      scroll.metrics.maxScrollExtent - 200) {
                    if (hasMore && !isLoading) fetchNotifications();
                  }
                  return false;
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (isLoading && notifications.isEmpty)
                      const SliverFillRemaining(
                        child: Center(child: LoadingIndicatorWidget()),
                      )
                    else if (notifications.isEmpty)
                      SliverFillRemaining(
                        child: _buildEmptyState(),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == notifications.length) {
                              return _buildLoadingMore();
                            }
                            return _buildItem(notifications[index]);
                          },
                          childCount: notifications.length + (hasMore ? 1 : 0),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.notifications_none, size: 64, color: Color(0xFFDDDDDD)),
            SizedBox(height: 16),
            Text('暂无消息', style: TextStyle(color: Color(0xFF666666))),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMore() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildItem(AppNotification n) {
    print(n.relatedBlog);
    return GestureDetector(
      onTap: () async {
        // 先标记为已读
        if (!n.isRead) {
          await markAsRead(n.id);
        }

        final String blogId = n.relatedBlog != null
            ? (n.relatedBlog!['_id'] ?? n.relatedBlog!['id'] ?? '').toString()
            : '';
        final String commentId = n.relatedComment != null
            ? (n.relatedComment!['_id'] ?? n.relatedComment!['id'] ?? '')
                .toString()
            : '';

        if (blogId.isNotEmpty) {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => BlogDetailPage(
                id: blogId,
                commentId: commentId,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
          ),
          color: Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像/类型图标
            if (n.sender?['avatar'] != null &&
                (n.sender!['avatar'] as String).isNotEmpty)
              SvgPicture.network(
                n.sender!['avatar'],
                height: 35,
                width: 35,
                placeholderBuilder: (context) => const CircleAvatar(
                  radius: 17.5,
                  backgroundColor: Color(0xFFE6F7FF),
                  child: Icon(Icons.person, size: 18, color: Color(0xFF1890FF)),
                ),
              )
            else
              const CircleAvatar(
                radius: 17.5,
                backgroundColor: Color(0xFFE6F7FF),
                child: Icon(Icons.notifications,
                    size: 18, color: Color(0xFF1890FF)),
              ),
            const SizedBox(width: 12),
            // 文本
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.sender!['username'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(n.createdAt),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8C8C8C)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  n.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF666666), height: 1.4),
                ),
                if (n.relatedComment != null &&
                    n.relatedComment!['content'] != null &&
                    (n.relatedComment!['content'] as String).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    (n.relatedComment!['content'] as String),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                  ),
                ],
                if (n.relatedBlog != null &&
                    n.relatedBlog!['title'] != null &&
                    (n.relatedBlog!['title'] as String).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (n.relatedBlog!['title'] as String),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF595959),
                            height: 1.4),
                      ),
                    ),
                  ),
                ],
              ],
            )),
            const SizedBox(width: 8),
            // 未读标记
            if (!n.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4D4F),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (diff.inDays < 1) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return iso;
    }
  }
}
