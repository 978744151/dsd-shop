import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/blog.dart';
import '../utils/http_client.dart';
import '../widgets/red_book_card.dart';
import '../widgets/custom_refresh_widget.dart';
import '../widgets/loading_indicator_widget.dart';

class TabContentWidget extends StatefulWidget {
  final String tabName;
  final String endpoint;

  const TabContentWidget({
    Key? key,
    required this.tabName,
    required this.endpoint,
  }) : super(key: key);

  @override
  State<TabContentWidget> createState() => _TabContentWidgetState();
}

class _TabContentWidgetState extends State<TabContentWidget>
    with AutomaticKeepAliveClientMixin {
  List<Blog> _blogs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchBlogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _fetchBlogs() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await HttpClient.get('${widget.endpoint}&page=1');

      if (!mounted) return;
      if (response['success']) {
        final List<dynamic> blogsData = response['data']['blogs'] ?? [];
        setState(() {
          _blogs = blogsData.map((item) => Blog.fromJson(item)).toList();
          _hasMore = response['data']['pagination']['page'] <
              response['data']['pagination']['pages'];
          _currentPage = 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (!mounted || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response =
          await HttpClient.get('${widget.endpoint}&page=$nextPage');

      if (!mounted) return;
      if (response['success']) {
        final List<dynamic> blogsData = response['data']['blogs'] ?? [];
        setState(() {
          _blogs.addAll(blogsData.map((item) => Blog.fromJson(item)));
          _hasMore = response['data']['pagination']['page'] <
              response['data']['pagination']['pages'];
          _currentPage = nextPage;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
      _blogs.clear();
    });
    await _fetchBlogs();
  }

  String _getEmptyStateText() {
    switch (widget.tabName) {
      case '关注':
        return '暂无关注的内容\n快去关注一些有趣的用户吧！';
      case '最新':
        return '暂无最新内容';
      default:
        return '暂无推荐内容';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const LoadingIndicatorWidget();
    }

    return CustomRefreshWidget(
      onRefresh: _refresh,
      child: _blogs.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Text(
                      _getEmptyStateText(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8C8C8C),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(8.0),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    itemBuilder: (context, index) {
                      if (index < _blogs.length) {
                        final blog = _blogs[index];
                        final randomHeight = 200.0 + (index % 3) * 50.0;
                        return RedBookCard(
                          key: ValueKey('${widget.tabName}_${blog.id}'),
                          id: blog.id,
                          title: blog.title,
                          content: blog.content,
                          defaultImage: blog.defaultImage,
                          name: blog.createName,
                          time: blog.createdAt,
                          type: blog.type,
                          likes: 0,
                          comments: 0,
                          avatar: '',
                          user: blog.user,
                          height: randomHeight,
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                    childCount: _blogs.length,
                  ),
                ),
                if (_isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
