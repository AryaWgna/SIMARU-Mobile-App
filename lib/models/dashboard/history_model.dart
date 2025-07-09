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
    final message = json['message'] as String;
    // Terjemahkan pesan status menjadi bahasa Indonesia
    String translatedMessage = message;

    if (message.contains('changed status from')) {
      translatedMessage =
          message.replaceAll('changed status from', 'mengubah status dari');
      translatedMessage = translatedMessage.replaceAll('to', 'menjadi');
      translatedMessage = translatedMessage.replaceAll('Available', 'Tersedia');
      translatedMessage =
          translatedMessage.replaceAll('Checked out', 'Dipinjam');
      translatedMessage =
          translatedMessage.replaceAll('Returned', 'Dikembalikan');
      translatedMessage =
          translatedMessage.replaceAll('In Repair', 'Dalam Perbaikan');
      translatedMessage =
          translatedMessage.replaceAll('Disposed', 'Dimusnahkan');
    }

    // Parse the action date and convert to local time
    DateTime parsedActionDate;
    try {
      // Parse the ISO string from the API
      parsedActionDate = DateTime.parse(json['action_date']);
      // Convert to local time zone
      parsedActionDate = parsedActionDate.toLocal();
    } catch (e) {
      // Fallback to current time if parsing fails
      parsedActionDate = DateTime.now();
    }

    return HistoryModel(
      historyId: json['history_id'],
      actionDate: parsedActionDate,
      user: UserInfo.fromJson(json['user']),
      message: translatedMessage,
      actionType: json['action_type'],
      oldStatus: _translateStatus(json['old_status']),
      newStatus: _translateStatus(json['new_status']),
      assetInfo: AssetInfo.fromJson(json['asset_info']),
    );
  }

  static String _translateStatus(String status) {
    switch (status) {
      case 'Available':
        return 'Tersedia';
      case 'Checked out':
        return 'Dipinjam';
      case 'Returned':
        return 'Dikembalikan';
      case 'In Repair':
        return 'Dalam Perbaikan';
      case 'Disposed':
        return 'Dimusnahkan';
      default:
        return status;
    }
  }

  // Get month year string for grouping
  String get monthYearString {
    return '${_getIndonesianMonthName(actionDate.month)} ${actionDate.year}';
  }

  // Get month name in Indonesian
  static String _getIndonesianMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return months[month - 1];
  }
}

class UserInfo {
  final int userId;
  final String employeeNumber;

  UserInfo({
    required this.userId,
    required this.employeeNumber,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['user_id'],
      employeeNumber: json['employee_number'] ?? '',
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
