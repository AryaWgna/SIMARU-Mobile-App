class CalibrationResponse {
  final bool success;
  final String message;
  final List<Calibration> data;
  final Pagination pagination;

  CalibrationResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory CalibrationResponse.fromJson(Map<String, dynamic> json) {
    return CalibrationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => Calibration.fromJson(e))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class Calibration {
  final int id;
  final String taskCode;
  final int assetId;
  final String assetName;
  final String assetCode;
  final String serialNumber;
  final String modelNumber;
  final String brandName;
  final Location location;
  final String planningCalibrationDate;
  final String? actualCalibrationDate;
  final String? nextCalibrationDate;
  final String statusCalibration;
  final int? vendorId;
  final String? certificateNumber;
  final String? certificateFilePath;
  final String? calibrationResult;
  final double? calibrationPrice;
  final String? notes;
  final int scheduledBy;
  final String scheduledByName;
  final int? completedBy;
  final String? completedByName;
  final String createdAt;
  final String updatedAt;

  Calibration({
    required this.id,
    required this.taskCode,
    required this.assetId,
    required this.assetName,
    required this.assetCode,
    required this.serialNumber,
    required this.modelNumber,
    required this.brandName,
    required this.location,
    required this.planningCalibrationDate,
    this.actualCalibrationDate,
    this.nextCalibrationDate,
    required this.statusCalibration,
    this.vendorId,
    this.certificateNumber,
    this.certificateFilePath,
    this.calibrationResult,
    this.calibrationPrice,
    this.notes,
    required this.scheduledBy,
    required this.scheduledByName,
    this.completedBy,
    this.completedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Calibration.fromJson(Map<String, dynamic> json) {
    return Calibration(
      id: json['id'] ?? 0,
      taskCode: json['task_code'] ?? '',
      assetId: json['asset_id'] ?? 0,
      assetName: json['asset_name'] ?? '',
      assetCode: json['asset_code'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      modelNumber: json['model_number'] ?? '',
      brandName: json['brand_name'] ?? '',
      location: Location.fromJson(json['location'] ?? {}),
      planningCalibrationDate: json['planning_calibration_date'] ?? '',
      actualCalibrationDate: json['actual_calibration_date'],
      nextCalibrationDate: json['next_calibration_date'],
      statusCalibration: json['status_calibration'] ?? '',
      vendorId: json['vendor_id'],
      certificateNumber: json['certificate_number'],
      certificateFilePath: json['certificate_file_path'],
      calibrationResult: json['calibration_result'],
      calibrationPrice: json['calibration_price']?.toDouble(),
      notes: json['notes'],
      scheduledBy: json['scheduled_by'] ?? 0,
      scheduledByName: json['scheduled_by_name'] ?? '',
      completedBy: json['completed_by'],
      completedByName: json['completed_by_name'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class Location {
  final String roomName;
  final String floorNumber;
  final String buildingName;

  Location({
    required this.roomName,
    required this.floorNumber,
    required this.buildingName,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      roomName: json['room_name'] ?? '',
      floorNumber: json['floor_number'] ?? '',
      buildingName: json['building_name'] ?? '',
    );
  }

  String getFullLocation() {
    return '$roomName, $floorNumber, $buildingName';
  }
}

class Pagination {
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final int limit;
  final bool hasNext;
  final bool hasPrev;

  Pagination({
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    required this.limit,
    required this.hasNext,
    required this.hasPrev,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      totalItems: json['total_items'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      currentPage: json['current_page'] ?? 0,
      limit: json['limit'] ?? 10,
      hasNext: json['has_next'] ?? false,
      hasPrev: json['has_prev'] ?? false,
    );
  }
}
