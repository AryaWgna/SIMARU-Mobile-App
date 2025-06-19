import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_config.dart';
import '../../controllers/complaint_controller.dart';

class ComplainDetailScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;

  const ComplainDetailScreen({
    super.key,
    required this.complaint,
  });

  @override
  State<ComplainDetailScreen> createState() => _ComplainDetailScreenState();
}

class _ComplainDetailScreenState extends State<ComplainDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Ambil controller dan load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller =
          Provider.of<ComplaintController>(context, listen: false);
      controller.fetchComplaintDetail(widget.complaint['id']);
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')} March ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildStatusBadge(String? status) {
    Color backgroundColor;
    Color textColor = Colors.white;
    String statusText = status?.toUpperCase() ?? 'UNKNOWN';

    final complaintDetail =
        Provider.of<ComplaintController>(context).complaintDetail;

    // Check if repair exists and has approval_by
    if (complaintDetail != null &&
        complaintDetail.repair != null &&
        complaintDetail.repair!['approval_by'] != null &&
        complaintDetail.repair!['approval_by'].toString() != "null" &&
        complaintDetail.repair!['approval_by'].toString() != "") {
      backgroundColor = Colors.green;
      statusText = 'APPROVED';
    } else {
      switch (status?.toLowerCase()) {
        case 'approved':
          backgroundColor = Colors.green;
          break;
        case 'pending':
          backgroundColor = Colors.orange;
          break;
        case 'rejected':
          backgroundColor = Colors.red;
          break;
        case 'finished':
          backgroundColor = Colors.blue;
          break;
        default:
          backgroundColor = Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF213268),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF213268),
        elevation: 0,
        title:
            const Text('Detail Keluhan', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ComplaintController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${controller.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        controller.fetchComplaintDetail(widget.complaint['id']),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final complaintDetail = controller.complaintDetail;
          if (complaintDetail == null) {
            return const Center(child: Text('Data tidak ditemukan'));
          }

          return RefreshIndicator(
            onRefresh: () =>
                controller.fetchComplaintDetail(widget.complaint['id']),
            color: const Color(0xFF213268),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Complaint Information
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detail Keluhan',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF213268),
                        ),
                      ),
                      _buildStatusBadge(complaintDetail.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (complaintDetail.complaintPicturePath != null)
                    Container(
                      width: double.infinity,
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          '${ApiConfig.baseUrl}/public${complaintDetail.complaintPicturePath}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.error_outline,
                                color: Colors.grey[400],
                                size: 50,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  _buildDetailItem('Tanggal Keluhan',
                      _formatDate(complaintDetail.complaintDate)),
                  _buildDetailItem('Asset Code', complaintDetail.assetCode),
                  _buildDetailItem('Asset Name', complaintDetail.assetName),
                  _buildDetailItem('Deskripsi', complaintDetail.description),
                  _buildDetailItem('Pelapor',
                      'ID: ${complaintDetail.reporterNumber ?? "-"}'),

                  // Repair Information
                  if (complaintDetail.repair != null) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Informasi Perbaikan'),
                    if (complaintDetail.repair!['repair_picture_path'] != null)
                      Container(
                        width: double.infinity,
                        height: 200,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            '${ApiConfig.baseUrl}/public${complaintDetail.repair!['repair_picture_path']}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.error_outline,
                                  color: Colors.grey[400],
                                  size: 50,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    _buildDetailItem('Tanggal Perbaikan',
                        _formatDate(complaintDetail.repair!['repair_date'])),
                    _buildDetailItem('Hasil Akhir',
                        complaintDetail.repair!['final_result'] ?? '-'),
                    _buildDetailItem('Deskripsi Perbaikan',
                        complaintDetail.repair!['repair_description'] ?? '-'),
                    _buildDetailItem('Biaya Perbaikan',
                        'Rp ${complaintDetail.repair!['repair_cost'] ?? '0'}'),
                    _buildDetailItem('Teknisi',
                        'ID: ${complaintDetail.repair!['technician_number'] ?? '-'}'),
                    _buildDetailItem('Part yang Diganti',
                        complaintDetail.repair!['parts_replaced'] ?? '-'),
                    _buildDetailItem(
                        'Tanggal Selesai',
                        _formatDate(
                            complaintDetail.repair!['completion_date'])),
                    _buildDetailItem('Disetujui Oleh',
                        'ID: ${complaintDetail.repair!['approver_number'] ?? '-'}'),
                    _buildDetailItem('Tanggal Persetujuan',
                        _formatDate(complaintDetail.repair!['approval_date'])),
                  ],

                  // Add Approve button if status is 'finished' and approval_by is null/empty
                  if (complaintDetail.status.toLowerCase() == 'finished' &&
                      complaintDetail.status.toLowerCase() != 'approved' &&
                      complaintDetail.repair != null &&
                      (complaintDetail.repair!['approval_by'] == null ||
                          complaintDetail.repair!['approval_by'].toString() ==
                              "null" ||
                          complaintDetail.repair!['approval_by'].toString() ==
                              ""))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: controller.isApproving
                              ? null
                              : () async {
                                  final success =
                                      await controller.approveRepair();
                                  if (success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Perbaikan berhasil disetujui')),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF213268),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: controller.isApproving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Approve Repair',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  // Add additional padding at the bottom for safe area
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
