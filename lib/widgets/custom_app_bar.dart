import 'package:flutter/material.dart';
import '../views/notification/notification_screen.dart';
import 'package:provider/provider.dart';
import '../controllers/notification_badge_controller.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationTap;

  const CustomAppBar({
    super.key,
    this.onNotificationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(82);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  late NotificationBadgeController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        Provider.of<NotificationBadgeController>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo di sebelah kiri
            Image.asset(
              'images/Logo_RS_UMMI.png',
              width: 150,
              height: 40,
            ),

            // Ikon notifikasi di sebelah kanan
            GestureDetector(
              onTap: widget.onNotificationTap ??
                  () {
                    // Navigasi ke halaman notifikasi jika tidak ada custom handler
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    ).then((_) {
                      // Refresh jumlah notifikasi setelah kembali dari halaman notifikasi
                      _controller.loadUnreadNotificationCount(context: context);
                    });
                  },
              child: Consumer<NotificationBadgeController>(
                  builder: (context, controller, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF213268),
                      size: 28,
                    ),
                    if (controller.isLoading)
                      const Positioned(
                        right: 0,
                        top: 0,
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF25B1FF),
                          ),
                        ),
                      )
                    else if (controller.notificationCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF25B1FF),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            controller.notificationCount > 9
                                ? '9+'
                                : controller.notificationCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
