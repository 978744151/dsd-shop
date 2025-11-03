class CityModel {
  final String id;
  final String name;
  final String? code;
  final String? provinceId;
  final String? provinceName;

  CityModel({
    required this.id,
    required this.name,
    this.code,
    this.provinceId,
    this.provinceName,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'],
      provinceId: json['provinceId'],
      provinceName: json['provinceName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'provinceId': provinceId,
      'provinceName': provinceName,
    };
  }
}