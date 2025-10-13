import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async'; // 添加Timer导入
import '../utils/storage.dart';
import '../utils/http_client.dart';
import '../api/comment_api.dart';
import '../utils/event_bus.dart';

class CustomBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    this.onTap,
  }) : super(key: key);

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation> {
  int unreadCount = 0;
  Timer? _timer; // 添加定时器变量
  late StreamSubscription _eventSubscription; // 添加事件订阅

  @override
  void initState() {
    super.initState();
    _getUnreadCount();
    // 启动定时器，每10秒调用一次_getUnreadCount
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _getUnreadCount();
    });

    // 监听未读消息数量更新事件
    _eventSubscription = eventBus.on<UnreadCountUpdateEvent>().listen((_) {
      _getUnreadCount();
    });
  }

  @override
  void dispose() {
    // 清理定时器和事件订阅
    _timer?.cancel();
    _eventSubscription.cancel();
    super.dispose();
  }

  Future<void> _getUnreadCount() async {
    try {
      final response = await HttpClient.get(NftApi.getUnreadCount);
      if (mounted && response['success'] == true) {
        setState(() {
          unreadCount = response['data']['unreadCount'] ?? 0;
        });
      }
    } catch (e) {
      print('获取未读消息数量失败: $e');
    }
  }

  // 公开方法，供外部调用刷新未读数量
  void refreshUnreadCount() {
    _getUnreadCount();
  }

  // 检查登录状态的方法
  Future<bool> _checkLoginStatus() async {
    try {
      final userInfoJson = await Storage.getString('userInfo');
      return userInfoJson != null && userInfoJson.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 处理购物车点击事件
  Future<void> _handleShopCartTap(BuildContext context, int index) async {
    final isLoggedIn = await _checkLoginStatus();
    if (!isLoggedIn) {
      // 未登录，跳转到登录页面
      context.go('/login');
    } else {
      // 已登录，执行正常导航
      widget.onTap?.call(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: (index) async {
        // 如果点击的是购物车图标（索引为2）
        if (index == 2) {
          await _handleShopCartTap(context, index);
        } else if (index == 3) {
          // 如果点击的是消息图标（索引为3），刷新未读数量并通知notifications页面刷新
          await _getUnreadCount();
          // 发送事件通知notifications页面刷新数据
          eventBus.fire(NotificationsRefreshEvent());
          widget.onTap?.call(index);
        } else {
          widget.onTap?.call(index);
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFFFFFFF),
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: const Color.fromARGB(255, 54, 53, 53),
      selectedLabelStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 16,
      ),
      elevation: 0,
      items: [
        const BottomNavigationBarItem(
          icon: SizedBox(),
          label: '欢迎',
        ),
        // 移除 const
        const BottomNavigationBarItem(
          icon: SizedBox(),
          label: '社区',
        ),

        BottomNavigationBarItem(
          icon: SizedBox(
            height: 20, // 与文字高度一致
            child: Icon(
              Icons.compare_arrows,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          activeIcon: SizedBox(
            height: 20, // 与文字高度一致
            child: Icon(
              Icons.compare_arrows_outlined,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const SizedBox(),
              if (unreadCount > 0)
                Positioned(
                  right: -25,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                          color: Color(0xFFFFFFFF), fontSize: 8),
                    ),
                  ),
                ),
            ],
          ),
          label: '消息',
        ),
        const BottomNavigationBarItem(
          icon: SizedBox(),
          label: '我的',
        ),
      ],
    );
  }
}
