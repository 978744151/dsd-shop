import 'package:flutter/material.dart';
import '../models/spring_festival_stats.dart';
import '../utils/http_client.dart';
import '../utils/screenshot_util.dart';

class SpringFestivalStatsPage extends StatefulWidget {
  const SpringFestivalStatsPage({Key? key}) : super(key: key);

  @override
  State<SpringFestivalStatsPage> createState() => _SpringFestivalStatsPageState();
}

class _SpringFestivalStatsPageState extends State<SpringFestivalStatsPage> {
  List<SpringFestivalStats> statsList = [];
  bool isLoading = true;
  int currentPage = 1;
  int totalPages = 1;
  bool hasMore = true;
  bool isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({bool loadMore = false}) async {
    if (loadMore) {
      if (!hasMore || isLoadingMore) return;
      setState(() {
        isLoadingMore = true;
      });
    } else {
      setState(() {
        isLoading = true;
        currentPage = 1;
      });
    }

    try {
      final response = await HttpClient.get(
        'spring-festival-stats',
        params: {
          'page': loadMore ? currentPage + 1 : 1,
          'limit': 20,
        },
      );

      if (!mounted) return;

      if (response['success']) {
        final List<dynamic> data = response['data']['items'] ?? [];
        final pagination = response['data']['pagination'] ?? {};
        
        final newStats = data.map((item) => SpringFestivalStats.fromJson(item)).toList();
        
        // 按电影票房消费降序排序
        newStats.sort((a, b) => b.movieBoxOffice.compareTo(a.movieBoxOffice));

        setState(() {
          if (loadMore) {
            statsList.addAll(newStats);
            currentPage++;
          } else {
            statsList = newStats;
            currentPage = 1;
          }
          
          totalPages = pagination['pages'] ?? 1;
          hasMore = currentPage < totalPages;
          isLoading = false;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e')),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _fetchData(loadMore: true);
    }
  }

  Future<void> _generateTableImage() async {
    if (statsList.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无数据，无法生成图片')),
      );
      return;
    }

    await ScreenshotUtil.captureAndShowImage(
      context: context,
      errorMessage: '表格图片生成失败，请重试',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '春节经济数据',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () => _generateTableImage(),
            tooltip: '生成表格图片',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _fetchData(),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    // 顶部说明卡片
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.celebration,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '春节消费数据',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '全国各城市春节期间经济统计',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 数据表格
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          child: Column(
                            children: [
                              // 表头
                              _buildTableHeader(),
                              
                              // 数据行
                              ...statsList.asMap().entries.map((entry) {
                                final index = entry.key;
                                final stats = entry.value;
                                return _buildTableRow(
                                  stats,
                                  isEven: index % 2 == 0,
                                );
                              }).toList(),

                              // 底部提示
                              Container(
                                width: 800,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFfff),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                   const Text(
                                      '搜索 商业星球 查看更多商业内容',
                                      style:  TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 加载更多指示器
                              if (isLoadingMore)
                                const SizedBox(
                                  width: 800,
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                                ),
                              
                              // 没有更多数据提示
                              // if (!hasMore && statsList.isNotEmpty)
                                // SizedBox(
                                //   width: 800,
                                //   child: Padding(
                                //     padding: const EdgeInsets.all(16),
                                //     child: Center(
                                //       child: Text(
                                //         '已加载全部数据',
                                //         style: TextStyle(
                                //           color: Colors.grey[400],
                                //           fontSize: 12,
                                //         ),
                                //       ),
                                //     ),
                                //   ),
                                // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      width: 800,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('城市', width: 80),
          _buildHeaderCell('接待游客(万)', width: 96),
          _buildHeaderCell('游客增长率(%)', width: 96),
          _buildHeaderCell('旅游总收入(亿)', width: 96),
          _buildHeaderCell('消费增长率(%)', width: 96),
          // _buildHeaderCell('餐联商务数据(亿)', width: 96),
          _buildHeaderCell('商企消费(亿)', width: 96),
          _buildHeaderCell('电影票房(万)', width: 96),
          _buildHeaderCell('数据来源', width: 50),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required double width}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF666666),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(SpringFestivalStats stats, {required bool isEven}) {
    return InkWell(
      onTap: () => _showNotesDialog(stats),
      child: Container(
        width: 800,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isEven ? Colors.white : const Color(0xFFFAFAFA),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildDataCell(stats.city.name, width: 80, isBold: true),
            _buildDataCell(_formatNumber(stats.touristVolume), width: 96),
            _buildDataCell(_formatPercentage(stats.totalVisitorsGrowthRate), width: 96),
            _buildDataCell(_formatCurrency(stats.tourismRevenue), width: 96),
            // _buildDataCell(_formatPercentage(stats.visitorConsumptionGrowthRate), width: 96),
            _buildDataCell(_formatCurrency(stats.cateringRevenue), width: 96),
            _buildDataCell(_formatCurrency(stats.businessConsumption), width: 96),
            _buildDataCell(_formatCurrency(stats.movieBoxOffice), width: 96),
            _buildDataCell(stats.dataSource, width: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {required double width, bool isBold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          color: isBold ? const Color(0xFF333333) : const Color(0xFF666666),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == 0) return '0';
    return value.toStringAsFixed(2);
  }

  String _formatCurrency(double value) {
    if (value == 0) return '¥0';
    return '¥${value.toStringAsFixed(value >= 100 ? 0 : 2)}';
  }

  String _formatPercentage(double value) {
    if (value == 0) return '0%';
    return '${value.toStringAsFixed(2)}%';
  }

  void _showNotesDialog(SpringFestivalStats stats) {
    if (stats.notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无备注信息')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFfff),
        title: Row(
          children: [
            const Icon(Icons.note_alt, color: Color(0xFFFF6B6B)),
            const SizedBox(width: 8),
            Text('${stats.city.name} - 备注'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            stats.notes,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF333333),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
