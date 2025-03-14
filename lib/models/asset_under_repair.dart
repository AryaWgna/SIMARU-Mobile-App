class AssetUnderRepair {
  final String totalUnderRepair;

  AssetUnderRepair({
    required this.totalUnderRepair,
  });

  factory AssetUnderRepair.fromJson(Map<String, dynamic> json) {
    return AssetUnderRepair(
      totalUnderRepair: json['data']['under_repair'] ?? '0',
    );
  }
} 