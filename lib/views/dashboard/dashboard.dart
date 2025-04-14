import 'package:flutter/material.dart';
import '../pages/profile.dart';
import '../pages/home_screen.dart';
import '../pages/qr_scanner_screen.dart';
import '../stockopname/stockopname_task_list.dart';
import '../complain/complain_list_screen.dart';

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
      return builder();
    } catch (e, s) {
      print("Error building $screenName: $e");
      print("Stack trace: $s");
      return Center(
        child: Text(
          'Kesalahan memuat $screenName: $e',
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: Colors.white,
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
                        icon: Icon(Icons.qr_code_scanner,
                            color: Colors.transparent),
                        label: '',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.build),
                        label: 'Perbaikan',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person),
                        label: 'Profil',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isKeyboardVisible &&
              MediaQuery.of(context).viewPadding.bottom == 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(
                child: SizedBox(
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
                      );
                    },
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Color(0xFFACC3EF),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
