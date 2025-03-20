import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(82),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF213268),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF56C5F1),
              blurRadius: 7.3,
              offset: Offset(0, 3),
              spreadRadius: 3,
            ),
          ],
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Image.asset(
              'images/Logo_RS_UMMI_white.png',
              width: 208.14,
              height: 55,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(82);
}
