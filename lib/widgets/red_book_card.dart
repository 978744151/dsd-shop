import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nft_once/models/blog.dart';

class RedBookCard extends StatelessWidget {
  final String? avatar;
  final String? name;
  final String title;
  final String content;
  final String time;
  final String? id;
  final String type;
  final String defaultImage;
  final int likes;
  final int comments;
  final double height;
  final Map<String, dynamic>? user;
  final VoidCallback? onTap;
  final String routePath;

  const RedBookCard({
    Key? key,
    this.avatar,
    this.user,
    this.id,
    this.name,
    required this.defaultImage,
    required this.title,
    required this.content,
    required this.time,
    required this.type,
    required this.likes,
    required this.comments,
    this.height = 200,
    this.onTap,
    this.routePath = '/message/messageDetail/',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () {
            context.go('$routePath$id');
          },
      child: Card(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                image: defaultImage.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(defaultImage),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: defaultImage.isEmpty
                  ? const Center(
                      child: Icon(Icons.image, size: 40, color: Colors.grey),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildAvatar(),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const Icon(Icons.favorite_border, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        likes.toString(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (user != null &&
        user!.containsKey('avatar') &&
        user!['avatar'] != null) {
      try {
        return SvgPicture.network(
          user!['avatar'],
          height: 15,
          width: 15,
          placeholderBuilder: (BuildContext context) => const CircleAvatar(
            radius: 7.5,
            backgroundColor: Color(0xFFE6F7FF),
            child: Icon(Icons.person, color: Color(0xFF1890FF), size: 10),
          ),
        );
      } catch (e) {
        return const CircleAvatar(
          radius: 7.5,
          backgroundColor: Color(0xFFE6F7FF),
          child: Icon(Icons.person, color: Color(0xFF1890FF), size: 10),
        );
      }
    } else {
      return const CircleAvatar(
        radius: 7.5,
        backgroundColor: Color(0xFFE6F7FF),
        child: Icon(Icons.person, color: Color(0xFF1890FF), size: 10),
      );
    }
  }
}
