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
import 'package:fluttertoast/fluttertoast.dart'; // 替换为fluttertoast导入

class BlogDetailPage extends StatefulWidget {
  final String id; // 添加 id 参数
  final String commentId;
  const BlogDetailPage({
    super.key,
    required this.id,
    this.commentId = '',
  });

  @override
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
  Offset _startPosition = Offset.zero; // 添加滑动开始位置变量
  bool _isNavigating = false; // 添加导航状态标志，防止重复触发
  int _currentImageIndex = 0; // 添加当前图片索引变量
  Set<String> _dislikedWords = {}; // 新增：不喜欢词集合

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
    _loadDislikedWords(); // 加载不喜欢词
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
  // 新增：不喜欢词工具方法
  Future<void> _loadDislikedWords() async {
    try {
      final Map<String, dynamic>? data =
          await Storage.getJson('disliked_words');
      final List<dynamic> words = (data != null ? (data['words'] ?? []) : []);
      setState(() {
        _dislikedWords = words.map((e) => e.toString()).toSet();
      });
    } catch (e) {}
  }

  Future<void> _saveDislikedWords() async {
    try {
      await Storage.setJson('disliked_words', {
        'words': _dislikedWords.toList(),
      });
    } catch (e) {}
  }

  String _maskDislikedWords(String text) {
    var result = text;
    for (final w in _dislikedWords) {
      if (w.trim().isEmpty) continue;
      final pattern = RegExp(RegExp.escape(w), caseSensitive: false);
      result = result.replaceAll(pattern, '***');
    }
    return result;
  }

  Future<void> _showDislikeBottomSheet(BuildContext context,
      {String? initialText}) async {
    final TextEditingController controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) {
        return Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(bCtx).viewInsets.bottom),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  '不喜欢的词',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '输入你想隐藏的词或短语，多个用空格分隔',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: (initialText == null || initialText.isEmpty)
                        ? '例如：广告 违禁词'
                        : '从评论中挑选要隐藏的词：${initialText.length > 24 ? initialText.substring(0, 24) + '...' : initialText}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  minLines: 1,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(bCtx).pop();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.black54,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('取消'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextButton(
                          onPressed: () async {
                            final input = controller.text.trim();
                            if (input.isEmpty) {
                              Fluttertoast.showToast(msg: '请输入要隐藏的词');
                              return;
                            }
                            final added = input
                                .split(RegExp(r"[\\s,]+"))
                                .where((e) => e.trim().isNotEmpty)
                                .map((e) => e.trim());
                            setState(() {
                              _dislikedWords.addAll(added);
                            });
                            await _saveDislikedWords();
                            Fluttertoast.showToast(msg: '已更新不喜欢词');
                            if (Navigator.of(bCtx).canPop()) {
                              Navigator.of(bCtx).pop();
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('确定隐藏'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
                        time: _timeAgo(reply['createdAt'] ?? ''),
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
                time: _timeAgo(item['createdAt'] ?? ''),
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

  String _timeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return dateString;
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
    // 如果正在忽略下一次点击，不要显示输入框
    if (_ignoreNextTap) {
      return;
    }
    setState(() {
      _showOverlay = _commentFocusNode.hasFocus;
    });
  }

  // 显示全屏图片查看器
  void _showFullScreenImage(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenImageViewer(
            images: blogInfo.images,
            initialIndex: initialIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  // 提交举报
  Future<void> _submitBlogReport(BuildContext context, String reportTypeId,
      {String targetType = 'blog'}) async {
    try {
      final response = await HttpClient.post(
        'report',
        body: {
          'targetId': widget.id,
          'targetType': targetType,
          'reasonType': reportTypeId,
        },
      );

      if (response['code'] == 200 || response['success'] == true) {
        Fluttertoast.showToast(msg: '举报已提交，感谢您的反馈');
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? '举报失败');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '举报失败，请稍后重试');
    }
  }

  // 博客举报对话框
  Future<void> _showBlogReportDialog(BuildContext context) async {
    try {
      // 获取举报类型列表
      final response = await HttpClient.get('report/types');
      if (response['code'] != 200 && response['success'] != true) {
        Fluttertoast.showToast(msg: '获取举报类型失败');
        return;
      }

      final List<dynamic> reportTypes = response['data']['reasonTypes'] ?? [];
      if (reportTypes.isEmpty) {
        Fluttertoast.showToast(msg: '暂无举报类型');
        return;
      }

      String? selectedType;
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 顶部指示条
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // 标题
                        const Text(
                          '举报评论',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '请选择举报原因：',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 举报选项列表
                        ...reportTypes.map((type) {
                          final typeId = type['key'];
                          final typeName = type['label'] ?? '未知类型';
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedType = typeId;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedType == typeId
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.grey[50],
                                  border: Border.all(
                                    color: selectedType == typeId
                                        ? Colors.red
                                        : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selectedType == typeId
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: selectedType == typeId
                                          ? Colors.red
                                          : Colors.grey[400],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        typeName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: selectedType == typeId
                                              ? Colors.red
                                              : Colors.black87,
                                          fontWeight: selectedType == typeId
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 20),
                        // 操作按钮
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: TextButton(
                                  onPressed: selectedType == null
                                      ? null
                                      : () async {
                                          Navigator.of(ctx).pop();
                                          await _submitBlogReport(
                                            context,
                                            selectedType!,
                                            targetType: 'blog',
                                          );
                                        },
                                  style: TextButton.styleFrom(
                                    backgroundColor: selectedType == null
                                        ? Colors.grey[300]
                                        : Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    '提交举报',
                                    style: TextStyle(
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
                ),
              );
            },
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
      );
    } catch (e) {
      Fluttertoast.showToast(msg: '获取举报类型失败');
    }
  }

  // 分享和举报对话框 - 使用_showCommentActions的样式
  Future<void> _showShareAndReportDialog(BuildContext context) async {
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
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
                              await Clipboard.setData(ClipboardData(
                                  text:
                                      'https://example.com/blog/${widget.id}'));
                              Fluttertoast.showToast(msg: '链接已复制');
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.share),
                            label: const Text(
                              '分享链接',
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
                              _showBlogReportDialog(context);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.report),
                            label: const Text(
                              '举报',
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
                              await showModalBottomSheet<void>(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (bCtx) {
                                  return Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20),
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
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Center(
                                              child: Container(
                                                width: 40,
                                                height: 4,
                                                margin: const EdgeInsets.only(bottom: 16),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                            ),
                                            const Text(
                                              '确认拉黑',
                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              '拉黑后对方将无法和你互动，是否确认？',
                                              style: TextStyle(fontSize: 14, color: Colors.grey),
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: SizedBox(
                                                    height: 44,
                                                    child: TextButton(
                                                      onPressed: () => Navigator.of(bCtx).pop(),
                                                      style: TextButton.styleFrom(
                                                        backgroundColor: Colors.grey[100],
                                                        foregroundColor: Colors.black54,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                      ),
                                                      child: const Text('取消'),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: SizedBox(
                                                    height: 44,
                                                    child: TextButton(
                                                      onPressed: () async {
                                                        try {
                                                          final resp = await HttpClient.post('user/block', body: {
                                                            'userId': blogInfo?.user?['_id'],
                                                          });
                                                          if ((resp is Map && (resp['success'] == true || resp['code'] == 200))) {
                                                            Fluttertoast.showToast(msg: '已拉黑该用户');
                                                          } else {
                                                            Fluttertoast.showToast(msg: '拉黑失败，请稍后重试');
                                                          }
                                                        } catch (e) {
                                                          Fluttertoast.showToast(msg: '拉黑失败，请稍后重试');
                                                        } finally {
                                                          if (Navigator.of(bCtx).canPop()) {
                                                            Navigator.of(bCtx).pop();
                                                          }
                                                        }
                                                      },
                                                      style: TextButton.styleFrom(
                                                        backgroundColor: Colors.orange,
                                                        foregroundColor: Colors.white,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                      ),
                                                      child: const Text('确认拉黑'),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.block),
                            label: const Text(
                              '拉黑',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            border: Border(
              bottom: BorderSide(
                color: Colors.transparent,
                width: 0,
              ),
            ),
          ),
          child: SafeArea(
            child: Container(
              height: kToolbarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  // 返回按钮
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/message');
                      }
                    },
                  ),
                  // 用户信息区域
                  Expanded(
                    child: Row(
                      children: [
                        SvgPicture.network(
                          "https://api.dicebear.com/9.x/big-ears/svg",
                          height: 36,
                          width: 36,
                          placeholderBuilder: (BuildContext context) =>
                              const Icon(
                            Icons.person,
                            size: 36,
                            color: Color(0xFF1890FF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            blogInfo.createName,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 关注按钮
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
                                      fetchBlogDetail();
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
                                        color:
                                            Color.fromARGB(59, 146, 138, 138))
                                    : BorderSide.none,
                              ),
                              backgroundColor:
                                  isFollowing ? const Color(0xFFFFFFFF) : null,
                            ),
                            child: Text(
                              isFollowing ? '已关注' : '关注',
                              style: TextStyle(
                                color: isFollowing
                                    ? Colors.black
                                    : const Color(0xFFFFFFFF),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 分享按钮
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.black),
                    onPressed: () {
                      _showShareAndReportDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onHorizontalDragStart: (details) {
          // 记录滑动开始位置
          _startPosition = details.globalPosition;
          _isNavigating = false; // 重置导航状态
        },
        onHorizontalDragUpdate: (details) {
          // 如果已经在导航中，直接返回
          if (_isNavigating) return;

          // 计算滑动距离
          final delta = details.globalPosition - _startPosition;

          // 检测从左边缘开始的右滑手势
          if (_startPosition.dx < 50 && delta.dx > 100) {
            _isNavigating = true; // 设置导航状态
            // 触发返回
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/message');
            }
          }
        },
        child: Stack(children: [
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
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    _showFullScreenImage(
                                        context, _currentImageIndex);
                                  },
                                  child: CarouselSlider.builder(
                                    itemCount: blogInfo.images.length,
                                    itemBuilder: (context, index, realIndex) {
                                      return Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(0),
                                          image: DecorationImage(
                                            image: NetworkImage(
                                                blogInfo.images[index]),
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
                                      autoPlayInterval:
                                          const Duration(seconds: 3),
                                      autoPlayAnimationDuration:
                                          const Duration(milliseconds: 800),
                                      onPageChanged: (index, reason) {
                                        setState(() {
                                          _currentImageIndex = index;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                // 图片数量指示器
                                if (blogInfo.images.length > 1)
                                  Positioned(
                                    bottom: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_currentImageIndex + 1}/${blogInfo.images.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
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
                            blogId: widget.id, // 传递博客id
                            topKeyProvider: () {
                              final id = comments[index].id;
                              return _topCommentKeys[id] ??= GlobalKey();
                            },
                            onReply: (commentId, replyTo, replyToName) {
                              final state = context.findAncestorStateOfType<
                                  _BlogDetailPageState>();
                              if (state != null && state._ignoreNextTap) {
                                // 长按期间不处理回复，直接返回
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
                          autofocus: false, // 禁止自动获取焦点
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
        ]),
      ),
    );
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
  final String blogId; // 添加博客id参数

  const CommentItem({
    super.key,
    required this.comment,
    this.parentComment,
    this.onReply,
    this.topKeyProvider,
    required this.blogId, // 添加必需的博客id参数
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

  // 统一的评论操作弹框 - 使用showGeneralDialog
  Future<void> _showCommentActions(BuildContext context, bool isOwn) async {
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
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
                              await Clipboard.setData(
                                  ClipboardData(text: comment.content));
                              Fluttertoast.showToast(msg: '内容已复制');
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
                      const SizedBox(width: 12),
                      if (isOwn)
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: TextButton.icon(
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                await showModalBottomSheet<void>(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (bCtx) {
                                    return Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 20,
                                                offset: const Offset(0, -8),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Center(
                                                child: Container(
                                                  width: 40,
                                                  height: 4,
                                                  margin: const EdgeInsets.only(
                                                      bottom: 16),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[300],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            2),
                                                  ),
                                                ),
                                              ),
                                              const Text(
                                                '确认删除',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                '删除后不可恢复，确定要删除这条评论吗？',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: SizedBox(
                                                      height: 44,
                                                      child: TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(bCtx)
                                                                .pop(),
                                                        style: TextButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.grey[100],
                                                          foregroundColor:
                                                              Colors.black54,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                        ),
                                                        child: const Text('取消'),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: SizedBox(
                                                      height: 44,
                                                      child: TextButton(
                                                        onPressed: () async {
                                                          try {
                                                            final resp =
                                                                await HttpClient
                                                                    .delete(
                                                                        'comment/delete/${comment.id}');
                                                            if ((resp is Map &&
                                                                (resp['success'] ==
                                                                        true ||
                                                                    resp['code'] ==
                                                                        200))) {
                                                              final state = context
                                                                  .findAncestorStateOfType<
                                                                      _BlogDetailPageState>();
                                                              state
                                                                  ?.fetchComments();
                                                              Fluttertoast
                                                                  .showToast(
                                                                      msg:
                                                                          '已删除评论');
                                                            } else {
                                                              Fluttertoast
                                                                  .showToast(
                                                                      msg:
                                                                          '删除失败，请稍后重试');
                                                            }
                                                          } catch (e) {
                                                            Fluttertoast.showToast(
                                                                msg:
                                                                    '删除失败，请稍后重试');
                                                          } finally {
                                                            if (Navigator.of(
                                                                    bCtx)
                                                                .canPop()) {
                                                              Navigator.of(bCtx)
                                                                  .pop();
                                                            }
                                                          }
                                                        },
                                                        style: TextButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          foregroundColor:
                                                              Colors.white,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                        ),
                                                        child: const Text('删除'),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
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
                        )
                      else ...[
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: TextButton.icon(
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                final st = context.findAncestorStateOfType<
                                    _BlogDetailPageState>();
                                if (st != null) {
                                  await st._showDislikeBottomSheet(context,
                                      initialText: comment.content ?? '');
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.visibility_off),
                              label: const Text(
                                '不喜欢',
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
                                _showReportDialog(context);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.report),
                              label: const Text(
                                '举报',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ]
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
    );
  }

  // 举报对话框
  // 举报对话框 - 使用showGeneralDialog
  Future<void> _showReportDialog(BuildContext context) async {
    try {
      // 获取举报类型列表
      final response = await HttpClient.get('report/types');
      if (response['code'] != 200 && response['success'] != true) {
        Fluttertoast.showToast(msg: '获取举报类型失败');
        return;
      }

      final List<dynamic> reportTypes = response['data']['reasonTypes'] ?? [];
      if (reportTypes.isEmpty) {
        Fluttertoast.showToast(msg: '暂无举报类型');
        return;
      }

      String? selectedType;
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 顶部指示条
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // 标题
                        const Text(
                          '举报评论',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '请选择举报原因：',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 举报选项列表
                        ...reportTypes.map((type) {
                          final typeId = type['key'];
                          final typeName = type['label'] ?? '未知类型';
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedType = typeId;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedType == typeId
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.grey[50],
                                  border: Border.all(
                                    color: selectedType == typeId
                                        ? Colors.red
                                        : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selectedType == typeId
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: selectedType == typeId
                                          ? Colors.red
                                          : Colors.grey[400],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        typeName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: selectedType == typeId
                                              ? Colors.red
                                              : Colors.black87,
                                          fontWeight: selectedType == typeId
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 20),
                        // 操作按钮
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: TextButton(
                                  onPressed: selectedType == null
                                      ? null
                                      : () async {
                                          Navigator.of(ctx).pop();
                                          await _submitReport(
                                            context,
                                            selectedType!,
                                            targetType: 'comment',
                                            blogId:
                                                blogId, // 使用CommentItem的blogId属性
                                          );
                                        },
                                  style: TextButton.styleFrom(
                                    backgroundColor: selectedType == null
                                        ? Colors.grey[300]
                                        : Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    '提交举报',
                                    style: TextStyle(
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
                ),
              );
            },
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
      );
    } catch (e) {
      Fluttertoast.showToast(msg: '获取举报类型失败');
    }
  }

  // 提交举报
  Future<void> _submitReport(BuildContext context, String reportTypeId,
      {String targetType = 'comment', String? blogId}) async {
    print('提交举报${comment}');
    try {
      final response = await HttpClient.post(
        'report',
        body: {
          'targetId': comment.id,
          'targetType': targetType,
          'reasonType': reportTypeId,
          'blogId': blogId,
        },
      );

      if (response['code'] == 200 || response['success'] == true) {
        Fluttertoast.showToast(msg: '举报已提交，感谢您的反馈');
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? '举报失败');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '举报失败，请稍后重试');
    }
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

            // 立即清除焦点，防止弹框期间输入框获得焦点
            FocusScope.of(context).unfocus();

            final isOwn = state != null &&
                (state.userInfo['_id'] != null) &&
                (state.userInfo['_id'] == comment.user?['_id']);
            if (isOwn) {
              _showCommentActions(context, true).whenComplete(() {
                final s =
                    context.findAncestorStateOfType<_BlogDetailPageState>();
                if (s != null) {
                  s._ignoreNextTap = false; // 弹框关闭后恢复点击
                  // 确保弹框关闭后焦点被完全清除
                  FocusScope.of(context).unfocus();
                }
              });
            } else {
              // 非本人评论：显示复制和举报选项
              _showCommentActions(context, false).whenComplete(() {
                final s =
                    context.findAncestorStateOfType<_BlogDetailPageState>();
                if (s != null) {
                  s._ignoreNextTap = false; // 弹框关闭后恢复点击
                  // 确保弹框关闭后焦点被完全清除
                  FocusScope.of(context).unfocus();
                }
              });
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
                        ],
                      ),
                      const SizedBox(height: 6),

                      //如果在第一层
                      if (comment.parentId == '')
                        Row(
                          children: [
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: (context
                                              .findAncestorStateOfType<
                                                  _BlogDetailPageState>()
                                              ?._maskDislikedWords(
                                                  comment.content ?? '') ??
                                          (comment.content ?? '')),
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
                            const SizedBox(width: 10),
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
                                          fontSize: 13,
                                        ),
                                      ),
                                    TextSpan(
                                      text: (context.findAncestorStateOfType<_BlogDetailPageState>()?._maskDislikedWords(comment.content ?? '') ?? (comment.content ?? '')),
                                      style: const TextStyle(
                                        color: Color(0xFF333333),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          // Expanded(
                          //   child: Text(
                          //     ,
                          //     style: const TextStyle(fontSize: 14),
                          //   ),
                          // ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start, //
                        children: [
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
                            height: 25,
                            child: Row(
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
                      )
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
              blogId: blogId, // 传递博客id
              onReply: onReply,
            ),
          ),
        ],
      ],
    );
  }
}

// 全屏图片查看器组件
class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 图片查看器
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 50,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          // 顶部关闭按钮和图片计数
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  if (widget.images.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentIndex + 1}/${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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
