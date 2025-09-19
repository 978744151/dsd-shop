import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/http_client.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  // 添加验证状态
  bool _isEmailValid = true;
  bool _isPasswordValid = true;
  String _emailError = '';
  String _passwordError = '';

  // 添加验证方法
  void _validateInputs() {
    setState(() {
      // 邮箱验证
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      _isEmailValid = emailRegex.hasMatch(_emailController.text);
      _emailError = _isEmailValid ? '' : '请输入有效的邮箱地址';

      // 密码验证
      _isPasswordValid = _passwordController.text.length >= 6;
      _passwordError = _isPasswordValid ? '' : '密码长度至少为6位';
    });
  }

  Future<void> _login() async {
    _validateInputs();
    if (!_isEmailValid || !_isPasswordValid) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = await HttpClient.post('auth/login', body: {
        'email': _emailController.text,
        'password': _passwordController.text,
      });
      if (data['success'] == true) {
        print(data);

        // 修改这里，根据实际返回的数据结构获取 token
        final token = data['data']['token']; // 修改这行
        await _saveToken(token);
        // await _fetchUserInfo();
        // final prefs = await SharedPreferences.getInstance();
        // await prefs.setString('userInfo', data['data']['user']);
        if (mounted) {
          context.go('/'); // 使用 go_router 进行导航
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登录失败，请检查邮箱和密码')),
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
      final data = await HttpClient.get('/auth/me');
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userInfo', json.encode(data['data']));
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
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFFFFF),
                              boxShadow: [
                                BoxShadow(
                                  // ignore: deprecated_member_use
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.flutter_dash,
                              size: 40,
                              color: Color(0xFF1890FF),
                            ),
                          ),
                        ),
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
                                    labelText: '输入任意邮箱',
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
                                TextField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible,
                                  onChanged: (value) => _validateInputs(),
                                  decoration: InputDecoration(
                                    labelText: '密码',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _isPasswordValid
                                            ? Colors.grey[300]!
                                            : Colors.red,
                                      ),
                                    ),
                                    errorText: _passwordError.isNotEmpty
                                        ? _passwordError
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 24),
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
                        // 添加额外的链接
                        Center(
                          child: TextButton(
                            onPressed: () {
                              // 处理注册操作
                            },
                            child: const Text(
                              '还没有账号？立即注册',
                              style: TextStyle(
                                color: const Color(0xFFFFFFFF),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
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
