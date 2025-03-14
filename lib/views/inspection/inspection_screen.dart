import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/custom_app_bar.dart';
import 'inspection_detail_screen.dart';
import 'inspection_detail_work_screen.dart';
import 'inspection_detail_completed_screen.dart';

class InspectionScreen extends StatelessWidget {
  const InspectionScreen({Key? key}) : super(key: key);

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
                'Inspection',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF213268),
                ),
              ),
            ),
            _buildInspectionItem(
              context: context,
              date: '06 March 2025',
              status: 'Scheduled',
              statusColor: Colors.blue,
              statusIcon: Icons.schedule,
              buttonText: 'Work',
              buttonColor: Colors.blue,
              showButton: true,
              onButtonTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const InspectionDetailWorkScreen()),
                );
              },
              onItemTap: () {
                // Tidak ada navigasi saat mengklik item "Scheduled"
              },
            ),
            const SizedBox(height: 16),
            _buildInspectionItem(
              context: context,
              date: '06 March 2025',
              status: 'In Progress',
              statusColor: Colors.blue,
              statusIcon: Icons.sync,
              buttonText: 'Done',
              buttonColor: const Color(0xFF76B947),
              showButton: true,
              onButtonTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const InspectionDetailScreen()),
                );
              },
              onItemTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const InspectionDetailScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildInspectionItem(
              context: context,
              date: '06 March 2025',
              status: 'Completed',
              statusColor: Colors.green,
              statusIcon: Icons.check_circle,
              buttonText: 'Passed',
              buttonColor: const Color(0xFF76B947),
              showButton: true,
              onButtonTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const InspectionDetailCompletedScreen()),
                );
              },
              onItemTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const InspectionDetailCompletedScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionItem({
    required BuildContext context,
    required String date,
    required String status,
    required Color statusColor,
    required IconData statusIcon,
    required String buttonText,
    required Color buttonColor,
    required bool showButton,
    required VoidCallback onButtonTap,
    required VoidCallback onItemTap,
  }) {
    return GestureDetector(
      onTap: onItemTap,
      child: Container(
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
                      Icon(statusIcon, color: statusColor, size: 16),
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
                          'Asset Name',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Brand Name | SN : 12345678',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Location',
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
                    'Inspect by Jhon Doe',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Routine',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (showButton)
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
      ),
    );
  }
}
