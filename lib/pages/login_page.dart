import 'package:business_savvy/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:business_savvy/utils/toast_util.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/http_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'user_agreement_page.dart';
import 'privacy_policy_page.dart';
import 'package:go_router/go_router.dart';
import '../router/router.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _phoneVerificationCodeController = TextEditingController();
  final _passwordController = TextEditingController();

  late FocusNode _emailFocusNode;
  late FocusNode _phoneFocusNode;
  late FocusNode _verificationCodeFocusNode;
  late FocusNode _phoneVerificationCodeFocusNode;
  late FocusNode _passwordFocusNode;

  bool _isLoading = false;
  bool _isSendingCode = false;
  int _countdown = 0;
  int _phoneCountdown = 0;

  bool _isEmailValid = true;
  bool _isPhoneValid = true;
  bool _isCodeValid = true;
  bool _isPhoneCodeValid = true;
  bool _isPasswordValid = true;

  String _emailError = '';
  String _phoneError = '';
  String _codeError = '';
  String _phoneCodeError = '';
  String _passwordError = '';

  bool _agreeToTerms = false;
  int _loginMode = 1; // 0: 邮箱, 1: 手机, 2: 密码（默认手机登录）
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
    _verificationCodeFocusNode = FocusNode();
    _phoneVerificationCodeFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
  }

  void _validateInputs() {
    setState(() {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      _isEmailValid = emailRegex.hasMatch(_emailController.text);
      _emailError = _isEmailValid ? '' : '请输入有效的邮箱地址';

      final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
      _isPhoneValid = phoneRegex.hasMatch(_phoneController.text);
      _phoneError = _isPhoneValid ? '' : '请输入有效的手机号';

      if (_loginMode == 2) {
        _isPasswordValid = _passwordController.text.length >= 6;
        _passwordError = _isPasswordValid ? '' : '密码至少6位';
      } else if (_loginMode == 0) {
        _isCodeValid = _verificationCodeController.text.length >= 4;
        _codeError = _isCodeValid ? '' : '请输入有效的验证码';
      } else if (_loginMode == 1) {
        _isPhoneCodeValid = _phoneVerificationCodeController.text.length >= 4;
        _phoneCodeError = _isPhoneCodeValid ? '' : '请输入有效的验证码';
      }
    });
  }

  bool _canLogin() {
    if (_loginMode == 2) {
      return _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    } else if (_loginMode == 0) {
      return _emailController.text.isNotEmpty &&
          _verificationCodeController.text.isNotEmpty;
    } else {
      return _phoneController.text.isNotEmpty &&
          _phoneVerificationCodeController.text.isNotEmpty;
    }
  }

  Future<void> _login() async {
    if (!_agreeToTerms) {
      _showAgreementConfirmDialog();
      return;
    }

    _validateInputs();

    if (_loginMode == 0) {
      if (_emailController.text.isEmpty) {
         ToastUtil.showPrimary('请输入邮箱地址');
        return;
      }
      if (_verificationCodeController.text.isEmpty) {

         ToastUtil.showPrimary('请输入验证码');
        return;
      }
      if (!_isEmailValid || !_isCodeValid) return;
    } else if (_loginMode == 1) {
      if (_phoneController.text.isEmpty) {

        ToastUtil.showPrimary('请输入手机号');
        return;
      }
      if (_phoneVerificationCodeController.text.isEmpty) {
         ToastUtil.showPrimary('请输入验证码');
        return;
      }
      if (!_isPhoneValid || !_isPhoneCodeValid) return;
    } else {
      if (_emailController.text.isEmpty) {

          ToastUtil.showPrimary('请输入邮箱地址');
        return;
      }
      if (_passwordController.text.isEmpty) {

        ToastUtil.showPrimary('请输入密码');
        return;
      }
      if (!_isEmailValid || !_isPasswordValid) return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> data;

      if (_loginMode == 0) {
        data = await HttpClient.post(
          'auth/email-login',
          body: {
            'email': _emailController.text,
            'code': _verificationCodeController.text,
          },
        );
      } else if (_loginMode == 1) {
        data = await HttpClient.post(
          'auth/phone-code-login',
          body: {
            'phone': _phoneController.text,
            'code': _phoneVerificationCodeController.text,
          },
        );
      } else {
        data = await HttpClient.post(
          'auth/login',
          body: {
            'email': _emailController.text,
            'password': _passwordController.text,
          },
        );
      }
      if (data['success'] == true) {
        final token = data['data']['token'];
        await _saveToken(token);
        await _fetchUserInfo();

        if (mounted) {
          Timer(Duration(seconds: 1), () {
            setState(() => _isLoading = false);
            context.go('/');
          });
        }
      } else {
        if (mounted) {
          String errorMsg = '登录失败';
          if (_loginMode == 0) {
            errorMsg = '登录失败，请检查邮箱和验证码';
          } else if (_loginMode == 1) {
            errorMsg = '登录失败，请检查手机号和验证码';
          } else {
            errorMsg = '登录失败，请检查邮箱和密码';
          }
          ToastUtil.showPrimary(errorMsg);
         setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      // print('Login error: $e');
    } finally {
      if (mounted) {
       
      }
    }
  }

  Future<void> _fetchUserInfo() async {
    try {
      final data = await HttpClient.get('auth/me');
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userInfo', json.encode(data['data']['user']));
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _sendVerificationCode() async {
    if (_emailController.text.isEmpty) {
       ToastUtil.showPrimary('请先输入邮箱地址');

      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      ToastUtil.showPrimary('请输入有效的邮箱地址');

      return;
    }

    setState(() => _isSendingCode = true);

    try {
      final data = await HttpClient.post(
        'auth/send-code',
        body: {'email': _emailController.text},
      );

      if (data['success'] == true) {
        setState(() {
          _countdown = 60;
        });

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
            ToastUtil.showPrimary('验证码已发送成功！');
        
        }
      } else {
        if (mounted) {
             ToastUtil.showPrimary(data['message'] ?? '发送验证码失败'); 
        }
      }
    } catch (e) {
      if (mounted) {
         ToastUtil.showPrimary( '发送验证码失败，请稍后重试'); 
       
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  Future<void> _sendPhoneVerificationCode() async {
    if (_phoneController.text.isEmpty) {
       ToastUtil.showPrimary( '请先输入手机号'); 
     
      return;
    }

    final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    if (!phoneRegex.hasMatch(_phoneController.text)) {
       ToastUtil.showPrimary( '请输入有效的手机号'); 
     
      return;
    }

    setState(() => _isSendingCode = true);

    try {
      final data = await HttpClient.post(
        'auth/send-phone-code',
        body: {'type': 'login', 'phone': _phoneController.text},
      );

      if (data['success'] == true) {
        setState(() {
          _phoneCountdown = 60;
        });

        Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_phoneCountdown > 0) {
            setState(() {
              _phoneCountdown--;
            });
          } else {
            timer.cancel();
          }
        });

        if (mounted) {
          ToastUtil.showPrimary( '验证码已发送成功！'); 
       
        }
      } else {
        if (mounted) {
           ToastUtil.showPrimary( data['message'] ?? '发送验证码失败'); 
         
        }
      }
    } catch (e) {
      if (mounted) {
         ToastUtil.showPrimary( '发送验证码失败，请稍后重试'); 
        
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  Future<void> _guestLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() => _isLoading = true);
    try {
      if (mounted) {
        context.go('/');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
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

  Future<void> _openUserAgreement() async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const UserAgreementPage()));
  }

  Future<void> _openPrivacyPolicy() async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()));
  }

  String _getLoginModeTitle() {
    switch (_loginMode) {
      case 0:
        return '邮箱登录';
      case 1:
        return '手机号登录';
      case 2:
        return '密码登录';
      default:
        return '欢迎回来';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    _phoneVerificationCodeController.dispose();
    _passwordController.dispose();

    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _verificationCodeFocusNode.dispose();
    _phoneVerificationCodeFocusNode.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 主内容区
          Expanded(
            child: GestureDetector(
              onTap: () {
                // 点击空白处关闭所有输入框的焦点
                _emailFocusNode.unfocus();
                _phoneFocusNode.unfocus();
                _verificationCodeFocusNode.unfocus();
                _phoneVerificationCodeFocusNode.unfocus();
                _passwordFocusNode.unfocus();
              },
              // decoration: BoxDecoration(
              //   gradient: LinearGradient(
              //     begin: Alignment.topLeft,
              //     end: Alignment.bottomRight,
              //     colors: [
              //       Theme.of(context).primaryColor,
              //       Color.fromARGB(255, 66, 83, 96),
              //       Theme.of(context).primaryColor,
              //     ],
              //   ),
              // ),
              child: SingleChildScrollView(
                child: Stack(
                  children: [
                    Positioned(
                      top: -100,
                      right: -100,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
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
                          color: const Color(0xFFFFFFFF).withOpacity(0.1),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 50),
                            Text(
                              _getLoginModeTitle(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '请登录您的账号',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  children: [
                                    // 登录内容
                                    if (_loginMode == 0) ...[
                                      TextField(
                                        controller: _emailController,
                                        focusNode: _emailFocusNode,
                                        onChanged: (value) => _validateInputs(),
                                        decoration: InputDecoration(
                                          labelText: '输入你的邮箱',
                                          prefixIcon: const Icon(
                                            Icons.email_outlined,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                                      const SizedBox(height: 14),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller:
                                                  _verificationCodeController,
                                              focusNode:
                                                  _verificationCodeFocusNode,
                                              keyboardType:
                                                  TextInputType.number,
                                              maxLength: 6,
                                              onChanged: (value) =>
                                                  _validateInputs(),
                                              decoration: InputDecoration(
                                                labelText: '验证码',
                                                prefixIcon: const Icon(
                                                  Icons.verified_user_outlined,
                                                ),
                                                counterText: '',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
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
                                          const SizedBox(width: 10),
                                          Container(
                                            width: 110,
                                            height: 54,
                                            alignment: Alignment.center,
                                            child: ElevatedButton(
                                              onPressed:
                                                  (_isSendingCode ||
                                                      _countdown > 0)
                                                  ? null
                                                  : _sendVerificationCode,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Theme.of(
                                                  context,
                                                ).primaryColor,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                minimumSize: const Size(
                                                  110,
                                                  44,
                                                ),
                                              ),
                                              child: _isSendingCode
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 1.5,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(Colors.white),
                                                      ),
                                                    )
                                                  : Text(
                                                      _countdown > 0
                                                          ? '${_countdown}s'
                                                          : '发送',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else if (_loginMode == 1) ...[
                                      TextField(
                                        controller: _phoneController,
                                        focusNode: _phoneFocusNode,
                                        keyboardType: TextInputType.phone,
                                        maxLength: 11,
                                        onChanged: (value) => _validateInputs(),
                                        decoration: InputDecoration(
                                          labelText: '输入你的手机号',
                                          prefixIcon: const Icon(
                                            Icons.phone_outlined,
                                          ),
                                          counterText: '',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: BorderSide(
                                              color: _isPhoneValid
                                                  ? Colors.grey[300]!
                                                  : Colors.red,
                                            ),
                                          ),
                                          errorText: _phoneError.isNotEmpty
                                              ? _phoneError
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller:
                                                  _phoneVerificationCodeController,
                                              focusNode:
                                                  _phoneVerificationCodeFocusNode,
                                              keyboardType:
                                                  TextInputType.number,
                                              maxLength: 6,
                                              onChanged: (value) =>
                                                  _validateInputs(),
                                              decoration: InputDecoration(
                                                labelText: '验证码',
                                                prefixIcon: const Icon(
                                                  Icons.verified_user_outlined,
                                                ),
                                                counterText: '',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: _isPhoneCodeValid
                                                            ? Colors.grey[300]!
                                                            : Colors.red,
                                                      ),
                                                    ),
                                                errorText:
                                                    _phoneCodeError.isNotEmpty
                                                    ? _phoneCodeError
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            width: 110,
                                            height: 54,
                                            alignment: Alignment.center,
                                            child: ElevatedButton(
                                              onPressed:
                                                  (_isSendingCode ||
                                                      _phoneCountdown > 0)
                                                  ? null
                                                  : _sendPhoneVerificationCode,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Theme.of(
                                                  context,
                                                ).primaryColor,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                minimumSize: const Size(
                                                  110,
                                                  44,
                                                ),
                                              ),
                                              child: _isSendingCode
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 1.5,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(Colors.white),
                                                      ),
                                                    )
                                                  : Text(
                                                      _phoneCountdown > 0
                                                          ? '${_phoneCountdown}s'
                                                          : '发送',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      TextField(
                                        controller: _emailController,
                                        focusNode: _emailFocusNode,
                                        onChanged: (value) => _validateInputs(),
                                        decoration: InputDecoration(
                                          labelText: '输入你的邮箱',
                                          prefixIcon: const Icon(
                                            Icons.email_outlined,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                                      const SizedBox(height: 14),
                                      TextField(
                                        controller: _passwordController,
                                        focusNode: _passwordFocusNode,
                                        obscureText: _obscurePassword,
                                        onChanged: (value) => _validateInputs(),
                                        decoration: InputDecoration(
                                          labelText: '输入你的密码',
                                          prefixIcon: const Icon(
                                            Icons.lock_outlined,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                                    ],
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Checkbox(
                                          value: _agreeToTerms,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              _agreeToTerms = value ?? false;
                                            });
                                          },
                                          activeColor: Theme.of(
                                            context,
                                          ).primaryColor,
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 0,
                                            ),
                                            child: RichText(
                                              text: TextSpan(
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black87,
                                                ),
                                                children: [
                                                  const TextSpan(
                                                    text: '我已阅读并同意',
                                                  ),
                                                  TextSpan(
                                                    text: '《用户协议》',
                                                    style: const TextStyle(
                                                      color: Color(0xFF1890FF),
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                    recognizer:
                                                        TapGestureRecognizer()
                                                          ..onTap =
                                                              _openUserAgreement,
                                                  ),
                                                  const TextSpan(text: '和'),
                                                  TextSpan(
                                                    text: '《隐私政策》',
                                                    style: const TextStyle(
                                                      color: Color(0xFF1890FF),
                                                      decoration: TextDecoration
                                                          .underline,
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
                                    SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(
                                            context,
                                          ).primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? Center(
                                                  child: const CircularProgressIndicator(
                                                    color: Color(0xFFFFFFFF),
                                                  ),
                                                )
                                            : const Text(
                                                '登录',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFFFFFFFF),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: TextButton(
                                onPressed: _guestLogin,
                                child: const Text(
                                  '不注册 继续浏览',
                                  style: TextStyle(
                                    color: Colors.white,
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
          // 底部登录方式切换条
          Container(
            decoration: BoxDecoration(color: Colors.white),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLoginModeIcon(
                      icon: Icons.email_outlined,
                      label: '邮箱登录',
                      mode: 0,
                      isActive: _loginMode == 0,
                    ),
                    const SizedBox(width: 36),
                    _buildLoginModeIcon(
                      icon: Icons.phone_outlined,
                      label: '手机登录',
                      mode: 1,
                      isActive: _loginMode == 1,
                    ),
                    const SizedBox(width: 36),
                    _buildLoginModeIcon(
                      icon: Icons.lock_outline,
                      label: '密码登录',
                      mode: 2,
                      isActive: _loginMode == 2,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginModeIcon({
    required IconData icon,
    required String label,
    required int mode,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _loginMode = mode;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // color: isActive ? Theme.of(context).primaryColor : Colors.white,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.black87,
              size: 22,
            ),
          ),
          // const SizedBox(height: 5),
          // Text(
          //   label,
          //   style: TextStyle(
          //     fontSize: 11,
          //     color: isActive ? Theme.of(context).primaryColor : Colors.grey[600],
          //     fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          //   ),
          // ),
        ],
      ),
    );
  }
}
