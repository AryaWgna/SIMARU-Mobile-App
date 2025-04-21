import 'package:flutter/material.dart';
import '../pages/profile.dart';
import '../pages/home_screen.dart';
import '../pages/qr_scanner_screen.dart';
import '../stockopname/stockopname_task_list.dart';
import '../complain/complain_list_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/today_activities_widget.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;

  const DashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _selectedIndex;
  final List<Widget> _screens = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    try {
      print("Initializing DashboardScreen screens...");
      _screens.addAll([
        _buildScreenWithErrorHandling(() => const HomeScreen(), 'HomeScreen'),
        _buildScreenWithErrorHandling(
            () => const StockopnameTaskList(), 'StockopnameTaskList'),
        const SizedBox(), // Placeholder for QR Scanner
        _buildScreenWithErrorHandling(
            () => const ComplainListScreen(), 'ComplainListScreen'),
        _buildScreenWithErrorHandling(
            () => const ProfileScreen(), 'ProfileScreen'),
      ]);
      print("DashboardScreen screens initialized successfully");
    } catch (e, s) {
      print("Error initializing DashboardScreen screens: $e");
      print("Stack trace: $s");
    }
  }

  Widget _buildScreenWithErrorHandling(Function builder, String screenName) {
    try {
      Widget screen = builder();
      // No need for bottom padding now that we're using bottomNavigationBar
      return screen;
    } catch (e, s) {
      print("Error building $screenName: $e");
      print("Stack trace: $s");
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
                setState(() {});
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

  void _onItemTapped(int index) {
    if (index == 2) return; // Ignore QR Scanner tab
    setState(() {
      _selectedIndex = index;
    });
  }

  void showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(82),
        child: CustomAppBar(),
      ),
      body: Stack(
        children: [
          _screens[_selectedIndex],
          if (_errorMessage != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Colors.red[900],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton:
          !isKeyboardVisible && MediaQuery.of(context).viewPadding.bottom == 0
              ? SizedBox(
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
                      String previousScreen;
                      switch (_selectedIndex) {
                        case 0:
                          previousScreen = 'home';
                          break;
                        case 1:
                          previousScreen = 'stockopname';
                          break;
                        case 3:
                          previousScreen = 'repair';
                          break;
                        case 4:
                          previousScreen = 'profile';
                          break;
                        default:
                          previousScreen = 'home';
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              QRScannerScreen(previousScreen: previousScreen),
                        ),
                      ).then((_) {
                        setState(() {
                          // Refresh state jika diperlukan
                        });
                      });
                    },
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Color(0xFFACC3EF),
                      size: 24,
                    ),
                  ),
                )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
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
              label: 'Stok',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner, color: Colors.transparent),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem),
              label: 'Komplain dan Laporan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
