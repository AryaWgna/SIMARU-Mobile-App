import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/custom_app_bar.dart';
import 'maintenance_form_screen.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({Key? key}) : super(key: key);

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
            // Menambahkan judul di bawah AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'Maintenance Teknisi',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF213268),
                ),
              ),
            ),

            // Item dengan status Scheduled
            _buildMaintenanceItem(
              context: context,
              date: '06 March 2025',
              status: 'Scheduled',
              statusColor: Colors.grey,
              assetName: 'Asset Name',
              assetCode: 'Asset Code',
              brandName: 'Brand Name',
              serialNumber: '12345678',
              location: 'Location',
              performedBy: 'Jhon Doe',
              maintenanceDesc: 'Maintenance Desc',
              showButton: true,
              buttonText: 'Work',
              buttonColor: const Color(0xFF2196F3),
              onButtonTap: () {
                _showScheduledDetail(context);
              },
            ),

            // Item dengan status In Progress
            _buildMaintenanceItem(
              context: context,
              date: '06 March 2025',
              status: 'In Progress',
              statusColor: Colors.blue,
              assetName: 'Asset Name',
              assetCode: 'Asset Code',
              brandName: 'Brand Name',
              serialNumber: '12345678',
              location: 'Location',
              performedBy: 'Jhon Doe',
              maintenanceDesc: 'Maintenance Desc',
              showButton: true,
              buttonText: 'Done',
              buttonColor: const Color(0xFF76B947),
              onButtonTap: () {
                _showInProgressDetail(context);
              },
            ),

            // Item dengan status Completed
            _buildMaintenanceItem(
              context: context,
              date: '06 March 2025',
              status: 'Completed',
              statusColor: Colors.green,
              assetName: 'Asset Name',
              assetCode: 'Asset Code',
              brandName: 'Brand Name',
              serialNumber: '12345678',
              location: 'Location',
              performedBy: 'Jhon Doe',
              maintenanceDesc: 'Maintenance Desc',
              showButton: false,
              nextMaintenance: 'Next Maintenance on April 8th',
              price: 'Rp.xxxx.xxxx',
              buttonText: '',
              buttonColor: Colors.transparent,
              onButtonTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceItem({
    required BuildContext context,
    required String date,
    required String status,
    required Color statusColor,
    required String assetName,
    required String assetCode,
    required String brandName,
    required String serialNumber,
    required String location,
    required String performedBy,
    required String maintenanceDesc,
    required bool showButton,
    String? nextMaintenance,
    String? price,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onButtonTap,
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
          // Header with date and status
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
                      'Monthly',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if (nextMaintenance != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          nextMaintenance,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      status == 'In Progress'
                          ? Icons.sync
                          : (status == 'Completed'
                              ? Icons.check_circle
                              : Icons.schedule),
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Asset info section
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Asset image placeholder
                Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(width: 12),

                // Asset details
                Expanded(
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
                        'Brand Name | SN : $serialNumber',
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
              ],
            ),
          ),

          // Perform by section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perform by $performedBy',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  maintenanceDesc,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                if (price != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      price,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Button (if needed)
          if (showButton)
            GestureDetector(
              onTap: onButtonTap,
              child: Container(
                width: double.infinity,
                height: 40,
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

  // Fungsi untuk menampilkan detail item dengan status Scheduled
  void _showScheduledDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaintenanceDetailScreen(
          status: 'Scheduled',
          performedBy: 'Jhon Doe',
        ),
      ),
    );
  }

  // Fungsi untuk menampilkan detail item dengan status In Progress
  void _showInProgressDetail(BuildContext context) {
    // Langsung navigasi ke form submit
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MaintenanceFormScreen(),
      ),
    );
  }
}

// Halaman detail untuk item dengan status Scheduled
class MaintenanceDetailScreen extends StatelessWidget {
  final String status;
  final String performedBy;

  const MaintenanceDetailScreen({
    Key? key,
    required this.status,
    required this.performedBy,
  }) : super(key: key);

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
            padding: const EdgeInsets.all(16),
            child: Text(
              'MAINTENANCE DETAIL',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF213268),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
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
                    const SizedBox(height: 16),
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
                            Icon(
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

                    // Maintenance Information Section
                    const SizedBox(height: 24),
                    Text(
                      'Maintenance Information',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF213268),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Maintenance Date', '-'),
                    _buildInfoRow('Perform by', '-'),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Done Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the form screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MaintenanceFormScreen(),
                    ),
                  );
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    const Color(0xFF76B947),
                  ),
                  shape: MaterialStateProperty.all(
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

// Halaman detail untuk item dengan status In Progress
class MaintenanceDetailProgressScreen extends StatelessWidget {
  final String performedBy;

  const MaintenanceDetailProgressScreen({
    Key? key,
    required this.performedBy,
  }) : super(key: key);

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
              'MAINTENANCE DETAIL',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF213268),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
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
                    const SizedBox(height: 16),
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

                    // Maintenance Information Section
                    const SizedBox(height: 24),
                    Text(
                      'Maintenance Information',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF213268),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Maintenance Date', '-'),
                    _buildInfoRow('Perform by', performedBy),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Done Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the form screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MaintenanceFormScreen(),
                    ),
                  );
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    const Color(0xFF76B947),
                  ),
                  shape: MaterialStateProperty.all(
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
