import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'auth_controller.dart';

class ProfileController extends ChangeNotifier {
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  final _storage = const FlutterSecureStorage();

  // Getters
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load user profile data
  Future<void> loadUserData(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("Fetching user profile data...");

      // Try to get from API first
      try {
        final userData = await ApiService.getProfile(context);
        _profile = userData;
        _isLoading = false;
        notifyListeners();
        return;
      } catch (e) {
        print("Error fetching from API: $e");

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
            notifyListeners();
            return;
          }
        } catch (storageError) {
          print("Error reading from secure storage: $storageError");
        }
      }

      // If all methods fail
      throw Exception('Tidak dapat memuat data profil');
    } catch (e) {
      print("Error loading user data: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout user
  Future<bool> logout(BuildContext context) async {
    try {
      // Perform logout with API without showing loading indicator
      final result = await ApiService.logout(context);
      return true;
    } catch (e) {
      print("Error during logout: $e");
      _errorMessage = e.toString();
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
