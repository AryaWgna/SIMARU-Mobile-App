import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/custom_app_bar.dart';
import '../../controllers/procurement_controller.dart';
import '../../models/procurement_model.dart';
import 'package:intl/intl.dart';

class ProcurementDetailScreen extends StatefulWidget {
  final String title;
  final String status;
  final String priority;
  final String requestDate;
  final int procurementId;

  const ProcurementDetailScreen({
    super.key,
    required this.title,
    required this.status,
    required this.priority,
    required this.requestDate,
    required this.procurementId,
  });

  @override
  State<ProcurementDetailScreen> createState() =>
      _ProcurementDetailScreenState();
}

class _ProcurementDetailScreenState extends State<ProcurementDetailScreen> {
  bool _isLoading = true;
  late Procurement _procurement;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProcurementDetail();
  }

  Future<void> _loadProcurementDetail() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final procurementData = await ProcurementController.getProcurementDetail(
        context,
        widget.procurementId,
      );

      if (mounted) {
        setState(() {
          _procurement = procurementData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load procurement detail: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: const CustomAppBar(),
        toolbarHeight: 82,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      ElevatedButton(
                        onPressed: _loadProcurementDetail,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Text(
                        'PROCUREMENT REQUEST DETAIL',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF213268),
                        ),
                      ),
                    ),

                    // Konten utama
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Procurement ID
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildInfoRow('Procurement ID',
                                  _procurement.procurementId.toString()),
                            ),

                            _buildDivider(),

                            // Title Request
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildInfoRow(
                                  'Title Request', _procurement.title),
                            ),

                            _buildDivider(),

                            // Requester
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildInfoRow('Requester',
                                  _procurement.requester.getFullName()),
                            ),

                            _buildDivider(),

                            // Request Date
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildInfoRow('Request Date',
                                  _procurement.getFormattedDate()),
                            ),

                            _buildDivider(),

                            // Status dengan icon
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  const Text(
                                    'Status:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        _getStatusIcon(_procurement.status),
                                        size: 16,
                                        color: _getStatusColor(
                                            _procurement.status),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _procurement.status,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _getStatusColor(
                                              _procurement.status),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // List Asset Section
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'List Asset',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Asset Cards - dinamis dari data
                            ..._procurement.details
                                .map((detail) =>
                                    _buildAssetCardFromDetail(detail))
                                .toList(),

                            // Spacer untuk memastikan semua konten terlihat
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Grand Total - menggunakan widget baru di posisi fixed
                    _buildGrandTotal(),
                  ],
                ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1, thickness: 1),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk format currency
  String _formatCurrency(String price) {
    try {
      double numPrice;
      // Remove any existing commas or dots first
      String cleanPrice = price.replaceAll('.', '').replaceAll(',', '');
      numPrice = double.parse(cleanPrice);

      // Format with period as thousand separator
      final formatter = NumberFormat("#,###", "id_ID");
      return formatter.format(numPrice);
    } catch (e) {
      print('Error formatting currency: $e');
      // Fallback to simple formatting if there's an error
      return price;
    }
  }

  // Helper untuk mendapatkan icon status
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Icons.check_circle_outline;
      case 'under review':
        return Icons.pending_outlined;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  // Helper untuk mendapatkan warna status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.blue;
      case 'under review':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Widget untuk card asset dari detail
  Widget _buildAssetCardFromDetail(ProcurementDetail detail) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asset Name: ${detail.assetName}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Qty: ${detail.quantity}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            // Estimated Unit Price (baris tersendiri)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Est. Unit Price:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Rp ${_formatCurrency(detail.estimatedUnitPrice)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Estimated Total Price (baris tersendiri)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Est. Total Price:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Rp ${_formatCurrency(detail.estimatedTotalPrice)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (detail.specifications.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Specifications: ${detail.specifications}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
            if (detail.status.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Status: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    detail.status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(detail.status),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Grand Total yang diperbaiki
  Widget _buildGrandTotal() {
    try {
      // Menghitung total dari semua detail items
      double total = 0;
      for (var detail in _procurement.details) {
        // Parse estimatedTotalPrice dari setiap item
        String cleanPrice =
            detail.estimatedTotalPrice.replaceAll('.', '').replaceAll(',', '');
        total += double.parse(cleanPrice);
      }

      // Format currency dengan rapi
      final formatter = NumberFormat("#,###", "id_ID");
      String formattedTotal = formatter.format(total);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Spread items to left and right
          children: [
            // Label di kiri
            Text(
              'Est. Grand Total:',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            // Nilai di kanan dengan font yang lebih besar dan tebal
            Text(
              'Rp ${formattedTotal}',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF213268),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error in _buildGrandTotal: $e');
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: const Text(
          'Total tidak tersedia',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }
}
