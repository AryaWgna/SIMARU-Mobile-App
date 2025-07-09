import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth/auth_controller.dart';
import '../../core/config/api_config.dart';
import 'dart:convert';
import 'complain_work_form_screen.dart';

class ComplainDetailViewScreen extends StatefulWidget {
  final String id;

  const ComplainDetailViewScreen({
    super.key,
    required this.id,
  });

  @override
  State<ComplainDetailViewScreen> createState() =>
      _ComplainDetailViewScreenState();
}

class _ComplainDetailViewScreenState extends State<ComplainDetailViewScreen> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? complaintDetail;

  @override
  void initState() {
    super.initState();
    _fetchComplaintDetail();
  }

  Future<void> _fetchComplaintDetail() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response =
          await ApiService.get('/complaints/${widget.id}', context: context);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            complaintDetail = data['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load complaint detail';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Failed to load complaint detail: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'Report Detail Teknisi',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF213268),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'REPORT DETAIL',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF213268),
              ),
            ),
          ),
          if (isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            )
          else if (complaintDetail != null)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Asset Image
                      if (complaintDetail!['complaint_picture_path'] != null)
                        Container(
                          width: double.infinity,
                          height: 160,
                          margin: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(
                                  '${ApiConfig.baseUrl}${complaintDetail!['complaint_picture_path']}'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          height: 160,
                          margin: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Asset Code
                      Text(
                        complaintDetail!['asset_id']?.toString() ?? '-',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF213268),
                        ),
                      ),

                      // Asset Name
                      Text(
                        complaintDetail!['asset_name'] ?? '-',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Performed By
                      Text(
                        complaintDetail!['reporter_name'] ?? '-',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),

                      // Complaint Description
                      Text(
                        complaintDetail!['description'] ?? '-',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Asset Information Header
                      Text(
                        'Asset Information',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF213268),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Asset Information Details
                      _buildInfoRow(
                          'Categories', complaintDetail!['categories'] ?? '-'),
                      _buildInfoRow('Sub Categories',
                          complaintDetail!['sub_categories'] ?? '-'),
                      _buildInfoRow(
                          'Location', complaintDetail!['location'] ?? '-'),
                      _buildInfoRow('Brand', complaintDetail!['brand'] ?? '-'),
                      _buildInfoRow('Model Number',
                          complaintDetail!['model_number'] ?? '-'),
                      _buildInfoRow('Serial Number',
                          complaintDetail!['serial_number'] ?? '-'),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

          // Work Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (complaintDetail != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ComplainWorkFormScreen(
                          assetCode:
                              complaintDetail!['asset_id']?.toString() ?? '-',
                          assetName: complaintDetail!['asset_name'] ?? '-',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  'Work',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
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
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
