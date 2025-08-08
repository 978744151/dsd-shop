class NFT {
  final String id;
  final String name;
  final String imageUrl;
  final String price; // 改为 String 类型
  final String stock; // 改为 String 类型
  final String category;

  NFT({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.stock,
    required this.category,
  });

  factory NFT.fromJson(Map<String, dynamic> json) {
    return NFT(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      stock: json['stock']?.toString() ?? '0',
      category: json['category']?.toString() ?? '',
    );
  }
}
