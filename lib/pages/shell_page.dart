import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // 添加这行
import '../widgets/bottom_navigation.dart';
import 'splash_ad_page.dart';
import '../utils/event_bus.dart';
import '../services/splash_ad_manager.dart';

class ShellPage extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ShellPage({
    required this.navigationShell,
    Key? key,
  }) : super(key: key);

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  bool _showSplashAd = false; // 默认不显示广告，等待异步检查结果
  bool _adCheckComplete = false; // 标记广告检查是否完成
  final _adManager = SplashAdManager();

  @override
  void initState() {
    super.initState();
    // 确保从登录页跳转时显示首页（第一个分支）
    if (widget.navigationShell.currentIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.navigationShell.goBranch(0);
      });
    }
    _checkAdStatus();
  }
  
  void _checkAdStatus() async {
    // 使用全局广告管理器检查是否应该显示广告
    bool shouldShowAd = await _adManager.shouldShowAd();
    
    if (mounted) {
      setState(() {
        _showSplashAd = shouldShowAd;
        _adCheckComplete = true;
      });
    }
  }
  
  void _onSplashAdInitialized() {
    print('Splash 广告已初始化，开始加载 home 数据');
    // 通过 event bus 通知 home_page 开始加载数据
    eventBus.fire(SplashAdInitializedEvent());
  }

  void _onSplashAdDismissed() {
    print('Splash 广告已关闭');
    setState(() {
      _showSplashAd = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.navigationShell,
          // 开屏广告 Overlay - 覆盖整个屏幕包括 tabbar
          if (_adCheckComplete && _showSplashAd)
            Positioned.fill(
              child: SplashAdOverlay(
                onInitialized: _onSplashAdInitialized,
                onDismiss: _onSplashAdDismissed,
              ),
            ),
        ],
      ),
      bottomNavigationBar: _adCheckComplete && _showSplashAd
          ? null  // 广告显示时隐藏底部导航
          : CustomBottomNavigation(
              currentIndex: widget.navigationShell.currentIndex,
              onTap: widget.navigationShell.goBranch,
            ),
    );
  }
}
