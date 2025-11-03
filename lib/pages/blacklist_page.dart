import 'package:business_savvy/pages/user_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/http_client.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/loading_indicator_widget.dart';
import '../widgets/custom_refresh_widget.dart';

class BlockedUserInfo {
  final String id;
  final String username;
  final String avatar;
  final String? bio;
  final int followersCount;
  final int followingCount;

  BlockedUserInfo({
    required this.id,
    required this.username,
    required this.avatar,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory BlockedUserInfo.fromJson(Map<String, dynamic> json) {
    return BlockedUserInfo(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      bio: json['bio'],
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
    );
  }
}

class BlacklistUser {
  final String id;
  final BlockedUserInfo? blockedUser;
  final String createdAt;

  BlacklistUser({
    required this.id,
    this.blockedUser,
    this.createdAt = '',
  });

  factory BlacklistUser.fromJson(Map<String, dynamic> json) {
    return BlacklistUser(
      id: json['_id'] ?? '',
      blockedUser: json['blockedUser'] != null
          ? BlockedUserInfo.fromJson(json['blockedUser'])
          : null,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class BlacklistPage extends StatefulWidget {
  const BlacklistPage({super.key});

  @override
  State<BlacklistPage> createState() => _BlacklistPageState();
}

class _BlacklistPageState extends State<BlacklistPage>
    with AutomaticKeepAliveClientMixin {
  List<BlacklistUser> blacklistUsers = [];
  bool isLoading = true;
  int currentPage = 1;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    fetchBlacklist();
  }

  @override
  bool get wantKeepAlive => true;

  // 获取黑名单列表
  Future<void> fetchBlacklist() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await HttpClient.get('blacklist', params: {
        'page': currentPage.toString(),
        'limit': '20',
      });

      if (!mounted) return;

      if (response['success'] == true) {
        final List<dynamic> data = response['data']['blacklists'] ?? [];
        final List<BlacklistUser> newUsers =
            data.map((json) => BlacklistUser.fromJson(json)).toList();

        setState(() {
          if (currentPage == 1) {
            blacklistUsers = newUsers;
          } else {
            blacklistUsers.addAll(newUsers);
          }
          hasMore = newUsers.length >= 20;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 取消拉黑
  Future<void> removeFromBlacklist(String userId) async {
    try {
      final response = await HttpClient.delete('blacklist/$userId');

      if (response['success'] == true) {
        setState(() {
          blacklistUsers.removeWhere((user) => user.blockedUser?.id == userId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已取消拉黑')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请重试')),
        );
      }
    }
  }

  // 刷新数据
  Future<void> onRefresh() async {
    currentPage = 1;
    await fetchBlacklist();
  }

  // 加载更多
  Future<void> loadMore() async {
    if (!hasMore || isLoading) return;
    currentPage++;
    await fetchBlacklist();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('黑名单'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading && blacklistUsers.isEmpty
          ? const Center(child: LoadingIndicatorWidget())
          : blacklistUsers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.block,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '暂无黑名单用户',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : CustomRefreshWidget(
                  onRefresh: onRefresh,
                  child: ListView.builder(
                    itemCount: blacklistUsers.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == blacklistUsers.length) {
                        // 加载更多指示器
                        if (hasMore) {
                          loadMore();
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: LoadingIndicatorWidget()),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final user = blacklistUsers[index];
                      return _buildUserItem(user);
                    },
                  ),
                ),
    );
  }

  Widget _buildUserItem(BlacklistUser user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 头像
          GestureDetector(
            onTap: () {
              if (user.blockedUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfilePage(
                      userId: user.blockedUser!.id,
                    ),
                  ),
                );
              }
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              child: user.blockedUser?.avatar.isNotEmpty == true
                  ? SvgPicture.network(
                      user.blockedUser!.avatar,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.person, size: 24),
            ),
          ),
          const SizedBox(width: 12),

          // 用户信息
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (user.blockedUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(
                        userId: user.blockedUser!.id,
                      ),
                    ),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.blockedUser?.username ?? '未知用户',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (user.blockedUser?.bio != null &&
                      user.blockedUser!.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.blockedUser!.bio!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),

          // 取消拉黑按钮
          ElevatedButton(
            onPressed: () => removeFromBlacklist(user.blockedUser!.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              // 按钮缩小
              minimumSize: const Size(60, 30),
            ),
            child: const Text(
              '取消拉黑',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}