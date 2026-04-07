class AdConfig {
  // 穿山甲广告配置
  static const String appId = "5776295"; // 替换为你的应用ID
  static const String appName = "商业星球";
  
  // 广告位ID配置
  static const String splashAdId = "103813429"; // 开屏广告位ID
  static const String bannerAdId = "your_banner_ad_id"; // 横幅广告位ID
  static const String interstitialAdId = "your_interstitial_ad_id"; // 插屏广告位ID
  static const String rewardVideoAdId = "your_reward_video_ad_id"; // 激励视频广告位ID
  
  // 广告配置参数
  static const int splashTimeout = 3000; // 开屏广告超时时间(毫秒)
  static const int splashCountdown = 5; // 开屏广告倒计时(秒)
  static const bool debugMode = false; // 调试模式，发布时改为false
  
  // 广告显示策略
  static const bool enableSplashAd = true; // 是否启用开屏广告
  static const bool enableBannerAd = true; // 是否启用横幅广告
  static const bool enableInterstitialAd = true; // 是否启用插屏广告
  static const bool enableRewardVideoAd = true; // 是否启用激励视频广告
}