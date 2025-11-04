import 'package:flutter/material.dart'; // 添加这行
import 'package:go_router/go_router.dart';
import 'package:bot_toast/bot_toast.dart';

import '../pages/home_page.dart';
import '../pages/shop_page.dart';
import '../pages/compare_page.dart';
import '../pages/shell_page.dart';
import '../pages/mine_page.dart';
import '../pages/login_page.dart';
import '../pages/shopDetailEcharts.dart';
import '../pages/test_map_page.dart';
import '../pages/simple_map_page.dart';
import '../pages/mall_detail_page.dart';
import '../pages/mall_brand_page.dart';
import '../pages/settings_page.dart';
import '../pages/blog_detail_page.dart';
import '../pages/message_page.dart';
import '../pages/create_blog_page.dart';
import '../pages/search_blog_page.dart';
import '../pages/history_page.dart';
import '../pages/favorites_page.dart';
import '../pages/follow_page.dart';
import '../pages/notifications_page.dart';
import '../pages/brand_center_page.dart';
import '../pages/feedback_page.dart';
import '../pages/user_profile_page.dart';
import '../pages/blacklist_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(); // 添加这行

final router = GoRouter(
  navigatorKey: _rootNavigatorKey, // 添加这行
  observers: [BotToastNavigatorObserver()],

  initialLocation: '/',
  redirect: (context, state) {
    // 如果访问根路径，重定向到message页面
    if (state.location == '/') {
      return '/';
    }
    return null; // 不重定向
  },
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellPage(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomePage(),
              routes: [
                GoRoute(
                  path: 'shopDetailEcharts/:id',
                  builder: (context, state) =>
                      ShopDetailEcharts(id: state.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'brandMap/:brandId',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) =>
                      SimpleMapPage(brandId: state.pathParameters['brandId']),
                ),
                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: 'mall-detail',
                  builder: (context, state) => MallDetailPage(),
                ),
                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: 'mall-brand/:mallId',
                  builder: (context, state) => MallBrandPage(
                    mallId: state.pathParameters['mallId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        // StatefulShellBranch(
        //   routes: [
        //     GoRoute(
        //       path: '/create',
        //       builder: (context, state) => CreateBlogPage(),
        //     ),
        //   ],
        // ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/message',
              builder: (context, state) => const MessagePage(),
              routes: [
                GoRoute(
                  path: 'messageDetail/:id', // 修改为子路由
                  parentNavigatorKey: _rootNavigatorKey, // 添加这行
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return BlogDetailPage(id: id);
                  },
                ),
                GoRoute(
                  path: 'create',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => CreateBlogPage(),
                ),
                GoRoute(
                  path: 'search',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const SearchBlogPage(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/compare',
              builder: (context, state) {
                final mallIdParam = state.queryParameters['mallId'];
                final mallNameParam = state.queryParameters['mallName'];
                final autoOpen = state.queryParameters['open'] == 'true';
                print('mallIdParam: $mallIdParam');
                return ComparePage(
                  mallId: mallIdParam,
                  autoOpenSelection: autoOpen,
                  mallName: mallNameParam,
                );
              },
            ),
            // 新增比较详情页
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/mine',
              builder: (context, state) => MinePage(),
              routes: [],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const HistoryPage(),
    ),
    GoRoute(
      path: '/favorites',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FavoritesPage(),
    ),
    GoRoute(
      path: '/follow',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final initialTabIndex =
            int.tryParse(state.queryParameters['tab'] ?? '0') ?? 0;
        return FollowPage(initialTabIndex: initialTabIndex);
      },
    ),
    GoRoute(
      path: '/feedback',
      builder: (context, state) => const FeedbackPage(),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsPage(),
    ),

    // 将笔记详情页移到这里
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/brand_center',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final autoFocus = state.queryParameters['autoFocus'] == 'true';
        return BrandCenterPage(autoFocus: autoFocus);
      },
    ),
    GoRoute(
      path: '/test-map',
      builder: (context, state) => const TestMapPage(),
    ),
    GoRoute(
      path: '/user/:userId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return UserProfilePage(userId: userId);
      },
    ),
    GoRoute(
      path: '/blacklist',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BlacklistPage(),
    ),
  ],
);
