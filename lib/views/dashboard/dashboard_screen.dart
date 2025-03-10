import 'package:flutter/material.dart';
import '../dashboard/home_screen.dart';
import '../procurement/procurement_screen.dart';
import '../history/history_screen.dart';
import '../qr_scanner/qr_scanner_screen.dart';
import '../pages/profile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 2) {
      // Navigate to QR Scanner screen when the center button is pressed
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerScreen()),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomeScreen(),
          const ProcurementScreen(),
          const SizedBox(), // Placeholder for QR Scanner
          const HistoryScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        backgroundColor: const Color(0xFF203268),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(42),
          side: const BorderSide(
            color: Color(0xFF25B1FF),
            width: 6,
          ),
        ),
        child: const Icon(
          Icons.qr_code_scanner,
          color: Color(0xFFACC3EF),
          size: 24,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRScannerScreen()),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Procurement',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.qr_code_scanner, color: Colors.transparent),
            ),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1A237E),
        unselectedItemColor: Colors.grey[600],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}
