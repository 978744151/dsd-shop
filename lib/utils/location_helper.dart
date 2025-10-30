import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/address.dart';

class LocationHelper {
  /// 检查并请求位置权限
  static Future<bool> checkAndRequestLocationPermission() async {
    // 检查位置服务是否开启
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // 检查权限状态
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // 权限被永久拒绝，引导用户到设置页面
      await openAppSettings();
      return false;
    }

    return true;
  }

  /// 获取当前位置
  static Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkAndRequestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('获取位置失败: $e');
      return null;
    }
  }

  /// 根据坐标获取详细地址信息
  static Future<AddressModel?> getDetailedAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        print('获取位置成功: $place');
        String province = place.administrativeArea ?? '';
        String city = place.locality ?? place.subAdministrativeArea ?? '';
        String district = place.subLocality ?? '';
        String street = place.street ?? '';
        String detail = place.name ?? '';

        // 构建完整地址
        String fullDetail = '';
        if (street.isNotEmpty) fullDetail += street;
        if (detail.isNotEmpty && detail != street) {
          fullDetail += (fullDetail.isNotEmpty ? ' ' : '') + detail;
        }

        return AddressModel(
          id: 'current_location',
          name: '当前位置',
          province: province,
          city: city,
          district: district,
          detail: fullDetail,
          phone: '',
          isDefault: false,
          // 注意：geocoding库无法直接获取省市ID，这里使用名称作为临时ID
          // 在实际应用中，你可能需要调用额外的API来获取真实的省市ID
          provinceId: _generateIdFromName(province),
          cityId: _generateIdFromName(city),
          districtId: _generateIdFromName(district),
        );
      }

      return null;
    } catch (e) {
      print('地址解析失败: $e');
      return null;
    }
  }

  /// 根据坐标获取地址信息（保持向后兼容）
  static Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      AddressModel? addressModel =
          await getDetailedAddressFromCoordinates(latitude, longitude);
      return addressModel?.displayAddress;
    } catch (e) {
      print('地址解析失败: $e');
      return null;
    }
  }

  /// 获取当前位置的详细地址信息
  static Future<AddressModel?> getCurrentDetailedAddress() async {
    try {
      Position? position = await getCurrentLocation();
      if (position == null) {
        return null;
      }

      return await getDetailedAddressFromCoordinates(
          position.latitude, position.longitude);
    } catch (e) {
      print('获取当前地址失败: $e');
      return null;
    }
  }

  /// 获取当前位置的地址（保持向后兼容）
  static Future<String?> getCurrentAddress() async {
    try {
      AddressModel? addressModel = await getCurrentDetailedAddress();
      return addressModel?.displayAddress;
    } catch (e) {
      print('获取当前地址失败: $e');
      return null;
    }
  }

  /// 根据地址名称生成简单的ID（临时方案）
  /// 在实际应用中，应该调用专门的地理编码API获取真实的省市ID
  static String? _generateIdFromName(String name) {
    if (name.isEmpty) return null;
    // 这里使用简单的哈希作为临时ID，实际应用中应该使用真实的省市编码
    return name.hashCode.abs().toString();
  }

  /// 计算两点之间的距离（米）
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
