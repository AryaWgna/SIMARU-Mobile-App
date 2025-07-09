class TotalAsset {
  final String totalAssets;

  TotalAsset({
    required this.totalAssets,
  });

  factory TotalAsset.fromJson(Map<String, dynamic> json) {
    return TotalAsset(
      totalAssets: json['data']['assets'] ?? '0',
    );
  }
} 