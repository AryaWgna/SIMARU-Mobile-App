import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'auth_controller.dart';
import '../utils/logger_util.dart';

class ProfileController extends ChangeNotifier {
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  final _storage = const FlutterSecureStorage();

  // Getters
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Load user profile data
  Future<void> loadUserData(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      LoggerUtil.i("Fetching user profile data...");

      // Try to get from API first
      try {
        final userData = await ApiService.getProfile(context);
        _profile = userData;
        _isLoading = false;
        _errorMessage = null; // Make sure to clear any previous errors
        notifyListeners();
        return;
      } catch (e) {
        LoggerUtil.w("Error fetching from API", e);

        // If API fails, try to get from secure storage
        try {
          final userId = await _storage.read(key: 'user_id');
          final employeeNumber = await _storage.read(key: 'employee_number');
          final rolesString = await _storage.read(key: 'roles');

          if (employeeNumber != null) {
            final Map<String, dynamic> userData = {
              'user_id': userId,
              'employee_number': employeeNumber,
              'roles': rolesString != null ? json.decode(rolesString) : [],
            };

            _profile = userData;
            _isLoading = false;
            _errorMessage = null; // Clear any previous errors
            notifyListeners();
            return;
          } else {
            throw Exception(
                'Data karyawan tidak ditemukan di penyimpanan lokal');
          }
        } catch (storageError) {
          LoggerUtil.e("Error reading from secure storage", storageError,
              StackTrace.current);
          throw Exception(
              'Gagal membaca data profil: ${storageError.toString()}');
        }
      }
    } catch (e) {
      LoggerUtil.e("Error loading user data", e, StackTrace.current);
      String displayError = e.toString();

      // Clean up the error message
      if (displayError.contains('Exception: ')) {
        displayError = displayError.replaceAll('Exception: ', '');
      }

      _errorMessage = displayError;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout user
  Future<bool> logout(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Perform logout with API
      final result = await ApiService.logout(context);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      LoggerUtil.e("Error during logout", e, StackTrace.current);

      String displayError = e.toString();
      if (displayError.contains('Exception: ')) {
        displayError = displayError.replaceAll('Exception: ', '');
      }

      _errorMessage = displayError;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset controller state
  void reset() {
    _profile = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
