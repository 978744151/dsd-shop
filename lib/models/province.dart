class ProvinceModel {
  final String id;
  final String name;
  final String? code;
  final int? mallCount;
  final int? brandCount;
  final int? storeCount;

  // 根据实际API返回的字段添加更多属性

  ProvinceModel({
    required this.id,
    required this.name,
    this.code,
    this.mallCount,
    this.brandCount,
    this.storeCount,
  });

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'],
      mallCount: json['mallCount'],
      brandCount: json['brandCount'],
      storeCount: json['storeCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'mallCount': mallCount,
      'brandCount': brandCount,
      'storeCount': storeCount,
    };
  }
}
