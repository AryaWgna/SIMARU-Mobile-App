class ApiConfig {
  // Base URL untuk API lokal di emulator
  static const String baseUrl =
      'https://web-magangunbin2025.rsummi.co.id/api/'; // Special IP for Android Emulator

  // Endpoint API untuk autentikasi yang sudah diperbarui
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh-token';

  // Endpoint API lainnya
  static const String assetsEndpoint = '/assets';

  // Timeout untuk permintaan API (dalam detik)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  // Endpoint URLs
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get logoutUrl => '$baseUrl$logoutEndpoint';
  static String get refreshTokenUrl => '$baseUrl$refreshTokenEndpoint';
  static String get profileUrl => '$baseUrl/user/profile';
  static String get complaintsUrl => '$baseUrl/complaints';

  static String getUserUrl(String userId) => '$baseUrl/users/$userId';
  static String getComplaintByIdUrl(String id) => '$baseUrl/complaints/$id';
  static String getUserComplaintsUrl(String userId) =>
      '$baseUrl/complaints/user/$userId';

  // Add endpoint for dashboard summary
  static String get dashboardSummaryUrl => '$baseUrl/dashboard/summary';

  // Add new endpoint for depreciation total value
  static String getDepreciationTotalUrl({int? year, int? month}) {
    String url = '$baseUrl/depreciations/total-value';
    List<String> params = [];

    if (year != null) params.add('year=$year');
    if (month != null) params.add('month=$month');

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    return url;
  }

  // Add new endpoint for history
  static String getHistoryUrl(String date, {String? page, String? limit}) {
    String url = '$baseUrl/asset-histories/activities/user/1';

    List<String> params = [];
    if (date.isNotEmpty) params.add('date=$date');
    if (page != null) params.add('page=$page');
    if (limit != null) params.add('limit=$limit');

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    return url;
  }

  // Tambahkan endpoint lain sesuai kebutuhan aplikasi Anda
  // static String get maintenanceUrl => '$baseUrl/maintenance';
  // static String get procurementUrl => '$baseUrl/procurement';

  // Helper untuk endpoint dinamis
  static String getEndpointUrl(String endpoint) {
    return '$baseUrl/$endpoint';
  }
}
