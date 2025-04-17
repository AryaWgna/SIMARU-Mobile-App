import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/custom_app_bar.dart';
import '../../core/config/api_config.dart';
import '../../controllers/auth_controller.dart';
import 'complain_work_form_screen.dart';

class ComplainDetailScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;

  const ComplainDetailScreen({
    Key? key,
    required this.complaint,
  }) : super(key: key);

  @override
  State<ComplainDetailScreen> createState() => _ComplainDetailScreenState();
}

class _ComplainDetailScreenState extends State<ComplainDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _complaintDetail;
  String? _errorMessage;
  bool _isApproving = false;

  @override
  void initState() {
    super.initState();
    _fetchComplaintDetail();
  }

  Future<void> _fetchComplaintDetail() async {
    try {
      final accessToken = await ApiService.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/complaints/${widget.complaint['id']}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            _complaintDetail = data['data'];
            _isLoading = false;
          });
        } else {
          throw Exception(
              data['message'] ?? 'Failed to fetch complaint details');
        }
      } else {
        throw Exception(
            'Failed to load complaint details: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRepair(int repairId) async {
    setState(() {
      _isApproving = true;
    });

    try {
      final accessToken = await ApiService.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/repairs/$repairId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'approval_by': 2, // Using the provided approval_by value
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Repair approved successfully'),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh the complaint details
            _fetchComplaintDetail();
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to approve repair');
        }
      } else {
        throw Exception('Failed to approve repair: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApproving = false;
        });
      }
    }
  }

  Future<void> _showApprovalConfirmation(int repairId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Approval'),
          content:
              const Text('Apakah Anda yakin ingin menyetujui perbaikan ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Setuju'),
              onPressed: () {
                Navigator.of(context).pop();
                _approveRepair(repairId);
              },
            ),
          ],
        );
      },
    );
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
      default:
        backgroundColor = Colors.grey;
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
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchComplaintDetail,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    SingleChildScrollView(
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
                              _buildStatusBadge(_complaintDetail?['status']),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_complaintDetail?['complaint_picture_path'] !=
                              null)
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
                                  '${ApiConfig.baseUrl}/public${_complaintDetail?['complaint_picture_path']}',
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
                              _formatDate(_complaintDetail?['complaint_date'])),
                          _buildDetailItem('Asset Code',
                              _complaintDetail?['asset_id'].toString() ?? '-'),
                          _buildDetailItem('Asset Name',
                              _complaintDetail?['asset_name'] ?? '-'),
                          _buildDetailItem('Deskripsi',
                              _complaintDetail?['description'] ?? '-'),
                          _buildDetailItem('Pelapor',
                              'ID: ${_complaintDetail?['reporter_number'] ?? '-'}'),

                          // Repair Information
                          if (_complaintDetail?['repair'] != null) ...[
                            const SizedBox(height: 24),
                            _buildSectionTitle('Informasi Perbaikan'),
                            if (_complaintDetail?['repair']
                                    ['repair_picture_path'] !=
                                null)
                              Container(
                                width: double.infinity,
                                height: 200,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    '${ApiConfig.baseUrl}/public${_complaintDetail?['repair']['repair_picture_path']}',
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
                            _buildDetailItem(
                                'Tanggal Perbaikan',
                                _formatDate(_complaintDetail?['repair']
                                    ['repair_date'])),
                            _buildDetailItem(
                                'Hasil Akhir',
                                _complaintDetail?['repair']['final_result'] ??
                                    '-'),
                            _buildDetailItem(
                                'Deskripsi Perbaikan',
                                _complaintDetail?['repair']
                                        ['repair_description'] ??
                                    '-'),
                            _buildDetailItem('Biaya Perbaikan',
                                'Rp ${_complaintDetail?['repair']['repair_cost'] ?? '0'}'),
                            _buildDetailItem('Teknisi',
                                'ID: ${_complaintDetail?['repair']['technician_number'] ?? '-'}'),
                            _buildDetailItem(
                                'Part yang Diganti',
                                _complaintDetail?['repair']['parts_replaced'] ??
                                    '-'),
                            _buildDetailItem(
                                'Tanggal Selesai',
                                _formatDate(_complaintDetail?['repair']
                                    ['completion_date'])),
                            _buildDetailItem('Disetujui Oleh',
                                'ID: ${_complaintDetail?['repair']['approver_number'] ?? '-'}'),
                            _buildDetailItem(
                                'Tanggal Persetujuan',
                                _formatDate(_complaintDetail?['repair']
                                    ['approval_date'])),
                          ],

                          // Add Approve button if status is 'finished' and approval_by is null
                          if (_complaintDetail?['status']?.toLowerCase() ==
                                  'finished' &&
                              _complaintDetail?['repair'] != null &&
                              _complaintDetail?['repair']['approval_by'] ==
                                  null)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: SizedBox(
                                width: double.infinity,
                                height: 45,
                                child: ElevatedButton(
                                  onPressed: _isApproving
                                      ? null
                                      : () => _showApprovalConfirmation(
                                          _complaintDetail!['repair']['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF213268),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isApproving
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
                          // Show approved status if approval_by exists
                          if (_complaintDetail?['repair'] != null &&
                              _complaintDetail?['repair']['approval_by'] !=
                                  null)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: Container(
                                width: double.infinity,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Repair Approved',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
