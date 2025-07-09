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
  final String? actualLocationName;
  final int? expectedLocationId;
  final String? expectedLocationName;
  final int? scannedBy;
  final String? scannerName;
  final String? notes;
  final String? assetMasterCode;
  final int? assetMasterId;
  final String? assetType;
  final String? referenceImagePath;

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
    this.actualLocationName,
    this.expectedLocationId,
    this.expectedLocationName,
    this.scannedBy,
    this.scannerName,
    this.notes,
    this.assetMasterCode,
    this.assetMasterId,
    this.assetType,
    this.referenceImagePath,
  });

  // Metode untuk membuat salinan objek dengan perubahan
  AssetScanDetail copyWith({
    int? detailId,
    int? opnameId,
    String? opnameCode,
    int? assetId,
    String? assetCode,
    String? assetDescription,
    String? scanDate,
    String? scanStatus,
    int? actualLocationId,
    String? actualLocationName,
    int? expectedLocationId,
    String? expectedLocationName,
    int? scannedBy,
    String? scannerName,
    String? notes,
    String? assetMasterCode,
    int? assetMasterId,
    String? assetType,
    String? referenceImagePath,
  }) {
    return AssetScanDetail(
      detailId: detailId ?? this.detailId,
      opnameId: opnameId ?? this.opnameId,
      opnameCode: opnameCode ?? this.opnameCode,
      assetId: assetId ?? this.assetId,
      assetCode: assetCode ?? this.assetCode,
      assetDescription: assetDescription ?? this.assetDescription,
      scanDate: scanDate ?? this.scanDate,
      scanStatus: scanStatus ?? this.scanStatus,
      actualLocationId: actualLocationId ?? this.actualLocationId,
      actualLocationName: actualLocationName ?? this.actualLocationName,
      expectedLocationId: expectedLocationId ?? this.expectedLocationId,
      expectedLocationName: expectedLocationName ?? this.expectedLocationName,
      scannedBy: scannedBy ?? this.scannedBy,
      scannerName: scannerName ?? this.scannerName,
      notes: notes ?? this.notes,
      assetMasterCode: assetMasterCode ?? this.assetMasterCode,
      assetMasterId: assetMasterId ?? this.assetMasterId,
      assetType: assetType ?? this.assetType,
      referenceImagePath: referenceImagePath ?? this.referenceImagePath,
    );
  }

  factory AssetScanDetail.fromJson(Map<String, dynamic> json) {
    return AssetScanDetail(
      detailId: json['detail_id'],
      opnameId: json['opname_id'] ?? 0,
      opnameCode: json['opname_code'] ?? '',
      assetId: json['asset_id'],
      assetCode: json['asset_code'],
      assetDescription: json['asset_description'] ?? json['asset_name'] ?? '',
      scanDate: json['scan_date'],
      scanStatus: json['scan_status'],
      actualLocationId: json['actual_location_id'],
      actualLocationName: json['actual_location_name'],
      expectedLocationId: json['expected_location_id'],
      expectedLocationName: json['expected_location_name'],
      scannedBy: json['scanned_by'],
      scannerName: json['scanner_name'],
      notes: json['notes'],
      assetMasterCode: json['asset_master_code'],
      assetMasterId: json['asset_master_id'],
      assetType: json['asset_type'],
      referenceImagePath: json['reference_image_path'],
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
  final String? roomType;
  final String? floor;
  final String? building;

  RoomInfo(
      {required this.roomId,
      required this.roomName,
      this.roomType,
      this.floor,
      this.building});

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      roomId: json['room_id'],
      roomName: json['room_name'],
      roomType: json['room_type'],
      floor: json['floor'],
      building: json['building'],
    );
  }
}

class OpnameInfo {
  final int opnameId;
  final String opnameCode;
  final String opnameCreatedAt;

  OpnameInfo({
    required this.opnameId,
    required this.opnameCode,
    required this.opnameCreatedAt,
  });

  factory OpnameInfo.fromJson(Map<String, dynamic> json) {
    return OpnameInfo(
      opnameId: json['opname_id'],
      opnameCode: json['opname_code'],
      opnameCreatedAt: json['opname_created_at'],
    );
  }
}
