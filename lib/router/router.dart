import 'package:flutter/material.dart'; // 添加这行
import 'package:go_router/go_router.dart';
import 'package:bot_toast/bot_toast.dart';

import '../pages/home_page.dart';
import '../pages/shop_page.dart';
import '../pages/message_page.dart';
import '../pages/shell_page.dart';
import '../pages/mine_page.dart';
import '../pages/login_page.dart';
import '../pages/shopDetailEcharts.dart';
import '../pages/test_map_page.dart';
import '../pages/simple_map_page.dart';

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
              builder: (context, state) => HomePage(),
              routes: [
                GoRoute(
                  path: 'shopDetailEcharts/:id',
                  builder: (context, state) =>
                      ShopDetailEcharts(id: state.pathParameters['id']!),
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
              path: '/shop',
              builder: (context, state) => ShopPage(),
              routes: [
                // GoRoute(
                //   path: 'detail/:id', // 修改为子路由
                //   parentNavigatorKey: _rootNavigatorKey, // 添加这行
                //   builder: (context, state) {
                //     final id = state.pathParameters['id']!;
                //     return ShopDetail(id: id);
                //   },
                // ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/message',
              builder: (context, state) => const MessagePage(),
              routes: [
                // GoRoute(
                //   path: 'messageDetail/:id', // 修改为子路由
                //   parentNavigatorKey: _rootNavigatorKey, // 添加这行
                //   builder: (context, state) {
                //     final id = state.pathParameters['id']!;
                //     return BlogDetailPage(id: id);
                //   },
                // ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/mine',
              builder: (context, state) => MinePage(),
            ),
          ],
        ),
      ],
    ),
    // 将博客详情页移到这里
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/test-map',
      builder: (context, state) => const TestMapPage(),
    ),
    GoRoute(
      path: '/simple-map',
      builder: (context, state) => const SimpleMapPage(),
    ),
  ],
);
