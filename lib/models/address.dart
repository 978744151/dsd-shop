class AddressModel {
  final String id;
  final String name;
  final String province;
  final String city;
  final String district;
  final String detail;
  final String phone;
  final bool isDefault;
  final String? provinceId;  // 省份ID
  final String? cityId;      // 城市ID
  final String? districtId;  // 区县ID

  AddressModel({
    required this.id,
    required this.name,
    required this.province,
    required this.city,
    required this.district,
    required this.detail,
    required this.phone,
    this.isDefault = false,
    this.provinceId,
    this.cityId,
    this.districtId,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isDefault: json['isDefault'] ?? false,
      provinceId: json['provinceId']?.toString(),
      cityId: json['cityId']?.toString(),
      districtId: json['districtId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'province': province,
      'city': city,
      'district': district,
      'detail': detail,
      'phone': phone,
      'isDefault': isDefault,
      'provinceId': provinceId,
      'cityId': cityId,
      'districtId': districtId,
    };
  }

  String get fullAddress => '$province$city$district$detail';
  String get shortAddress => '$city$district';
  
  // 只显示市的地址
  String get displayAddress {
    if (city.isNotEmpty) {
      return city;
    } else if (province.isNotEmpty) {
      return province;
    } else {
      return detail.isNotEmpty ? detail : '未知地址';
    }
  }
}