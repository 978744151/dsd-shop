class CoachData {
  final String province;
  final String city;
  final String storeName;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final int coachCount;

  CoachData({
    required this.province,
    required this.city,
    required this.storeName,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.coachCount,
  });

  factory CoachData.fromJson(Map<String, dynamic> json) {
    return CoachData(
      province: json['province']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      storeName: json['storeName']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      coachCount: json['coachCount'] as int? ?? 0,
    );
  }
}

class ProvinceData {
  final String name;
  final int coachCount;
  final List<CityData> cities;

  ProvinceData({
    required this.name,
    required this.coachCount,
    required this.cities,
  });
}

class CityData {
  final String name;
  final int coachCount;
  final List<CoachData> stores;

  CityData({
    required this.name,
    required this.coachCount,
    required this.stores,
  });
}
