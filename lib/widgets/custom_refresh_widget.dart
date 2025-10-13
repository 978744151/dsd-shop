import 'package:flutter/material.dart';

/// 统一的下拉刷新组件
/// 提供一致的样式和行为
class CustomRefreshWidget extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;
  final double strokeWidth;
  final double edgeOffset;

  const CustomRefreshWidget({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.strokeWidth = 3.0,
    this.edgeOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? const Color(0xFF4e65ff), // 统一的主题色
      backgroundColor: backgroundColor ?? const Color(0xFFFFFFFF),
      displacement: displacement,
      strokeWidth: strokeWidth,
      edgeOffset: edgeOffset,
      child: child,
    );
  }
}
