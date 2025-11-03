import 'package:business_savvy/pages/feedback_page.dart';
import 'package:business_savvy/pages/privacy_policy_page.dart';
import 'package:business_savvy/pages/user_agreement_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/storage.dart';
import 'dart:convert';
import '../utils/http_client.dart';
import '../utils/toast_util.dart';
import '../utils/image_upload_util.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/event_bus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  Map<dynamic, dynamic> userInfo = {};
  String? _avatarPath;
  XFile? _avatarXFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfoJson = await Storage.getString('userInfo');
      if (userInfoJson != null) {
        setState(() {
          userInfo = json.decode(userInfoJson);
          _nameController.text =
              userInfo['username'] ?? userInfo['username'] ?? '';
          _emailController.text = userInfo['email'] ?? '';
        });
      }
    } catch (e) {
      print('获取用户信息失败: $e');
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _avatarXFile = image;
          _avatarPath = image.path;
        });
      }
    } catch (e) {
      ToastUtil.showError('选择头像失败: $e');
    }
  }

  Future<void> _saveSettings() async {
    if (_nameController.text.trim().isEmpty) {
      ToastUtil.showError('请输入用户名');
      return;
    }

    // 验证邮箱格式
    if (_emailController.text.trim().isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(_emailController.text.trim())) {
        ToastUtil.showError('请输入有效的邮箱地址');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 更新用户名和邮箱
      final updateData = {
        'username': _nameController.text.trim(),
      };

      if (_emailController.text.trim().isNotEmpty) {
        updateData['email'] = _emailController.text.trim();
      }

      final nameResponse =
          await HttpClient.put('user/profile', body: updateData);

      if (nameResponse['success'] == true) {
        // 更新本地存储的用户信息
        userInfo['username'] = _nameController.text.trim();
        if (_emailController.text.trim().isNotEmpty) {
          userInfo['email'] = _emailController.text.trim();
        }
        await Storage.setString('userInfo', json.encode(userInfo));

        // 如果有选择新头像，上传头像
        if (_avatarXFile != null) {
          await _uploadAvatar();
        }

        ToastUtil.showSuccess('设置保存成功');

        // 触发mine页面刷新事件，让mine页面调用_getToken更新用户信息
        eventBus.fire(MinePageRefreshEvent());

        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/mine');
        }
      } else {
        ToastUtil.showError(nameResponse['message'] ?? '保存失败');
      }
    } catch (e) {
      ToastUtil.showError('保存失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadAvatar() async {
    if (_avatarXFile == null) return;

    try {
      Map<String, dynamic> response;

      if (kIsWeb) {
        // Web平台使用ImageUploadUtil
        response = await ImageUploadUtil.uploadImageForWeb(
          _avatarXFile!,
          uploadPath: '/user/avatar',
        );
      } else {
        // 移动端使用File
        final file = File(_avatarXFile!.path);
        response = await HttpClient.uploadFile(
          '/user/avatar',
          file,
        );
      }

      if (response['success'] == true) {
        // 更新本地存储的头像信息
        userInfo['avatar'] = response['data']['avatarUrl'];
        await Storage.setString('userInfo', json.encode(userInfo));
      }
    } catch (e) {
      print('上传头像失败: $e');
      ToastUtil.showError('上传头像失败');
    }
  }

  // _buildCustomAppBar 方法已被 SliverAppBar 替代，可以删除此方法

  Widget _buildModernAvatarSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 120, 160, 230), // 更深的蓝色
                        Color.fromARGB(255, 120, 160, 230), // 更深的
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _buildAvatarImage(),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '点击修改头像',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '支持JPG、PNG格式，建议尺寸512x512',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (_avatarXFile != null) {
      // 显示新选择的头像
      if (kIsWeb) {
        return Image.network(
          _avatarXFile!.path,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        );
      } else {
        return Image.file(
          File(_avatarXFile!.path),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        );
      }
    } else if (userInfo['avatar'] != null && userInfo['avatar'].isNotEmpty) {
      // 显示现有头像
      return Image.network(
        userInfo['avatar'],
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.3),
            Colors.purple.withOpacity(0.3),
          ],
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 40.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Color.fromARGB(255, 120, 160, 230), // 更深的蓝色
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                '个人设置',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromARGB(255, 120, 160, 230), // 更深的蓝色
                    ],
                  ),
                ),
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/mine');
                  }
                },
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '保存',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // 头像部分
                  // _buildModernAvatarSection(),
                  // const SizedBox(height: 30),
                  // 用户信息设置
                  _buildUserInfoSection(),
                  const SizedBox(height: 30),
                  // 其他设置项
                  _buildOtherSettingsSection(),
                  const SizedBox(height: 30),
                  // 退出登录按钮
                  _buildLogoutSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF667eea),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '用户信息设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 用户名输入框
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: '请输入您的用户名',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFF667eea),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF667eea),
                  size: 20,
                ),
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            maxLength: 20,
            buildCounter: (context,
                {required currentLength, required isFocused, maxLength}) {
              return Container(
                margin: const EdgeInsets.only(top: 8),
                child: Text(
                  '$currentLength/${maxLength ?? 0}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // 邮箱输入框
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: false, 
            decoration: InputDecoration(
              hintText: '请输入您的邮箱地址（可选）',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFF764ba2),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF764ba2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.alternate_email,
                  color: Color(0xFF764ba2),
                  size: 20,
                ),
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '邮箱地址用于接收重要通知和找回密码',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     Container(
          //       padding: const EdgeInsets.all(8),
          //       decoration: BoxDecoration(
          //         color: const Color(0xFF764ba2).withOpacity(0.1),
          //         borderRadius: BorderRadius.circular(10),
          //       ),
          //       child: const Icon(
          //         Icons.settings_outlined,
          //         color: Color(0xFF764ba2),
          //         size: 20,
          //       ),
          //     ),
          //     const SizedBox(width: 12),
          //     const Text(
          //       '更多设置',
          //       style: TextStyle(
          //         fontSize: 18,
          //         fontWeight: FontWeight.w600,
          //         color: Colors.black87,
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 20),
          _buildModernSettingItem(
            icon: Icons.history,
            title: '浏览历史',
            subtitle: '查看您的浏览记录',
            color: Colors.indigo,
            onTap: () {
              context.push('/history');
            },
          ),
          // _buildModernSettingItem(
          //   icon: Icons.notifications_outlined,
          //   title: '通知设置',
          //   subtitle: '管理推送通知偏好',
          //   color: Colors.orange,
          //   onTap: () {
          //     // TODO: 实现通知设置
          //   },
          // ),
          _buildModernSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: '隐私协议',
            subtitle: '隐私协议',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivacyPolicyPage(),
                ),
              );
              // TODO: 实现隐私设置
            },
          ),
          _buildModernSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: '协议和声明',
            subtitle: '用户协议和免责声明',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserAgreementPage(),
                ),
              );
              // TODO: 实现隐私设置
            },
          ),
          _buildModernSettingItem(
            icon: Icons.help_outline,
            title: '帮助与反馈',
            subtitle: '获取帮助或提供建议',
            color: Colors.blue,
            onTap: () {
              // context.push('/feedback');
              Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                builder: (context) => FeedbackPage(),
              ));
              // TODO: 实现帮助与反馈
            },
          ),
          // _buildModernSettingItem(
          //   icon: Icons.info_outline,
          //   title: '关于我们',
          //   subtitle: '了解应用信息',
          //   color: Colors.purple,
          //   onTap: () {
          //     // TODO: 实现关于我们
          //   },
          //   isLast: true,
          // ),
        ],
      ),
    );
  }

  Widget _buildModernSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: Colors.grey[200],
            indent: 60,
          ),
      ],
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[500],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '退出登录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '退出登录将清除所有本地数据',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final result = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.logout_rounded,
                  size: 40,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  '退出登录',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '确定要退出登录吗？',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(null),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(1),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('确定退出'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
      
      // 后续代码保持不变
      if (result == 1) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        ToastUtil.showSuccess('已退出登录');
        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      ToastUtil.showError('退出登录失败: $e');
    }
  }

}