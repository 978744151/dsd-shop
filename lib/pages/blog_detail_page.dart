import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert'; // 添加这行
import 'package:flutter/services.dart'; // 新增：用于剪贴板

import '../api/comment_api.dart';
import 'package:intl/intl.dart'; // 添加这行
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/http_client.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../utils/storage.dart'; // 添加导入
import 'package:adaptive_dialog/adaptive_dialog.dart';

class BlogDetailPage extends StatefulWidget {
  final String id; // 添加 id 参数
  final String commentId;
  const BlogDetailPage({
    super.key,
    required this.id,
    this.commentId = '',
  });

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

// 在文件顶部添加 BlogInfo 类
class BlogInfo {
  final String title;
  final String createName;
  final String content;
  final String createdAt;
  final String type;
  final List<String> tags; // 新增：标签列表
  final List<Comment> replies;
  final List<String> images;
  final Map<String, dynamic>? user; // 添加这行
  final bool isFollowed; // 添加这行
  int favoriteCount; // 添加这行

  BlogInfo({
    this.title = '',
    this.createName = '',
    this.content = '',
    this.createdAt = '',
    this.type = '',
    this.tags = const [], // 新增：默认空列表
    this.replies = const [],
    this.images = const [],
    this.user, // 添加这行
    this.favoriteCount = 0,
    this.isFollowed = false, // 添加这行
  });

  factory BlogInfo.fromJson(Map<String, dynamic> json) {
    return BlogInfo(
      title: json['title'] ?? '',
      createName: json['createName'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] ?? '',
      type: json['type'] ?? '',
      tags: List<String>.from(json['tags'] ?? []), // 新增：解析标签
      images: List<String>.from(json['images'] ?? []),
      user: json['user'] as Map<String, dynamic>?, // 添加这行
      isFollowed: json['isFollowed'] ?? false, // 添加这行
      favoriteCount: json['favoriteCount'] ?? 0, // 添加这行
    );
  }
}

class _BlogDetailPageState extends State<BlogDetailPage>
    with TickerProviderStateMixin {
  // 添加遮罩层控制变量
  bool _showOverlay = false;

  // 添加动画控制器
  late AnimationController _favoriteAnimationController;
  late Animation<double> _favoriteAnimation;

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  String? _currentCommentId; // 添加评论ID变量
  String? _currentReplyTo; // 添加回复用户ID变量
  List<Comment> comments = [];
  BlogInfo blogInfo = BlogInfo();
  String _replyToName = ''; // 添加这行
  bool isFollowing = false;
  bool isFavorite = false; // 添加收藏状态变量
  Map<dynamic, dynamic> userInfo = {};
  // 用于滚动到指定评论
  final Map<String, GlobalKey> _topCommentKeys = {};
  bool _didScrollToComment = false;
  bool _ignoreNextTap = false; // 新增：长按后屏蔽下一次点击，避免触发输入框

  @override
  void initState() {
    super.initState();
    _commentFocusNode.addListener(_handleFocusChange);

    // 初始化动画控制器
    _favoriteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _favoriteAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _favoriteAnimationController,
      curve: Curves.elasticOut,
    ));

    fetchBlogDetail();
    fetchComments();
    fetchHistory();
    checkFavoriteStatus(); // 检查收藏状态
  }

  Future<void> getToken(String token) async {
    try {
      final userInfoJson = await Storage.getString('userInfo');
      if (userInfoJson != null) {
        setState(() {
          userInfo = json.decode(userInfoJson);
        });
        fetchFollowInfo(userInfo['_id']);
        checkFavoriteStatus(); // 获取用户信息后检查收藏状态
      }
    } catch (e) {
      print('获取用户信息失败: $e');
    }
  }

  // 检查收藏状态
  Future<void> checkFavoriteStatus() async {
    try {
      final response =
          await HttpClient.get('blogs/favorite/status/${widget.id}');

      if (response is Map && response['success'] == true) {
        setState(() {
          isFavorite = response['data']['isFavorited'] ?? false;
        });
      }
    } catch (e) {
      print('检查收藏状态失败: $e');
    }
  }

  // 切换收藏状态
  Future<void> toggleFavorite() async {
    if (userInfo.isEmpty || widget.id == null) return;

    // 播放动画
    _favoriteAnimationController.forward().then((_) {
      _favoriteAnimationController.reverse();
    });

    try {
      final endpoint = isFavorite
          ? 'blogs/unfavorite/${widget.id}'
          : 'blogs/favorite/${widget.id}';

      final response = await HttpClient.post(endpoint, body: {});
      if (response is Map && response['success'] == true) {
        checkFavoriteStatus();
        fetchComments();
        setState(() {
          // 根据当前收藏状态更新favoriteCount
          if (isFavorite) {
            // 如果当前是收藏状态，即将取消收藏，减少计数
            blogInfo.favoriteCount -= 1;
          } else {
            // 如果当前是未收藏状态，即将添加收藏，增加计数
            blogInfo.favoriteCount += 1;
          }
          // 切换收藏状态（这个会在checkFavoriteStatus中被再次更新，但f为了UI立即响应先更新）
          isFavorite = !isFavorite;
        });
        // 显示提示
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(isFavorite ? '已添加到收藏' : '已取消收藏'),
        //     duration: const Duration(seconds: 1),
        //   ),
        // );
      }
    } catch (e) {
      print('切换收藏状态失败: $e');
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _favoriteAnimationController.dispose();
    super.dispose();
  }

// 添加获取关注信息的方法
  Future<void> fetchFollowInfo(id) async {
    if (!mounted) return;
    try {
      final response = await HttpClient.get('follow/status', params: {
        'userId': id,
        'followId': blogInfo.user?['_id'] ?? '', // 修改：使用笔记作者的 _i
      });
      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          isFollowing = response['data']['isFollowing'] ?? false;
        });
        print(isFollowing);
      }
    } catch (e) {
      print('获取关注信息失败: $e');
    }
  }

  Future<void> fetchHistory() async {
    if (!mounted) return;
    try {
      await HttpClient.get(NftApi.getCommentHistory(widget.id));
      if (!mounted) return; // Check mounted again after await
    } catch (e) {
      if (!mounted) return;
      // Handle error if needed
    }
  }

  String formatDateTime(String dateTimeString) {
    try {
      final DateTime dateTime = DateTime.parse(dateTimeString);
      final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');
      return formatter.format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  Future<void> fetchBlogDetail() async {
    if (!mounted) return;

    try {
      final response = await HttpClient.get(NftApi.getBlogDetail(widget.id));
      if (!mounted) return; // Check mounted again after await

      if (response['success'] != false) {
        setState(() {
          blogInfo = BlogInfo.fromJson(response['data'] ?? {});
        });
        getToken('token');
      }
    } catch (e) {
      if (!mounted) return;
      // Handle error if needed
    }
  }

  Future<void> fetchComments() async {
    if (!mounted) return;

    try {
      final response = await HttpClient.get(NftApi.getComments, params: {
        'blogId': widget.id,
      });
      if (!mounted) return; // Check mounted again after await

      if (response['success'] != false) {
        final List<dynamic> data = response['data']['comment'] ?? [];
        setState(() {
          comments = data.map((item) {
            final List<Comment> replies =
                (item['replies'] as List<dynamic>? ?? [])
                    .map((reply) => Comment(
                        id: reply['id'] ?? '', // 修改：直接获取评论 ID
                        author: reply['user']['username'] ?? '',
                        content: reply['content'] ?? '',
                        time: formatDateTime(reply['createdAt'] ?? ''),
                        avatar: reply['user']['avatar'] ?? '',
                        isReply: true,
                        toUserName: reply['toUserName'] ?? '',
                        likeCount: reply['likeCount'] ?? 0,
                        isLiked: reply['isLiked'], // 修改这行
                        parentId: reply['parentId'] ?? '',
                        user: reply['user'] ?? {}))
                    .toList();
            return Comment(
                id: item['id'] ?? '', // 修改：直接获取评论 ID
                author: item['user']['username'] ?? '',
                content: item['content'] ?? '',
                time: formatDateTime(item['createdAt'] ?? ''),
                avatar: item['user']['avatar'] ?? '',
                isReply: false,
                replies: replies,
                toUserName: item['toUserName'] ?? '',
                // ... 其他属性保持不变 ...
                likeCount: item['likeCount'] ?? 0,
                isLiked: item['isLiked'], // 修改这行
                parentId: item['parentId'] ?? '',
                user: item['user'] ?? {});
          }).toList();
        });
        // 如果需要，滚动到指定的评论位置（根据 commentId 推算父级）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.commentId.isNotEmpty && !_didScrollToComment) {
            final String? targetTopId = _findTopLevelIdFor(widget.commentId);
            if (targetTopId != null) {
              final key = _topCommentKeys[targetTopId];
              final contextForKey = key?.currentContext;
              if (contextForKey != null) {
                Scrollable.ensureVisible(
                  contextForKey,
                  duration: const Duration(milliseconds: 300),
                  alignment: 0.1,
                );
                _didScrollToComment = true;
              }
            }
          }
        });
        setState(() {
          _currentCommentId = null;
          _currentReplyTo = null;
          _replyToName = '';
        });
      }
    } catch (e) {
      if (!mounted) return;
      // Handle error if needed
    }
  }

  // 根据任意评论ID寻找其所属的顶层评论ID
  String? _findTopLevelIdFor(String commentId) {
    for (final top in comments) {
      if (top.id == commentId) return top.id;
      for (final reply in top.replies) {
        if (reply.id == commentId) return top.id;
      }
    }
    return null;
  }

  Future<void> _sendComment() async {
    if (_commentController.text.isEmpty) return;

    try {
      final response = await HttpClient.post(
        NftApi.createComment,
        body: {
          'blogId': widget.id,
          'content': _commentController.text,
        },
      );

      if (response['success'] == true) {
        _commentController.clear();
        // 重新获取评论列表
        fetchComments();
      }
    } catch (e) {
      // 错误处理
    }
  }

  Future<void> _replyComment(String commentId, String replyTo) async {
    if (_commentController.text.isEmpty) return;

    try {
      if (commentId.isEmpty) {
        return;
      }
      final response = await HttpClient.post(
        CommentApi.replyComment,
        body: {
          'blogId': widget.id,
          'commentId': commentId,
          'content': _commentController.text,
          'replyTo': replyTo,
        },
      );

      if (response['success'] == true) {
        _commentController.clear();
        fetchComments();
      }
    } catch (e) {
      print('Reply error: $e');
    }
  }

  // 添加焦点监听处理
  void _handleFocusChange() {
    setState(() {
      _showOverlay = _commentFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          // 在 AppBar 中修改返回按钮的处理

          backgroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/message');
                // context.go('/message');
              }
              // if (Navigator.canPop(context)) {
              //   // 添加检查
              //   Navigator.pop(context);
              // }
            },
          ),

          title: Row(
            children: [
              SvgPicture.network(
                "https://api.dicebear.com/9.x/big-ears/svg",
                height: 36,
                width: 36,
                placeholderBuilder: (BuildContext context) => const Icon(
                  Icons.person,
                  size: 36,
                  color: Color(0xFF1890FF),
                ),
              ),
              const SizedBox(width: 8), // 减小间距
              Expanded(
                child: Text(
                  blogInfo.createName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1, // 限制一行
                  overflow: TextOverflow.ellipsis, // 超出显示省略号
                ),
              ),
              const SizedBox(width: 8), // 减小间距
              if (blogInfo.user?['_id'] != userInfo['_id'])
                TextButton(
                  onPressed: () async {
                    print(isFollowing);
                    if (isFollowing == true) {
                      final result = await showModalActionSheet<int>(
                        context: context,
                        title: '取消关注',
                        message: '不再关注该作者？',
                        actions: [
                          SheetAction(
                            label: '不再关注',
                            key: 1,
                            isDestructiveAction: true,
                          ),
                        ],
                        cancelLabel: '取消',
                      );

                      if (result == 1) {
                        try {
                          final response = await HttpClient.post(
                            'follow/unfollow',
                            body: {'userId': blogInfo.user?['_id']},
                          );

                          if (response['success'] == true) {
                            if (mounted) {
                              fetchBlogDetail();
                            }
                          }
                        } catch (e) {
                          if (mounted) {}
                        }
                      }
                    } else {
                      try {
                        final response = await HttpClient.post(
                          'follow/follow',
                          body: {'userId': blogInfo.user?['_id']},
                        );

                        if (response['success'] == true) {
                          if (mounted) {
                            fetchBlogDetail(); // 重新获取笔记信息以更新关注状态
                          }
                        }
                      } catch (e) {
                        if (mounted) {}
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isFollowing
                          ? const BorderSide(
                              color: Color.fromARGB(59, 146, 138, 138))
                          : BorderSide.none,
                    ),
                    backgroundColor:
                        isFollowing ? const Color(0xFFFFFFFF) : null,
                  ),
                  child: Text(
                    isFollowing ? '已关注' : '关注',
                    style: TextStyle(
                      color:
                          isFollowing ? Colors.black : const Color(0xFFFFFFFF),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        body: Stack(children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80), // 添加底部 padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // 添加轮播图
                          if (blogInfo.images.isNotEmpty) ...[
                            CarouselSlider.builder(
                              itemCount: blogInfo.images.length,
                              itemBuilder: (context, index, realIndex) {
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(0),
                                    image: DecorationImage(
                                      image:
                                          NetworkImage(blogInfo.images[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                              options: CarouselOptions(
                                height: 400,
                                viewportFraction: 1.0,
                                autoPlay: false,
                                enlargeCenterPage: false,
                                autoPlayInterval: const Duration(seconds: 3),
                                autoPlayAnimationDuration:
                                    const Duration(milliseconds: 800),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      blogInfo.title,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  blogInfo.content,
                                  textAlign: TextAlign.left, // 添加这行
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.8,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (blogInfo.tags.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: blogInfo.tags
                                        .map((tag) => Text('#$tag',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            )))
                                        .toList(),
                                  ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Text(
                                      blogInfo.createdAt,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Divider(
                                  color: Color.fromARGB(68, 200, 207, 201),
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      '所有评论',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // 添加评论输入提示框
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    boxShadow: [
                                      BoxShadow(
                                        // ignore: deprecated_member_use
                                        color: Colors.black.withOpacity(0.05),
                                        offset: const Offset(0, -1),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      SvgPicture.network(
                                        "https://api.dicebear.com/9.x/big-ears/svg",
                                        height: 30,
                                        width: 30,
                                        placeholderBuilder:
                                            (BuildContext context) =>
                                                const Icon(Icons.person),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            if (_ignoreNextTap) {
                                              _ignoreNextTap = false;
                                              return;
                                            }
                                            setState(() {
                                              _replyToName = '';
                                              _currentCommentId = null;
                                              _currentReplyTo = null;
                                            });
                                            FocusScope.of(context).requestFocus(
                                                _commentFocusNode);
                                          },
                                          child: Container(
                                            height: 38,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: const Color(0xFFE8E8E8),
                                                width: 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            child: const Row(
                                              children: [
                                                Text(
                                                  '说点什么吧...',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // 修改 ListView.builder 中的调用
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return CommentItem(
                            comment: comments[index],
                            parentComment: null,
                            topKeyProvider: () {
                              final id = comments[index].id;
                              return _topCommentKeys[id] ??= GlobalKey();
                            },
                            onReply: (commentId, replyTo, replyToName) {
                              if (_ignoreNextTap) {
                                _ignoreNextTap = false;
                                return;
                              }
                              FocusScope.of(context)
                                  .requestFocus(_commentFocusNode);
                              setState(() {
                                _currentCommentId = commentId;
                                _currentReplyTo = replyTo;
                                _replyToName = replyToName; // 使用传入的用户名
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -1),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              // 添加遮罩层
            ],
          ),

          // 输入框固定在底部，始终保持在最顶层
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                if (_showOverlay)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _showOverlay = false;
                        _currentCommentId = null;
                        _currentReplyTo = null;
                        _replyToName = '';
                      });
                    },
                    child: Container(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.5),
                      height: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).viewInsets.bottom -
                          80,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, -1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocusNode, // 添加 focusNode
                          textInputAction: TextInputAction.send, // 添加这行
                          onSubmitted: (value) {
                            // 添加这行
                            if (_currentCommentId != null &&
                                _currentReplyTo != null) {
                              _replyComment(
                                  _currentCommentId!, _currentReplyTo!);
                            } else {
                              _sendComment();
                            }
                            setState(() {
                              _currentCommentId = null;
                              _currentReplyTo = null;
                              _replyToName = '';
                            });
                          },
                          decoration: InputDecoration(
                            hintText: _replyToName.isEmpty
                                ? '写点什么吧...'
                                : '回复 @$_replyToName',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 添加收藏按钮
                      AnimatedBuilder(
                        animation: _favoriteAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _favoriteAnimation.value,
                            child: IconButton(
                              padding: EdgeInsets.zero, // 移除默认内边距
                              iconSize: 30,
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                              ),
                              onPressed: toggleFavorite,
                            ),
                          );
                        },
                      ),
                      Text(
                        blogInfo.favoriteCount.toString(),
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 修改发送按钮的 onPressed 处理
                      TextButton(
                        onPressed: () {
                          if (_currentCommentId != null &&
                              _currentReplyTo != null) {
                            _replyComment(_currentCommentId!, _currentReplyTo!);
                          } else {
                            _sendComment();
                          }
                          // 隐藏键盘
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _currentCommentId = null;
                            _currentReplyTo = null;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          '发送',
                          style: TextStyle(
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]));
  }
}

// 添加 User 类定义
class Users {
  final Map<String, dynamic> data;

  Users({
    required this.data,
  });

  String? get name => data['name'];
  String? get avatar => data['avatar'];
}

class Comment {
  final String id; // 添加评论ID
  final String author;
  final String content;
  final String time;
  final String avatar;
  final bool isReply;
  final String toUserName;
  final Map<String, dynamic>? user; // 直接使用 Map
  final List<Comment> replies; // 添加子评论列表
  final int? likeCount; // 新增
  final bool isLiked; // 新增
  final String? parentId; // 新增

  Comment({
    required this.id, // 添加到构造函数
    required this.author,
    required this.content,
    required this.time,
    required this.avatar,
    this.toUserName = '',
    this.isReply = false,
    this.user,
    this.replies = const [], // 默认空列表
    this.likeCount, // 新增
    this.isLiked = false, // 新增
    this.parentId, // 新增
  });
}

// 修改 CommentItem 类的定义
class CommentItem extends StatelessWidget {
  final Comment comment;
  final Comment? parentComment;
  final Function(String, String, String)? onReply; // 修改回调函数类型，添加用户名参数
  final GlobalKey Function()? topKeyProvider;

  const CommentItem({
    super.key,
    required this.comment,
    this.parentComment,
    this.onReply,
    this.topKeyProvider,
  });
  // 修改 _handleLike 方法
  Future<void> _handleLike(BuildContext context) async {
    try {
      final response = await HttpClient.post(
        'comment/like',
        body: {'commentId': comment.id},
      );

      if (response['code'] == 200 || response['success'] == true) {
        // 修改这行
        if (context.mounted) {
          context
              .findAncestorStateOfType<_BlogDetailPageState>()
              ?.fetchComments();
        }
      }
    } catch (e) {
      print('Like error: $e');
    }
  }

  // 新增：展示自己的评论操作弹框 - 使用从底部弹出的Dialog
  Future<void> _showOwnCommentActions(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 顶部指示条
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 标题

                  const SizedBox(height: 20),
                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: TextButton.icon(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              try {
                                final result = await showOkCancelAlertDialog(
                                  context: context,
                                  title: '删除评论',
                                  message: '确定要删除这条评论吗？',
                                  okLabel: '删除',
                                  cancelLabel: '取消',
                                  isDestructiveAction: true,
                                );
                                if (result == OkCancelResult.ok) {
                                  final resp = await HttpClient.delete(
                                      'comment/${comment.id}');
                                  if ((resp is Map &&
                                      (resp['success'] == true ||
                                          resp['code'] == 200))) {
                                    final state =
                                        context.findAncestorStateOfType<
                                            _BlogDetailPageState>();
                                    state?.fetchComments();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('已删除评论')),
                                    );
                                  }
                                }
                              } catch (e) {}
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.delete_forever),
                            label: const Text(
                              '删除',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: TextButton.icon(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await Clipboard.setData(
                                  ClipboardData(text: comment.content));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('内容已复制')),
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.copy),
                            label: const Text(
                              '复制',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 取消按钮
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Colors.black54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    ).then((value) {
      // 弹框关闭后清除焦点
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyForTop = (parentComment == null && topKeyProvider != null)
        ? topKeyProvider!()
        : null;
    return Column(
      key: keyForTop,
      children: [
        InkWell(
          onTap: () {
            final state =
                context.findAncestorStateOfType<_BlogDetailPageState>();
            if (state != null && state._ignoreNextTap) {
              // 屏蔽长按后的首次点击，防止触发输入框
              state._ignoreNextTap = false;
              return;
            }
            if (onReply != null) {
              onReply!(
                comment.id,
                comment.user?['_id'] ?? '',
                comment.author, // 传递当前评论的作者名
              );
            }
          },
          onLongPress: () {
            final state =
                context.findAncestorStateOfType<_BlogDetailPageState>();
            // 长按后先屏蔽下一次点击
            state?._ignoreNextTap = true;
            // 移除：长按时不再立即清除输入焦点，改为在弹框关闭后清除
            final isOwn = state != null &&
                (state.userInfo['_id'] != null) &&
                (state.userInfo['_id'] == comment.user?['_id']);
            if (isOwn) {
              _showOwnCommentActions(context).whenComplete(() {
                // 弹框关闭时清除焦点，避免输入框弹出
                FocusScope.of(context).unfocus();
                final s =
                    context.findAncestorStateOfType<_BlogDetailPageState>();
                if (s != null) {
                  s._ignoreNextTap = false; // 弹框关闭后恢复点击
                }
              });
            } else {
              // 非本人评论：保持 _ignoreNextTap 为 true，直到下一次 onTap 被消费后再自动重置
              // 在 onTap 中会检测并重置为 false
            }
          },
          child: Padding(
            // 将 Container 改为 Padding 以优化点击响应
            padding: EdgeInsets.only(
                left: comment.isReply ? 56 : 16,
                right: 6,
                top: comment.isReply ? 10 : 16, // 增加上下内边距
                bottom: comment.isReply ? 10 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.network(
                  comment.avatar,
                  height: comment.isReply ? 30 : 38, // 根据是否为回复设置不同高度
                  width: comment.isReply ? 30 : 38, // 根据是否为回复设置不同宽度
                  placeholderBuilder: (BuildContext context) => Icon(
                    Icons.person,
                    size: comment.isReply ? 30 : 38, // 占位图标也相应调整大小
                    color: const Color(0xFF1890FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start, //
                        children: [
                          Text(
                            comment.author,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            comment.time,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 40,
                            height: 35,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment:
                                  MainAxisAlignment.start, // 添加这行
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 0), // 添加顶部内边距，让心形向下移动
                                  child: GestureDetector(
                                    onTap: () => _handleLike(context),
                                    child: Icon(
                                      comment.isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 18,
                                      color: comment.isLiked
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                                if (comment.likeCount != null &&
                                    comment.likeCount! > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0),
                                    child: Text(
                                      '${comment.likeCount}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      //如果在第一层
                      if (comment.parentId == '')
                        Row(
                          children: [
                            Text(
                              comment.content ?? '',
                              style: const TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // &&
                          //     comment.toUserName !=
                          //         parentComment?.user?['name']
                          if (comment.toUserName.isNotEmpty) ...[
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    if (comment.toUserName != comment.author)
                                      TextSpan(
                                        text: '回复 ${comment.toUserName}: ',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    TextSpan(
                                      text: comment.content,
                                      style: const TextStyle(
                                        color: Color(0xFF333333),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          // Expanded(
                          //   child: Text(
                          //     ,
                          //     style: const TextStyle(fontSize: 14),
                          //   ),
                          // ),
                        ],
                      ),
                      // const SizedBox(height: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (comment.replies.isNotEmpty) ...[
          ...comment.replies.map(
            (reply) => CommentItem(
              comment: reply,
              parentComment: comment,
              onReply: onReply,
            ),
          ),
        ],
      ],
    );
  }
}
