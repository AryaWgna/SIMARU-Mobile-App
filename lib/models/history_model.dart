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
