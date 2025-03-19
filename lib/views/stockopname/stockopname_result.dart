// stockopname_result_screen.dart
import 'package:flutter/material.dart';
import 'stockopname_detail.dart';
import 'stockopname_scan_completed.dart';

class StockopnameResultScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const StockopnameResultScreen({
    super.key,
    required this.task,
  });

  @override
  _StockopnameResultScreenState createState() =>
      _StockopnameResultScreenState();
}

class _StockopnameResultScreenState extends State<StockopnameResultScreen> {
  late List<Map<String, dynamic>> scannedAssets;
  late List<Map<String, dynamic>> unscannedAssets;

  @override
  void initState() {
    super.initState();
    // Data dummy untuk aset yang sudah discan
    scannedAssets = [
      {
        'id': '1',
        'name': 'Asset Name',
        'code': 'ASSET001',
        'location': widget.task['location'],
        'condition': 'Good',
        'notes': '-',
        'status': 'Found',
      }
    ];

    // Data dummy untuk aset yang belum discan
    unscannedAssets = [
      {
        'id': '2',
        'name': 'Asset Name',
        'code': 'ASSET002',
        'location': widget.task['location'],
        'isAvailable': true,
      },
      {
        'id': '3',
        'name': 'Asset Name',
        'code': 'ASSET003',
        'location': widget.task['location'],
        'isAvailable': true,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF213268),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Image.asset(
          'images/Logo_RS_UMMI_white.png',
          height: 55,
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
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

                  // Right Column - Values
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatValue(
                          '${widget.task['foundAssets']}/${widget.task['totalAssets']}'),
                      _buildStatValue('${widget.task['wrongLocation']}'),
                      _buildStatValue('${widget.task['slightlyDMG']}'),
                      _buildStatValue('${widget.task['highlyDMG']}'),
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
                  // Handle scan action
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

          // Container for Unscanned Assets
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    spreadRadius: 0,
                    blurRadius: 5,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(
                        left: 24.0, top: 33.0, bottom: 20.0),
                    child: Text(
                      'Unscanned Assets',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  // List of unscanned assets
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: unscannedAssets.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child:
                              _buildUnscannedAssetCard(unscannedAssets[index]),
                        );
                      },
                    ),
                  ),

                  // Bottom Buttons
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 24.0, right: 24.0, bottom: 23.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => _navigateToCompleted(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF659B09),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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

  Widget _buildUnscannedAssetCard(Map<String, dynamic> asset) {
    return GestureDetector(
      onTap: () => _navigateToDetail(asset),
      child: Container(
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

            // Right details - tambahkan Expanded dan padding kanan
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    9.0, 5.0, 9.0, 5.0), // Tambahkan padding kanan
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
                      overflow: TextOverflow
                          .ellipsis, // Tambahkan ellipsis untuk teks panjang
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Asset Code: ${asset['code']}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow
                          .ellipsis, // Tambahkan ellipsis untuk teks panjang
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Location: ${asset['location']}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow
                          .ellipsis, // Tambahkan ellipsis untuk teks panjang
                    ),
                    const SizedBox(height: 10),
                    // Available badge
                    Container(
                      width: 98,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF659B09),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Center(
                        child: Text(
                          'Available',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> asset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockopnameDetailFormScreen(
          asset: asset,
          task: widget.task,
        ),
      ),
    ).then((updatedAsset) {
      if (updatedAsset != null) {
        setState(() {
          // Hapus asset dari unscanned dan tambahkan ke scanned
          int index =
              unscannedAssets.indexWhere((a) => a['id'] == updatedAsset['id']);
          if (index != -1) {
            unscannedAssets.removeAt(index);
            scannedAssets.add(updatedAsset);

            // Update task stats
            widget.task['foundAssets'] = widget.task['foundAssets'] + 1;
          }
        });
      }
    });
  }

  void _navigateToCompleted() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockopnameScanCompletedScreen(task: widget.task),
      ),
    );
  }
}
