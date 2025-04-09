import 'package:flutter/material.dart';
import '../models/calibration_model.dart';
import 'auth_controller.dart';
import 'dart:convert';

class CalibrationController extends ChangeNotifier {
  List<Calibration> _calibrations = [];
  Calibration? _selectedCalibration;
  bool _isLoading = false;
  String? _error;
  Pagination? _pagination;

  List<Calibration> get calibrations => _calibrations;
  Calibration? get selectedCalibration => _selectedCalibration;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Pagination? get pagination => _pagination;

  Future<void> loadCalibrations(BuildContext context) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await ApiService.get('/calibrations', context: context);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final calibrationResponse = CalibrationResponse.fromJson(jsonResponse);

        if (calibrationResponse.success) {
          _calibrations = calibrationResponse.data;
          _pagination = calibrationResponse.pagination;
          _error = null;
        } else {
          _error = calibrationResponse.message;
        }
      } else {
        _error = 'Failed to load calibrations';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Calibration?> getCalibrationById(BuildContext context, int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response =
          await ApiService.get('/calibrations/$id', context: context);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          _selectedCalibration = Calibration.fromJson(jsonResponse['data']);
          _error = null;
          return _selectedCalibration;
        } else {
          _error =
              jsonResponse['message'] ?? 'Failed to load calibration details';
          return null;
        }
      } else {
        _error = 'Failed to load calibration details';
        return null;
      }
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCalibration(
      BuildContext context, int id, Map<String, dynamic> data,
      {String? filePath}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await ApiService.put(
        '/calibrations/$id',
        body: data,
        context: context,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          // Refresh calibration data
          await getCalibrationById(context, id);
          return true;
        }
      }
      _error = 'Failed to update calibration';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelectedCalibration() {
    _selectedCalibration = null;
    notifyListeners();
  }
}
