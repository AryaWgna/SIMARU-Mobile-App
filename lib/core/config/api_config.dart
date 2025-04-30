class ApiConfig {
  // URL API untuk lingkungan pengembangan
  static const String devApiUrl = 'http://api-dev.assets-tracker.com';

  // URL API untuk lingkungan produksi
  static const String prodApiUrl = 'https://api.assets-tracker.com';

  // Base URL untuk API lokal di emulator
  static const String baseUrl =
      'http://192.168.43.221:5000'; // Special IP for Android Emulator to access host machine

  // API URL aktif berdasarkan mode (development/production)
  static String get activeApiUrl {
    // Untuk pengembangan, gunakan localhost
    // Dalam produksi, ganti dengan URL server yang sebenarnya
    const bool isProduction = false;
    return isProduction ? prodApiUrl : baseUrl;
  }

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
  static String get loginUrl => '$activeApiUrl$loginEndpoint';
  static String get logoutUrl => '$activeApiUrl$logoutEndpoint';
  static String get refreshTokenUrl => '$activeApiUrl$refreshTokenEndpoint';
  static String get profileUrl => '$activeApiUrl/user/profile';
  static String get complaintsUrl => '$activeApiUrl/complaints';

  static String getUserUrl(String userId) => '$activeApiUrl/users/$userId';
  static String getComplaintByIdUrl(String id) =>
      '$activeApiUrl/complaints/$id';
  static String getUserComplaintsUrl(String userId) =>
      '$activeApiUrl/complaints/user/$userId';

  // Add endpoint for dashboard summary
  static String get dashboardSummaryUrl => '$activeApiUrl/dashboard/summary';

  // Add new endpoint for depreciation total value
  static String getDepreciationTotalUrl({int? year, int? month}) {
    String url = '$activeApiUrl/depreciations/total-value';
    List<String> params = [];

    if (year != null) params.add('year=$year');
    if (month != null) params.add('month=$month');

    if (params.isNotEmpty) {
      url += '?' + params.join('&');
    }

    return url;
  }

  // Add new endpoint for history
  static String getHistoryUrl(String date, {String? page, String? limit}) {
    String url = '$activeApiUrl/asset-histories/activities/user/1';

    List<String> params = [];
    if (date.isNotEmpty) params.add('date=$date');
    if (page != null) params.add('page=$page');
    if (limit != null) params.add('limit=$limit');

    if (params.isNotEmpty) {
      url += '?' + params.join('&');
    }

    return url;
  }

  // Tambahkan endpoint lain sesuai kebutuhan aplikasi Anda
  // static String get maintenanceUrl => '$baseUrl/maintenance';
  // static String get procurementUrl => '$baseUrl/procurement';

  // Helper untuk endpoint dinamis
  static String getEndpointUrl(String endpoint) {
    return '$activeApiUrl/$endpoint';
  }
}
