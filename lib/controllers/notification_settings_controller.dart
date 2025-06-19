import 'package:flutter/material.dart';
import '../services/firebase_messaging_service.dart';

class NotificationSettingsController extends ChangeNotifier {
  String? _fcmToken;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Mengambil token FCM
  Future<void> getToken(
      BuildContext context, FirebaseMessagingService messagingService) async {
    _isLoading = true;
    notifyListeners();

    try {
      _fcmToken = messagingService.token;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Gagal memuat token: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mengirim token ke server
  Future<bool> sendTokenToServer(BuildContext context,
      FirebaseMessagingService messagingService, String authToken) async {
    _isLoading = true;
    notifyListeners();

    try {
      await messagingService.sendFcmTokenToServer(authToken);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Gagal mengirim token: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset controller state
  void reset() {
    _fcmToken = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
