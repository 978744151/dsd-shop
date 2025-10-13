import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/http_client.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/loading_indicator_widget.dart';
import '../widgets/custom_refresh_widget.dart';

class FollowUser {
  final String id;
  final String username;
  final String avatar;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final String createdAt;

  FollowUser({
    required this.id,
    required this.username,
    required this.avatar,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.createdAt = '',
  });

  factory FollowUser.fromJson(Map<String, dynamic> json) {
    return FollowUser(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      bio: json['bio'],
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      isFollowing: json['isFollowing'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class FollowPage extends StatefulWidget {
  const FollowPage({super.key});

  @override
  State<FollowPage> createState() => _FollowPageState();
}

class _FollowPageState extends State<FollowPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  // 关注列表
  List<FollowUser> followingList = [];
  bool isLoadingFollowing = true;
  int followingPage = 1;
  bool hasMoreFollowing = true;

  // 粉丝列表
  List<FollowUser> followersList = [];
  bool isLoadingFollowers = true;
  int followersPage = 1;
  bool hasMoreFollowers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 初始加载数据
    fetchFollowing();
    fetchFollowers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  // 获取关注列表
  Future<void> fetchFollowing() async {
    if (!mounted) return;

    setState(() {
      isLoadingFollowing = true;
    });

    try {
      final response = await HttpClient.get('follow/info', params: {
        'type': 'following',
        'page': followingPage.toString(),
        'limit': '20',
      });

      if (!mounted) return;

      if (response['success'] == true) {
        final List<dynamic> data = response['data']['following'] ?? [];
        final List<FollowUser> newUsers =
            data.map((item) => FollowUser.fromJson(item)).toList();

        setState(() {
          if (followingPage == 1) {
            followingList = newUsers;
          } else {
            followingList.addAll(newUsers);
          }
          hasMoreFollowing = newUsers.length >= 20;
          followingPage++;
          isLoadingFollowing = false;
        });
      } else {
        setState(() {
          isLoadingFollowing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingFollowing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载关注列表失败：${e.toString()}')),
      );
    }
  }

  // 获取粉丝列表
  Future<void> fetchFollowers() async {
    if (!mounted) return;

    setState(() {
      isLoadingFollowers = true;
    });

    try {
      final response = await HttpClient.get('follow/info', params: {
        'type': 'followers',
        'page': followersPage.toString(),
        'limit': '20',
      });

      if (!mounted) return;

      if (response['success'] == true) {
        final List<dynamic> data = response['data']['followers'] ?? [];
        final List<FollowUser> newUsers =
            data.map((item) => FollowUser.fromJson(item)).toList();

        setState(() {
          if (followersPage == 1) {
            followersList = newUsers;
          } else {
            followersList.addAll(newUsers);
          }
          hasMoreFollowers = newUsers.length >= 20;
          followersPage++;
          isLoadingFollowers = false;
        });
      } else {
        setState(() {
          isLoadingFollowers = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingFollowers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载粉丝列表失败：${e.toString()}')),
      );
    }
  }

  // 切换关注状态
  Future<void> toggleFollow(String userId, bool isCurrentlyFollowing) async {
    try {
      final endpoint =
          isCurrentlyFollowing ? 'follow/unfollow' : 'follow/follow';
      final response =
          await HttpClient.post(endpoint, body: {'userId': userId});

      if (response['success'] == true) {
        setState(() {
          // 更新关注列表
          for (int i = 0; i < followingList.length; i++) {
            if (followingList[i].id == userId) {
              followingList[i] = FollowUser(
                id: followingList[i].id,
                username: followingList[i].username,
                avatar: followingList[i].avatar,
                bio: followingList[i].bio,
                followersCount: followingList[i].followersCount,
                followingCount: followingList[i].followingCount,
                isFollowing: !followingList[i].isFollowing,
                createdAt: followingList[i].createdAt,
              );
              break;
            }
          }

          // 更新粉丝列表
          for (int i = 0; i < followersList.length; i++) {
            if (followersList[i].id == userId) {
              followersList[i] = FollowUser(
                id: followersList[i].id,
                username: followersList[i].username,
                avatar: followersList[i].avatar,
                bio: followersList[i].bio,
                followersCount: followersList[i].followersCount,
                followingCount: followersList[i].followingCount,
                isFollowing: !followersList[i].isFollowing,
                createdAt: followersList[i].createdAt,
              );
              break;
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败：${e.toString()}')),
      );
    }
  }

  // 刷新关注列表
  Future<void> refreshFollowing() async {
    print('开始刷新关注列表');
    setState(() {
      followingPage = 1;
      hasMoreFollowing = true;
      followingList.clear();
    });
    await fetchFollowing();
    print('关注列表刷新完成');

    // 显示刷新完成提示
    if (mounted) {}
  }

  // 刷新粉丝列表
  Future<void> refreshFollowers() async {
    print('开始刷新粉丝列表');
    setState(() {
      followersPage = 1;
      hasMoreFollowers = true;
      followersList.clear();
    });
    await fetchFollowers();
    print('粉丝列表刷新完成');

    // 显示刷新完成提示
    if (mounted) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 自定义顶部栏 - 返回按钮和TabBar在同一行
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                // 返回按钮
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      size: 18,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // TabBar
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: const Color(0xFF8C8C8C),
                    indicatorColor: Theme.of(context).primaryColor,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    // tabbar底部线距离变长
                    tabs: const [
                      Tab(text: '关注'),
                      Tab(text: '粉丝'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const ClampingScrollPhysics(),
              children: [
                // 关注列表
                _buildFollowingList(),
                // 粉丝列表
                _buildFollowersList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingList() {
    return RefreshIndicator(
      onRefresh: refreshFollowing,
      color: Theme.of(context).primaryColor,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >=
              scrollInfo.metrics.maxScrollExtent - 200) {
            if (hasMoreFollowing && !isLoadingFollowing) {
              fetchFollowing();
            }
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (isLoadingFollowing && followingList.isEmpty)
              SliverFillRemaining(
                child: const Center(child: LoadingIndicatorWidget()),
              )
            else if (followingList.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState('暂无关注', '快去关注感兴趣的人吧！'),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == followingList.length) {
                      return _buildLoadingIndicator();
                    }
                    return _buildUserCard(followingList[index]);
                  },
                  childCount: followingList.length + (hasMoreFollowing ? 1 : 0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowersList() {
    return RefreshIndicator(
      onRefresh: refreshFollowers,
      color: Theme.of(context).primaryColor,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >=
              scrollInfo.metrics.maxScrollExtent - 200) {
            if (hasMoreFollowers && !isLoadingFollowers) {
              fetchFollowers();
            }
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (isLoadingFollowers && followersList.isEmpty)
              SliverFillRemaining(
                child: const Center(child: LoadingIndicatorWidget()),
              )
            else if (followersList.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState('暂无粉丝', '发布优质内容吸引更多粉丝吧！'),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == followersList.length) {
                      return _buildLoadingIndicator();
                    }
                    return _buildUserCard(followersList[index]);
                  },
                  childCount: followersList.length + (hasMoreFollowers ? 1 : 0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(FollowUser user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF5F5F5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 头像
          // CircleAvatar(
          //   radius: 28,
          //   backgroundColor: const Color(0xFFF5F5F5),
          //   backgroundImage:
          //       user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
          //   child: user.avatar.isEmpty
          //       ? const Icon(
          //           Icons.person,
          //           color: Color(0xFF1890FF),
          //           size: 28,
          //         )
          //       : null,
          // ),
          SvgPicture.network(
            user.avatar ?? '',
            height: 35, // 固定头像大小
            width: 35,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 35,
                width: 35,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.grey),
              );
            },
          ),
          const SizedBox(width: 16),
          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '粉丝 ${user.followersCount}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8C8C8C),
                  ),
                ),
              ],
            ),
          ),
          // 关注按钮
          if (user.id != 'current_user_id') // 假设当前用户ID，实际应该从存储中获取
            GestureDetector(
              onTap: () => toggleFollow(user.id, user.isFollowing),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: user.isFollowing
                      ? Colors.white
                      : Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: user.isFollowing
                        ? const Color(0xFFD9D9D9)
                        : Theme.of(context).primaryColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  user.isFollowing ? '已关注' : '关注',
                  style: TextStyle(
                    fontSize: 14,
                    color: user.isFollowing
                        ? const Color(0xFF8C8C8C)
                        : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1890FF)),
        ),
      ),
    );
  }
}
