import 'dart:ffi';

class ProvinceModel {
  final String id;
  final String name;
  final String? code;
  final Int? mallCount;
  final Int? brandCount;
  final Int? storeCount;

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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'],
      mallCount: json['mallCount'],
      brandCount: json['brandCount'],
      storeCount: json['storeCount'],
    );
  }
}
