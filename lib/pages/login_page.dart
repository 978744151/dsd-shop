import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/http_client.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'user_agreement_page.dart';
import 'privacy_policy_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  bool _isLoading = false;
  bool _isSendingCode = false;
  int _countdown = 0;
  // 添加验证状态
  bool _isEmailValid = true;
  bool _isCodeValid = true;
  String _emailError = '';
  String _codeError = '';
  // 添加协议同意状态
  bool _agreeToTerms = false;

  // 添加验证方法
  void _validateInputs() {
    setState(() {
      // 邮箱验证
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      _isEmailValid = emailRegex.hasMatch(_emailController.text);
      _emailError = _isEmailValid ? '' : '请输入有效的邮箱地址';

      // 验证码验证
      _isCodeValid = _verificationCodeController.text.length >= 4;
      _codeError = _isCodeValid ? '' : '请输入有效的验证码';
    });
  }

  // 检查是否可以登录
  bool _canLogin() {
    return _emailController.text.isNotEmpty &&
        _verificationCodeController.text.isNotEmpty;
  }

  Future<void> _login() async {
    // 检查邮箱和验证码是否为空
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入邮箱地址')),
      );
      return;
    }

    if (_verificationCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入验证码')),
      );
      return;
    }

    // 如果未同意协议，显示确认弹框
    if (!_agreeToTerms) {
      _showAgreementConfirmDialog();
      return;
    }

    _validateInputs();
    if (!_isEmailValid || !_isCodeValid) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = await HttpClient.post('auth/email-login', body: {
        'email': _emailController.text,
        'code': _verificationCodeController.text,
      });
      if (data['success'] == true) {
        // 修改这里，根据实际返回的数据结构获取 token
        final token = data['data']['token']; // 修改这行
        await _saveToken(token);
        await _fetchUserInfo();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userInfo', data['data']['user']);
        if (mounted) {
          context.go('/'); // 使用 go_router 进行导航
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登录失败，请检查邮箱和验证码')),
          );
        }
      }
    } catch (e) {
      // print('Login error: $e'); // 添加错误日志
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('未知错误')),
      //   );
      // }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchUserInfo() async {
    try {
      final data = await HttpClient.get('auth/me');
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userInfo', json.encode(data['data']['user']));
        if (mounted) {
          context.go('/'); // 使用 go_router 进行导航
        }
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // 发送验证码
  Future<void> _sendVerificationCode() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入邮箱地址')),
      );
      return;
    }

    // 验证邮箱格式
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的邮箱地址')),
      );
      return;
    }

    setState(() => _isSendingCode = true);

    try {
      final data = await HttpClient.post('auth/send-code', body: {
        'email': _emailController.text,
      });

      if (data['success'] == true) {
        // 开始倒计时
        setState(() {
          _countdown = 60;
        });

        // 倒计时逻辑
        Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_countdown > 0) {
            setState(() {
              _countdown--;
            });
          } else {
            timer.cancel();
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('验证码已发送成功！'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? '发送验证码失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发送验证码失败，请稍后重试')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  // 游客登录
  Future<void> _guestLogin() async {
    setState(() => _isLoading = true);

    try {
      // 直接跳转到主页，不需要token验证
      if (mounted) {
        context.go('/'); // 使用 go_router 进行导航
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 显示协议确认弹框
  void _showAgreementConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFF8FAFF),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部装饰和图标
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1890FF),
                              const Color(0xFF40A9FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1890FF).withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '用户协议确认',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // 内容区域
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      const Text(
                        '登录即表示您同意我们的用户协议和隐私政策',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 协议链接区域
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              _openUserAgreement();
                            },
                            child: const Text(
                              '《用户协议》',
                              style: TextStyle(
                                color: Color(0xFF1890FF),
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text(
                            '  和  ',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              _openPrivacyPolicy();
                            },
                            child: const Text(
                              '《隐私政策》',
                              style: TextStyle(
                                color: Color(0xFF1890FF),
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 按钮区域
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0x66666666),
                                  width: 1.5,
                                ),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: const Text(
                                  '取消',
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    _agreeToTerms = true;
                                  });
                                  _login();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: const Text(
                                  '同意并继续',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 打开用户协议和免责声明页面
  Future<void> _openUserAgreement() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserAgreementPage(),
      ),
    );
  }

  // 打开隐私协议页面
  Future<void> _openPrivacyPolicy() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1890FF),
              Color.fromARGB(255, 66, 83, 96),
              Color(0xFF90CAF9),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                // 背景装饰圆形
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // ignore: deprecated_member_use
                      color: const Color(0xFFFFFFFF).withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -150,
                  left: -150,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // ignore: deprecated_member_use
                      color: const Color(0xFFFFFFFF).withOpacity(0.1),
                    ),
                  ),
                ),
                // 主要内容
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        // Logo或图标
                        // Center(
                        //   child: Container(
                        //     width: 80,
                        //     height: 80,
                        //     decoration: BoxDecoration(
                        //       shape: BoxShape.circle,
                        //       color: const Color(0xFFFFFFFF),
                        //       boxShadow: [
                        //         BoxShadow(
                        //           // ignore: deprecated_member_use
                        //           color: Colors.black.withOpacity(0.1),
                        //           blurRadius: 10,
                        //           offset: const Offset(0, 5),
                        //         ),
                        //       ],
                        //     ),
                        //     child: const Icon(
                        //       Icons.flutter_dash,
                        //       size: 40,
                        //       color: Color(0xFF1890FF),
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 40),
                        const Text(
                          '欢迎回来',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '请登录您的账号',
                          style: TextStyle(
                            fontSize: 16,
                            // ignore: deprecated_member_use
                            color: const Color(0xFFFFFFFF).withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 48),
                        // 登录表单容器
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                // 原有的TextField和按钮代码保持不变
                                // 修改 TextField 部分
                                TextField(
                                  controller: _emailController,
                                  onChanged: (value) => _validateInputs(),
                                  decoration: InputDecoration(
                                    labelText: '输入你的邮箱',
                                    prefixIcon:
                                        const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _isEmailValid
                                            ? Colors.grey[300]!
                                            : Colors.red,
                                      ),
                                    ),
                                    errorText: _emailError.isNotEmpty
                                        ? _emailError
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // 验证码输入框
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _verificationCodeController,
                                        keyboardType: TextInputType.number,
                                        maxLength: 6,
                                        onChanged: (value) => _validateInputs(),
                                        decoration: InputDecoration(
                                          labelText: '验证码',
                                          prefixIcon: const Icon(
                                              Icons.verified_user_outlined),
                                          counterText: '',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: _isCodeValid
                                                  ? Colors.grey[300]!
                                                  : Colors.red,
                                            ),
                                          ),
                                          errorText: _codeError.isNotEmpty
                                              ? _codeError
                                              : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 120,
                                      height: 56, // 与TextField高度保持一致
                                      alignment: Alignment.center,
                                      child: ElevatedButton(
                                        onPressed:
                                            (_isSendingCode || _countdown > 0)
                                                ? null
                                                : _sendVerificationCode,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          minimumSize: const Size(120, 48),
                                        ),
                                        child: _isSendingCode
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                _countdown > 0
                                                    ? '${_countdown}s'
                                                    : '发送验证码',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // 垃圾邮件提示
                                Text(
                                  '未收到验证码？请检查垃圾邮件文件夹',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // 用户协议和免责声明复选框
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: _agreeToTerms,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _agreeToTerms = value ?? false;
                                        });
                                      },
                                      activeColor: const Color(0xFF1890FF),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 12.0),
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                            children: [
                                              const TextSpan(text: '我已阅读并同意'),
                                              TextSpan(
                                                text: '《用户协议与声明》',
                                                style: const TextStyle(
                                                  color: Color(0xFF1890FF),
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                                recognizer:
                                                    TapGestureRecognizer()
                                                      ..onTap =
                                                          _openUserAgreement,
                                              ),
                                              const TextSpan(text: '和'),
                                              TextSpan(
                                                text: '《隐私声明》',
                                                style: const TextStyle(
                                                  color: Color(0xFF1890FF),
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                                recognizer:
                                                    TapGestureRecognizer()
                                                      ..onTap =
                                                          _openPrivacyPolicy,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1890FF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      const Color(0xFFFFFFFF)),
                                            ),
                                          )
                                        : const Text(
                                            '登录',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFFFFFFF),
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 不注册 继续浏览按钮
                        Center(
                          child: TextButton(
                            onPressed: _guestLogin,
                            child: const Text(
                              '不注册 继续浏览',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        // 添加额外的链接
                        // Center(
                        //   child: TextButton(
                        //     onPressed: () {
                        //       // 处理注册操作
                        //     },
                        //     child: const Text(
                        //       '还没有账号？立即注册',
                        //       style: TextStyle(
                        //         color: const Color(0xFFFFFFFF),
                        //         fontSize: 14,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
