import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 添加foundation导入用于kIsWeb
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:nft_once/api/comment_api.dart';
import 'package:nft_once/router/router.dart';
import 'package:nft_once/utils/toast_util.dart';

import 'dart:io';
import 'dart:convert';
import '../config/env.dart';

// 添加条件导入
import 'package:image_picker/image_picker.dart';
// 在文件顶部添加导入
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 添加导入
import '../utils/event_bus.dart';
import '../utils/http_client.dart';
import '../utils/image_upload_util.dart'; // 导入图片上传工具类

class CreateBlogPage extends StatefulWidget {
  const CreateBlogPage({Key? key}) : super(key: key);

  @override
  State<CreateBlogPage> createState() => _CreateBlogPageState();
}

class _CreateBlogPageState extends State<CreateBlogPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  List<XFile> _xFiles = []; // 保存XFile用于H5平台
  List<File> _images = []; // 保存File用于App平台
  final ImagePicker _picker = ImagePicker();
  List<String> _selectedTags = [];
  final List<String> _suggestedTags = [
    '汇数通起飞',
    '狰',
    '孔子',
    '兵家',
    '儒家',
    '财神',
    '一鹿生花',
    '百家争鸣'
  ];
  bool _validateForm() {
    if (_titleController.text.isEmpty) {
      Fluttertoast.showToast(msg: '请填写标题');
      return false;
    }

    // if (_contentController.text.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('请输入内容')),
    //   );
    //   return false;
    // }

    if (_xFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请至少上传一张图片')),
      );
      return false;
    }

    return true;
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isNotEmpty) {
        // 检查图片数量限制
        if (_xFiles.length + images.length > 9) {
          throw Exception('最多只能上传9张图片');
        }

        // 检查每张图片
        for (var image in images) {
          try {
            print('图片路径: ${image.path}');
            print('图片名称: ${image.name}');
            final File file = File(image.path);
            final int sizeInBytes = await file.length();
            final double sizeInMb = sizeInBytes / (1024 * 1024);

            if (sizeInMb > 5) {
              throw Exception('图片大小不能超过5MB');
            }
          } catch (fileError) {
            print('处理图片文件时出错: $fileError');
            continue; // 跳过这张图片，继续处理下一张
          }
        }

        setState(() {
          _xFiles.addAll(images); // 保存XFile用于H5
          _images
              .addAll(images.map((image) => File(image.path))); // 保存File用于App
        });
      }
    } catch (e) {
      print('图片选择错误: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _uploadBlog() async {
    if (!_validateForm()) return;

    OverlayEntry? overlayEntry; // 替换 dialogContext

    try {
      // 创建加载指示器的 OverlayEntry
      overlayEntry = OverlayEntry(
        builder: (context) => Container(
          color: Colors.black.withOpacity(0.5),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );

      // 显示加载指示器
      Overlay.of(context).insert(overlayEntry);

      // 获取 token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      print(token);
      if (token == null) {
        router.go('/login');
        throw Exception('请先登录');
      }

      List<Map<String, String>> imageUrls = [];
      for (var i = 0; i < _xFiles.length; i++) {
        try {
          print('正在上传图片 ${i + 1}/${_xFiles.length}');

          Map<String, dynamic> response;

          // 根据平台选择不同的上传方式
          if (kIsWeb) {
            // H5平台的上传方式 - 使用XFile
            response = await ImageUploadUtil.uploadImageForWeb(_xFiles[i]);
          } else {
            // App平台的上传方式 - 使用File
            response = await HttpClient.uploadFile('upload/image', _images[i]);
          }

          if (response['success'] == true &&
              response['data'] != null &&
              response['data']['url'] != null) {
            imageUrls.add({'image': response['data']['url']});
            print('图片 ${i + 1} 上传成功: ${response['data']['url']}');
          } else {
            throw Exception('服务器返回的数据格式不正确: $response');
          }
        } catch (imageError) {
          print('图片 ${i + 1} 上传失败: $imageError');
          rethrow; // 向上传递错误
        }
      }

      // 上传笔记内容
      final blogData = {
        'title': _titleController.text,
        'content': _contentController.text,
        'blogImage': imageUrls,
        'tags': _selectedTags,
      };

      final blogResponse =
          await HttpClient.post(NftApi.createBlog, body: blogData);
      if (blogResponse['success'] == true) {
        overlayEntry.remove(); // 移除加载指示器
        if (mounted) {
          FocusScope.of(context).unfocus();
          ToastUtil.showSuccess("发布成功");
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            eventBus.fire(BlogCreatedEvent());
            context.pop();
          }
        }
      }
    } catch (e) {
      print('发布错误: $e');
      overlayEntry?.remove(); // 错误时移除加载指示器
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发布失败: ${e.toString()}'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _openGallery(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              PhotoViewGallery.builder(
                itemCount: _xFiles.length,
                builder: (context, index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: kIsWeb
                        ? NetworkImage(
                            _xFiles[index].path) // Web平台使用NetworkImage
                        : FileImage(_images[index])
                            as ImageProvider, // App平台使用FileImage
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  );
                },
                scrollPhysics: BouncingScrollPhysics(),
                backgroundDecoration: BoxDecoration(color: Colors.black),
                pageController: PageController(initialPage: initialIndex),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: const Color(0xFFFFFFFF)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => context.pop(), // 修改这里，直接导航到根路由
        ),
        actions: [
          TextButton(
            onPressed: () {
              // if (_validateForm()) {
              _uploadBlog();
              // }
            },
            child: Container(
              // padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  Text('发布', style: TextStyle(color: const Color(0xFFFFFFFF))),
            ),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 图片网格
            if (_xFiles.isEmpty)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 100, // 减小高度
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 32, color: Colors.grey),
                      SizedBox(height: 4),
                      Text('添加图片',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 100, // 减小高度
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _xFiles.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _xFiles.length) {
                      return GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          margin:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.add_photo_alternate,
                              color: Colors.grey),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _openGallery(index),
                          child: Container(
                            width: 100,
                            margin: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: kIsWeb
                                    ? NetworkImage(_xFiles[index]
                                        .path) // Web平台使用NetworkImage
                                    : FileImage(_images[index])
                                        as ImageProvider, // App平台使用FileImage
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 12,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _xFiles.removeAt(index); // 删除XFile
                                _images.removeAt(index); // 删除File
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                // ignore: deprecated_member_use
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close,
                                  color: const Color(0xFFFFFFFF), size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            // 标题和内容输入
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '添加标题',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    style: TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: '分享你的故事...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                ],
              ),
            ),

            // 标签选择
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('添加标签',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _suggestedTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTags.remove(tag);
                            } else {
                              _selectedTags.add(tag);
                            }
                          });
                        },
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.red[50] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
