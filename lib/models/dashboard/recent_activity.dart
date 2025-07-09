class RecentActivity {
  final String assetId;
  final String date;
  final String time;
  final String oldStatus;
  final String newStatus;

  RecentActivity({
    required this.assetId,
    required this.date,
    required this.time,
    required this.oldStatus,
    required this.newStatus,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      assetId: json['asset_id'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      oldStatus: json['old_status'] ?? '',
      newStatus: json['new_status'] ?? '',
    );
  }
}
