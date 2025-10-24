class BrandModel {
  final String id;
  final String? brandId;
  final String? title;
  final String? content;
  final String? createName;
  final String? createdAt;
  final String? type;
  final String? avatar;
  final String? name;
  final String? defaultImage;
  final String? logo;
  final int? storeCount; // 新增门店数量字段
  final Map<String, dynamic>? user; // 直接使用 Map

  BrandModel(
      {required this.id,
      this.title,
      this.content,
      this.createName,
      this.createdAt,
      this.type,
      this.defaultImage,
      this.avatar,
      this.name,
      this.brandId,
      this.user,
      this.logo,
      this.storeCount}); // 新增门店数量参数  添加这行

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      content: json['content'] ?? '',
      createName: json['createName'] ?? '',
      createdAt: json['createdAt'] ?? '',
      type: json['type'] ?? '',
      defaultImage: json['defaultImage'] ?? '',
      logo: json['logo'], // 直接使用 Map
      brandId: json['brandId'] ?? '',
      storeCount: json['storeCount'] as int?, // 新增门店数量字段
    );
  }
}
