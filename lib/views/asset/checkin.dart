import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/asset_checkin_controller.dart';
import 'package:provider/provider.dart';

class CheckInScreen extends StatefulWidget {
  final Map<String, dynamic>? assetData;

  const CheckInScreen({super.key, this.assetData});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final TextEditingController notesController = TextEditingController();
  late AssetCheckinController _checkinController;

  @override
  void initState() {
    super.initState();
    _checkinController =
        Provider.of<AssetCheckinController>(context, listen: false);
    _checkinController.reset(); // Reset controller state
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _processReturn() async {
    final assetId = widget.assetData?['asset_id'];
    if (assetId == null) {
      _checkinController.setError('ID aset tidak ditemukan');
      return;
    }

    final result = await _checkinController.processReturn(
      assetId: assetId,
      notes: notesController.text,
      context: context,
    );

    if (result != null && result['success'] == true) {
      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengembalian berhasil'),
          backgroundColor: Color(0xFF213268),
        ),
      );

      // Modifikasi data status asset untuk diupdate
      if (widget.assetData != null) {
        final updatedAssetData = Map<String, dynamic>.from(widget.assetData!);
        updatedAssetData['current_status'] = 'available';
        updatedAssetData['condition'] = _checkinController.selectedCondition;

        // Kembali ke halaman detail dengan data yang diperbarui
        Navigator.pop(context, updatedAssetData);
      } else {
        Navigator.pop(context, true); // Return true for success
      }
    } else if (result != null && result['success'] == false) {
      // Error message already set in controller
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Pengembalian gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(82),
        child: AppBar(
          backgroundColor: const Color(0xFF213268),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Center(
            child: Image.asset(
              'images/Logo_RS_UMMI_white.png',
              width: 208,
              height: 55,
            ),
          ),
          actions: const [
            SizedBox(width: 55),
          ],
        ),
      ),
      body: Consumer<AssetCheckinController>(
        builder: (context, controller, child) {
          return Container(
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PENGEMBALIAN ASET',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF213268),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Asset Info
                  if (widget.assetData != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F8FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD1DEFF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF213268),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Informasi Aset',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF213268),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const SizedBox(
                                width: 100,
                                child: Text(
                                  'Kode Aset:',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.assetData?['asset_code'] ?? '-',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF213268),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const SizedBox(
                                width: 100,
                                child: Text(
                                  'Nama Aset:',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.assetData?['asset_name'] ??
                                      widget.assetData?['asset_master']
                                          ?['asset_name'] ??
                                      'Tidak diketahui',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF213268),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 25),

                  // Error message if any
                  if (controller.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.errorMessage!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Tanggal kembali - fixed to today
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal Pengembalian',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Color(0xFF757575)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(controller.currentDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Kondisi aset dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kondisi Aset',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonFormField<String>(
                          dropdownColor: Colors.white,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            border: InputBorder.none,
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          value: controller.selectedCondition,
                          icon: const Icon(Icons.arrow_drop_down),
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              controller.setSelectedCondition(newValue);
                            }
                          },
                          items: controller.conditions
                              .map<DropdownMenuItem<String>>((condition) {
                            return DropdownMenuItem<String>(
                              value: condition['value'],
                              child: Text(condition['label']!),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Notes - border added
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catatan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan catatan',
                          hintStyle: const TextStyle(color: Color(0xFF666666)),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<AssetCheckinController>(
        builder: (context, controller, child) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [],
            ),
            padding: const EdgeInsets.only(left: 21, right: 21, bottom: 18),
            child: ElevatedButton(
              onPressed: controller.isLoading ? null : _processReturn,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF213268),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: controller.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Kembalikan',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
