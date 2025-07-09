import 'package:intl/intl.dart';

class NetAssetModel {
  final double totalAcquisitionCost;
  final double totalBookValue;
  final double totalDepreciation;
  final int assetCount;
  final int depreciableAssetCount;
  final String asOfDate;
  final String formattedTotalBookValue;
  final String formattedTotalDepreciation;

  NetAssetModel({
    required this.totalAcquisitionCost,
    required this.totalBookValue,
    required this.totalDepreciation,
    required this.assetCount,
    required this.depreciableAssetCount,
    required this.asOfDate,
    required this.formattedTotalBookValue,
    required this.formattedTotalDepreciation,
  });

  factory NetAssetModel.fromJson(Map<String, dynamic> json) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: '',
      decimalDigits: 0,
    );

    return NetAssetModel(
      totalAcquisitionCost: json['total_acquisition_cost'] != null
          ? json['total_acquisition_cost'].toDouble()
          : 0.0,
      totalBookValue: json['total_book_value'] != null
          ? json['total_book_value'].toDouble()
          : 0.0,
      totalDepreciation: json['total_depreciation'] != null
          ? json['total_depreciation'].toDouble()
          : 0.0,
      assetCount: json['asset_count'] ?? 0,
      depreciableAssetCount: json['depreciable_asset_count'] ?? 0,
      asOfDate: json['as_of_date'] ?? '-',
      formattedTotalBookValue:
          currencyFormatter.format(json['total_book_value'] ?? 0),
      formattedTotalDepreciation:
          currencyFormatter.format(json['total_depreciation'] ?? 0),
    );
  }
}
