import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/custom_app_bar.dart';
import 'complain_form_screen.dart';
import 'complain_detail_screen.dart';

class ComplainListScreen extends StatelessWidget {
  const ComplainListScreen({super.key});

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'Report Teknisi',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF213268),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildComplainItem(
                  context: context,
                  date: '06 March 2025 16:02:02',
                  timeAgo: '2 Minutes ago',
                  assetCode: 'Asset Code',
                  assetName: 'Asset Name',
                  brandName: 'Brand Name',
                  serialNumber: '12345678',
                  location: 'Location',
                  performedBy: 'Jhon Doe',
                  complainDesc: 'Complaint Desc',
                ),
                _buildComplainItem(
                  context: context,
                  date: '06 March 2025 16:02:02',
                  timeAgo: '2 Minutes ago',
                  assetCode: 'Asset Code',
                  assetName: 'Asset Name',
                  brandName: 'Brand Name',
                  serialNumber: '12345678',
                  location: 'Location',
                  performedBy: 'Jhon Doe',
                  complainDesc: 'Complaint Desc',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ComplainFormScreen()),
          );
        },
        backgroundColor: const Color(0xFF213268),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildComplainItem({
    required BuildContext context,
    required String date,
    required String timeAgo,
    required String assetCode,
    required String assetName,
    required String brandName,
    required String serialNumber,
    required String location,
    required String performedBy,
    required String complainDesc,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  timeAgo,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assetCode,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  assetName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$brandName | SN : $serialNumber',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performedBy,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  complainDesc,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComplainDetailScreen(
                    assetCode: assetCode,
                    assetName: assetName,
                    performedBy: performedBy,
                    complainDesc: complainDesc,
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Center(
                child: Text(
                  'Work',
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
  }
}
