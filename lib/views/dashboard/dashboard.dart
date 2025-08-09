import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/profile.dart';
import '../pages/home_screen.dart';
import '../pages/qr_scanner_screen.dart';
import '../stockopname/stockopname.dart';
import '../complain/complain_list_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../controllers/auth/auth_controller.dart' as AuthApi;
import '../../controllers/dashboard/dashboard_controller.dart';
import '../../auth/login.dart';
import 'dart:async'; // Import untuk Timer
import 'package:google_fonts/google_fonts.dart';

// Import untuk mengatasi masalah anti-screenshot
import 'dart:io';
import 'package:no_screenshot/no_screenshot.dart';
import '../../utils/logger_util.dart';
import '../../services/socket/socket_service.dart'
    as SocketApi; // Import untuk ApiService dari socket
import '../../utils/snackbar_util.dart';

// Route observer for tracking navigation
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class DashboardScreen extends StatefulWidget {
  final int initialIndex;

  const DashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Widget> _screens = [];
  late DashboardController _dashboardController;
  Timer? _sessionCheckTimer; // Timer untuk memeriksa sesi
  DateTime? _lastBackPressTime; // Track the last back button press time

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
      LoggerUtil.i("Initializing DashboardScreen screens...");
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
      LoggerUtil.i("DashboardScreen screens initialized successfully");

      // Set navigasi otomatis untuk token expired
      AuthApi.ApiService.navigateToLogin = (BuildContext ctx) {
        Navigator.of(ctx).pushAndRemoveUntil(
          MaterialPageRoute(builder: (c) => const LoginScreen()),
          (route) => false,
        );
      };

      // Hanya lakukan pengecekan jika aplikasi diluncurkan langsung ke dashboard
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeValidateToken();

        // Mulai timer untuk memeriksa sesi secara berkala (setiap 5 menit)
        _startSessionCheckTimer();
      });
    } catch (e, s) {
      LoggerUtil.e("Error initializing DashboardScreen screens", e, s);
    }
  }

  // Mulai timer untuk memeriksa validitas sesi secara berkala
  void _startSessionCheckTimer() {
    // Batalkan timer yang ada jika sudah berjalan
    _sessionCheckTimer?.cancel();

    // Buat timer baru yang berjalan setiap 5 menit
    _sessionCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      LoggerUtil.d("Running periodic session check...");
      _checkSessionValidity();
    });

    LoggerUtil.d("Session check timer started");
  }

  // Periksa validitas sesi dan redirect ke login jika tidak valid
  Future<void> _checkSessionValidity() async {
    if (!mounted) return;

    try {
      final isValid = await AuthApi.ApiService.checkSessionValidity();
      LoggerUtil.d(
          "Session validity check result: ${isValid ? 'valid' : 'invalid'}");

      if (!isValid && mounted) {
        LoggerUtil.i("Session invalid, redirecting to login screen");
        // Navigasi ke login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      LoggerUtil.e("Error checking session validity", e);
    }
  }

  @override
  void dispose() {
    // Batalkan timer saat widget dihapus
    _sessionCheckTimer?.cancel();
    super.dispose();
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
      LoggerUtil.e("Error building $screenName", e, s);

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
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Refresh screen by rebuilding it
                _dashboardController.refreshState();
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                'Refresh',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF213268),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    SnackbarUtil.showError(context, message);
  }

  // Update the _onWillPop method to handle hierarchical navigation
  // Show exit confirmation dialog
  Future<bool> _onWillPop() async {
    // Check if current tab has navigation history to go back to
    if (_dashboardController.hasHistory()) {
      // Pop from history and navigate back
      final previousScreen = _dashboardController.popFromHistory();
      LoggerUtil.i("Going back to previous screen: $previousScreen");

      // In a real implementation, we would navigate to that screen here
      // For now, we just return false to prevent app exit
      return false;
    }

    // If we're not on the home tab, navigate to home tab
    if (_dashboardController.selectedIndex != 0) {
      _dashboardController.setSelectedIndex(0);
      return false;
    }

    // If the last back press was less than 2 seconds ago, show exit confirmation
    if (_lastBackPressTime != null &&
        DateTime.now().difference(_lastBackPressTime!) <
            const Duration(seconds: 2)) {
      return await _showExitConfirmation(context);
    } else {
      // Update the last back press time
      _lastBackPressTime = DateTime.now();
      SnackbarUtil.showSnackbar(
        context,
        'Tekan sekali lagi untuk keluar',
        duration: const Duration(seconds: 2),
      );
      return false;
    }
  }

  // Show exit confirmation dialog
  Future<bool> _showExitConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Konfirmasi Keluar',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF213268),
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari aplikasi?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF213268),
            ),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
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

        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            appBar: const CustomAppBar(),
            body: _screens[controller.selectedIndex],
            floatingActionButton: isKeyboardVisible
                ? null
                : SizedBox(
                    width: 84,
                    height: 84,
                    child: FloatingActionButton(
                      elevation:
                          4, // Slightly higher elevation for better visibility
                      backgroundColor: const Color(0xFF203268),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(42),
                        side: const BorderSide(
                          color: Color(0xFF25B1FF),
                          width: 6,
                        ),
                      ),
                      onPressed: () {
                        try {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QRScannerScreen(
                                previousScreen:
                                    controller.getPreviousScreenName(),
                              ),
                            ),
                          ).then((_) {
                            // Refresh state jika diperlukan
                            if (mounted) {
                              controller.refreshState();
                            }
                          }).catchError((error) {
                            LoggerUtil.e('Error navigating to QR scanner',
                                error, StackTrace.current);
                            if (mounted) {
                              showError(
                                  'Error membuka scanner QR: ${error.toString()}');
                            }
                          });
                        } catch (e) {
                          LoggerUtil.e('Error opening QR scanner', e,
                              StackTrace.current);
                          showError(
                              'Error membuka scanner QR: ${e.toString()}');
                        }
                      },
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors
                            .white, // Better contrast with white instead of light blue
                        size: 30, // Slightly larger icon
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
                onTap: (index) {
                  // Do nothing if the center button is tapped
                  if (index == 2) return;
                  controller.setSelectedIndex(index);
                },
                type: BottomNavigationBarType.fixed,
                selectedItemColor: const Color(0xFF213268),
                unselectedItemColor:
                    Colors.grey[700], // Darker color for better contrast
                backgroundColor: Colors.white,
                elevation: 8,
                selectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                ),
                iconSize: 28, // Larger icons
                items: [
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(
                          bottom: 4), // Add padding for larger tap target
                      child: const Icon(Icons.home),
                    ),
                    label: 'Beranda',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(
                          bottom: 4), // Add padding for larger tap target
                      child: const Icon(Icons.inventory),
                    ),
                    label: 'Opname',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(
                          bottom: 4), // Add padding for larger tap target
                      child: const Icon(Icons.qr_code_scanner,
                          color: Colors.transparent),
                    ),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(
                          bottom: 4), // Add padding for larger tap target
                      child: const Icon(Icons.report_problem),
                    ),
                    label: 'Keluhan',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(
                          bottom: 4), // Add padding for larger tap target
                      child: const Icon(Icons.person),
                    ),
                    label: 'Profil',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
