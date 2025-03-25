import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import '../procurement/procurement_form_screen.dart';
import '../procurement/procurement_detail_screen.dart';
import '../procurement/form_rfq.dart';
import '../procurement/purchase_order_screen.dart';
import '../procurement/receipt_detail_screen.dart';
import '../../controllers/procurement_controller.dart';
import '../../models/procurement_model.dart';

class ProcurementScreen extends StatefulWidget {
  const ProcurementScreen({super.key});

  @override
  State<ProcurementScreen> createState() => _ProcurementScreenState();
}

class _ProcurementScreenState extends State<ProcurementScreen> {
  int _selectedTabIndex = 0;
  final List<VendorItem> vendors = [];
  bool _isLoading = false;
  List<Procurement> _procurements = [];
  String? _errorMessage;

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

    // Load procurements data
    _loadProcurements();
  }

  // Method to load procurements
  Future<void> _loadProcurements() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await ProcurementController.getProcurementList(context);
      if (mounted) {
        setState(() {
          _procurements = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load procurements: $e';
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    }
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

  // Updated method to build procurement item using API data
  Widget _buildProcurementItem(Procurement procurement) {
    // Helper to determine icon based on status
    IconData getStatusIcon() {
      switch (procurement.status) {
        case 'Submitted':
          return Icons.check_circle_outline;
        case 'Under Review':
          return Icons.access_time;
        case 'Approved':
          return Icons.check_circle;
        case 'Rejected':
          return Icons.cancel_outlined;
        default:
          return Icons.help_outline;
      }
    }

    // Helper to determine icon color
    Color getStatusIconColor() {
      switch (procurement.status) {
        case 'Submitted':
          return const Color(0xFF757575);
        case 'Under Review':
          return const Color(0xFFDAAE0F);
        case 'Approved':
          return const Color(0xFF659B09);
        case 'Rejected':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    // Helper to determine priority color
    Color getPriorityColor() {
      switch (procurement.priority) {
        case 'High':
          return Colors.red;
        case 'Medium':
          return const Color(0xFFF16A1B);
        case 'Low':
          return const Color(0xFF659B09);
        default:
          return Colors.grey;
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProcurementDetailScreen(
              title: procurement.title,
              status: procurement.status,
              priority: procurement.priority,
              requestDate: procurement.getFormattedDate(),
              procurementId: procurement.procurementId,
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
            color: const Color.fromRGBO(0, 0, 0, 0.1),
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
                    procurement.title,
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
                          Icon(getStatusIcon(),
                              color: getStatusIconColor(), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            procurement.status,
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
                        procurement.priority,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: getPriorityColor(),
                        ),
                      )),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      'Qty:',
                      Text(
                        procurement.getQuantityText(),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                        ),
                      )),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      'Request Date:',
                      Text(
                        procurement.getFormattedDate(),
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
                ...vendors.map((vendor) =>
                    _buildVendorCard(vendor, vendors.indexOf(vendor))),

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
        onPressed: () async {
          // Navigasi ke FormRFQ dan tunggu hasilnya
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormRFQ()),
          );

          // Jika hasil tidak null, tambahkan vendor baru dengan data dari form
          if (result != null && result is Map<String, dynamic>) {
            setState(() {
              // Konversi qty dari string ke int
              int qty1 = int.tryParse(result['qty1'] ?? '3') ?? 3;
              int qty2 = int.tryParse(result['qty2'] ?? '3') ?? 3;

              vendors.add(
                VendorItem(
                  name: result['vendorName'] ?? "Vendor Name",
                  assets: [
                    AssetItem(
                        name: result['assetName1'] ?? "Asset 1",
                        qty: qty1,
                        estimated: result['estimatedCost1'] ??
                            "7.500.000(Rp/2.500.000)",
                        actual: "900.000/bulan"),
                    AssetItem(
                        name: result['assetName2'] ?? "Asset 2",
                        qty: qty2,
                        estimated: result['estimatedCost2'] ??
                            "7.500.000(Rp/2.500.000)",
                        actual: "900.000/bulan"),
                  ],
                  paymentTerms: result['paymentTerms'] ??
                      "payment through commercial bank",
                  deliveryTerms: result['deliveryTerms'] ??
                      "Delivery using JNE delivery service",
                ),
              );
            });
          }
        },
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
          ...vendor.assets.map((asset) => _buildAssetItem(asset)),

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

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),

          // Error message
          if (_errorMessage != null && !_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  ElevatedButton(
                    onPressed: _loadProcurements,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Content based on selected tab
          if (!_isLoading && _errorMessage == null)
            Expanded(
              child: _selectedTabIndex == 1
                  ? _buildQuotationScreen() // Tampilkan layar quotation untuk tab 1
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_selectedTabIndex == 0) ...[
                          // Request Tab - Now using data from API
                          if (_procurements.isEmpty)
                            const Center(
                                child: Text('No procurement data found')),
                          ..._procurements
                              .where((p) => [
                                    'Submitted',
                                    'Under Review',
                                    'Approved',
                                    'Rejected'
                                  ].contains(p.status))
                              .map((p) => _buildProcurementItem(p))
                              .toList(),
                        ] else if (_selectedTabIndex == 2) ...[
                          // Purchase Order Tab
                          // Filter procurements relevant to Purchase Order tab
                          ..._procurements
                              .where((p) => p.status == 'Approved')
                              .map((p) => _buildProcurementItem(p))
                              .toList(),
                        ] else if (_selectedTabIndex == 3) ...[
                          // Receipt Tab
                          // Filter procurements relevant to Receipt tab
                          ..._procurements
                              .where((p) => p.status == 'Received')
                              .map((p) => _buildProcurementItem(p))
                              .toList(),
                        ],
                      ],
                    ),
            ),
        ],
      ),
      floatingActionButton: _selectedTabIndex != 1
          ? GestureDetector(
              onTap: () {
                if (_selectedTabIndex == 2) {
                  // Jika tab Purchase Order yang aktif
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PurchaseOrderScreen(),
                    ),
                  );
                } else if (_selectedTabIndex == 3) {
                  // Jika tab Receipt yang aktif
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReceiptDetailScreen(),
                    ),
                  );
                } else {
                  // Untuk tab lainnya (Request)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProcurementFormScreen(),
                    ),
                  ).then((_) {
                    // Refresh data setelah kembali dari form
                    _loadProcurements();
                  });
                }
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
