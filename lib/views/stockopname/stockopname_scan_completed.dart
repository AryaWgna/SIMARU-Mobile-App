// stockopname_scan_completed_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import 'stockopname_detail.dart';

class StockopnameScanCompletedScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const StockopnameScanCompletedScreen({
    super.key,
    required this.task,
  });

  @override
  _StockopnameScanCompletedScreenState createState() =>
      _StockopnameScanCompletedScreenState();
}

class _StockopnameScanCompletedScreenState
    extends State<StockopnameScanCompletedScreen> {
  late List<Map<String, dynamic>> scannedAssets;

  @override
  void initState() {
    super.initState();
    // Data dummy untuk multiple asset yang sudah discan
    scannedAssets = [
      {
        'id': '1',
        'name': 'Asset Name',
        'code': 'ASSET001',
        'location': widget.task['location'],
        'condition': 'Good',
        'notes': '-',
        'status': 'Found',
      },
      {
        'id': '2',
        'name': 'Asset Name',
        'code': 'ASSET002',
        'location': widget.task['location'],
        'condition': 'Fair',
        'notes': '-',
        'status': 'Found',
      },
      {
        'id': '3',
        'name': 'Asset Name',
        'code': 'ASSET003',
        'location': widget.task['location'],
        'condition': 'Good',
        'notes': 'Needs cleaning',
        'status': 'Found',
      },
      {
        'id': '4',
        'name': 'Asset Name',
        'code': 'ASSET004',
        'location': widget.task['location'],
        'condition': 'Poor',
        'notes': 'Requires maintenance',
        'status': 'Found',
      },
    ];
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: const CustomAppBar(),
        toolbarHeight: 82,
      ),
      body: Column(
        children: [
          // Building name title
          const Padding(
            padding: EdgeInsets.only(top: 28.0, bottom: 24.0),
            child: Center(
              child: Text(
                'Building A, ICU 1st Floor',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF213268),
                ),
              ),
            ),
          ),

          // Statistics
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
              height: 114,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column - Labels
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatLabel('Found'),
                      _buildStatLabel('Wrong Location'),
                      _buildStatLabel('Slightly DMG'),
                      _buildStatLabel('Highly DMG'),
                    ],
                  ),

                  // Right Column - Values - Showing all assets found
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatValue('50/50'),
                      _buildStatValue('0'),
                      _buildStatValue('0'),
                      _buildStatValue('0'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 33),

          // Scan button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StockopnameDetailFormScreen(
                        asset: {
                          'id':
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          'name': 'Asset Name',
                          'code': 'ASSET00X',
                          'location': widget.task['location'],
                          'condition': '',
                          'notes': '',
                          'status': 'Pending',
                        },
                        task: widget.task,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF213268),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Scan',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 21),

          // Scan Result Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Scan Result',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF213268),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // List of Scanned Assets
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ListView.builder(
                itemCount: scannedAssets.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 21.0),
                    child: _buildAssetCard(scannedAssets[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }

  Widget _buildStatValue(String value) {
    return Text(
      ': $value',
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }

  Widget _buildAssetCard(Map<String, dynamic> asset) {
    return Container(
      height: 121,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left image placeholder
          Container(
            width: 121,
            height: 121,
            decoration: const BoxDecoration(
              color: Color(0xFFB3B3B3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),

          // Right details - pertahankan detail aset yang sudah ada
          Padding(
            padding: const EdgeInsets.only(left: 9.0, top: 5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset['name'],
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Status: ${asset['status']}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Condition: ${asset['condition']}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Notes: ${asset['notes']}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
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
}
