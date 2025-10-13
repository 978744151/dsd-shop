import 'package:flutter/material.dart';
import 'package:nft_once/pages/simple_map_page.dart';
import '../models/brand.dart';
import '../utils/http_client.dart';
import '../utils/toast_util.dart';

class MallBrandPage extends StatefulWidget {
  final String mallId;

  const MallBrandPage({Key? key, required this.mallId}) : super(key: key);

  @override
  State<MallBrandPage> createState() => _MallBrandPageState();
}

class _MallBrandPageState extends State<MallBrandPage> {
  bool isLoading = false;
  List<BrandModel> brands = [];
  Map<String, dynamic>? mallInfo;

  @override
  void initState() {
    super.initState();
    fetchMallBrands();
  }

  // 获取商场品牌列表
  Future<void> fetchMallBrands() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await HttpClient.get('mall/${widget.mallId}/brands');

      if (response['success'] == true) {
        final List<dynamic> brandsData = response['data']['brands'] ?? [];
        final mallData = response['data']['mall'];

        setState(() {
          brands = brandsData.map((item) => BrandModel.fromJson(item)).toList();
          mallInfo = mallData;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ToastUtil.showError('获取品牌数据失败');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // ToastUtil.showError('网络错误，请稍后重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCustomHeader(),
                Expanded(
                  child: brands.isEmpty
                      ? const Center(child: Text('暂无品牌数据'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: brands.length,
                          itemBuilder: (context, index) {
                            return _buildBrandItem(brands[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 120, 160, 230), // 更深的蓝色
            Color.fromARGB(255, 120, 160, 230), // 更深的
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 自定义导航栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      mallInfo?['name'] ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // 平衡左侧按钮
                ],
              ),
            ),
            // 商场信息区域
            if (mallInfo != null)
              Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            mallInfo?['address'] ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoChip('品牌数量', '${brands.length}'),
                        if (mallInfo?['floorCount'] != null)
                          _buildInfoChip('楼层', '${mallInfo?['floorCount']}F'),
                        if (mallInfo?['totalArea'] != null)
                          _buildInfoChip('面积', '${mallInfo?['totalArea']}㎡'),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            label + ':',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandItem(BrandModel brand) {
    return Container(
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
      child: GestureDetector(
        onTap: () => {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SimpleMapPage(
                brandId: brand.id,
              ),
            ),
          )
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(brand.logo ?? ''),
                  fit: BoxFit.contain,
                  onError: (exception, stackTrace) =>
                      const AssetImage('assets/brand/default.png'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                brand.name ?? '未命名品牌',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
