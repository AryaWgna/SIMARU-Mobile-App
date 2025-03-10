import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  Widget _buildHistoryItem(String date, String time, String assetId,
      String fromStatus, String toStatus) {
    return Container(
      width: 360,
      height: 73,
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Blue line on the left
          Container(
            width: 8,
            height: 73,
            decoration: const BoxDecoration(
              color: Color(0xFF25B1FF),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
          ),
          // Date and time
          Positioned(
            left: 19,
            top: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
          // Vertical divider
          Positioned(
            left: 110,
            top: 0,
            child: Container(
              width: 1,
              height: 73,
              color: const Color(0xFFCAC4D0),
            ),
          ),
          // Asset info
          Positioned(
            left: 128,
            top: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assetId,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    children: [
                      const TextSpan(text: 'You change status from '),
                      TextSpan(
                        text: fromStatus,
                        style: TextStyle(
                          color: fromStatus == 'Available'
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFFA726),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' to '),
                      TextSpan(
                        text: toStatus,
                        style: TextStyle(
                          color: toStatus == 'Available'
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFFA726),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(82),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF213268),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF56C5F1),
                blurRadius: 7.3,
                offset: Offset(0, 3),
                spreadRadius: 3,
              ),
            ],
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Image.asset(
                'images/Logo_RS_UMMI_white.png',
                width: 208.14,
                height: 55,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Title and subtitle
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 27, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'History',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF213268),
                      height: 0.56,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Display all your activities',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF757575),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'March',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF213268),
                      height: 0.75,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // History items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 9, 24, 0),
              child: ListView(
                children: [
                  _buildHistoryItem('04 Mar 25', '16:00', 'Asset ID: 123456',
                      'Checked Out', 'Available'),
                  _buildHistoryItem('04 Mar 25', '08:00', 'Asset ID: 123456',
                      'Available', 'Checked Out'),
                  _buildHistoryItem('03 Mar 25', '16:00', 'Asset ID: 123456',
                      'Checked Out', 'Available'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
