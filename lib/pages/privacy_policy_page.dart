import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:html' as html show IFrameElement, window;
import 'dart:ui_web' as ui;

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  final String _url =
      'https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1802222266591763904';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initializeWebFrame();
    }
  }

  void _initializeWebFrame() {
    if (kIsWeb) {
      // 在Web端注册iframe
      final String viewId = 'privacy-policy-iframe';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF333333),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '隐私协议',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF333333),
              size: 24,
            ),
            onPressed: () {
              if (!kIsWeb && _controller != null) {
                _controller!.reload();
              } else if (kIsWeb) {
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
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                supportZoom: false,
                useOnLoadResource: true,
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _isLoading = true;
                });
              },
              onLoadStop: (controller, url) {
                setState(() {
                  _isLoading = false;
                });
              },
              onReceivedError: (controller, request, error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('页面加载失败: ${error.description}'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            )
          else
            const HtmlElementView(viewType: 'privacy-policy-iframe'),

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
