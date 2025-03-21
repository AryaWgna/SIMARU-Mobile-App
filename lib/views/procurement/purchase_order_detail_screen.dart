import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';

class PurchaseOrderDetailScreen extends StatefulWidget {
  final String? procurementId;
  final String? titleRequest;
  final String? requester;
  final String? selectedVendor;

  const PurchaseOrderDetailScreen({
    super.key,
    this.procurementId,
    this.titleRequest,
    this.requester,
    this.selectedVendor,
  });

  @override
  State<PurchaseOrderDetailScreen> createState() =>
      _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends State<PurchaseOrderDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  // Additional controllers
  final poIdController = TextEditingController();
  final poDateController = TextEditingController();
  final ppnController = TextEditingController();
  final poContactController = TextEditingController();

  // Status items
  bool inReview = true;

  // Asset items
  List<AssetItem> assets = [
    AssetItem(
      name: "Asset Name: Asset 1",
      qty: 3,
      estimated: "7.500.000(Rp/2.500.000)",
    ),
    AssetItem(
      name: "Asset Name: Asset 1",
      qty: 3,
      estimated: "7.500.000(Rp/2.500.000)",
    ),
  ];

  @override
  void dispose() {
    poIdController.dispose();
    poDateController.dispose();
    ppnController.dispose();
    poContactController.dispose();
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
                      // Title (di kiri)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'PURCHASE ORDER DETAIL',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF213268),
                          ),
                        ),
                      ),

                      // Info Table (dengan border tipis)
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
                            _buildTableRow('PO ID', '-'),
                            _buildTableRow('Title Procurement', '-'),
                            _buildTableRow('PO Date', '-'),
                            _buildTableRow('Requester', '-'),
                            _buildTableRow('PPN', '-'),
                            _buildTableRow('PO Contact', '-'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Status section
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Color(0xFFDAAE0F),
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Under Review',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Vendor Card
                      Container(
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
                              // Vendor Name
                              Text(
                                widget.selectedVendor ?? 'Vendor Name',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Inter',
                                ),
                              ),

                              const SizedBox(height: 12),
                              const Divider(height: 1),

                              // Asset items
                              ...assets.map((asset) => _buildAssetItem(asset)),

                              // Payment Terms
                              const Padding(
                                padding: EdgeInsets.only(top: 12, bottom: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Payment Terms',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'payment through commercial bank',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF757575),
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Delivery Terms
                              const Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Delivery Terms',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Delivery using JNE delivery service',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF757575),
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Footer dengan tombol Submit
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
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context);
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
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            '-',
            style: TextStyle(
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

  Widget _buildAssetItem(AssetItem asset) {
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

    // Memisahkan angka menjadi dua bagian untuk actual
    const String mainAmount = '900.000';
    const String additionalInfo = '(@300.000)';

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
                  asset.name,
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
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: mainAmount,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF25B1FF),
                              fontFamily: 'Inter',
                            ),
                          ),
                          TextSpan(
                            text: additionalInfo,
                            style: TextStyle(
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
          // Checkbox biru yang bisa diinteraksi
          Checkbox(
            value: asset.isSelected,
            onChanged: (bool? value) {
              setState(() {
                asset.isSelected = value ?? false;
              });
            },
            activeColor: const Color(0xFF25B1FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class AssetItem {
  final String name;
  final int qty;
  final String estimated;
  bool isSelected;

  AssetItem({
    required this.name,
    required this.qty,
    required this.estimated,
    this.isSelected = false,
  });
}
