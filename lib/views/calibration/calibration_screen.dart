import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/custom_app_bar.dart';
import 'calibration_detail_screen.dart';
import 'calibration_detail_progress_screen.dart';
import 'calibration_detail_work_screen.dart';
import 'calibration_assist_screen.dart';

class CalibrationScreen extends StatelessWidget {
  const CalibrationScreen({super.key});

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 16),
              child: Text(
                'Calibration',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF213268),
                ),
              ),
            ),
            _buildCalibrationItem(
              context: context,
              date: '06 March 2025',
              status: 'Scheduled',
              statusColor: Colors.grey,
              assetName: 'Asset Name',
              brandName: 'Brand Name',
              serialNumber: '12345678',
              location: 'Location',
              performedBy: 'Vendor Name',
              buttonText: 'Assist',
              buttonColor: const Color(0xFF213268),
              onButtonTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalibrationAssistScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildCalibrationItem(
              context: context,
              date: '06 March 2025',
              status: 'In Progress',
              statusColor: Colors.blue,
              assetName: 'Asset Name',
              brandName: 'Brand Name',
              serialNumber: '12345678',
              location: 'Location',
              performedBy: 'Technician Name',
              buttonText: 'Work',
              buttonColor: Colors.blue,
              onButtonTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalibrationDetailWorkScreen(
                      performedBy: 'Technician Name',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildCalibrationItem(
              context: context,
              date: '06 March 2025',
              status: 'In Progress',
              statusColor: Colors.blue,
              assetName: 'Asset Name',
              brandName: 'Brand Name',
              serialNumber: '12345678',
              location: 'Location',
              performedBy: 'Vendor Name',
              buttonText: 'Done',
              buttonColor: const Color(0xFF76B947),
              onButtonTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalibrationDetailProgressScreen(
                      performedBy: 'Vendor Name',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationItem({
    required BuildContext context,
    required String date,
    required String status,
    required Color statusColor,
    required String assetName,
    required String brandName,
    required String serialNumber,
    required String location,
    required String performedBy,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onButtonTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Monthly',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      status == 'In Progress' ? Icons.sync : Icons.schedule,
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[300],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asset Code',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        assetName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Brand Name | SN : $serialNumber',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perform by',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  performedBy,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onButtonTap,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Center(
                child: Text(
                  buttonText,
                  style: GoogleFonts.inter(
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
}
