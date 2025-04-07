class ApiConfig {
  // Base URL untuk API
  static const String baseUrl = 'http://localhost:8026';

  // Endpoint URLs
  static String get loginUrl => '$baseUrl/auth/login';
  static String get refreshTokenUrl => '$baseUrl/auth/refresh-token';
  static String get profileUrl => '$baseUrl/user/profile';
  static String get logoutUrl => '$baseUrl/auth/logout';

  // Add new endpoint for history
  static String getHistoryUrl(String date) =>
      '$baseUrl/asset-histories/activities/user/1?date=$date';

  // Tambahkan endpoint lain sesuai kebutuhan aplikasi Anda
  // static String get maintenanceUrl => '$baseUrl/maintenance';
  // static String get procurementUrl => '$baseUrl/procurement';

  // Helper untuk endpoint dinamis
  static String getEndpointUrl(String endpoint) {
    return '$baseUrl/$endpoint';
  }
}
