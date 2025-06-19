import 'package:flutter/material.dart';
import '../auth/login.dart';
import '../controllers/auth_controller.dart' as auth;
import 'package:no_screenshot/no_screenshot.dart';
import 'dart:io';

class DashboardController extends ChangeNotifier {
  int _selectedIndex = 0;
  String? _errorMessage;
  bool _tokenChecked = false;
  final NoScreenshot _noScreenshot = NoScreenshot();

  // Getters
  int get selectedIndex => _selectedIndex;
  String? get errorMessage => _errorMessage;
  bool get tokenChecked => _tokenChecked;

  // Setter untuk selected index
  void setSelectedIndex(int index) {
    if (index == 2) return; // Ignore QR Scanner tab
    _selectedIndex = index;
    notifyListeners();
  }

  // Method untuk menonaktifkan fitur anti-screenshot yang mungkin masih aktif
  Future<void> disableAnyActiveScreenshotProtection() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        print("Dashboard: Memastikan anti-screenshot dinonaktifkan");
        await _noScreenshot.screenshotOn();
        print("Dashboard: Anti-screenshot berhasil dinonaktifkan");
      }
    } catch (e) {
      print("Dashboard: Error saat menonaktifkan anti-screenshot: $e");
    }
  }

  // Validasi token hanya jika diperlukan
  Future<bool> maybeValidateToken() async {
    // Skip validasi jika sudah dicek atau token sudah ada dari login screen
    if (_tokenChecked) return true;

    try {
      final isLoggedIn = await auth.ApiService.isLoggedIn();
      if (!isLoggedIn) {
        // Token tidak valid, perlu navigasi ke login
        return false;
      }

      // Token ada dan valid - tandai sudah dicek
      _tokenChecked = true;
      notifyListeners();
      return true;
    } catch (e) {
      print("Error validating token: $e");
      _tokenChecked = true;
      notifyListeners();
      return true; // Tetap lanjutkan meski ada error
    }
  }

  // Menampilkan error dan mengaturnya untuk hilang setelah beberapa detik
  void showError(String message) {
    _errorMessage = message;
    notifyListeners();

    // Clear error message setelah beberapa waktu
    Future.delayed(const Duration(seconds: 3), () {
      _errorMessage = null;
      notifyListeners();
    });
  }

  // Method untuk mendapatkan nama previous screen berdasarkan tab yang aktif
  String getPreviousScreenName() {
    switch (_selectedIndex) {
      case 0:
        return 'home';
      case 1:
        return 'stockopname';
      case 3:
        return 'repair';
      case 4:
        return 'profile';
      default:
        return 'home';
    }
  }

  // Method untuk refresh state
  void refreshState() {
    notifyListeners();
  }
}
