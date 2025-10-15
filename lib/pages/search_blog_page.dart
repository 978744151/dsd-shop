import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../utils/http_client.dart';
import '../widgets/loading_indicator_widget.dart';
import '../widgets/custom_refresh_widget.dart';
import '../widgets/red_book_card.dart';
import 'dart:math';

class Blog {
  final String id;
  final String title;
  final String content;
  final String createName;
  final String createdAt;
  final String type;
  final String defaultImage;
  final Map<String, dynamic>? user;
  final int favoriteCount;

  Blog({
    required this.id,
    required this.title,
    required this.content,
    required this.createName,
    required this.createdAt,
    required this.type,
    this.favoriteCount = 0,
    required this.defaultImage,
    this.user,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createName: json['createName'] ?? '',
      createdAt: json['createdAt'] ?? '',
      type: json['type'] ?? '',
      defaultImage: json['defaultImage'] ?? '',
      favoriteCount: json['favoriteCount'] ?? 0,
      user: json['user'],
    );
  }
}

class SearchBlogPage extends StatefulWidget {
  const SearchBlogPage({Key? key}) : super(key: key);

  @override
  State<SearchBlogPage> createState() => _SearchBlogPageState();
}

class _SearchBlogPageState extends State<SearchBlogPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Blog> searchResults = [];
  bool isLoading = false;
  bool isSearching = false;
  bool hasMore = true;
  int page = 1;
  String currentQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 页面加载完成后自动聚焦到搜索输入框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        hasMore &&
        currentQuery.isNotEmpty) {
      _loadMoreResults();
    }
  }

  Future<void> _searchBlogs(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        searchResults.clear();
        currentQuery = '';
        hasMore = true;
        page = 1;
      });
      return;
    }

    setState(() {
      isSearching = true;
      isLoading = true;
      searchResults.clear();
      currentQuery = query;
      page = 1;
      hasMore = true;
    });

    try {
      final response = await HttpClient.get('blogs/all', params: {
        'search': query,
        'page': page.toString(),
        'limit': '20',
      });

      if (response['success'] == true) {
        final List<dynamic> blogData = response['data']['blogs'] ?? [];
        final List<Blog> blogs =
            blogData.map((json) => Blog.fromJson(json)).toList();

        setState(() {
          searchResults = blogs;
          hasMore = blogs.length >= 20;
          isLoading = false;
          isSearching = false;
        });
      } else {
        setState(() {
          searchResults = [];
          hasMore = false;
          isLoading = false;
          isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        searchResults = [];
        hasMore = false;
        isLoading = false;
        isSearching = false;
      });
    }
  }

  Future<void> _loadMoreResults() async {
    if (isLoading || !hasMore || currentQuery.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await HttpClient.get('/api/blogs/search', params: {
        'q': currentQuery,
        'page': (page + 1).toString(),
        'limit': '20',
      });

      if (response['success'] == true) {
        final List<dynamic> blogData = response['data'] ?? [];
        final List<Blog> newBlogs =
            blogData.map((json) => Blog.fromJson(json)).toList();

        setState(() {
          searchResults.addAll(newBlogs);
          page++;
          hasMore = newBlogs.length >= 20;
          isLoading = false;
        });
      } else {
        setState(() {
          hasMore = false;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasMore = false;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9f9f9),
        body: Column(
          children: [
            // 自定义AppBar
            Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: const BoxDecoration(
                color: Color(0xFFffffff),
              ),
              child: Container(
                height: kToolbarHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // 返回按钮
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFF333333)),
                      onPressed: () => context.pop(),
                    ),
                    // 搜索框
                    Expanded(
                      child: Container(
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: const InputDecoration(
                            hintText: '搜索笔记...',
                            hintStyle: TextStyle(
                              color: Color(0xFF8C8C8C),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Color(0xFF8C8C8C),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 0),
                          ),
                          onSubmitted: _searchBlogs,
                          textInputAction: TextInputAction.search,
                        ),
                      ),
                    ),
                    // 搜索按钮
                    TextButton(
                      onPressed: () => _searchBlogs(_searchController.text),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        overlayColor: Colors.transparent,
                      ),
                      child: const Text(
                        '搜索',
                        style: TextStyle(
                          color: Color(0xFF000000),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 搜索结果内容
            Expanded(
              child: _buildSearchContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchContent() {
    if (currentQuery.isEmpty) {
      return _buildEmptyState('输入关键词搜索笔记', Icons.search);
    }

    if (isSearching) {
      return const LoadingIndicatorWidget();
    }

    if (searchResults.isEmpty && !isLoading) {
      return _buildEmptyState('没有找到相关笔记', Icons.search_off);
    }

    return CustomRefreshWidget(
      onRefresh: () async {
        await _searchBlogs(currentQuery);
      },
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                children: [
                  // 搜索结果提示
                  if (searchResults.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '找到 ${searchResults.length} 个相关结果',
                        style: const TextStyle(
                          color: Color(0xFF8C8C8C),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  // 搜索结果网格
                  MasonryGridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final blog = searchResults[index];
                      final randomHeight = 200.0 + (Random().nextInt(100));

                      return RedBookCard(
                        avatar: blog.user?['avatar'] ?? '',
                        name: blog.user?['username'] ?? blog.createName,
                        title: blog.title,
                        content: blog.content,
                        time: blog.createdAt,
                        type: blog.type,
                        defaultImage: blog.defaultImage,
                        likes: blog.favoriteCount,
                        comments: 0,
                        height: randomHeight,
                        id: blog.id,
                        user: blog.user,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // 加载更多指示器
          SliverToBoxAdapter(
            child: SizedBox(
              height: isLoading ? 56 : 0,
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: const Color(0xFFE0E0E0),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
