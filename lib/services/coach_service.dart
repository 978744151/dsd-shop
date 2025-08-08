import '../models/coach_data.dart';

class CoachService {
  static List<CoachData> getMockCoachData() {
    return [
      // 北京
      CoachData(
        province: '北京',
        city: '北京市',
        storeName: 'Coach北京三里屯店',
        address: '北京市朝阳区三里屯路19号',
        phone: '010-12345678',
        latitude: 39.9042,
        longitude: 116.4074,
        coachCount: 15,
      ),
      CoachData(
        province: '北京',
        city: '北京市',
        storeName: 'Coach北京国贸店',
        address: '北京市朝阳区建国门外大街1号',
        phone: '010-87654321',
        latitude: 39.9087,
        longitude: 116.3975,
        coachCount: 12,
      ),

      // 上海
      CoachData(
        province: '上海',
        city: '上海市',
        storeName: 'Coach上海南京路店',
        address: '上海市黄浦区南京东路123号',
        phone: '021-12345678',
        latitude: 31.2304,
        longitude: 121.4737,
        coachCount: 18,
      ),
      CoachData(
        province: '上海',
        city: '上海市',
        storeName: 'Coach上海陆家嘴店',
        address: '上海市浦东新区陆家嘴环路1000号',
        phone: '021-87654321',
        latitude: 31.2397,
        longitude: 121.4998,
        coachCount: 20,
      ),

      // 广东
      CoachData(
        province: '广东',
        city: '广州市',
        storeName: 'Coach广州天河店',
        address: '广州市天河区天河路123号',
        phone: '020-12345678',
        latitude: 23.1291,
        longitude: 113.2644,
        coachCount: 14,
      ),
      CoachData(
        province: '广东',
        city: '深圳市',
        storeName: 'Coach深圳万象城店',
        address: '深圳市罗湖区宝安南路1881号',
        phone: '0755-12345678',
        latitude: 22.5431,
        longitude: 114.0579,
        coachCount: 16,
      ),

      // 浙江
      CoachData(
        province: '浙江',
        city: '杭州市',
        storeName: 'Coach杭州西湖店',
        address: '杭州市西湖区湖滨路123号',
        phone: '0571-12345678',
        latitude: 30.2741,
        longitude: 120.1551,
        coachCount: 10,
      ),
      CoachData(
        province: '浙江',
        city: '宁波市',
        storeName: 'Coach宁波天一店',
        address: '宁波市海曙区中山东路123号',
        phone: '0574-12345678',
        latitude: 29.8683,
        longitude: 121.5444,
        coachCount: 8,
      ),

      // 江苏
      CoachData(
        province: '江苏',
        city: '南京市',
        storeName: 'Coach南京新街口店',
        address: '南京市玄武区中山路123号',
        phone: '025-12345678',
        latitude: 32.0603,
        longitude: 118.7969,
        coachCount: 12,
      ),
      CoachData(
        province: '江苏',
        city: '苏州市',
        storeName: 'Coach苏州观前店',
        address: '苏州市姑苏区观前街123号',
        phone: '0512-12345678',
        latitude: 31.2990,
        longitude: 120.5853,
        coachCount: 9,
      ),

      // 四川
      CoachData(
        province: '四川',
        city: '成都市',
        storeName: 'Coach成都春熙路店',
        address: '成都市锦江区春熙路123号',
        phone: '028-12345678',
        latitude: 30.5728,
        longitude: 104.0668,
        coachCount: 11,
      ),

      // 湖北
      CoachData(
        province: '湖北',
        city: '武汉市',
        storeName: 'Coach武汉江汉路店',
        address: '武汉市江汉区江汉路123号',
        phone: '027-12345678',
        latitude: 30.5928,
        longitude: 114.3055,
        coachCount: 8,
      ),

      // 陕西
      CoachData(
        province: '陕西',
        city: '西安市',
        storeName: 'Coach西安钟楼店',
        address: '西安市碑林区东大街123号',
        phone: '029-12345678',
        latitude: 34.2655,
        longitude: 108.9507,
        coachCount: 7,
      ),
    ];
  }

  static List<ProvinceData> getProvinceData() {
    final coachData = getMockCoachData();
    final Map<String, List<CoachData>> provinceMap = {};

    for (var coach in coachData) {
      if (!provinceMap.containsKey(coach.province)) {
        provinceMap[coach.province] = [];
      }
      provinceMap[coach.province]!.add(coach);
    }

    return provinceMap.entries.map((entry) {
      final cityMap = <String, List<CoachData>>{};
      for (var coach in entry.value) {
        if (!cityMap.containsKey(coach.city)) {
          cityMap[coach.city] = [];
        }
        cityMap[coach.city]!.add(coach);
      }

      final cities = cityMap.entries.map((cityEntry) {
        return CityData(
          name: cityEntry.key,
          coachCount:
              cityEntry.value.fold(0, (sum, coach) => sum + coach.coachCount),
          stores: cityEntry.value,
        );
      }).toList();

      return ProvinceData(
        name: entry.key,
        coachCount: entry.value.fold(0, (sum, coach) => sum + coach.coachCount),
        cities: cities,
      );
    }).toList();
  }

  static List<Map<String, dynamic>> getProvinceMapData() {
    final provinceData = getProvinceData();
    return provinceData.map((province) {
      return {
        'name': province.name,
        'value': province.coachCount,
      };
    }).toList();
  }

  static List<Map<String, dynamic>> getCityMapData(String provinceName) {
    final provinceData = getProvinceData();
    final province = provinceData.firstWhere(
      (p) => p.name == provinceName,
      orElse: () => ProvinceData(name: '', coachCount: 0, cities: []),
    );

    return province.cities.map((city) {
      return {
        'name': city.name,
        'value': city.coachCount,
      };
    }).toList();
  }
}
