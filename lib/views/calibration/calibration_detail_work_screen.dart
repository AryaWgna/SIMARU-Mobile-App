import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/custom_app_bar.dart';
import 'calibration_detail_progress_screen.dart';

class CalibrationDetailWorkScreen extends StatelessWidget {
  final String performedBy;

  const CalibrationDetailWorkScreen({
    super.key,
    required this.performedBy,
  });

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul Calibration Detail
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'CALIBRATION DETAIL',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF213268),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Asset Image
                  Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  // Asset Basic Info with Status
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asset Code',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF213268),
                            ),
                          ),
                          Text(
                            'Asset Name',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF213268),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.sync,
                            color: Colors.blue,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'In Progress',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Asset Information Section
                  const SizedBox(height: 24),
                  Text(
                    'Asset Information',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF213268),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Categories', '-'),
                  _buildInfoRow('Sub Categories', '-'),
                  _buildInfoRow('Location', '-'),
                  _buildInfoRow('Brand', '-'),
                  _buildInfoRow('Model Number', '-'),
                  _buildInfoRow('Serial Number', '-'),

                  // Calibration Information Section
                  const SizedBox(height: 24),
                  Text(
                    'Calibration Information',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF213268),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Calibration Date', '-'),
                  _buildInfoRow('Perform by', performedBy),

                  // Done Button
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigasi ke halaman detail dengan form submit
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CalibrationDetailProgressScreen(
                              performedBy: performedBy,
                            ),
                          ),
                        );
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          const Color(0xFF76B947),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
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
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
