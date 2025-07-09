import 'package:flutter/material.dart';
import '../../auth/login.dart';
import '../auth/auth_controller.dart' as auth;
import 'package:no_screenshot/no_screenshot.dart';
import 'dart:io';
import '../../utils/logger_util.dart';

class DashboardController extends ChangeNotifier {
  int _selectedIndex = 0;
  int _previousIndex = 0; // Track previous tab index

  // Navigation history for each tab
  final List<List<String>> _navigationHistory = [
    [], // Home tab history
    [], // Stockopname tab history
    [], // QR Scanner tab history (unused)
    [], // Complaint tab history
    [], // Profile tab history
  ];

  String? _errorMessage;
  bool _tokenChecked = false;
  final NoScreenshot _noScreenshot = NoScreenshot();
  bool _tabChangeInProgress = false; // Flag to prevent rapid tab changes

  // Getters
  int get selectedIndex => _selectedIndex;
  int get previousIndex => _previousIndex;
  String? get errorMessage => _errorMessage;
  bool get tokenChecked => _tokenChecked;
  bool get tabChangeInProgress => _tabChangeInProgress;

  // Get navigation history for current tab
  List<String> get currentTabHistory => _navigationHistory[_selectedIndex];

  // Push a screen to the current tab's navigation history
  void pushToHistory(String screenName) {
    if (_selectedIndex == 2) return; // Ignore QR Scanner tab

    _navigationHistory[_selectedIndex].add(screenName);
    LoggerUtil.i(
        "Added $screenName to tab $_selectedIndex history. History now: ${_navigationHistory[_selectedIndex]}",
        "NAVIGATION");
  }

  // Pop from the current tab's navigation history
  // Returns the previous screen name, or null if history is empty
  String? popFromHistory() {
    if (_selectedIndex == 2) return null; // Ignore QR Scanner tab

    if (_navigationHistory[_selectedIndex].isNotEmpty) {
      _navigationHistory[_selectedIndex].removeLast();
      final String? previousScreen =
          _navigationHistory[_selectedIndex].isNotEmpty
              ? _navigationHistory[_selectedIndex].last
              : null;

      LoggerUtil.i(
          "Popped from tab $_selectedIndex history. History now: ${_navigationHistory[_selectedIndex]}",
          "NAVIGATION");
      return previousScreen;
    }
    return null;
  }

  // Check if current tab has navigation history
  bool hasHistory() {
    return _navigationHistory[_selectedIndex].length > 1;
  }

  // Clear history for a specific tab
  void clearTabHistory(int tabIndex) {
    if (tabIndex >= 0 && tabIndex < _navigationHistory.length) {
      _navigationHistory[tabIndex].clear();
      LoggerUtil.i("Cleared history for tab $tabIndex", "NAVIGATION");
    }
  }

  // Setter untuk selected index
  void setSelectedIndex(int index) {
    // If tab change is already in progress, prevent rapid changes
    if (_tabChangeInProgress) {
      LoggerUtil.d(
          "DashboardController: Tab change already in progress, ignoring change to $index");
      return;
    }

    // Ignore QR Scanner tab (index 2)
    if (index == 2) {
      LoggerUtil.d("DashboardController: Ignoring QR Scanner tab selection");
      return;
    }

    // Set flag to prevent rapid tab changes
    _tabChangeInProgress = true;

    // Store previous index
    _previousIndex = _selectedIndex;

    // Update to new index
    _selectedIndex = index;

    LoggerUtil.i(
        "DashboardController: Tab changed from $_previousIndex to $_selectedIndex");
    notifyListeners();

    // Reset flag after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _tabChangeInProgress = false;
    });
  }

  // Go back to previous tab
  void goToPreviousTab() {
    if (_previousIndex != _selectedIndex && _previousIndex != 2) {
      LoggerUtil.i(
          "DashboardController: Returning to previous tab $_previousIndex");
      _selectedIndex = _previousIndex;
      notifyListeners();
    } else {
      LoggerUtil.d(
          "DashboardController: No valid previous tab to return to, staying at $_selectedIndex");
    }
  }

  // Method untuk menonaktifkan fitur anti-screenshot yang mungkin masih aktif
  Future<void> disableAnyActiveScreenshotProtection() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        LoggerUtil.i("Dashboard: Memastikan anti-screenshot dinonaktifkan");
        await _noScreenshot.screenshotOn();
        LoggerUtil.i("Dashboard: Anti-screenshot berhasil dinonaktifkan");
      }
    } catch (e) {
      LoggerUtil.e("Dashboard: Error saat menonaktifkan anti-screenshot", e,
          StackTrace.current);
    }
  }

  // Validasi token hanya jika diperlukan
  Future<bool> maybeValidateToken() async {
    // Skip validasi jika sudah dicek atau token sudah ada dari login screen
    if (_tokenChecked) return true;

    LoggerUtil.i("DashboardController: Validating token...");
    try {
      // First check if we have a token
      final isLoggedIn = await auth.ApiService.isLoggedIn();
      if (!isLoggedIn) {
        LoggerUtil.w("DashboardController: No token found, need to login");
        // Token tidak valid, perlu navigasi ke login
        return false;
      }

      // Then try to refresh the token to ensure it's still valid
      LoggerUtil.d(
          "DashboardController: Token found, refreshing to validate...");
      final refreshSuccess = await auth.ApiService.refreshToken();
      if (!refreshSuccess) {
        LoggerUtil.w(
            "DashboardController: Token refresh failed, need to login");
        return false;
      }

      // Finally, try to get user profile as a final validation
      try {
        LoggerUtil.d(
            "DashboardController: Fetching profile to verify token...");
        await auth.ApiService.getProfile(
            auth.ApiService.navigatorKey.currentContext!);
        LoggerUtil.i(
            "DashboardController: Profile fetch successful, token is valid");
      } catch (e) {
        LoggerUtil.e("DashboardController: Error fetching profile", e,
            StackTrace.current);
        // If profile fetch fails due to token issues, return false
        if (e.toString().contains("401") ||
            e.toString().contains("SESSION_EXPIRED")) {
          LoggerUtil.w(
              "DashboardController: Token appears to be invalid based on profile fetch");
          return false;
        }
        // Otherwise continue despite profile fetch error
      }

      // Token ada dan valid - tandai sudah dicek
      LoggerUtil.i("DashboardController: Token validation successful");
      _tokenChecked = true;
      notifyListeners();
      return true;
    } catch (e) {
      LoggerUtil.e(
          "DashboardController: Error validating token", e, StackTrace.current);
      _tokenChecked = true;
      notifyListeners();
      return false; // Return false on error to be safe
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
