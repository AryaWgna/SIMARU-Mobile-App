import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_config.dart';
import '../../controllers/asset_complaint_controller.dart';

class AssetComplaintScreen extends StatefulWidget {
  final Map<String, dynamic>? assetData;
  final String assetCode;

  const AssetComplaintScreen({
    super.key,
    required this.assetData,
    required this.assetCode,
  });

  @override
  State<AssetComplaintScreen> createState() => _AssetComplaintScreenState();
}

class _AssetComplaintScreenState extends State<AssetComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late AssetComplaintController _complaintController;

  @override
  void initState() {
    super.initState();
    print('[COMPLAINT DEBUG] Asset Data: ${widget.assetData}');
    print('[COMPLAINT DEBUG] Asset Code: ${widget.assetCode}');

    // Mengambil controller
    _complaintController =
        Provider.of<AssetComplaintController>(context, listen: false);
    // Reset all state when entering complaint screen
    _complaintController.resetState();
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Sumber Gambar',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF213268),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSourceOption(
                      icon: Icons.photo_camera,
                      label: 'Kamera',
                      onTap: () {
                        Navigator.pop(context);
                        _getImage(ImageSource.camera);
                      },
                    ),
                    _buildSourceOption(
                      icon: Icons.photo_library,
                      label: 'Galeri',
                      onTap: () {
                        Navigator.pop(context);
                        _getImage(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF213268),
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xFF213268),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Kualitas gambar 70%
        maxWidth: 800, // Maksimal lebar 800px
        maxHeight: 800, // Maksimal tinggi 800px
        preferredCameraDevice: CameraDevice.rear,
        requestFullMetadata: false, // Tidak memerlukan metadata lengkap
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Validasi gambar menggunakan controller
        if (await _complaintController.validateImageFile(imageFile)) {
          _complaintController.setImage(imageFile);
        }
      }
    } catch (e) {
      print('[COMPLAINT DEBUG] Error in _getImage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error mengambil gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Cek dan ambil asset_id dari assetData
    int? assetId;
    if (widget.assetData != null) {
      if (widget.assetData!['id'] != null) {
        assetId = int.tryParse(widget.assetData!['id'].toString());
      } else if (widget.assetData!['asset_id'] != null) {
        assetId = int.tryParse(widget.assetData!['asset_id'].toString());
      }
    }

    if (assetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Aset tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Submit dengan controller
    final success = await _complaintController.submitComplaint(
      assetId: assetId,
      description: _descriptionController.text,
    );

    if (success && mounted) {
      // Menampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keluhan berhasil dikirim'),
          backgroundColor: Color(0xFF213268),
        ),
      );

      // Modifikasi data asset untuk diupdate di halaman detail
      if (widget.assetData != null) {
        final updatedAssetData = Map<String, dynamic>.from(widget.assetData!);
        // Status aset tidak perlu diubah untuk komplain, tetapi kita tetap mengembalikan data
        // untuk konsistensi dengan fitur lainnya

        // Kembali ke halaman detail dengan data yang diperbarui
        Navigator.pop(context, updatedAssetData);
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Consumer<AssetComplaintController>(
        builder: (context, controller, _) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // AppBar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 82 + statusBarHeight,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF213268),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF56C5F1),
                      blurRadius: 3,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),

            // AppBar Content
            Positioned(
              top: statusBarHeight,
              left: 0,
              right: 0,
              height: 82,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 40),
                        child: Image.asset(
                          'images/Logo_RS_UMMI_white.png',
                          width: 208.14,
                          height: 55,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Positioned(
              top: 82 + statusBarHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Text(
                        'Formulir Keluhan Aset',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF213268),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Asset Information Card
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

                            // Asset ID Display
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
                                    widget.assetData?['asset_code'] ??
                                        widget.assetCode,
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

                            // Asset Name Display
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
                      const SizedBox(height: 24),

                      // Description Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deskripsi Masalah',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              hintText:
                                  'Jelaskan masalah yang Anda alami dengan aset ini (minimal 5 karakter)',
                              hintStyle: const TextStyle(
                                color: Color(0xFFAAAAAA),
                                fontSize: 14,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Color(0xFFCCCCCC)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Color(0xFFCCCCCC)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Color(0xFF213268)),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            maxLines: 5,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Deskripsi masalah wajib diisi';
                              }
                              if (value.length < 5) {
                                return 'Deskripsi minimal 5 karakter';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Image Upload Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'Lampirkan Foto',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '(Opsional)',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (controller.selectedImage == null)
                            GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Container(
                                width: double.infinity,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F8FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF213268),
                                    width: 1,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      color: Color(0xFF213268),
                                      size: 32,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tambahkan Foto',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: Color(0xFF213268),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: const Color(0xFFCCCCCC)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      controller.selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      controller.clearImage();
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: _showImageSourceDialog,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF213268)
                                            .withOpacity(0.8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      if (controller.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    controller.errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                              controller.isLoading ? null : _submitComplaint,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF213268),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade500,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: controller.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Buat Keluhan',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
