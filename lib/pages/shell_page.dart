import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // 添加这行
import '../widgets/bottom_navigation.dart';

class ShellPage extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ShellPage({
    required this.navigationShell,
    Key? key,
  }) : super(key: key);

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: widget.navigationShell.goBranch,
      ),
    );
  }
}
