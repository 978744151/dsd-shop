import '../utils/storage.dart';

/// 开屏广告管理器（单例）
/// 用于全局控制广告显示逻辑，避免重复检查
class SplashAdManager {
  static final SplashAdManager _instance = SplashAdManager._internal();
  factory SplashAdManager() => _instance;
  SplashAdManager._internal();

  bool _isChecking = false;
  bool? _shouldShowAd;
  DateTime? _lastCheckTime;

  /// 检查是否应该显示广告（带缓存机制）
  Future<bool> shouldShowAd() async {
    // 如果正在检查中，等待结果
    if (_isChecking) {
      while (_isChecking) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _shouldShowAd ?? false;
    }

    // 如果已经检查过且时间在5秒内，直接返回缓存结果
    if (_shouldShowAd != null && _lastCheckTime != null) {
      final timeSinceLastCheck = DateTime.now().difference(_lastCheckTime!);
      if (timeSinceLastCheck.inSeconds < 5) {
        return _shouldShowAd!;
      }
    }

    _isChecking = true;

    try {
      String? lastShownTimeStr = await Storage.getString('last_splash_ad_time');
      DateTime now = DateTime.now();

      // 如果之前记录过广告显示时间
      if (lastShownTimeStr != null) {
        try {
          DateTime lastShownTime = DateTime.parse(lastShownTimeStr);
          Duration timeDiff = now.difference(lastShownTime);

          // 如果距离上次显示广告不到10分钟，则不显示广告
          if (timeDiff.inMinutes < 10) {
            _shouldShowAd = false;
            _lastCheckTime = now;
            return false;
          }
        } catch (e) {
          print('解析上次广告时间失败: $e');
        }
      }

      _shouldShowAd = true;
      _lastCheckTime = now;
      return true;
    } finally {
      _isChecking = false;
    }
  }

  /// 记录广告已显示
  Future<void> markAdAsShown() async {
    DateTime now = DateTime.now();
    await Storage.setString('last_splash_ad_time', now.toIso8601String());
    _shouldShowAd = false;
    _lastCheckTime = now;
  }

  /// 重置状态（用于测试）
  void reset() {
    _shouldShowAd = null;
    _lastCheckTime = null;
  }
}
