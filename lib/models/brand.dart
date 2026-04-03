class BrandModel {
  final String id;
  final String? brandId;
  final String? title;
  final String? content;
  final String? createName;
  final String? description; // 新增品牌描述字段
  final String? updatedAt;
  final String? createdAt; // 新增更新时间字段    
  final String? code; // 新增品牌编码字段
      
  final String? type;
  final String? avatar;
  final String? score;
  final String? name;
  final String? defaultImage;
  final String? logo;
  final int? storeCount; // 新增门店数量字段
  final Map<String, dynamic>? user; // 直接使用 Map

  BrandModel(
      {required this.id,
      this.title,
      this.content,
      this.description, // 新增品牌描述参数
      this.createName,
      this.updatedAt,
      this.createdAt, // 新增更新时间参数
      this.code, // 新增品牌编码字段
      this.type,
      this.defaultImage,
      this.avatar,
      this.name,
      this.brandId,
      this.user,
      this.logo,
      this.score,
      this.storeCount}); // 新增门店数量参数  添加这行

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      content: json['content'] ?? '',
      createName: json['createName'] ?? '',
      createdAt: json['createdAt'] ?? '',
      description: json['description'] ?? '', // 新增品牌描述参数
      type: json['type'] ?? '',
      updatedAt: (json['updatedAt'] ?? json['updatedAt'] ?? '').toString(), // 兼容两种字段名
      code: json['code'] ?? '', // 新增品牌编码字段
      defaultImage: json['defaultImage'] ?? '',
      logo: json['logo'], // 直接使用 Map
      brandId: json['brandId'] ?? '',
      avatar: json['avatar'], // 直接使用 Map
      score: json['score']?.toString() ?? '',
      storeCount: json['storeCount'] as int?, // 新增门店数量字段
    );
  }
}
