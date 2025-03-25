import 'package:flutter/material.dart';
import '../pages/profile.dart';
import '../pages/home_screen.dart';
import '../pages/procurement_screen.dart';
import '../pages/history_screen.dart';
import '../pages/qr_scanner_screen.dart';

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
      // Inisialisasi screens dengan cara yang lebih aman
      _screens.addAll([
        // Bungkus masing-masing dengan try-catch untuk mendeteksi error
        _buildScreenWithErrorHandling(() => const HomeScreen(), 'HomeScreen'),
        _buildScreenWithErrorHandling(
            () => const ProcurementScreen(), 'ProcurementScreen'),
        const SizedBox(), // Placeholder for QR Scanner
        _buildScreenWithErrorHandling(
            () => const HistoryScreen(), 'HistoryScreen'),
        _buildScreenWithErrorHandling(
            () => const ProfileScreen(), 'ProfileScreen'),
      ]);
      print("DashboardScreen screens initialized successfully");
    } catch (e, s) {
      print("Error initializing DashboardScreen screens: $e");
      print("Stack trace: $s");
    }
  }

  // Helper method to handle errors in screen initialization
  Widget _buildScreenWithErrorHandling(Function builder, String screenName) {
    try {
      return builder();
    } catch (e, s) {
      print("Error building $screenName: $e");
      print("Stack trace: $s");
      return Center(
        child: Text(
          'Error loading $screenName: $e',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
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
    // Hilangkan error setelah 3 detik
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
      body: Stack(
        children: [
          _screens[_selectedIndex],
          // Notifikasi error di bagian atas
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
      extendBody: true, // Penting untuk mencegah bottom overflow
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomNavigationBar(
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
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory),
                label: 'Procurement',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner, color: Colors.transparent),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton:
          isKeyboardVisible || MediaQuery.of(context).viewPadding.bottom > 0
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
                      String previousScreen;
                      switch (_selectedIndex) {
                        case 0:
                          previousScreen = 'home';
                          break;
                        case 1:
                          previousScreen = 'procurement';
                          break;
                        case 3:
                          previousScreen = 'history';
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
                      );
                    },
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Color(0xFFACC3EF),
                      size: 24,
                    ),
                  ),
                ),
    );
  }
}
