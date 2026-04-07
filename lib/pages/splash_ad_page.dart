import 'package:flutter/material.dart';
// import 'package:flutter_unionad/flutter_unionad.dart';
import 'dart:async';
import '../config/ad_config.dart';
import '../services/splash_ad_manager.dart';

/// 开屏广告 Overlay Widget
/// 用于在 home_page 上覆盖显示开屏广告
class SplashAdOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  final VoidCallback onInitialized;

  const SplashAdOverlay({
    Key? key,
    required this.onDismiss,
    required this.onInitialized,
  }) : super(key: key);

  @override
  State<SplashAdOverlay> createState() => _SplashAdOverlayState();
}

class _SplashAdOverlayState extends State<SplashAdOverlay> {
  Timer? _timer;
  int _countdown = AdConfig.splashCountdown;
  bool _offstage = true;
  bool _isInitialized = false;
  bool _shouldShowAd = true; // 控制是否应该显示广告
  final _adManager = SplashAdManager();

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  // 检查是否应该显示广告（每10分钟只显示一次）
  void _checkFirstLaunch() async {
    // 使用全局广告管理器检查
    bool shouldShow = await _adManager.shouldShowAd();
    
    if (!shouldShow) {
      _shouldShowAd = false;
      widget.onInitialized();
      widget.onDismiss();
      return;
    }
    
    _initializeAd();
  }

  // 初始化广告SDK
  void _initializeAd() async {
    // 如果不应该显示广告，则直接返回
    if (!_shouldShowAd) {
      return;
    }
    
    // 记录广告已显示
    await _adManager.markAdAsShown();
    
    if (!AdConfig.enableSplashAd) {
      widget.onInitialized();
      _startCountdown();
      return;
    }

    try {
      // 初始化穿山甲SDK
      // final res = await FlutterUnionad.register(
      //   androidAppId: AdConfig.appId,
      //   iosAppId: AdConfig.appId,
      //   appName: AdConfig.appName,
      //   useMediation: true,
      //   allowShowNotify: true,
      //   debug: AdConfig.debugMode,
      //   supportMultiProcess: true,
      // );

      // print('广告SDK初始化成功 $res');

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        // 通知 home_page 可以开始加载数据
        widget.onInitialized();
        _startCountdown();
      }
    } catch (e) {
      print('广告SDK初始化失败: $e');
      if (mounted) {
        widget.onInitialized();
        _startCountdown();
      }
    }
  }

  // 开始倒计时
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_countdown > 0) {
          setState(() {
            _countdown--;
          });
        } else {
          _timer?.cancel();
          _dismissAd();
        }
      }
    });
  }

  // 关闭广告
  void _dismissAd() {
    _timer?.cancel();
    widget.onDismiss();
  }

  // 跳过广告
  void _skipAd() {
    _timer?.cancel();
    _dismissAd();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果不应该显示广告，返回空容器
    if (!_shouldShowAd) {
      return Container();
    }
    
    return Stack(
      children: [
        // 开屏广告Widget - 仅在初始化成功后显示
        if (_isInitialized)
          // Offstage(
          //   offstage: _offstage,
          //   child: FlutterUnionadSplashAdView(
          //     androidCodeId: AdConfig.splashAdId,
          //     iosCodeId: AdConfig.splashAdId,
          //     supportDeepLink: true,
          //     width: MediaQuery.of(context).size.width,
          //     height: MediaQuery.of(context).size.height,
          //     hideSkip: false,
          //     timeout: AdConfig.splashTimeout,
          //     callBack: FlutterUnionadSplashCallBack(
          //       onShow: () {
          //         print("开屏广告显示");
          //         setState(() => _offstage = false);
          //       },
          //       onClick: () {
          //         print("开屏广告点击");
          //         // 点击广告后，SDK 会自动处理跳转逻辑
          //         // 这里可以添加自定义逻辑，比如埋点统计
          //         // 注意：不要在这里调用 _dismissAd()，会干扰 SDK 的跳转
          //       },
          //       onFail: (error) {
          //         print("开屏广告失败 $error");
          //         _dismissAd();
          //       },
          //       onFinish: () {
          //         print("开屏广告倒计时结束");
          //         _dismissAd();
          //       },
          //       onSkip: () {
          //         print("开屏广告跳过");
          //         _dismissAd();
          //       },
          //       onTimeOut: () {
          //         print("开屏广告超时");
          //         _dismissAd();
          //       },
          //     ),
          //   ),
          // ),

        // 背景图片或品牌Logo（广告加载时显示）
        Offstage(
          offstage: !_offstage,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4e65ff),
                  Color(0xFF6c7ce7),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 应用Logo
                Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/logo/logo.jpg'),
                  fit: BoxFit.contain,
                  
                ),
                  ),
                ),
                const SizedBox(height: 20),
                // 应用名称
                const Text(
                  '商业星球',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                // 应用描述
                const Text(
                  '探索商业世界的无限可能',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                // 加载指示器
                  // const CircularProgressIndicator(
                  //   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  // ),
                
              ],
            ),
          ),
        ),

        // 跳过按钮
        Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          right: 20,
          child: GestureDetector(
            onTap: _skipAd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '跳过 $_countdown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
