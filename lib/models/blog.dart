class Blog {
  final String id;
  final String title;
  final String content;
  final String createName;
  final String createdAt;
  final String type;
  final String? avatar;
  final String? name;
  final String defaultImage;
  final Map<String, dynamic>? user; // 直接使用 Map

  Blog({
    required this.id,
    required this.title,
    required this.content,
    required this.createName,
    required this.createdAt,
    required this.type,
    required this.defaultImage,
    this.avatar,
    this.name,
    this.user,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createName: json['createName'] ?? '',
      createdAt: json['createdAt'] ?? '',
      type: json['type'] ?? '',
      defaultImage: json['defaultImage'] ?? '',
      user: json['user'], // 直接使用 Map
    );
  }
}
