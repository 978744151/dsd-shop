import 'dart:io';

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import '../api/feedback_api.dart';
import '../utils/toast_util.dart';
import '../utils/http_client.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  String _selectedFeedbackType = 'bug'; // 默认选择错误报告
  final ValueNotifier<String> _feedbackLabelNotifier =
      ValueNotifier<String>('错误报告');
  bool _isSubmitting = false;

  // 反馈类型列表
  final List<Map<String, String>> _feedbackTypes = [
    {'value': 'bug', 'label': '错误报告'},
    {'value': 'feature', 'label': '功能建议'},
    {'value': 'improvement', 'label': '改进建议'},
    {'value': 'question', 'label': '问题咨询'},
    {'value': 'complaint', 'label': '投诉建议'},
    {'value': 'other', 'label': '其他'},
  ];

  // 截图控制器
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void dispose() {
    _feedbackController.dispose();
    _feedbackLabelNotifier.dispose();
    super.dispose();
  }

  // 显示反馈类型选择底部弹框
  void _showFeedbackTypeDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '选择反馈类型',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 反馈类型列表
            ...(_feedbackTypes.map((item) {
              final isSelected = _selectedFeedbackType == item['value'];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedFeedbackType = item['value']!;
                    _feedbackLabelNotifier.value = item['label']!;
                  });
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue.withOpacity(0.5)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['label']!,
                        style: TextStyle(
                          color: isSelected ? Colors.blue : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // 提交反馈
  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ToastUtil.showPrimary('请输入反馈内容');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await HttpClient.post(FeedbackApi.submitFeedback, body: {
        'type': _selectedFeedbackType,
        'content': _feedbackController.text.trim(),
      });

      if (mounted) {
        ToastUtil.showPrimary('反馈提交成功，感谢您的反馈！');
        Navigator.of(context).pop(); // 返回上一页
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showPrimary('提交失败，请稍后重试');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户反馈'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 反馈类型选择
              const Text(
                '反馈类型',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showFeedbackTypeDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder<String>(
                        valueListenable: _feedbackLabelNotifier,
                        builder: (context, value, child) {
                          return Text(
                            value,
                            style: TextStyle(
                              color: _selectedFeedbackType.isNotEmpty
                                  ? Colors.black87
                                  : Colors.grey,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 反馈内容输入
              const Text(
                '反馈内容',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _feedbackController,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: '请详细描述您遇到的问题或建议...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    maximumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '提交反馈',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
