import 'package:flutter/material.dart';

class RFQScreen extends StatefulWidget {
  final String? procurementId;
  final String? title;

  const RFQScreen({
    super.key,
    this.procurementId,
    this.title,
  });

  @override
  State<RFQScreen> createState() => _RFQScreenState();
}

class _RFQScreenState extends State<RFQScreen> {
  final List<VendorItem> vendors = [];

  @override
  void initState() {
    super.initState();
    // Tambahkan vendor default seperti di gambar
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom app bar to match the image
          Container(
            height: 60,
            color: const Color(0xFF213268),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'images/Logo_RS_UMMI.png',
                        height: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Maintain balance
                ],
              ),
            ),
          ),

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
                  _buildInfoField('Procurement ID', '-'),
                  _buildInfoField('Title Request', '-'),
                  _buildInfoField('Requester', '-'),
                  _buildInfoField('Request Date', '-'),

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
                      ,

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
                        Navigator.pop(context);
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
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
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
