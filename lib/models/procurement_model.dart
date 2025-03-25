class ProcurementResponse {
  final bool status;
  final String message;
  final List<Procurement> data;
  final Pagination pagination;

  ProcurementResponse({
    required this.status,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory ProcurementResponse.fromJson(Map<String, dynamic> json) {
    return ProcurementResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => Procurement.fromJson(e))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
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

class Procurement {
  final int procurementId;
  final Requester requester;
  final String requestDate;
  final String title;
  final String justification;
  final String priority;
  final String status;
  final List<ProcurementDetail> details;
  final String totalEstimatedPrice;
  final String createdAt;
  final String updatedAt;

  Procurement({
    required this.procurementId,
    required this.requester,
    required this.requestDate,
    required this.title,
    required this.justification,
    required this.priority,
    required this.status,
    required this.details,
    required this.totalEstimatedPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Procurement.fromJson(Map<String, dynamic> json) {
    return Procurement(
      procurementId: json['procurement_id'] ?? 0,
      requester: Requester.fromJson(json['requester'] ?? {}),
      requestDate: json['request_date'] ?? '',
      title: json['title'] ?? '',
      justification: json['justification'] ?? '',
      priority: json['priority'] ?? '',
      status: json['status'] ?? '',
      details: (json['details'] as List<dynamic>? ?? [])
          .map((e) => ProcurementDetail.fromJson(e))
          .toList(),
      totalEstimatedPrice: json['total_estimated_price']?.toString() ?? '0',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  // Helper untuk format tanggal dan harga
  String getFormattedDate() {
    try {
      final date = DateTime.parse(requestDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return requestDate;
    }
  }

  // Helper untuk mendapatkan jumlah aset
  String getQuantityText() {
    if (details.isEmpty) {
      return '0'; // Jika tidak ada detail, tampilkan 0
    }
    
    int total = 0;
    for (var detail in details) {
      total += detail.quantity;
    }
    return total.toString();
  }
}

class Requester {
  final int userId;
  final String email;
  final String firstName;
  final String lastName;
  final String role;

  Requester({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory Requester.fromJson(Map<String, dynamic> json) {
    return Requester(
      userId: json['user_id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? '',
    );
  }

  String getFullName() {
    return '$firstName $lastName';
  }
}

class ProcurementDetail {
  final int procurementDetailId;
  final int procurementId;
  final String assetName;
  final String specifications;
  final int quantity;
  final String estimatedUnitPrice;
  final String estimatedTotalPrice;
  final String status;
  final String statusPriceComparison;
  final List<dynamic>
      vendorQuotations; // Bisa diubah jika ada struktur vendor quotations

  ProcurementDetail({
    required this.procurementDetailId,
    required this.procurementId,
    required this.assetName,
    required this.specifications,
    required this.quantity,
    required this.estimatedUnitPrice,
    required this.estimatedTotalPrice,
    required this.status,
    required this.statusPriceComparison,
    required this.vendorQuotations,
  });

  factory ProcurementDetail.fromJson(Map<String, dynamic> json) {
    return ProcurementDetail(
      procurementDetailId: json['procurement_detail_id'] ?? 0,
      procurementId: json['procurement_id'] ?? 0,
      assetName: json['asset_name'] ?? '',
      specifications: json['specifications'] ?? '',
      quantity: json['quantity'] ?? 0,
      estimatedUnitPrice: json['estimated_unit_price']?.toString() ?? '0',
      estimatedTotalPrice: json['estimated_total_price']?.toString() ?? '0',
      status: json['status'] ?? '',
      statusPriceComparison: json['status_price_comparison'] ?? '',
      vendorQuotations: json['vendor_quotations'] ?? [],
    );
  }
}
