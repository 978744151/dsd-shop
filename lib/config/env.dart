class ApiConfig {
  // 不同环境的baseUrl
  // static const String devBaseUrl = 'http://localhost:5002/api/';

  static const String devBaseUrl = 'http://8.155.53.210:3001/api/';
  static const String testBaseUrl = 'http://test-api.example.com/api/v1';
  static const String prodBaseUrl = 'http://8.155.53.210:3000/api/v1';

  // 当前使用的环境
  static const String baseUrl = devBaseUrl; // 可以根据构建环境切换

  static String getFullPath(String path) => baseUrl + path;

  static const String nftCategories = '$baseUrl/nft-categories';
  static const String nfts = '$baseUrl/nfts';
}
