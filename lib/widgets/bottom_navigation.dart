import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        onTap?.call(index);
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFFFFFFF),
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: const Color.fromARGB(255, 54, 53, 53),
      selectedLabelStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 16,
      ),
      elevation: 0,
      items: [
        const BottomNavigationBarItem(
          icon: SizedBox(),
          label: '欢迎',
        ),
        // 移除 const
        const BottomNavigationBarItem(
          icon: SizedBox(),
          label: '社区',
        ),

        BottomNavigationBarItem(
          icon: SizedBox(
            height: 20, // 与文字高度一致
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          activeIcon: SizedBox(
            height: 20, // 与文字高度一致
            child: Icon(
              Icons.shopping_cart,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          label: '',
        ),
        const BottomNavigationBarItem(
          icon: SizedBox(),
          label: '公告',
        ),
        const BottomNavigationBarItem(
          icon: SizedBox(),
          label: '我的',
        ),
      ],
    );
  }
}
