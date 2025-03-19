import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import '../procurement/procurement_form_screen.dart';
import '../procurement/procurement_detail_screen.dart';

class ProcurementScreen extends StatefulWidget {
  const ProcurementScreen({Key? key}) : super(key: key);

  @override
  State<ProcurementScreen> createState() => _ProcurementScreenState();
}

class _ProcurementScreenState extends State<ProcurementScreen> {
  int _selectedTabIndex = 0;
  final List<VendorItem> vendors = [];

  @override
  void initState() {
    super.initState();
    // Tambahkan vendor default
    vendors.add(
      VendorItem(
        name: "Vendor Name",
        assets: [
          AssetItem(
              name: "Asset 1",
              qty: 3,
              estimated: "7.500.000(Rp/2.500.000)",
              actual: "900.000/bulan"),
          AssetItem(
              name: "Asset 2",
              qty: 3,
              estimated: "7.500.000(Rp/2.500.000)",
              actual: "900.000/bulan"),
        ],
        paymentTerms: "payment through commercial bank",
        deliveryTerms: "Delivery using JNE delivery service",
      ),
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _addVendor() {
    setState(() {
      vendors.add(
        VendorItem(
          name: "Vendor Name",
          assets: [
            AssetItem(
                name: "Asset 1",
                qty: 3,
                estimated: "7.500.000(Rp/2.500.000)",
                actual: "900.000/bulan"),
            AssetItem(
                name: "Asset 2",
                qty: 3,
                estimated: "7.500.000(Rp/2.500.000)",
                actual: "900.000/bulan"),
          ],
          paymentTerms: "payment through commercial bank",
          deliveryTerms: "Delivery using JNE delivery service",
        ),
      );
    });
  }

  void _removeVendor(int index) {
    setState(() {
      vendors.removeAt(index);
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProcurementDetailScreen(
              title: title,
              status: status,
              priority: priority,
              requestDate: requestDate,
            ),
          ),
        );
      },
      child: Container(
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
      ),
    );
  }

  // Fungsi untuk tampilan RFQ (Quotation)
  Widget _buildQuotationScreen() {
    return Column(
      children: [
        // Request For Quotation title
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: const Text(
            'REQUEST FOR QUOTATION',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF213268),
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Main content - scrollable
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info fields
                _buildQuotationInfoField('Procurement ID', '-'),
                _buildQuotationInfoField('Title Request', '-'),
                _buildQuotationInfoField('Requester', '-'),
                _buildQuotationInfoField('Request Date', '-'),

                const SizedBox(height: 16),

                // Choose Vendor section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Choose Vendor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF213268),
                      ),
                    ),
                    _buildAddVendorButton(),
                  ],
                ),

                const SizedBox(height: 12),

                // Vendor cards
                ...vendors
                    .map((vendor) =>
                        _buildVendorCard(vendor, vendors.indexOf(vendor)))
                    .toList(),

                // Partially visible vendor card to match the image
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Grand total section
                _buildEstGrandTotal('Est. Grand Total:', 'Rp. x.xxx.xxxx'),
                _buildEstGrandTotal('Vendor Grand Total:', 'Rp. x.xxx.xxxx'),
                _buildEstGrandTotal('Vendor2 Grand Total:', 'Rp. x.xxx.xxxx'),

                const SizedBox(height: 16),

                // Submit button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedTabIndex = 0; // Kembali ke tab Request
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF213268),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
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
    );
  }

  Widget _buildQuotationInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddVendorButton() {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF25B1FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton.icon(
        onPressed: _addVendor,
        icon: const Icon(
          Icons.add,
          color: Colors.white,
          size: 16,
        ),
        label: const Text(
          'Add Vendor',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildVendorCard(VendorItem vendor, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor name and actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vendor.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        // Edit vendor logic
                      },
                      child: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _removeVendor(index),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Asset divider
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),

          // Assets
          ...vendor.assets.map((asset) => _buildAssetItem(asset)).toList(),

          // Payment Terms
          Padding(
            padding:
                const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Terms',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  vendor.paymentTerms,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Delivery Terms
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Terms',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  vendor.deliveryTerms,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetItem(AssetItem asset) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asset Name: ${asset.name}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Qty: ${asset.qty}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated: ${asset.estimated}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
              Text(
                asset.actual,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF25B1FF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstGrandTotal(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
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

          // Content based on selected tab
          Expanded(
            child: _selectedTabIndex == 1
                ? _buildQuotationScreen() // Tampilkan layar quotation untuk tab 1
                : ListView(
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
      floatingActionButton: _selectedTabIndex != 1
          ? GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProcurementFormScreen(),
                  ),
                );
              },
              child: Container(
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
            )
          : null, // Sembunyikan FAB saat tab Quotation aktif
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class VendorItem {
  String name;
  List<AssetItem> assets;
  String paymentTerms;
  String deliveryTerms;

  VendorItem({
    required this.name,
    required this.assets,
    required this.paymentTerms,
    required this.deliveryTerms,
  });
}

class AssetItem {
  String name;
  int qty;
  String estimated;
  String actual;

  AssetItem({
    required this.name,
    required this.qty,
    required this.estimated,
    required this.actual,
  });
}
