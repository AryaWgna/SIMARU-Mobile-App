import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/custom_app_bar.dart';
import '../../controllers/procurement_controller.dart';
import 'dart:convert';

class ProcurementFormScreen extends StatefulWidget {
  const ProcurementFormScreen({super.key});

  @override
  State<ProcurementFormScreen> createState() => _ProcurementFormScreenState();
}

class _ProcurementFormScreenState extends State<ProcurementFormScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _justificationController =
      TextEditingController();
  String _selectedPriority = 'High'; // Set default priority
  final List<AssetItem> _assetItems = [AssetItem()];
  double _grandTotal = 0.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _justificationController.dispose();
    for (var item in _assetItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _addAssetItem() {
    setState(() {
      _assetItems.add(AssetItem());
    });
  }

  void _removeAssetItem(int index) {
    if (_assetItems.length > 1) {
      // Pastikan selalu ada minimal 1 item
      setState(() {
        _assetItems.removeAt(index);
        _calculateGrandTotal(); // Hitung ulang total setelah menghapus
      });
    } else {
      // Optional: Tampilkan snackbar atau pesan lain jika mencoba menghapus item terakhir
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada satu item')),
      );
    }
  }

  void _calculateGrandTotal() {
    double total = 0.0;
    for (var item in _assetItems) {
      if (item.costController.text.isNotEmpty) {
        try {
          final priceText = item.costController.text.replaceAll(',', '');
          final price = double.tryParse(priceText) ?? 0.0;
          final qty = int.tryParse(item.qtyController.text) ?? 1;
          total += price * qty;
        } catch (e) {
          print('Error calculating price: $e');
        }
      }
    }
    setState(() {
      _grandTotal = total;
    });
  }

  // Validasi form sebelum submit
  bool _validateForm() {
    if (_titleController.text.isEmpty) {
      _showErrorSnackBar('Title tidak boleh kosong');
      return false;
    }

    if (_selectedPriority == 'Select Priority') {
      _showErrorSnackBar('Silakan pilih priority');
      return false;
    }

    if (_justificationController.text.isEmpty) {
      _showErrorSnackBar('Justification tidak boleh kosong');
      return false;
    }

    // Tambahkan validasi untuk panjang justification minimal 10 karakter
    if (_justificationController.text.length < 10) {
      _showErrorSnackBar('Justification harus minimal 10 karakter');
      return false;
    }

    // Validasi asset items
    for (int i = 0; i < _assetItems.length; i++) {
      final item = _assetItems[i];

      if (item.nameController.text.isEmpty) {
        _showErrorSnackBar('Asset name pada item ${i + 1} tidak boleh kosong');
        return false;
      }

      if (item.qtyController.text.isEmpty) {
        _showErrorSnackBar('Quantity pada item ${i + 1} tidak boleh kosong');
        return false;
      }

      // Validasi quantity harus angka
      try {
        int.parse(item.qtyController.text);
      } catch (e) {
        _showErrorSnackBar('Quantity pada item ${i + 1} harus berupa angka');
        return false;
      }

      if (item.costController.text.isEmpty) {
        _showErrorSnackBar(
            'Estimated cost pada item ${i + 1} tidak boleh kosong');
        return false;
      }

      // Validasi cost harus angka
      try {
        double.parse(item.costController.text.replaceAll(',', ''));
      } catch (e) {
        _showErrorSnackBar(
            'Estimated cost pada item ${i + 1} harus berupa angka');
        return false;
      }

      // Jika item justification diisi, validasi panjang minimal
      if (item.justificationController.text.isNotEmpty &&
          item.justificationController.text.length < 10) {
        _showErrorSnackBar(
            'Justification pada item ${i + 1} harus minimal 10 karakter');
        return false;
      }
    }

    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Submit form
  Future<void> _submitForm() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare details
      List<Map<String, dynamic>> details = [];

      for (var item in _assetItems) {
        // Untuk specifications dan justification, jika kosong, set null
        final specifications = item.specificationsController.text.isEmpty
            ? null
            : item.specificationsController.text;

        final justification = item.justificationController.text.isEmpty
            ? null
            : item.justificationController.text;

        details.add({
          "asset_name": item.nameController.text,
          "quantity": int.parse(item.qtyController.text),
          "estimated_unit_price":
              double.parse(item.costController.text.replaceAll(',', '')),
          "specifications": specifications,
          "justification": justification
        });
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        "title": _titleController.text,
        "priority": _selectedPriority,
        "justification": _justificationController.text,
        "details": details
      };

      print('Submitting procurement: ${json.encode(requestBody)}');

      // Submit to API
      final response = await ProcurementController.submitProcurementRequest(
          context, requestBody);

      setState(() {
        _isSubmitting = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(response['message'] ?? 'Procurement created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back or to detail page
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context, true);
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      print('Error submitting procurement: $e');

      // Tampilkan pesan error yang lebih ramah
      String errorMessage = e.toString();
      // Hapus "Exception: " dari awal pesan error jika ada
      if (errorMessage.startsWith("Exception: ")) {
        errorMessage = errorMessage.substring("Exception: ".length);
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'Form Procurement Request',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF213268),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // REQUEST FORM Header
                        Text(
                          'REQUEST FORM',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF213268),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Title Field
                        _buildFormField(
                          label: 'Title',
                          controller: _titleController,
                          hintText: 'Enter Asset Name',
                        ),

                        const SizedBox(height: 16),

                        // Priority Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Priority',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedPriority,
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  iconSize: 24,
                                  elevation: 16,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedPriority = newValue!;
                                    });
                                  },
                                  items: <String>[
                                    'High',
                                    'Medium',
                                    'Low',
                                  ].map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Justification Field
                        _buildFormField(
                          label: 'Justification',
                          controller: _justificationController,
                          hintText: 'Enter Justification',
                          maxLines: 3,
                        ),

                        const SizedBox(height: 24),

                        // List Asset Header
                        Text(
                          'List Asset',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF213268),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Asset Items
                        ...List.generate(_assetItems.length, (index) {
                          return _buildAssetItemFields(
                            assetItem: _assetItems[index],
                            index: index,
                            onCostChanged: _calculateGrandTotal,
                            onRemove: () => _removeAssetItem(index),
                          );
                        }),

                        // Grand Total
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Grand Total:',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                'Rp. ${_grandTotal.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tambahkan space untuk tombol submit
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),

              // Submit Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      const Color(0xFF213268),
                    ),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 12),
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Submit',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),

          // Floating Add Button
          Positioned(
            right: 16,
            bottom: 90, // Posisi di atas tombol submit
            child: FloatingActionButton(
              onPressed: _addAssetItem,
              backgroundColor: const Color(0xFF25B1FF),
              mini: true,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF213268)),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 14),
          onChanged: (value) {
            if (label == 'Estimated Cost' || label == 'Qty') {
              _calculateGrandTotal();
            }
          },
        ),
      ],
    );
  }

  Widget _buildAssetItemFields({
    required AssetItem assetItem,
    required int index,
    required VoidCallback onCostChanged,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan tombol hapus
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Asset Item ${index + 1}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF213268),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onRemove,
                splashRadius: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Asset Name
          _buildFormField(
            label: 'Asset Name',
            controller: assetItem.nameController,
            hintText: 'Enter Asset Name',
          ),

          const SizedBox(height: 12),

          // Qty
          _buildFormField(
            label: 'Qty',
            controller: assetItem.qtyController,
            hintText: 'Enter Qty',
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 12),

          // Estimated Cost
          _buildFormField(
            label: 'Estimated Cost',
            controller: assetItem.costController,
            hintText: 'Enter Estimated Cost',
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 12),

          // Specifications
          _buildFormField(
            label: 'Specifications (Optional)',
            controller: assetItem.specificationsController,
            hintText: 'Enter Specifications',
            maxLines: 2,
          ),

          const SizedBox(height: 12),

          // Justification
          _buildFormField(
            label: 'Justification (Optional)',
            controller: assetItem.justificationController,
            hintText: 'Enter Justification',
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class AssetItem {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController justificationController = TextEditingController();
  final TextEditingController specificationsController =
      TextEditingController();

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    costController.dispose();
    justificationController.dispose();
    specificationsController.dispose();
  }
}
