class brandApi {
  static const String getBrand = 'map/brands';
  static const String getBrandTree = 'map/tree';
  static const String getBrandDetail = 'map/brandDetail';
  static const String getBrandBase = 'map/brands/detail';
  static const String getMalls = 'map/malls';
  static const String getComparison = 'map/comparison';
  static const String getProvinces = 'map/provinces';
  static const String getCities = 'map/cities';
  static const String getComparisonReports = 'map/comparison/reports';
  static String getComparisonReportsDetail(id) => 'map/comparison/reports/$id';

  // 地址相关API
  static const String getAddressList = 'user/addresses';
  static const String getDefaultAddress = 'user/addresses/default';
  static const String setDefaultAddress = 'user/addresses/default';
}
