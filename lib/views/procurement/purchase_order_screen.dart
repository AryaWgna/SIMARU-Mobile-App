import 'package:flutter/material.dart';
import 'purchase_order_detail_screen.dart';
import '../../widgets/custom_app_bar.dart';

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers untuk form fields
  final procurementIdController = TextEditingController();
  final titleRequestController = TextEditingController();
  final requesterController = TextEditingController();
  final quotationDateController = TextEditingController();

  // Data untuk vendor dan asset
  List<VendorItem> vendors = [
    VendorItem(
      name: "Vendor Name",
      isSelected: true,
      assets: [
        AssetItem(
          name: "Asset 1",
          qty: 3,
          estimated: "7.500.000(Rp/2.500.000)",
          actual: "900.000(@300.000)",
          isSelected: true,
        ),
        AssetItem(
          name: "Asset 2",
          qty: 3,
          estimated: "7.500.000(Rp/2.500.000)",
          actual: "900.000(@300.000)",
          isSelected: false,
        ),
      ],
      paymentTerms: "payment through commercial bank",
      deliveryTerms: "Delivery using JNE delivery service",
    ),
    VendorItem(
      name: "Vendor Name",
      isSelected: false,
      assets: [
        AssetItem(
          name: "Asset 1",
          qty: 3,
          estimated: "7.500.000(Rp/2.500.000)",
          actual: "900.000(@300.000)",
          isSelected: false,
        ),
        AssetItem(
          name: "Asset 2",
          qty: 3,
          estimated: "7.500.000(Rp/2.500.000)",
          actual: "900.000(@300.000)",
          isSelected: true,
        ),
      ],
      paymentTerms: "payment through commercial bank",
      deliveryTerms: "Delivery using JNE delivery service",
    ),
  ];

  @override
  void dispose() {
    procurementIdController.dispose();
    titleRequestController.dispose();
    requesterController.dispose();
    quotationDateController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: const CustomAppBar(),
        toolbarHeight: 82,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul halaman (di kiri)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'PURCHASE ORDER',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF213268),
                          ),
                        ),
                      ),

                      // Tabel info (dengan border tipis)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFEEF1F4),
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Table(
                          border: TableBorder.all(
                            color: const Color(0xFFEEF1F4),
                            width: 0.5,
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(1.5),
                            1: FlexColumnWidth(2.5),
                          },
                          children: [
                            _buildTableRow('Procurement ID', '-'),
                            _buildTableRow('Title Request', '-'),
                            _buildTableRow('Requester', '-'),
                            _buildTableRow('Quotation Date', '-'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Choose Vendor section
                      const Text(
                        'Choose Vendor',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF213268),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Vendor Cards (dengan ukuran yang dibatasi)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width -
                              32, // dikurangi 16 pixel dari kiri dan kanan
                        ),
                        child: Column(
                          children: vendors
                              .map((vendor) => _buildVendorCard(vendor))
                              .toList(),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Footer dengan Grand Total dan tombol Submit
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.1),
                  blurRadius: 4,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Column(
              children: [
                // Grand total section
                _buildGrandTotal('Est. Grand Total:', 'Rp. x.xxx.xxxx'),
                const SizedBox(height: 8),
                _buildGrandTotal('Vendor Grand Total:', 'Rp. x.xxx.xxxx'),
                const SizedBox(height: 8),
                _buildGrandTotal('Vendor2 Grand Total:', 'Rp. x.xxx.xxxx'),

                const SizedBox(height: 12),

                // Submit Button
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Navigasi ke detail PO
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PurchaseOrderDetailScreen(
                            procurementId: procurementIdController.text,
                            titleRequest: titleRequestController.text,
                            requester: requesterController.text,
                            selectedVendor:
                                vendors.firstWhere((v) => v.isSelected).name,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF213268),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF213268),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF213268),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVendorCard(VendorItem vendor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF213268)),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vendor name
            Text(
              vendor.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // Assets
            ...vendor.assets.map((asset) => _buildAssetItem(asset)),

            // Payment Terms
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Terms',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vendor.paymentTerms,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF757575),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            // Delivery Terms
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Terms',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vendor.deliveryTerms,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF757575),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetItem(AssetItem asset) {
    // Memisahkan angka actual menjadi 2 bagian (sebelum @ dan setelah @)
    String mainAmount = '';
    String additionalInfo = '';

    if (asset.actual.contains('@')) {
      final parts = asset.actual.split('@');
      mainAmount = parts[0];
      additionalInfo = '@${parts[1]}';
    } else {
      mainAmount = asset.actual;
    }

    // Memisahkan angka estimasi menjadi dua bagian
    String mainEstimateAmount = '';
    String additionalEstimateInfo = '';

    if (asset.estimated.contains('(')) {
      final parts = asset.estimated.split('(');
      mainEstimateAmount = parts[0];
      additionalEstimateInfo = '(${parts[1]}';
    } else {
      mainEstimateAmount = asset.estimated;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asset Name: ${asset.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Inter',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${asset.qty}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF757575),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    const Text(
                      'Estimated: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                        fontFamily: 'Inter',
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: mainEstimateAmount,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF25B1FF),
                              fontFamily: 'Inter',
                            ),
                          ),
                          TextSpan(
                            text: additionalEstimateInfo,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: mainAmount,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF25B1FF),
                              fontFamily: 'Inter',
                            ),
                          ),
                          TextSpan(
                            text: additionalInfo,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Radio button dengan GestureDetector
          GestureDetector(
            onTap: () {
              setState(() {
                // Mencari vendor yang memiliki asset ini
                for (var vendor in vendors) {
                  for (var i = 0; i < vendor.assets.length; i++) {
                    // Jika menemukan asset yang sama
                    if (vendor.assets[i].name == asset.name) {
                      // Buat versi baru dari asset ini dengan status terpilih dibalik
                      vendor.assets[i] = AssetItem(
                        name: asset.name,
                        qty: asset.qty,
                        estimated: asset.estimated,
                        actual: asset.actual,
                        isSelected: !asset.isSelected,
                      );
                    }
                  }
                }
              });
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFCCCCCC)),
                color: Colors.white,
              ),
              child: asset.isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF25B1FF),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrandTotal(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF3D3D3D),
          ),
        ),
      ],
    );
  }
}

class VendorItem {
  final String name;
  final List<AssetItem> assets;
  final String paymentTerms;
  final String deliveryTerms;
  final bool isSelected;

  VendorItem({
    required this.name,
    required this.assets,
    required this.paymentTerms,
    required this.deliveryTerms,
    this.isSelected = false,
  });
}

class AssetItem {
  final String name;
  final int qty;
  final String estimated;
  final String actual;
  final bool isSelected;

  AssetItem({
    required this.name,
    required this.qty,
    required this.estimated,
    required this.actual,
    this.isSelected = false,
  });
}
