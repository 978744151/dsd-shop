import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'dart:html' as html show IFrameElement, window;
import 'dart:ui_web' as ui;

class UserAgreementPage extends StatefulWidget {
  const UserAgreementPage({super.key});

  @override
  State<UserAgreementPage> createState() => _UserAgreementPageState();
}

class _UserAgreementPageState extends State<UserAgreementPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  final String _url = 'http://nfttools.cn/user-agreement';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeWebView();
    } else {
      _initializeWebFrame();
    }
  }

  void _initializeWebFrame() {
    if (kIsWeb) {
      // 在Web端注册iframe
      final String viewId = 'user-agreement-iframe';
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        viewId,
        (int viewId) {
          final html.IFrameElement iframe = html.IFrameElement()
            ..src = _url
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%';
          
          iframe.onLoad.listen((_) {
            setState(() {
              _isLoading = false;
            });
          });
          
          return iframe;
        },
      );
      
      // 延迟设置加载状态
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // 更新加载进度
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            // 处理加载错误
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('页面加载失败: ${error.description}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(_url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '用户协议与免责声明',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        leading: IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: Color(0xFF666666),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // 刷新按钮
          IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.refresh,
                size: 16,
                color: Color(0xFF666666),
              ),
            ),
            onPressed: () {
              if (!kIsWeb) {
                _controller.reload();
              } else {
                // Web端刷新页面
                html.window.location.reload();
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // WebView内容 - 根据平台选择不同的实现
          if (!kIsWeb)
            WebViewWidget(controller: _controller)
          else
            const HtmlElementView(viewType: 'user-agreement-iframe'),

          // 加载指示器
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1890FF),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '正在加载用户协议...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
