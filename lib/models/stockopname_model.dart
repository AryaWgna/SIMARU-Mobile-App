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
  final String assetCode;
  final String assetName;
  final String location;
  final String condition;
  final String currentStatus;
  final DateTime scanTime;

  StockOpnameItem({
    this.assetId,
    required this.assetCode,
    required this.assetName,
    required this.location,
    required this.condition,
    required this.currentStatus,
    required this.scanTime,
  });

  factory StockOpnameItem.fromJson(Map<String, dynamic> json) {
    return StockOpnameItem(
      assetId: json['asset_id'],
      assetCode: json['asset_code'] ?? '',
      assetName: json['asset_name'] ?? '',
      location: json['location'] ?? '',
      condition: json['condition'] ?? '',
      currentStatus: json['current_status'] ?? '',
      scanTime: json['scan_time'] != null
          ? DateTime.parse(json['scan_time'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asset_id': assetId,
      'asset_code': assetCode,
      'asset_name': assetName,
      'location': location,
      'condition': condition,
      'current_status': currentStatus,
      'scan_time': scanTime.toIso8601String(),
    };
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

  StockOpname({
    required this.opnameId,
    required this.opnameCode,
    required this.roomId,
    required this.roomName,
    required this.totalAssets,
    required this.scannedAssets,
  });

  factory StockOpname.fromJson(Map<String, dynamic> json) {
    return StockOpname(
      opnameId: json['opname_id'] ?? 0,
      opnameCode: json['opname_code'] ?? '',
      roomId: json['room_id'] ?? 0,
      roomName: json['room_name'] ?? '',
      totalAssets: json['total_assets'] ?? 0,
      scannedAssets: json['scanned_assets'] ?? 0,
    );
  }
}
