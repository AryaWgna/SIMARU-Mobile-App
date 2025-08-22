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

  // Additional detailed asset information to match StockOpnameItem
  final String? brandName;
  final String? model;
  final String? serialNumber;
  final String? pic;
  final String? category;
  final String? condition;
  final String?
      originalCondition; // Kondisi awal/sebelumnya sebelum ada perubahan
  final String? createdAt;
  final String? updatedAt;

  // Asset Master information (expanded)
  final String? assetMasterName;
  final String? description;
  final String? subcategoryName;
  final bool? isDepreciable;
  final bool? needsCalibration;

  // Physical asset details (expanded)
  final int? brandId;

  // Purchase information
  final String? purchaseDate;
  final String? purchaseCost;
  final String? warrantyEndDate;

  // Employee/PIC information (expanded)
  final int? userId;
  final String? employeeNumber;
  final String? employeeName;

  // Location details (expanded)
  final int? roomId;
  final String? roomName;
  final String? buildingName;
  final String? floorNumber;
  final String? expectedBuildingName;
  final String? expectedFloorNumber;

  // QR and timestamps (expanded)
  final String? qrCodePath;

  // Depreciation info
  final Map<String, dynamic>? depreciationInfo;

  // Current status info
  final String? currentStatus;

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
    // Additional detailed asset information
    this.brandName,
    this.model,
    this.serialNumber,
    this.pic,
    this.category,
    this.condition,
    this.originalCondition,
    this.createdAt,
    this.updatedAt,
    // Asset Master information (expanded)
    this.assetMasterName,
    this.description,
    this.subcategoryName,
    this.isDepreciable,
    this.needsCalibration,
    // Physical asset details (expanded)
    this.brandId,
    // Purchase information
    this.purchaseDate,
    this.purchaseCost,
    this.warrantyEndDate,
    // Employee/PIC information (expanded)
    this.userId,
    this.employeeNumber,
    this.employeeName,
    // Location details (expanded)
    this.roomId,
    this.roomName,
    this.buildingName,
    this.floorNumber,
    this.expectedBuildingName,
    this.expectedFloorNumber,
    // QR and timestamps (expanded)
    this.qrCodePath,
    // Depreciation info
    this.depreciationInfo,
    // Current status info
    this.currentStatus,
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
    // Additional detailed asset information
    String? brandName,
    String? model,
    String? serialNumber,
    String? pic,
    String? category,
    String? condition,
    String? originalCondition,
    String? createdAt,
    String? updatedAt,
    // Asset Master information (expanded)
    String? assetMasterName,
    String? description,
    String? subcategoryName,
    bool? isDepreciable,
    bool? needsCalibration,
    // Physical asset details (expanded)
    int? brandId,
    // Purchase information
    String? purchaseDate,
    String? purchaseCost,
    String? warrantyEndDate,
    // Employee/PIC information (expanded)
    int? userId,
    String? employeeNumber,
    String? employeeName,
    // Location details (expanded)
    int? roomId,
    String? roomName,
    String? buildingName,
    String? floorNumber,
    String? expectedBuildingName,
    String? expectedFloorNumber,
    // QR and timestamps (expanded)
    String? qrCodePath,
    // Depreciation info
    Map<String, dynamic>? depreciationInfo,
    // Current status info
    String? currentStatus,
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
      // Additional detailed asset information
      brandName: brandName ?? this.brandName,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      pic: pic ?? this.pic,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      originalCondition: originalCondition ?? this.originalCondition,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // Asset Master information (expanded)
      assetMasterName: assetMasterName ?? this.assetMasterName,
      description: description ?? this.description,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      isDepreciable: isDepreciable ?? this.isDepreciable,
      needsCalibration: needsCalibration ?? this.needsCalibration,
      // Physical asset details (expanded)
      brandId: brandId ?? this.brandId,
      // Purchase information
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      warrantyEndDate: warrantyEndDate ?? this.warrantyEndDate,
      // Employee/PIC information (expanded)
      userId: userId ?? this.userId,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      employeeName: employeeName ?? this.employeeName,
      // Location details (expanded)
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      buildingName: buildingName ?? this.buildingName,
      floorNumber: floorNumber ?? this.floorNumber,
      expectedBuildingName: expectedBuildingName ?? this.expectedBuildingName,
      expectedFloorNumber: expectedFloorNumber ?? this.expectedFloorNumber,
      // QR and timestamps (expanded)
      qrCodePath: qrCodePath ?? this.qrCodePath,
      // Depreciation info
      depreciationInfo: depreciationInfo ?? this.depreciationInfo,
      // Current status info
      currentStatus: currentStatus ?? this.currentStatus,
    );
  }

  factory AssetScanDetail.fromJson(Map<String, dynamic> json) {
    return AssetScanDetail(
      detailId: json['detail_id'],
      opnameId: json['opname_id'] ?? 0,
      opnameCode: json['opname_code'] ?? '',
      assetId: json['asset_id'],
      assetCode: json['asset_code'],
      assetDescription: json['asset_description'] ??
          json['asset_name'] ??
          json['asset_master_name'] ??
          '',
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
      // Additional detailed asset information
      brandName: json['brand_name'],
      model: json['model'],
      serialNumber: json['serial_number'],
      pic: json['pic'],
      category: json['category'],
      condition: json['condition'],
      originalCondition: json['original_condition'] ??
          json[
              'condition'], // Fallback to current condition if original not available
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      // Asset Master information (expanded)
      assetMasterName: json['asset_master_name'],
      description: json['description'],
      subcategoryName: json['subcategory_name'],
      isDepreciable: json['is_depreciable'],
      needsCalibration: json['needs_calibration'],
      // Physical asset details (expanded)
      brandId: json['brand_id'],
      // Purchase information
      purchaseDate: json['purchase_date'],
      purchaseCost: json['purchase_cost'],
      warrantyEndDate: json['warranty_end_date'],
      // Employee/PIC information (expanded)
      userId: json['user_id'],
      employeeNumber: json['employee_number'],
      employeeName: json['employee_name'],
      // Location details (expanded)
      roomId: json['room_id'],
      roomName: json['room_name'],
      buildingName: json['building_name'],
      floorNumber: json['floor_number'],
      expectedBuildingName: json['expected_building_name'],
      expectedFloorNumber: json['expected_floor_number'],
      // QR and timestamps (expanded)
      qrCodePath: json['qr_code'],
      // Depreciation info
      depreciationInfo: json['depreciation'],
      // Current status info
      currentStatus: json['current_status'],
    );
  }

  // Helper method to get asset name (prioritize asset_master_name over asset_description)
  String get assetName => assetMasterName ?? assetDescription;
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
