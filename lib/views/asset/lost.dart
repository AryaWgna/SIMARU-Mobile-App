import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/asset_lost_controller.dart';
import 'package:provider/provider.dart';

class LostScreen extends StatefulWidget {
  final Map<String, dynamic>? assetData;

  const LostScreen({super.key, this.assetData});

  @override
  State<LostScreen> createState() => _LostScreenState();
}

class _LostScreenState extends State<LostScreen> {
  final TextEditingController notesController = TextEditingController();
  late AssetLostController _lostController;

  @override
  void initState() {
    super.initState();
    _lostController = Provider.of<AssetLostController>(context, listen: false);
    _lostController.reset(); // Reset controller state
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _reportLost() async {
    final assetId = widget.assetData?['asset_id'];
    if (assetId == null) {
      _lostController.setError('ID aset tidak ditemukan');
      return;
    }

    final result = await _lostController.reportLost(
      assetId: assetId,
      notes: notesController.text,
      context: context,
    );

    if (result != null && result['success'] == true) {
      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan kehilangan berhasil dikirim'),
          backgroundColor: Color(0xFF213268),
        ),
      );

      // Modifikasi data status asset untuk diupdate
      if (widget.assetData != null) {
        final updatedAssetData = Map<String, dynamic>.from(widget.assetData!);
        updatedAssetData['current_status'] = 'lost';

        // Kembali ke halaman detail dengan data yang diperbarui
        Navigator.pop(context, updatedAssetData);
      } else {
        Navigator.pop(context, true); // Return true for success
      }
    } else if (result != null && result['success'] == false) {
      // Error message already set in controller
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Laporan kehilangan gagal'),
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
      body: Consumer<AssetLostController>(
        builder: (context, controller, child) {
          return Container(
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LAPORKAN KEHILANGAN',
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

                  // Warning Icon
                  const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFFA000),
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Warning Text
                  const Center(
                    child: Text(
                      'Peringatan!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFA000),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Warning Description
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Laporkan kehilangan hanya jika aset benar-benar hilang. Laporan ini tidak dapat dibatalkan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notes - border added
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alasan Kehilangan',
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
                          hintText: 'Jelaskan alasan kehilangan',
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
      bottomNavigationBar: Consumer<AssetLostController>(
        builder: (context, controller, child) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [],
            ),
            padding: const EdgeInsets.only(left: 21, right: 21, bottom: 18),
            child: ElevatedButton(
              onPressed: controller.isLoading ? null : _reportLost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
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
                      'Laporkan Kehilangan',
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
