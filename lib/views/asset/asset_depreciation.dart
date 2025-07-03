import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'asset_document.dart';
import 'asset_history.dart';
import 'asset_schedule.dart';
import 'asset_mutation.dart';
import 'asset_details.dart';

class AssetDepreciation extends StatefulWidget {
  const AssetDepreciation({super.key});

  @override
  State<AssetDepreciation> createState() => _AssetDepreciationState();
}

class _AssetDepreciationState extends State<AssetDepreciation> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAssetInfoTable(screenWidth),
                const SizedBox(height: 24),
                _buildDepreciationChart(screenWidth),
                const SizedBox(height: 24),
                _buildDepreciationTable(screenWidth),
                // Tambahkan bottom padding untuk menghindari tertutup oleh tab bar
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, 'depreciation'),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    // Ukur tinggi status bar
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return PreferredSize(
      preferredSize: const Size.fromHeight(82),
      child: Stack(
        children: [
          // Warna biru tua untuk AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 82 + statusBarHeight,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF213268),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF56C5F1),
                    blurRadius: 3,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),

          // AppBar Content
          Positioned(
            top: statusBarHeight,
            left: 0,
            right: 0,
            height: 82,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 32),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AssetDetails(qrData: '')),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: Image.asset(
                        'images/Logo_RS_UMMI_white.png',
                        width: 208.14,
                        height: 55,
                        fit: BoxFit.contain,
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

  Widget _buildAssetInfoTable(double screenWidth) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF213268),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Text(
              'Asset Information',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          _buildInfoRow('Date Acquired', '-'),
          _buildInfoRow('Total Cost', '-'),
          _buildInfoRow('Salvage Value', '-'),
          _buildInfoRow('Asset Life', '-'),
          _buildInfoRow('Depreciation Method', '-'),
          _buildInfoRow('Condition', '-'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEF1F4), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Color(0xFF3D3D3D),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Color(0xFF3D3D3D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepreciationChart(double screenWidth) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF213268),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Text(
              'Depreciation Monthly Status',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(
                        color: Color(0xFFECECEC),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return const FlLine(
                        color: Color(0xFFECECEC),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              (2025 + value.toInt()).toString(),
                              style: const TextStyle(
                                color: Color(0xFF4F4F4F),
                                fontSize: 10,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}M',
                            style: const TextStyle(
                              color: Color(0xFF4F4F4F),
                              fontSize: 10,
                              fontFamily: 'Poppins',
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 5),
                        FlSpot(1, 4.5),
                        FlSpot(2, 3.5),
                        FlSpot(3, 3),
                        FlSpot(4, 2),
                        FlSpot(5, 1.5),
                      ],
                      isCurved: true,
                      color: const Color(0xFF56C5F1),
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: const Color(0xFF165BAA),
                            strokeColor: const Color(0xFF165BAA),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepreciationTable(double screenWidth) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF213268),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Text(
              'Depreciation Schedule',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFFF5F7FA),
              ),
              columnSpacing: 16,
              horizontalMargin: 16,
              columns: const [
                DataColumn(
                  label: Text(
                    '#',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D3D3D),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Month',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D3D3D),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Depreciation\nExpense',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D3D3D),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Accumulated\nDepreciation',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D3D3D),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Book Value\n(End of Year)',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D3D3D),
                    ),
                  ),
                ),
              ],
              rows: [
                _buildDataTableRow(
                    '1', 'Jan', '100,000', '100,000', '4,900,000'),
                _buildDataTableRow(
                    '2', 'Feb', '100,000', '200,000', '4,800,000'),
                _buildDataTableRow(
                    '3', 'Mar', '100,000', '300,000', '4,700,000'),
                _buildDataTableRow(
                    '4', 'Apr', '100,000', '400,000', '4,600,000'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataTableRow(String no, String month, String expense,
      String accumulated, String bookValue) {
    return DataRow(
      cells: [
        DataCell(Text(
          no,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFF3D3D3D),
          ),
        )),
        DataCell(Text(
          month,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFF3D3D3D),
          ),
        )),
        DataCell(Text(
          expense,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFF3D3D3D),
          ),
        )),
        DataCell(Text(
          accumulated,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFF3D3D3D),
          ),
        )),
        DataCell(Text(
          bookValue,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFF3D3D3D),
          ),
        )),
      ],
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, String activePage) {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, -4),
            blurRadius: 4,
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            Icons.folder,
            'Document',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssetDocument()),
            ),
          ),
          _buildNavItem(
            Icons.history,
            'History',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssetHistory()),
            ),
          ),
          _buildNavItem(
            Icons.calendar_today,
            'Schedule',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssetSchedule()),
            ),
          ),
          _buildNavItem(
            Icons.swap_horiz,
            'Mutasi',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssetMutation()),
            ),
          ),
          _buildNavItem(
            Icons.trending_down,
            'Depreciation',
            activePage == 'depreciation',
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isActive ? const Color(0xFF213268) : const Color(0xFF757575),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: isActive
                    ? const Color(0xFF213268)
                    : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
