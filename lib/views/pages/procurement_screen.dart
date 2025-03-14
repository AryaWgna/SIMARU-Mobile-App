import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';

class ProcurementScreen extends StatefulWidget {
  const ProcurementScreen({Key? key}) : super(key: key);

  @override
  State<ProcurementScreen> createState() => _ProcurementScreenState();
}

class _ProcurementScreenState extends State<ProcurementScreen> {
  int _selectedTabIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  Widget _buildTabButton(String text, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF213268) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF213268),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF213268),
          ),
        ),
      ),
    );
  }

  Widget _buildProcurementItem({
    required String title,
    required String status,
    required IconData statusIcon,
    required Color statusIconColor,
    required String priority,
    required Color priorityColor,
    required String quantity,
    required String requestDate,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 4,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: Color.fromRGBO(0, 0, 0, 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                    'Status:',
                    Row(
                      children: [
                        Icon(statusIcon, color: statusIconColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )),
                const SizedBox(height: 8),
                _buildInfoRow(
                    'Priority:',
                    Text(
                      priority,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: priorityColor,
                      ),
                    )),
                const SizedBox(height: 8),
                _buildInfoRow(
                    'Qty:',
                    Text(
                      quantity,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                      ),
                    )),
                const SizedBox(height: 8),
                _buildInfoRow(
                    'Request Date:',
                    Text(
                      requestDate,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, Widget value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        value,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          // Tab buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                _buildTabButton('Request', _selectedTabIndex == 0, 0),
                const SizedBox(width: 8),
                _buildTabButton('Quotation', _selectedTabIndex == 1, 1),
                const SizedBox(width: 8),
                _buildTabButton('Purchase Order', _selectedTabIndex == 2, 2),
                const SizedBox(width: 8),
                _buildTabButton('Receipt', _selectedTabIndex == 3, 3),
              ],
            ),
          ),
          // Procurement List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_selectedTabIndex == 0) ...[
                  // Request Tab
                  _buildProcurementItem(
                    title: 'Title',
                    status: 'Submitted',
                    statusIcon: Icons.check_circle_outline,
                    statusIconColor: const Color(0xFF757575),
                    priority: 'High',
                    priorityColor: Colors.red,
                    quantity: '1',
                    requestDate: '06/03/2025',
                  ),
                  _buildProcurementItem(
                    title: 'Title',
                    status: 'Under Review',
                    statusIcon: Icons.access_time,
                    statusIconColor: const Color(0xFFDAAE0F),
                    priority: 'Medium',
                    priorityColor: const Color(0xFFF16A1B),
                    quantity: '1',
                    requestDate: '06/03/2025',
                  ),
                  _buildProcurementItem(
                    title: 'Title',
                    status: 'Approved',
                    statusIcon: Icons.check_circle,
                    statusIconColor: const Color(0xFF659B09),
                    priority: 'Low',
                    priorityColor: const Color(0xFF659B09),
                    quantity: '1',
                    requestDate: '06/03/2025',
                  ),
                  _buildProcurementItem(
                    title: 'Title',
                    status: 'Rejected',
                    statusIcon: Icons.cancel_outlined,
                    statusIconColor: Colors.red,
                    priority: 'High',
                    priorityColor: Colors.red,
                    quantity: '1',
                    requestDate: '06/03/2025',
                  ),
                ] else if (_selectedTabIndex == 1) ...[
                  // Quotation Tab
                  _buildProcurementItem(
                    title: 'Title',
                    status: 'Under Review',
                    statusIcon: Icons.access_time,
                    statusIconColor: const Color(0xFFDAAE0F),
                    priority: 'Medium',
                    priorityColor: const Color(0xFFF16A1B),
                    quantity: '1',
                    requestDate: '06/03/2025',
                  ),
                  _buildProcurementItem(
                    title: 'Title',
                    status: 'Under Review',
                    statusIcon: Icons.access_time,
                    statusIconColor: const Color(0xFFDAAE0F),
                    priority: 'High',
                    priorityColor: Colors.red,
                    quantity: '2',
                    requestDate: '05/03/2025',
                  ),
                ] else if (_selectedTabIndex == 2) ...[
                  // Purchase Order Tab
                  _buildProcurementItem(
                    title: 'Vendor',
                    status: 'Under Review',
                    statusIcon: Icons.access_time,
                    statusIconColor: const Color(0xFFDAAE0F),
                    priority: 'High',
                    priorityColor: Colors.red,
                    quantity: '1',
                    requestDate: '05/03/2025',
                  ),
                ] else if (_selectedTabIndex == 3) ...[
                  // Receipt Tab
                  _buildProcurementItem(
                    title: 'Title',
                    status: 'Received',
                    statusIcon: Icons.check_circle,
                    statusIconColor: Colors.green,
                    priority: 'High',
                    priorityColor: Colors.red,
                    quantity: '1',
                    requestDate: '06/03/2025',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF25B1FF),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(37, 177, 255, 0.25),
              blurRadius: 8,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 24,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
