class HistoryModel {
  final int historyId;
  final DateTime actionDate;
  final UserInfo user;
  final String message;
  final String actionType;
  final String oldStatus;
  final String newStatus;
  final AssetInfo assetInfo;

  HistoryModel({
    required this.historyId,
    required this.actionDate,
    required this.user,
    required this.message,
    required this.actionType,
    required this.oldStatus,
    required this.newStatus,
    required this.assetInfo,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      historyId: json['history_id'],
      actionDate: DateTime.parse(json['action_date']),
      user: UserInfo.fromJson(json['user']),
      message: json['message'],
      actionType: json['action_type'],
      oldStatus: json['old_status'],
      newStatus: json['new_status'],
      assetInfo: AssetInfo.fromJson(json['asset_info']),
    );
  }

  // Get month year string for grouping
  String get monthYearString {
    return '${_getMonthName(actionDate.month)} ${actionDate.year}';
  }

  // Get month name
  static String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

class UserInfo {
  final int userId;
  final String email;
  final EmployeeInfo employee;

  UserInfo({
    required this.userId,
    required this.email,
    required this.employee,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['user_id'],
      email: json['email'],
      employee: EmployeeInfo.fromJson(json['employee']),
    );
  }
}

class EmployeeInfo {
  final String name;
  final String position;
  final String departmentName;

  EmployeeInfo({
    required this.name,
    required this.position,
    required this.departmentName,
  });

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      name: json['name'],
      position: json['position'],
      departmentName: json['department_name'],
    );
  }
}

class AssetInfo {
  final int assetId;
  final String assetName;
  final String assetCode;

  AssetInfo({
    required this.assetId,
    required this.assetName,
    required this.assetCode,
  });

  factory AssetInfo.fromJson(Map<String, dynamic> json) {
    return AssetInfo(
      assetId: json['asset_id'],
      assetName: json['asset_name'],
      assetCode: json['asset_code'],
    );
  }
}

class HistoryPagination {
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final int limit;
  final bool hasNext;
  final bool hasPrev;

  HistoryPagination({
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    required this.limit,
    required this.hasNext,
    required this.hasPrev,
  });

  factory HistoryPagination.fromJson(Map<String, dynamic> json) {
    return HistoryPagination(
      totalItems: json['total_items'],
      totalPages: json['total_pages'],
      currentPage: json['current_page'],
      limit: json['limit'],
      hasNext: json['has_next'],
      hasPrev: json['has_prev'],
    );
  }
}
