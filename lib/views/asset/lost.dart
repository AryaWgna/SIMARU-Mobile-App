import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import 'dart:convert';

class LostScreen extends StatefulWidget {
  final Map<String, dynamic>? assetData;

  const LostScreen({super.key, this.assetData});

  @override
  State<LostScreen> createState() => _LostScreenState();
}

class _LostScreenState extends State<LostScreen> {
  final TextEditingController notesController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _reportLost() async {
    if (notesController.text.isEmpty) {
      setState(() {
        errorMessage = 'Catatan tidak boleh kosong';
      });
      return;
    }

    final assetId = widget.assetData?['asset_id'];
    if (assetId == null) {
      setState(() {
        errorMessage = 'ID aset tidak ditemukan';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final requestBody = {
        "asset_id": assetId,
        "loss_reason": notesController.text,
      };

      print('Sending lost report: $requestBody');

      final response = await ApiService.post(
        '/asset-transfers/loss',
        body: requestBody,
        context: context,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final bool isSuccess =
            data['success'] == true || data['status'] == true;

        if (isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Laporan kehilangan berhasil dikirim'),
              backgroundColor: Color(0xFF213268),
            ),
          );

          // Modifikasi data status asset untuk diupdate
          if (widget.assetData != null) {
            final updatedAssetData =
                Map<String, dynamic>.from(widget.assetData!);
            updatedAssetData['current_status'] = 'lost';

            // Kembali ke halaman detail dengan data yang diperbarui
            Navigator.pop(context, updatedAssetData);
          } else {
            Navigator.pop(context, true); // Return true for success
          }
        } else {
          throw Exception(data['message'] ?? 'Laporan kehilangan gagal');
        }
      } else {
        var errorMsg = 'Laporan kehilangan gagal: ${response.statusCode}';
        try {
          final data = json.decode(response.body);
          if (data['message'] != null) {
            errorMsg = data['message'];
          } else if (data['error'] != null) {
            errorMsg = data['error'];
          }

          // Tambahkan log untuk debugging
          print('Error response data: $data');
        } catch (e) {
          print('Failed to parse error response: $e');
        }

        throw Exception(errorMsg);
      }
    } catch (e) {
      print('Lost report process failed: $e');
      setState(() {
        errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
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
      body: Container(
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
              if (errorMessage != null)
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
                          errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),

              // Notes - alasan kehilangan
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alasan Kehilangan',
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
                      hintText: 'Masukkan detail kehilangan',
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
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [],
        ),
        padding: const EdgeInsets.only(left: 21, right: 21, bottom: 18),
        child: ElevatedButton(
          onPressed: isLoading ? null : _reportLost,
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
          child: isLoading
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
                    fontFamily: 'Inter',
                  ),
                ),
        ),
      ),
    );
  }
}
