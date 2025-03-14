class NetAssetValue {
  final String totalNetValue;

  NetAssetValue({
    required this.totalNetValue,
  });

  factory NetAssetValue.fromJson(Map<String, dynamic> json) {
    return NetAssetValue(
      totalNetValue: json['data']['net_aset_value'] ?? 'Rp. 0',
    );
  }
}
