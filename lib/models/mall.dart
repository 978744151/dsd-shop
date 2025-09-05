class Province {
  final String name;
  final String id;

  Province({
    required this.name,
    required this.id,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      name: json['name']?.toString() ?? '',
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
    );
  }
}

class City {
  final String name;
  final String id;

  City({
    required this.name,
    required this.id,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name']?.toString() ?? '',
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
    );
  }
}

class MallData {
  final Province province;
  final City city;
  final String address;
  final String code;
  final int floorCount;
  final bool isActive;
  final String name;
  final int totalArea;
  final String id;
  MallData(
      {required this.province,
      required this.city,
      required this.address,
      required this.code,
      required this.floorCount,
      required this.isActive,
      required this.name,
      required this.totalArea,
      required this.id});

  factory MallData.fromJson(Map<String, dynamic> json) {
    return MallData(
      province: Province.fromJson(json['province'] ?? {}),
      city: City.fromJson(json['city'] ?? {}),
      address: json['address']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      floorCount: json['floorCount'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      totalArea: json['totalArea'] as int? ?? 0,
      id: json['_id']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}
