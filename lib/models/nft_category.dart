class NFTCategory {
  final String id;
  final String name;
  final String icon;

  NFTCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory NFTCategory.fromJson(Map<String, dynamic> json) {
    return NFTCategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}
