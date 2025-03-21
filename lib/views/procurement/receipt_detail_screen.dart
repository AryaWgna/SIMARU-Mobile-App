import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';

class ReceiptDetailScreen extends StatefulWidget {
  final String? procurementId;
  final String? poId;
  final String? titleProcurement;
  final String? poDate;
  final String? requester;
  final String? ppn;
  final String? poContact;
  final String? selectedVendor;

  const ReceiptDetailScreen({
    super.key,
    this.procurementId,
    this.poId,
    this.titleProcurement,
    this.poDate,
    this.requester,
    this.ppn,
    this.poContact,
    this.selectedVendor,
  });

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller untuk field delivered by
  final deliveredByController = TextEditingController();
  final keteranganController = TextEditingController();

  // Asset items
  List<AssetItem> assets = [
    AssetItem(
      name: "Asset 1",
      qty: 3,
      estimated: "7.500.000(Rp/2.500.000)",
    ),
    AssetItem(
      name: "Asset 2",
      qty: 3,
      estimated: "7.500.000(Rp/2.500.000)",
    ),
  ];

  @override
  void dispose() {
    deliveredByController.dispose();
    keteranganController.dispose();
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          'RECEIPT DETAIL',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF213268),
                          ),
                        ),
                      ),

                      // Info Table with thin border
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFEEF1F4),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.5),
                            1: FlexColumnWidth(2.5),
                          },
                          border: TableBorder.all(
                            color: const Color(0xFFEEF1F4),
                            width: 1,
                            borderRadius: BorderRadius.circular(8),
                          ),
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

                      const SizedBox(height: 24),

                      // Delivered by section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delivered by',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0xFFCCCCCC)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: deliveredByController,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Color(0xFF666666),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Type Here',
                                hintStyle: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Vendor Card
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFF213268)),
                          borderRadius: BorderRadius.circular(10),
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
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
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
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
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
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
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
              color: Color(0xFF3D3D3D),
              fontWeight: FontWeight.w400,
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
              color: Color(0xFF3D3D3D),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetItem(AssetItem asset) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Wrap(
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
                            text: asset.estimated.split('(').first,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF25B1FF),
                              fontFamily: 'Inter',
                            ),
                          ),
                          TextSpan(
                            text: asset.estimated.contains('(')
                                ? '(${asset.estimated.split('(')[1]}'
                                : '',
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
              ),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: '900.000',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF25B1FF),
                        fontFamily: 'Inter',
                      ),
                    ),
                    TextSpan(
                      text: '(@300.000)',
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
          const SizedBox(height: 10),
          // Keterangan field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Keterangan',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: keteranganController,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Type Here',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
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
