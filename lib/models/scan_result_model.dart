class AssetScanDetail {
  final int detailId;
  final int opnameId;
  final String opnameCode;
  final int assetId;
  final String assetCode;
  final String assetDescription;
  final String? scanDate;
  final String scanStatus;
  final int? actualLocationId;
  final int? expectedLocationId;
  final String? expectedLocationName;
  final int? scannedBy;
  final String? scannerName;
  final String? notes;

  AssetScanDetail({
    required this.detailId,
    required this.opnameId,
    required this.opnameCode,
    required this.assetId,
    required this.assetCode,
    required this.assetDescription,
    this.scanDate,
    required this.scanStatus,
    this.actualLocationId,
    this.expectedLocationId,
    this.expectedLocationName,
    this.scannedBy,
    this.scannerName,
    this.notes,
  });

  factory AssetScanDetail.fromJson(Map<String, dynamic> json) {
    return AssetScanDetail(
      detailId: json['detail_id'],
      opnameId: json['opname_id'],
      opnameCode: json['opname_code'],
      assetId: json['asset_id'],
      assetCode: json['asset_code'],
      assetDescription: json['asset_description'],
      scanDate: json['scan_date'],
      scanStatus: json['scan_status'],
      actualLocationId: json['actual_location_id'],
      expectedLocationId: json['expected_location_id'],
      expectedLocationName: json['expected_location_name'],
      scannedBy: json['scanned_by'],
      scannerName: json['scanner_name'],
      notes: json['notes'],
    );
  }
}

class SummaryData {
  final int totalAssets;
  final int scannedAssets;
  final int foundAssets;
  final int missingAssets;
  final int misplacedAssets;

  SummaryData({
    required this.totalAssets,
    required this.scannedAssets,
    required this.foundAssets,
    required this.missingAssets,
    required this.misplacedAssets,
  });

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    return SummaryData(
      totalAssets: json['total_assets'],
      scannedAssets: json['scanned_assets'],
      foundAssets: json['found_assets'],
      missingAssets: json['missing_assets'],
      misplacedAssets: json['misplaced_assets'],
    );
  }
}

class RoomInfo {
  final int roomId;
  final String roomName;

  RoomInfo({required this.roomId, required this.roomName});

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      roomId: json['room_id'],
      roomName: json['room_name'],
    );
  }
}
