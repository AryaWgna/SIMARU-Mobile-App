class ApiConfig {
  // Base URL untuk API
  static const String baseUrl =
      'https://12d9aa80-068d-4c47-a664-b62f5cad5ec5.mock.pstmn.io';

  // Endpoint URLs
  static String get loginUrl => '$baseUrl/auth/login';
  static String get refreshTokenUrl => '$baseUrl/auth/refresh-token';
  static String get profileUrl => '$baseUrl/user/profile';
  static String get logoutUrl => '$baseUrl/auth/logout';

  // Tambahkan endpoint lain sesuai kebutuhan aplikasi Anda
  // static String get maintenanceUrl => '$baseUrl/maintenance';
  // static String get procurementUrl => '$baseUrl/procurement';

  // Helper untuk endpoint dinamis
  static String getEndpointUrl(String endpoint) {
    return '$baseUrl/$endpoint';
  }
}
