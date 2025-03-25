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

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // Inisialisasi screens dengan cara yang lebih aman
    _screens.addAll([
      const HomeScreen(),
      const ProcurementScreen(),
      const SizedBox(), // Placeholder for QR Scanner
      const HistoryScreen(),
      const ProfileScreen(),
    ]);
  }

  void _onItemTapped(int index) {
    if (index == 2) return; // Ignore QR Scanner tab
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pastikan _selectedIndex valid
    if (_selectedIndex >= _screens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF213268),
        unselectedItemColor: Colors.grey,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
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
