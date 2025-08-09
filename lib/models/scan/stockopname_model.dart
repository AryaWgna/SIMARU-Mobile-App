class StockOpnameModel {
  final int id;
  final String opnameCode;
  final DateTime opnameDate;
  final int plannedAssets;
  final int scannedAssets;
  final String status;
  final String createdBy;
  final DateTime createdAt;

  StockOpnameModel({
    required this.id,
    required this.opnameCode,
    required this.opnameDate,
    required this.plannedAssets,
    required this.scannedAssets,
    required this.status,
    required this.createdBy,
    required this.createdAt,
  });

  factory StockOpnameModel.fromJson(Map<String, dynamic> json) {
    return StockOpnameModel(
      id: json['id'],
      opnameCode: json['opname_code'] ?? '',
      opnameDate: json['opname_date'] != null
          ? DateTime.parse(json['opname_date'])
          : DateTime.now(),
      plannedAssets: json['planned_assets'] ?? 0,
      scannedAssets: json['scanned_assets'] ?? 0,
      status: json['status'] ?? 'pending',
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'opname_code': opnameCode,
      'opname_date': opnameDate.toIso8601String(),
      'planned_assets': plannedAssets,
      'scanned_assets': scannedAssets,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class StockOpnameItem {
  final int? assetId;
  final int? detailId; // Add detailId for notes API endpoint compatibility
  final String assetCode;
  final String assetName;
  final String location;
  final String condition;
  final String currentStatus;
  final DateTime scanTime;
  final String? notes;

  // Asset Master information
  final int? assetMasterId;
  final String? assetMasterCode;
  final String? assetMasterName;
  final String? description;
  final String? assetType;
  final String? subcategoryName;
  final String? referenceImagePath;
  final bool? isDepreciable;
  final bool? needsCalibration;

  // Physical asset details
  final String? serialNumber;
  final String? model;
  final int? brandId;
  final String? brandName;

  // Purchase information
  final String? purchaseDate;
  final String? purchaseCost;
  final String? warrantyEndDate;

  // Employee/PIC information
  final int? userId;
  final String? employeeNumber;
  final String? employeeName;
  final String? pic;

  // Location details
  final int? roomId;
  final String? roomName;
  final String? buildingName;
  final String? floorNumber;
  final String? actualLocationName;
  final String? expectedLocationName;
  final String? expectedBuildingName;
  final String? expectedFloorNumber;

  // QR and timestamps
  final String? qrCodePath;
  final String? createdAt;
  final String? updatedAt;

  // Depreciation info
  final Map<String, dynamic>? depreciationInfo;

  // Category information
  final String? category;

  StockOpnameItem({
    this.assetId,
    this.detailId,
    required this.assetCode,
    required this.assetName,
    required this.location,
    required this.condition,
    required this.currentStatus,
    required this.scanTime,
    this.notes,
    // Asset Master fields
    this.assetMasterId,
    this.assetMasterCode,
    this.assetMasterName,
    this.description,
    this.assetType,
    this.subcategoryName,
    this.referenceImagePath,
    this.isDepreciable,
    this.needsCalibration,
    // Physical asset details
    this.serialNumber,
    this.model,
    this.brandId,
    this.brandName,
    // Purchase information
    this.purchaseDate,
    this.purchaseCost,
    this.warrantyEndDate,
    // Employee/PIC information
    this.userId,
    this.employeeNumber,
    this.employeeName,
    this.pic,
    // Location details
    this.roomId,
    this.roomName,
    this.buildingName,
    this.floorNumber,
    this.actualLocationName,
    this.expectedLocationName,
    this.expectedBuildingName,
    this.expectedFloorNumber,
    // QR and timestamps
    this.qrCodePath,
    this.createdAt,
    this.updatedAt,
    // Depreciation info
    this.depreciationInfo,
    // Category information
    this.category,
  });

  factory StockOpnameItem.fromJson(Map<String, dynamic> json) {
    return StockOpnameItem(
      assetId: json['asset_id'],
      detailId: json['detail_id'], // Parse detailId from API response
      assetCode: json['asset_code'] ?? '',
      assetName: json['asset_name'] ?? json['asset_master_name'] ?? '',
      location: json['location'] ?? json['room_name'] ?? '',
      condition: json['condition'] ?? '',
      currentStatus: json['current_status'] ?? json['scan_status'] ?? '',
      scanTime: json['scan_time'] != null
          ? DateTime.parse(json['scan_time'])
          : DateTime.now(),
      notes: json['notes'],
      // Asset Master fields
      assetMasterId: json['asset_master_id'],
      assetMasterCode: json['asset_master_code'],
      assetMasterName: json['asset_master_name'],
      description: json['description'],
      assetType: json['asset_type'],
      subcategoryName: json['subcategory_name'],
      referenceImagePath: json['reference_image_path'],
      isDepreciable: json['is_depreciable'],
      needsCalibration: json['needs_calibration'],
      // Physical asset details
      serialNumber: json['serial_number'],
      model: json['model'],
      brandId: json['brand_id'],
      brandName: json['brand_name'],
      // Purchase information
      purchaseDate: json['purchase_date'],
      purchaseCost: json['purchase_cost'],
      warrantyEndDate: json['warranty_end_date'],
      // Employee/PIC information
      userId: json['user_id'],
      employeeNumber: json['employee_number'],
      employeeName: json['employee_name'],
      pic: json['pic'],
      // Location details
      roomId: json['room_id'],
      roomName: json['room_name'],
      buildingName: json['building_name'],
      floorNumber: json['floor_number'],
      actualLocationName: json['actual_location_name'],
      expectedLocationName: json['expected_location_name'],
      expectedBuildingName: json['expected_building_name'],
      expectedFloorNumber: json['expected_floor_number'],
      // QR and timestamps
      qrCodePath: json['qr_code'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      // Depreciation info
      depreciationInfo: json['depreciation'],
      // Category information
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asset_id': assetId,
      'detail_id': detailId,
      'asset_code': assetCode,
      'asset_name': assetName,
      'location': location,
      'condition': condition,
      'current_status': currentStatus,
      'scan_time': scanTime.toIso8601String(),
      'notes': notes,
      // Asset Master fields
      'asset_master_id': assetMasterId,
      'asset_master_code': assetMasterCode,
      'asset_master_name': assetMasterName,
      'description': description,
      'asset_type': assetType,
      'subcategory_name': subcategoryName,
      'reference_image_path': referenceImagePath,
      'is_depreciable': isDepreciable,
      'needs_calibration': needsCalibration,
      // Physical asset details
      'serial_number': serialNumber,
      'model': model,
      'brand_id': brandId,
      'brand_name': brandName,
      // Purchase information
      'purchase_date': purchaseDate,
      'purchase_cost': purchaseCost,
      'warranty_end_date': warrantyEndDate,
      // Employee/PIC information
      'user_id': userId,
      'employee_number': employeeNumber,
      'employee_name': employeeName,
      'pic': pic,
      // Location details
      'room_id': roomId,
      'room_name': roomName,
      'building_name': buildingName,
      'floor_number': floorNumber,
      'actual_location_name': actualLocationName,
      'expected_location_name': expectedLocationName,
      'expected_building_name': expectedBuildingName,
      'expected_floor_number': expectedFloorNumber,
      // QR and timestamps
      'qr_code': qrCodePath,
      'created_at': createdAt,
      'updated_at': updatedAt,
      // Depreciation info
      'depreciation': depreciationInfo,
      // Category information
      'category': category,
    };
  }

  // Add copyWith method to create a new instance with updated fields
  StockOpnameItem copyWith({
    int? assetId,
    int? detailId,
    String? assetCode,
    String? assetName,
    String? location,
    String? condition,
    String? currentStatus,
    DateTime? scanTime,
    String? notes,
    // Asset Master fields
    int? assetMasterId,
    String? assetMasterCode,
    String? assetMasterName,
    String? description,
    String? assetType,
    String? subcategoryName,
    String? referenceImagePath,
    bool? isDepreciable,
    bool? needsCalibration,
    // Physical asset details
    String? serialNumber,
    String? model,
    int? brandId,
    String? brandName,
    // Purchase information
    String? purchaseDate,
    String? purchaseCost,
    String? warrantyEndDate,
    // Employee/PIC information
    int? userId,
    String? employeeNumber,
    String? employeeName,
    String? pic,
    // Location details
    int? roomId,
    String? roomName,
    String? buildingName,
    String? floorNumber,
    String? actualLocationName,
    String? expectedLocationName,
    String? expectedBuildingName,
    String? expectedFloorNumber,
    // QR and timestamps
    String? qrCodePath,
    String? createdAt,
    String? updatedAt,
    // Depreciation info
    Map<String, dynamic>? depreciationInfo,
    // Category information
    String? category,
  }) {
    return StockOpnameItem(
      assetId: assetId ?? this.assetId,
      detailId: detailId ?? this.detailId,
      assetCode: assetCode ?? this.assetCode,
      assetName: assetName ?? this.assetName,
      location: location ?? this.location,
      condition: condition ?? this.condition,
      currentStatus: currentStatus ?? this.currentStatus,
      scanTime: scanTime ?? this.scanTime,
      notes: notes ?? this.notes,
      // Asset Master fields
      assetMasterId: assetMasterId ?? this.assetMasterId,
      assetMasterCode: assetMasterCode ?? this.assetMasterCode,
      assetMasterName: assetMasterName ?? this.assetMasterName,
      description: description ?? this.description,
      assetType: assetType ?? this.assetType,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      referenceImagePath: referenceImagePath ?? this.referenceImagePath,
      isDepreciable: isDepreciable ?? this.isDepreciable,
      needsCalibration: needsCalibration ?? this.needsCalibration,
      // Physical asset details
      serialNumber: serialNumber ?? this.serialNumber,
      model: model ?? this.model,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      // Purchase information
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      warrantyEndDate: warrantyEndDate ?? this.warrantyEndDate,
      // Employee/PIC information
      userId: userId ?? this.userId,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      employeeName: employeeName ?? this.employeeName,
      pic: pic ?? this.pic,
      // Location details
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      buildingName: buildingName ?? this.buildingName,
      floorNumber: floorNumber ?? this.floorNumber,
      actualLocationName: actualLocationName ?? this.actualLocationName,
      expectedLocationName: expectedLocationName ?? this.expectedLocationName,
      expectedBuildingName: expectedBuildingName ?? this.expectedBuildingName,
      expectedFloorNumber: expectedFloorNumber ?? this.expectedFloorNumber,
      // QR and timestamps
      qrCodePath: qrCodePath ?? this.qrCodePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // Depreciation info
      depreciationInfo: depreciationInfo ?? this.depreciationInfo,
      // Category information
      category: category ?? this.category,
    );
  }
}

class StockOpnameSummary {
  final int totalAssets;
  final int scannedAssets;
  final int missingAssets;
  final List<String> scannedAssetCodes;
  final List<String> missingAssetCodes;

  StockOpnameSummary({
    required this.totalAssets,
    required this.scannedAssets,
    required this.missingAssets,
    required this.scannedAssetCodes,
    required this.missingAssetCodes,
  });

  factory StockOpnameSummary.fromJson(Map<String, dynamic> json) {
    List<String> scannedCodes = [];
    List<String> missingCodes = [];

    if (json['scanned_assets'] is List) {
      scannedCodes = List<String>.from(json['scanned_assets']);
    }

    if (json['missing_assets'] is List) {
      missingCodes = List<String>.from(json['missing_assets']);
    }

    return StockOpnameSummary(
      totalAssets: json['total_assets'] ?? 0,
      scannedAssets: json['scanned_count'] ?? 0,
      missingAssets: json['missing_count'] ?? 0,
      scannedAssetCodes: scannedCodes,
      missingAssetCodes: missingCodes,
    );
  }
}

class Building {
  final int id;
  final String? name;
  final String? address;

  Building({required this.id, this.name, this.address});

  factory Building.fromJson(Map<String, dynamic> json) {
    // Debug print untuk melihat data mentah
    print('Building fromJson raw data: $json');

    // Coba berbagai kemungkinan key untuk id
    int buildingId = 0;
    if (json['building_id'] != null) {
      // Prioritaskan building_id karena ini format dari API
      if (json['building_id'] is String) {
        buildingId = int.tryParse(json['building_id']) ?? 0;
      } else {
        buildingId = json['building_id'];
      }
    } else if (json['id'] != null) {
      if (json['id'] is String) {
        buildingId = int.tryParse(json['id']) ?? 0;
      } else {
        buildingId = json['id'];
      }
    }

    // Coba berbagai kemungkinan key untuk name
    String? buildingName;
    if (json['building_name'] != null) {
      // Prioritaskan building_name karena ini format dari API
      buildingName = json['building_name'].toString();
    } else if (json['name'] != null) {
      buildingName = json['name'].toString();
    }

    // Coba berbagai kemungkinan key untuk address
    String? buildingAddress;
    if (json['address'] != null) {
      buildingAddress = json['address'].toString();
    }

    print(
        'Building parsed: id=$buildingId, name=$buildingName, address=$buildingAddress');

    return Building(
      id: buildingId,
      name: buildingName,
      address: buildingAddress,
    );
  }
}

class Room {
  final int id;
  final String? name;
  final int buildingId;

  Room({required this.id, this.name, required this.buildingId});

  factory Room.fromJson(Map<String, dynamic> json) {
    // Debug print untuk melihat data mentah
    print('Room fromJson raw data: $json');

    // Coba berbagai kemungkinan key untuk id
    int roomId = 0;
    if (json['room_id'] != null) {
      // Prioritaskan room_id karena ini format dari API
      if (json['room_id'] is String) {
        roomId = int.tryParse(json['room_id']) ?? 0;
      } else {
        roomId = json['room_id'];
      }
    } else if (json['id'] != null) {
      if (json['id'] is String) {
        roomId = int.tryParse(json['id']) ?? 0;
      } else {
        roomId = json['id'];
      }
    }

    // Coba berbagai kemungkinan key untuk name
    String? roomName;
    if (json['room_name'] != null) {
      // Prioritaskan room_name karena ini format dari API
      roomName = json['room_name'].toString();
    } else if (json['name'] != null) {
      roomName = json['name'].toString();
    }

    // Coba berbagai kemungkinan key untuk building_id
    int bId = 0;
    if (json['building_id'] != null) {
      if (json['building_id'] is String) {
        bId = int.tryParse(json['building_id']) ?? 0;
      } else {
        bId = json['building_id'];
      }
    }

    print('Room parsed: id=$roomId, name=$roomName, buildingId=$bId');

    return Room(
      id: roomId,
      name: roomName,
      buildingId: bId,
    );
  }
}

class StockOpname {
  final int opnameId;
  final String opnameCode;
  final int roomId;
  final String roomName;
  final int totalAssets;
  final int scannedAssets;
  final String status;

  StockOpname({
    required this.opnameId,
    required this.opnameCode,
    required this.roomId,
    required this.roomName,
    required this.totalAssets,
    required this.scannedAssets,
    this.status = 'pending',
  });

  factory StockOpname.fromJson(Map<String, dynamic> json) {
    return StockOpname(
      opnameId: json['opname_id'] ?? 0,
      opnameCode: json['opname_code'] ?? '',
      roomId: json['room_id'] ?? 0,
      roomName: json['room_name'] ?? '',
      totalAssets: json['total_assets'] ?? 0,
      scannedAssets: json['scanned_assets'] ?? 0,
      status: json['status'] ?? 'pending',
    );
  }

  // Add copyWith method to create a new instance with updated fields
  StockOpname copyWith({
    int? opnameId,
    String? opnameCode,
    int? roomId,
    String? roomName,
    int? totalAssets,
    int? scannedAssets,
    String? status,
  }) {
    return StockOpname(
      opnameId: opnameId ?? this.opnameId,
      opnameCode: opnameCode ?? this.opnameCode,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      totalAssets: totalAssets ?? this.totalAssets,
      scannedAssets: scannedAssets ?? this.scannedAssets,
      status: status ?? this.status,
    );
  }
}
