import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// A utility class for logging using the logger package
class LoggerUtil {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls if stacktrace is provided
      lineLength: 120, // Width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      printTime: true, // Should each log print contain a timestamp
    ),
    // Use a simpler printer for release mode
    level: kDebugMode ? Level.verbose : Level.warning,
  );

  // Use this for general debug logs
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  // Use this for informational logs
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  // Use this for warning logs
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  // Use this for error logs
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  // Use this for critical error logs
  static void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  // Use this for verbose logs (detailed information)
  static void v(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.v(message, error: error, stackTrace: stackTrace);
  }

  // A helper method to log API requests
  static void logApiRequest(String method, String url, {dynamic body}) {
    if (body != null) {
      _logger.i('API Request: $method $url\nBody: $body');
    } else {
      _logger.i('API Request: $method $url');
    }
  }

  // A helper method to log API responses
  static void logApiResponse(
      String method, String url, int statusCode, dynamic responseBody) {
    if (statusCode >= 200 && statusCode < 300) {
      _logger
          .i('API Response: $method $url ($statusCode)\nBody: $responseBody');
    } else {
      _logger.e('API Error: $method $url ($statusCode)\nBody: $responseBody');
    }
  }
}
