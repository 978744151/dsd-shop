import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/services.dart';
import 'router/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const defaultColor = Color(0xFF4e65ff);
    final ThemeData myDarkTheme = ThemeData(
      brightness: Brightness.dark, // 必须设置为dark
      primaryColor: Colors.blueGrey[900],
      scaffoldBackgroundColor: Color(0xFF121212),
      canvasColor: Color(0xFF1E1E1E),
      cardColor: Color(0xFF252525),
      dividerColor: Colors.white30,
      // 更多自定义...
    );
    return MaterialApp.router(
      // 移除了不存在的 navigatorKey 参数
      routerConfig: router,
      title: '懂商帝',
      builder: BotToastInit(),
      theme: ThemeData(
        primaryColor: defaultColor,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF), // 全局背景色设为白色

        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: const Color(0xFFFFFFFF), // 状态栏颜色
            // statusBarBrightness: Brightness.dark, // 状态栏图标深色
          ),
        ),
        // 设置 TextButton 主题
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: defaultColor,
            foregroundColor: const Color(0xFFFFFFFF),
          ),
        ),
        // 设置 ElevatedButton 主题
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: const Color(0xFFFFFFFF),
          ),
        ),
        // 设置 OutlinedButton 主题
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: Color(0xFFB2CBF6),
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        appBarTheme: AppBarTheme(
          color: Color(0xFF1A1A1A),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.blueGrey[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        cardTheme: CardThemeData(
          color: Color(0xFF252525),
          elevation: 2,
          margin: EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // 其他组件样式...
      ),
      themeMode: ThemeMode.light, // 强制使用暗色模式（测试用）
      // themeMode: ThemeMode.system, // 跟随系统主题
    );
  }
}
