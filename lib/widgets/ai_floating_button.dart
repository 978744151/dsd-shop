import 'package:business_savvy/pages/deepseek_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

/// AI悬浮按钮组件
/// 可拖动、定时显示提示、带晃动动画
class AiFloatingButton extends StatefulWidget {
  /// 初始距离右边的距离
  final double initialRight;
  
  /// 初始距离底部的距离
  final double initialBottom;
  
  /// 提示文字
  final String tipText;
  
  /// 首次显示提示的延迟时间(秒)
  final int initialDelay;
  
  /// 提示显示的间隔时间(分钟)
  final int intervalMinutes;
  
  /// 提示显示的持续时间(秒)
  final int tipDuration;
  
  const AiFloatingButton({
    Key? key,
    this.initialRight = 16,
    this.initialBottom = 50,
    this.tipText = '我是Savvy智能体\n可以向我问答',
    this.initialDelay = 3,
    this.intervalMinutes = 1,
    this.tipDuration = 10,
  }) : super(key: key);

  @override
  State<AiFloatingButton> createState() => _AiFloatingButtonState();
}

class _AiFloatingButtonState extends State<AiFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  Timer? _aiTipTimer;
  bool _showTipText = false;

  // AI按钮位置偏移量
  double _aiButtonX = 0;
  double _aiButtonY = 0;

  @override
  void initState() {
    super.initState();

    // 初始化晃动动画
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // 启动定时提示
    _startAiTipTimer();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _aiTipTimer?.cancel();
    super.dispose();
  }

  /// 启动AI提示定时器
  void _startAiTipTimer() {
    // 首次延迟显示
    Future.delayed(Duration(seconds: widget.initialDelay), () {
      if (mounted) _showAiTipOnce();
    });

    // 定时显示
    _aiTipTimer = Timer.periodic(Duration(minutes: widget.intervalMinutes), (timer) {
      if (mounted) _showAiTipOnce();
    });
  }

  /// 显示一次AI提示
  void _showAiTipOnce() {
    setState(() {
      _showTipText = true;
    });
    _shakeController.repeat(reverse: true);

    Future.delayed(Duration(seconds: widget.tipDuration), () {
      if (mounted) {
        setState(() {
          _showTipText = false;
        });
        _shakeController.stop();
        _shakeController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: widget.initialRight + _aiButtonX,
      bottom: widget.initialBottom + _aiButtonY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            // 对于right定位:向右拖动(dx>0)时,right值应该减小
            // 对于bottom定位:向上拖动(dy<0)时,bottom值应该增大
            _aiButtonX -= details.delta.dx;
            _aiButtonY -= details.delta.dy;
          });
        },
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                0,
                _showTipText ? -_shakeAnimation.value : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 提示文字
                  if (_showTipText)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8, right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.tipText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  // AI按钮
                  GestureDetector(
                    onTap: () {
                      // context.push('/ai-chat');
                      // context.push('/deepseek');
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (context) => DeepseekPage(),
                        ),
                      );
                      if (_showTipText) {
                        setState(() {
                          _showTipText = false;
                        });
                        _shakeController.stop();
                        _shakeController.reset();
                      }
                    },
                    child: Center(
                      child: Image.asset(
                        'assets/logo/ai_blue.png',
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
