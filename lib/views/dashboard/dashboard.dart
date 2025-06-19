import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/profile.dart';
import '../pages/home_screen.dart';
import '../pages/qr_scanner_screen.dart';
import '../stockopname/stockopname.dart';
import '../complain/complain_list_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../auth/login.dart';

// Import untuk mengatasi masalah anti-screenshot
import 'dart:io';
import 'package:no_screenshot/no_screenshot.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;

  const DashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Widget> _screens = [];
  late DashboardController _dashboardController;

  @override
  void initState() {
    super.initState();

    _dashboardController =
        Provider.of<DashboardController>(context, listen: false);

    // Reset selected index ke 0 (Home) saat dashboard dibuka
    _dashboardController.setSelectedIndex(widget.initialIndex);

    // Pastikan fitur anti-screenshot dinonaktifkan saat dashboard dibuka
    _dashboardController.disableAnyActiveScreenshotProtection();

    try {
      print("Initializing DashboardScreen screens...");
      _screens.addAll([
        _buildScreenWithErrorHandling(() => const HomeScreen(), 'HomeScreen'),
        _buildScreenWithErrorHandling(
            () => const StockopnameScreen(), 'StockopnameScreen'),
        const SizedBox(), // Placeholder for QR Scanner
        _buildScreenWithErrorHandling(
            () => const ComplainListScreen(), 'ComplainListScreen'),
        _buildScreenWithErrorHandling(
            () => const ProfileScreen(), 'ProfileScreen'),
      ]);
      print("DashboardScreen screens initialized successfully");

      // Set navigasi otomatis untuk token expired
      ApiService.navigateToLogin = (BuildContext ctx) {
        Navigator.of(ctx).pushAndRemoveUntil(
          MaterialPageRoute(builder: (c) => const LoginScreen()),
          (route) => false,
        );
      };

      // Hanya lakukan pengecekan jika aplikasi diluncurkan langsung ke dashboard
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeValidateToken();
      });
    } catch (e, s) {
      print("Error initializing DashboardScreen screens: $e");
      print("Stack trace: $s");
    }
  }

  // Validasi token hanya jika diperlukan
  Future<void> _maybeValidateToken() async {
    final isValid = await _dashboardController.maybeValidateToken();
    if (!isValid && mounted) {
      // Jika tidak ada token, navigasi ke login tanpa menampilkan loading
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildScreenWithErrorHandling(Function builder, String screenName) {
    try {
      Widget screen = builder();
      return screen;
    } catch (e, s) {
      print("Error building $screenName: $e");
      print("Stack trace: $s");

      // Menampilkan pesan error jika ada masalah dengan widget
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showError('Kesalahan memuat $screenName: $e');
        }
      });

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Kesalahan memuat $screenName: $e',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Refresh screen by rebuilding it
                _dashboardController.refreshState();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF213268),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void showError(String message) {
    _dashboardController.showError(message);

    // Tampilkan snackbar dengan pesan error yang tidak mengganggu tab bar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[900],
        duration: const Duration(seconds: 3),
        // Gunakan margin dan floating behavior agar tidak mengganggu tab bar
        margin: const EdgeInsets.only(
          bottom: 70.0, // Margin agar tidak menutupi tab bar
          left: 20.0,
          right: 20.0,
        ),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Tutup',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        final bool isKeyboardVisible =
            MediaQuery.of(context).viewInsets.bottom > 0;

        // Menggunakan initialIndex hanya saat pertama kali dibuat
        if (widget.initialIndex != 0 && controller.selectedIndex == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.setSelectedIndex(widget.initialIndex);
          });
        }

        return Scaffold(
          appBar: const CustomAppBar(),
          body: _screens[controller.selectedIndex],
          floatingActionButton: isKeyboardVisible
              ? null
              : SizedBox(
                  width: 84,
                  height: 84,
                  child: FloatingActionButton(
                    elevation: 0,
                    backgroundColor: const Color(0xFF203268),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(42),
                      side: const BorderSide(
                        color: Color(0xFF25B1FF),
                        width: 6,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QRScannerScreen(
                            previousScreen: controller.getPreviousScreenName(),
                          ),
                        ),
                      ).then((_) {
                        // Refresh state jika diperlukan
                        controller.refreshState();
                      });
                    },
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Color(0xFFACC3EF),
                      size: 24,
                    ),
                  ),
                ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: controller.selectedIndex,
              onTap: controller.setSelectedIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF213268),
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.white,
              elevation: 8,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory),
                  label: 'Opname',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.qr_code_scanner, color: Colors.transparent),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.report_problem),
                  label: 'Komplain',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
