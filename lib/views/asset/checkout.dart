import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/asset_checkout_controller.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic>? assetData;

  const CheckoutScreen({super.key, this.assetData});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  TextEditingController notesController = TextEditingController();
  late AssetCheckoutController _checkoutController;

  @override
  void initState() {
    super.initState();
    _checkoutController =
        Provider.of<AssetCheckoutController>(context, listen: false);
    _checkoutController.reset(); // Reset controller state
    _checkoutController.fetchRooms(context); // Fetch rooms from API
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _processCheckout() async {
    final assetId = widget.assetData?['asset_id'];
    if (assetId == null) {
      _checkoutController.setError('ID aset tidak ditemukan');
      return;
    }

    final result = await _checkoutController.processCheckout(
      assetId: assetId,
      notes: notesController.text,
      context: context,
    );

    if (result != null && result['success'] == true) {
      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peminjaman berhasil'),
          backgroundColor: Color(0xFF213268),
        ),
      );

      // Modifikasi data status asset untuk diupdate
      if (widget.assetData != null) {
        final updatedAssetData = Map<String, dynamic>.from(widget.assetData!);
        updatedAssetData['current_status'] = 'check out';

        // Kembali ke halaman detail dengan data yang diperbarui
        Navigator.pop(context, updatedAssetData);
      } else {
        Navigator.pop(context, true); // Return true for success
      }
    } else if (result != null && result['success'] == false) {
      // Error message already set in controller
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Peminjaman gagal'),
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
      body: Consumer<AssetCheckoutController>(
        builder: (context, controller, child) {
          return Container(
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PEMINJAMAN ASET',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF213268),
                      fontFamily: 'Inter',
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
                                  fontFamily: 'Inter',
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
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.assetData?['asset_code'] ?? '-',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
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
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.assetData?['asset_name'] ??
                                      'Tidak diketahui',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
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

                  // Tanggal checkout - fixed to today
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal Peminjaman',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                          fontFamily: 'Inter',
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
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Radio Buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pinjam Ke',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Radio(
                            value: true,
                            groupValue: controller.isEmployeeSelected,
                            onChanged: (value) {
                              controller.setIsEmployeeSelected(true);
                            },
                            activeColor: const Color(0xFF25B1FF),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          const Text(
                            'Karyawan',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(width: 45),
                          Radio(
                            value: false,
                            groupValue: controller.isEmployeeSelected,
                            onChanged: (value) {
                              controller.setIsEmployeeSelected(false);
                            },
                            activeColor: const Color(0xFF25B1FF),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          const Text(
                            'Lokasi',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Conditional content berdasarkan pemilihan
                  if (!controller.isEmployeeSelected) ...[
                    // Room Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ruangan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF666666),
                            fontFamily: 'Inter',
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
                          child: controller.roomList.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  child: Text(
                                    'Memuat data ruangan...',
                                    style: TextStyle(
                                      color: Color(0xFF666666),
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : DropdownButtonFormField<String>(
                                  dropdownColor: Colors.white,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    border: InputBorder.none,
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                  hint: const Text('Pilih Ruangan'),
                                  value: controller.selectedRoom,
                                  icon: const Icon(Icons.arrow_drop_down),
                                  isExpanded: true,
                                  onChanged: (String? newValue) {
                                    controller.setSelectedRoom(newValue);
                                  },
                                  items: controller.roomList
                                      .map<DropdownMenuItem<String>>((room) {
                                    return DropdownMenuItem<String>(
                                      value: room['room_id'].toString(),
                                      child: Text(room['room_name'] ??
                                          'Ruangan Tidak Diketahui'),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Notes - border removed
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catatan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                          fontFamily: 'Inter',
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
      bottomNavigationBar: Consumer<AssetCheckoutController>(
        builder: (context, controller, child) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [],
            ),
            padding: const EdgeInsets.only(left: 21, right: 21, bottom: 18),
            child: ElevatedButton(
              onPressed: controller.isLoading ? null : _processCheckout,
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
                      'Pinjam',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Inter',
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
