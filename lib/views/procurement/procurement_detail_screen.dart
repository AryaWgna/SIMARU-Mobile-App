import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/custom_app_bar.dart';

class ProcurementDetailScreen extends StatelessWidget {
  final String title;
  final String status;
  final String priority;
  final String requestDate;

  const ProcurementDetailScreen({
    super.key,
    required this.title,
    required this.status,
    required this.priority,
    required this.requestDate,
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul di bawah AppBar
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildInfoRow('Procurement ID', '-'),
                  ),

                  _buildDivider(),

                  // Title Request
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildInfoRow('Title Request', title),
                  ),

                  _buildDivider(),

                  // Requester
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildInfoRow('Requester', '-'),
                  ),

                  _buildDivider(),

                  // Request Date
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildInfoRow('Request Date', requestDate),
                  ),

                  _buildDivider(),

                  // Status - Diubah sesuai gambar dengan teks di kanan
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Status',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDAAE0F),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Under Review',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  _buildDivider(),

                  // List Asset Header
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.grey.shade200,
                    child: Text(
                      'List Asset',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF213268),
                      ),
                    ),
                  ),

                  // Asset Item 1
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _buildAssetItemDetailed(
                          assetName: 'Asset 1',
                          qty: '1',
                          estimated: '7.000.000/2.000.000',
                        ),
                      ),
                    ),
                  ),

                  // Asset Item 2
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _buildAssetItemDetailed(
                          assetName: 'Asset 2',
                          qty: '1',
                          estimated: '7.000.000/2.000.000',
                        ),
                      ),
                    ),
                  ),

                  // Spacer untuk memastikan Est. Grand Total berada di bawah
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Est. Grand Total - Posisi fixed di bawah
          Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Est. Grand Total:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Rp. xx.xxx.xxxx',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFE0E0E0),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetItemDetailed({
    required String assetName,
    required String qty,
    required String estimated,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                'Asset Name',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: Text(
                assetName,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Qty
        Padding(
          padding: const EdgeInsets.only(left: 100),
          child: Text(
            'Qty: $qty',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),

        const SizedBox(height: 2),

        // Estimated
        Padding(
          padding: const EdgeInsets.only(left: 100),
          child: Text(
            'Estimated: $estimated',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
