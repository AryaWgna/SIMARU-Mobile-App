class AssetMutationItem {
  final int mutationId;
  final int assetId;
  final int? fromRoomId;
  final int? toRoomId;
  final String fromRoomName;
  final String toRoomName;
  final String fromBuildingName;
  final String toBuildingName;
  final String reason;
  final DateTime mutationDate;
  final String approvalStatus;
  final String requestedBy;
  final String? approvedBy;
  final DateTime? approvalDate;

  AssetMutationItem({
    required this.mutationId,
    required this.assetId,
    this.fromRoomId,
    this.toRoomId,
    required this.fromRoomName,
    required this.toRoomName,
    required this.fromBuildingName,
    required this.toBuildingName,
    required this.reason,
    required this.mutationDate,
    required this.approvalStatus,
    required this.requestedBy,
    this.approvedBy,
    this.approvalDate,
  });

  factory AssetMutationItem.fromJson(Map<String, dynamic> json) {
    return AssetMutationItem(
      mutationId: json['mutation_id'] ?? 0,
      assetId: json['asset_id'] ?? 0,
      fromRoomId: json['from_room_id'],
      toRoomId: json['to_room_id'],
      fromRoomName: json['from_room']?['room_name'] ??
          json['from_room_name'] ??
          'Unknown',
      toRoomName:
          json['to_room']?['room_name'] ?? json['to_room_name'] ?? 'Unknown',
      fromBuildingName: json['from_room']?['building']?['building_name'] ??
          json['from_building_name'] ??
          'Unknown',
      toBuildingName: json['to_room']?['building']?['building_name'] ??
          json['to_building_name'] ??
          'Unknown',
      reason: json['reason'] ?? '',
      mutationDate: json['mutation_date'] != null
          ? DateTime.parse(json['mutation_date'])
          : DateTime.now(),
      approvalStatus: json['approval_status'] ?? 'pending',
      requestedBy: json['requested_by']?['name'] ??
          json['requested_by_name'] ??
          'Unknown',
      approvedBy: json['approved_by']?['name'] ?? json['approved_by_name'],
      approvalDate: json['approval_date'] != null
          ? DateTime.parse(json['approval_date'])
          : null,
    );
  }
}

class BuildingItem {
  final int buildingId;
  final String buildingName;
  final List<RoomItem> rooms;

  BuildingItem({
    required this.buildingId,
    required this.buildingName,
    required this.rooms,
  });

  factory BuildingItem.fromJson(Map<String, dynamic> json) {
    List<RoomItem> rooms = [];

    if (json['rooms'] != null) {
      rooms = (json['rooms'] as List)
          .map((room) => RoomItem.fromJson(room))
          .toList();
    }

    return BuildingItem(
      buildingId: json['building_id'] ?? 0,
      buildingName: json['building_name'] ?? '',
      rooms: rooms,
    );
  }
}

class RoomItem {
  final int roomId;
  final String roomName;
  final int buildingId;

  RoomItem({
    required this.roomId,
    required this.roomName,
    required this.buildingId,
  });

  factory RoomItem.fromJson(Map<String, dynamic> json) {
    return RoomItem(
      roomId: json['room_id'] ?? 0,
      roomName: json['room_name'] ?? '',
      buildingId: json['building_id'] ?? 0,
    );
  }
}
