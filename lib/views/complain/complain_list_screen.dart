import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../core/config/api_config.dart';
import 'complain_detail_screen.dart';
import 'complain_form_screen.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/custom_app_bar.dart';

class ComplainListScreen extends StatefulWidget {
  const ComplainListScreen({super.key});

  @override
  State<ComplainListScreen> createState() => _ComplainListScreenState();
}

class _ComplainListScreenState extends State<ComplainListScreen> {
  List<dynamic> _complaints = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = await ApiService.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.getUserComplaintsUrl('1')),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            _complaints = data['data'];
            _isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch complaints');
        }
      } else {
        throw Exception('Failed to load complaints: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')} March ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildStatusBadge(String? status, Map<String, dynamic> complaint) {
    Color backgroundColor;
    Color textColor = Colors.white;
    String statusText;

    // Check if repair exists and has approval_by
    if (complaint['repair'] != null &&
        complaint['repair']['approval_by'] != null) {
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
      statusText = status?.toUpperCase() ?? 'UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _isLoading
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
                              onPressed: _fetchComplaints,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : _complaints.isEmpty
                        ? const Center(
                            child: Text('Tidak ada keluhan yang ditemukan'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _complaints.length,
                            itemBuilder: (context, index) {
                              final complaint = _complaints[index];
                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (complaint[
                                                  'complaint_picture_path'] !=
                                              null)
                                            Container(
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.grey.shade200,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  ApiService.baseUrl +
                                                      '/public' +
                                                      (complaint[
                                                              'complaint_picture_path'] ??
                                                          ''),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    print(
                                                        'Error loading image: $error');
                                                    return Center(
                                                      child: Icon(
                                                        Icons.error_outline,
                                                        color: Colors.grey[400],
                                                        size: 40,
                                                      ),
                                                    );
                                                  },
                                                  loadingBuilder: (context,
                                                      child, loadingProgress) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        _formatDate(complaint[
                                                            'complaint_date']),
                                                        style:
                                                            GoogleFonts.inter(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                    _buildStatusBadge(
                                                        complaint['status'],
                                                        complaint),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '2 Minutes ago',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Asset Code:',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  complaint['asset_id']
                                                          ?.toString() ??
                                                      '',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Asset Name:',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  complaint['asset_name'] ?? '',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: Colors.grey.shade200,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Complaint Desc:',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            complaint['description'] ?? '',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ComplainDetailScreen(
                                              complaint: complaint,
                                            ),
                                          ),
                                        ).then((_) => _fetchComplaints());
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        height: 45,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF213268),
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            complaint['status']
                                                        ?.toLowerCase() ==
                                                    'finished'
                                                ? 'Approve'
                                                : 'Lihat Detail',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64.0),
        child: FloatingActionButton(
          heroTag: 'complain_list_fab',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ComplainFormScreen()),
            ).then((_) => _fetchComplaints());
          },
          backgroundColor: const Color(0xFF213268),
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
