import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
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
      ..loadRequest(Uri.parse(
          'https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1802222266591763904'));
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
          '隐私协议',
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
              _controller.reload();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // WebView内容
          WebViewWidget(controller: _controller),

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
                      '正在加载隐私协议...',
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
