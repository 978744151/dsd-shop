import 'city.dart';

class SpringFestivalStats {
  final CityModel city;
  final double touristVolume; // 接待游客总量
  final double tourismRevenue; // 旅游总收入
  final double cateringRevenue; // 餐联商务数据
  final double businessConsumption; // 商户企业消费
  final double movieBoxOffice; // 电影票房
  final double totalVisitorsGrowthRate; // 游客消费增长比率 (%)
  final double visitorConsumptionGrowthRate; // 游客消费增长比率 (%)
  final String notes; // 备注
  final String dataSource; // 数据来源

  SpringFestivalStats({
    required this.city,
    required this.touristVolume,
    required this.tourismRevenue,
    required this.cateringRevenue,
    required this.businessConsumption,
    required this.movieBoxOffice,
    required this.totalVisitorsGrowthRate,
    required this.visitorConsumptionGrowthRate,
    required this.notes,
    required this.dataSource,
  });

  factory SpringFestivalStats.fromJson(Map<String, dynamic> json) {
    return SpringFestivalStats(
      city: CityModel.fromJson(json['city'] ?? {}),
      touristVolume: _parseDouble(json['totalVisitors']),
      tourismRevenue: _parseDouble(json['tourismRevenue']),
      cateringRevenue: _parseDouble(json['cateringRevenue']),
      businessConsumption: _parseDouble(json['mallEnterpriseConsumption']),
      movieBoxOffice: _parseDouble(json['movieTicketConsumption']),
      totalVisitorsGrowthRate: _parseDouble(json['totalVisitorsGrowthRate']),
      visitorConsumptionGrowthRate: _parseDouble(json['visitorConsumptionGrowthRate']),
      notes: json['notes']?.toString() ?? '',
      dataSource: json['dataSource']?.toString() ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // 移除 ¥ 符号和逗号
      final cleaned = value.replaceAll(RegExp(r'[¥,]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city.toJson(),
      'touristVolume': touristVolume,
      'tourismRevenue': tourismRevenue,
      'cateringRevenue': cateringRevenue,
      'businessConsumption': businessConsumption,
      'movieBoxOffice': movieBoxOffice,
      'totalVisitorsGrowthRate': totalVisitorsGrowthRate,
      'visitorConsumptionGrowthRate': visitorConsumptionGrowthRate,
      'notes': notes,
      'dataSource': dataSource,
    };
  }
}
