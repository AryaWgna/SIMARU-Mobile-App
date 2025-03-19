// stockopname_scan_screen.dart
import 'package:flutter/material.dart';
import 'stockopname_result.dart';
import 'stockopname_detail.dart';
import 'stockopname_scan_completed.dart';

class StockopnameScanScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const StockopnameScanScreen({
    super.key,
    required this.task,
  });

  @override
  _StockopnameScanScreenState createState() => _StockopnameScanScreenState();
}

class _StockopnameScanScreenState extends State<StockopnameScanScreen> {
  void _navigateToDetail() {
    Map<String, dynamic> assetData = {
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
    );
  }

  void _navigateToResult() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockopnameResultScreen(task: widget.task),
      ),
    );
  }

  void _navigateToCompleted() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockopnameScanCompletedScreen(task: widget.task),
      ),
    );
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
                onPressed: () => _navigateToDetail(),
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

          // Asset Card
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
                // Lost Button (Red)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => _navigateToResult(),
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

                // Done Button (Green)
                Expanded(
                  child: SizedBox(
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
}
