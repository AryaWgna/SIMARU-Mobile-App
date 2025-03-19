import 'package:flutter/material.dart';
import 'stockopname_detail.dart';
import 'stockopname_scan_completed.dart';
import '../../widgets/custom_app_bar.dart';

class StockopnameScanResultScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const StockopnameScanResultScreen({
    super.key,
    required this.task,
  });

  @override
  _StockopnameScanResultScreenState createState() =>
      _StockopnameScanResultScreenState();
}

class _StockopnameScanResultScreenState
    extends State<StockopnameScanResultScreen> {
  // State untuk menentukan tampilan (scan atau result)
  bool _showResultView = false;
  bool _isLostView = false;

  // Data dummy
  late List<Map<String, dynamic>> scannedAssets;
  late List<Map<String, dynamic>> unscannedAssets;

  @override
  void initState() {
    super.initState();

    // Tambahkan variabel state baru untuk menyimpan status tombol lost
    _isLostView = false;

    // Initialize data
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

  // Navigasi ke detail form
  void _navigateToDetail([Map<String, dynamic>? existingAsset]) {
    Map<String, dynamic> assetData = existingAsset ??
        {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': 'Asset Name',
          'code': 'ASSET00${widget.task['id']}',
          'location': widget.task['location'],
          'condition': '',
          'notes': '',
          'status': 'Pending',
        };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockopnameDetailFormScreen(
          asset: assetData,
          task: widget.task,
        ),
      ),
    ).then((updatedAsset) {
      if (updatedAsset != null) {
        setState(() {
          if (existingAsset != null) {
            // Asset yang sudah ada, cari dari unscanned
            int index = unscannedAssets
                .indexWhere((a) => a['id'] == updatedAsset['id']);
            if (index != -1) {
              unscannedAssets.removeAt(index);
              scannedAssets.add(updatedAsset);
              widget.task['foundAssets'] = widget.task['foundAssets'] + 1;
            }
          } else {
            // Asset baru, tambahkan ke scanned
            scannedAssets.add(updatedAsset);
            widget.task['foundAssets'] = widget.task['foundAssets'] + 1;
          }
        });
      }
    });
  }

  // Navigasi ke completed screen
  void _navigateToCompleted() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockopnameScanCompletedScreen(task: widget.task),
      ),
    );
  }

  // Toggle antara view scan dan result
  void _toggleView({bool isLostView = false}) {
    setState(() {
      // Jika sudah dalam result view dan _isLostView sama dengan parameter,
      // kembali ke tampilan scan
      if (_showResultView && _isLostView == isLostView) {
        _showResultView = false;
        _isLostView = false;
      } else {
        // Jika tidak, atur ke tampilan result dengan mode lost atau tidak
        _showResultView = true;
        _isLostView = isLostView;
      }
    });
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
            if (_showResultView) {
              // Jika di result view, kembali ke scan view
              setState(() {
                _showResultView = false;
                _isLostView = false; // Reset isLostView saat kembali
              });
            } else {
              // Jika di scan view, kembali ke halaman sebelumnya
              Navigator.pop(context);
            }
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
                  if (_showResultView) {
                    // Dalam result view, kembalikan ke scan view
                    setState(() {
                      _showResultView = false;
                    });
                  } else {
                    // Dalam scan view, navigasi ke detail form
                    _navigateToDetail();
                  }
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

          // Conditional part based on view state
          if (!_showResultView) ...[
            // SCAN VIEW
            const SizedBox(height: 20),

            // Asset Card (if any scanned asset exists)
            if (scannedAssets.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
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

                      // Right details
                      const Padding(
                        padding: EdgeInsets.only(left: 9.0, top: 5.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Asset Name',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Status: Found',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Condition: Good',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Notes: -',
                              style: TextStyle(
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
                ),
              ),

            const Spacer(),

            // Bottom Buttons
            Padding(
              padding:
                  const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 23.0),
              child: Row(
                children: [
                  // Lost Button (Red) - Toggle to result view
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => _toggleView(isLostView: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.highlight_off,
                                color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Lost',
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

                  const SizedBox(width: 14),

                  // Done Button (Green) - Navigate to completed
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _navigateToCompleted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLostView
                              ? Colors.red
                              : const Color(0xFF659B09),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                        ),
                        child: _isLostView
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.highlight_off,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Lost',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
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
          ] else ...[
            // RESULT VIEW
            // Unscanned Assets Container
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
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
                      padding:
                          EdgeInsets.only(left: 24.0, top: 33.0, bottom: 20.0),
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
                            child: _buildUnscannedAssetCard(
                                unscannedAssets[index]),
                          );
                        },
                      ),
                    ),

                    // Done Button
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 24.0, right: 24.0, bottom: 23.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isLostView
                              ? () => _toggleView(
                                  isLostView:
                                      true) // Kembali ke scan view jika di mode lost
                              : _navigateToCompleted, // Navigasi ke completed jika tidak di mode lost
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLostView
                                ? Colors.red
                                : const Color(0xFF659B09),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 4,
                          ),
                          child: _isLostView
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.highlight_off,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      'Lost', // Mengganti teks "Lost" menjadi "Kembali" untuk kejelasan
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
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

            // Right details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9.0, 5.0, 9.0, 5.0),
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
                      overflow: TextOverflow.ellipsis,
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
                      overflow: TextOverflow.ellipsis,
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
                      overflow: TextOverflow.ellipsis,
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
}
