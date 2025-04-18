import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../../core/config/api_config.dart';
import '../../services/socket_service.dart';
import 'package:dotted_border/dotted_border.dart';

class AssetComplaintScreen extends StatefulWidget {
  final Map<String, dynamic>? assetData;
  final String assetCode;

  const AssetComplaintScreen({
    Key? key,
    required this.assetData,
    required this.assetCode,
  }) : super(key: key);

  @override
  State<AssetComplaintScreen> createState() => _AssetComplaintScreenState();
}

class _AssetComplaintScreenState extends State<AssetComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _assetIdController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Log untuk debugging
    print('[COMPLAINT DEBUG] Asset Data: ${widget.assetData}');
    print('[COMPLAINT DEBUG] Asset Code: ${widget.assetCode}');

    // Pre-populate the asset ID field
    if (widget.assetData != null) {
      // Use asset_id if available, otherwise use the scanned QR code
      final assetId =
          widget.assetData!['asset_id']?.toString() ?? widget.assetCode;
      print('[COMPLAINT DEBUG] Using Asset ID: $assetId');
      _assetIdController.text = assetId;
    } else {
      _assetIdController.text = widget.assetCode;
      print(
          '[COMPLAINT DEBUG] No Asset Data, using Asset Code: ${widget.assetCode}');
    }
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
                    fontFamily: 'Inter',
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
                fontFamily: 'Inter',
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
        // Validasi format file
        final String extension = image.path.split('.').last.toLowerCase();
        print('[COMPLAINT DEBUG] Image extension: $extension');

        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          setState(() {
            _errorMessage =
                'Format file tidak didukung. Gunakan: JPG, JPEG, atau PNG.';
          });
          return;
        }

        // Validasi ukuran file
        final File file = File(image.path);
        final int fileSize = await file.length();
        final double fileSizeInMB = fileSize / (1024 * 1024);
        print(
            '[COMPLAINT DEBUG] Image size: ${fileSizeInMB.toStringAsFixed(2)} MB');

        if (fileSizeInMB > 5) {
          setState(() {
            _errorMessage = 'Ukuran file terlalu besar. Maksimal 5 MB.';
          });
          return;
        }

        // Jika format valid, atur gambar
        setState(() {
          _selectedImage = File(image.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error mengambil gambar: $e';
      });
      print('[COMPLAINT DEBUG] Error in _getImage: $e');
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Menggunakan endpoint dari ApiConfig
      var complaintUrl = ApiConfig.complaintsUrl;
      print('[COMPLAINT DEBUG] Using complaint URL: $complaintUrl');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(complaintUrl),
      );

      // Menambahkan field yang diperlukan sesuai dokumentasi
      request.fields['asset_id'] = _assetIdController.text;
      request.fields['description'] = _descriptionController.text;

      // Menambahkan image jika ada
      if (_selectedImage != null) {
        try {
          // Mendapatkan MIME type
          final String extension =
              _selectedImage!.path.split('.').last.toLowerCase();
          String mimeType;

          if (extension == 'jpg' || extension == 'jpeg') {
            mimeType = 'image/jpeg';
          } else if (extension == 'png') {
            mimeType = 'image/png';
          } else {
            mimeType = 'application/octet-stream';
          }

          print(
              '[COMPLAINT DEBUG] File MIME type: $mimeType, extension: $extension');

          // Membaca file sebagai bytes
          final bytes = await _selectedImage!.readAsBytes();
          final filename = _selectedImage!.path.split('/').last;

          // Membuat multipart file dengan MIME type yang spesifik
          final multipartFile = http.MultipartFile.fromBytes(
            'image_file',
            bytes,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          );

          request.files.add(multipartFile);
          print(
              '[COMPLAINT DEBUG] Added file $filename with MIME type $mimeType');
        } catch (e) {
          print('[COMPLAINT DEBUG] Error adding file: $e');
          setState(() {
            _isLoading = false;
            _errorMessage = 'Error saat mengunggah gambar: $e';
          });
          return;
        }
      }

      // Menambahkan token otorisasi
      final accessToken = await ApiService.getAccessToken();
      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      // Log request headers
      print('[COMPLAINT DEBUG] Request headers: ${request.headers}');

      // Log request fields
      print('[COMPLAINT DEBUG] Request fields: ${request.fields}');

      // Log request files
      if (request.files.isNotEmpty) {
        print(
            '[COMPLAINT DEBUG] Request files: ${request.files.length} file(s)');
        for (var file in request.files) {
          print(
              '[COMPLAINT DEBUG] File: ${file.filename}, field: ${file.field}, contentType: ${file.contentType}');
        }
      }

      // Mengirim request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      print('Submit complaint response: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Parse response
      var jsonResponse = json.decode(response.body);

      // Cek response code dan status
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (jsonResponse['status'] == true) {
          if (mounted) {
            // Menampilkan pesan sukses dan kembali ke halaman sebelumnya
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Komplain berhasil dikirim'),
                backgroundColor: Color(0xFF213268),
              ),
            );
            Navigator.pop(context);
          }
        } else {
          // Menampilkan pesan error dari API
          setState(() {
            _errorMessage =
                jsonResponse['message'] ?? 'Gagal mengirim komplain';
          });
        }
      } else if (response.statusCode == 400) {
        // Menampilkan pesan error untuk bad request
        setState(() {
          _errorMessage = jsonResponse['errors'] ?? 'Data tidak valid';
        });
      } else if (response.statusCode == 401) {
        // Menampilkan pesan error untuk unauthorized
        setState(() {
          _errorMessage = 'Sesi anda telah berakhir. Silakan login kembali.';
        });
      } else if (response.statusCode == 404) {
        // Menampilkan pesan error untuk asset not found
        setState(() {
          _errorMessage = jsonResponse['errors'] ?? 'Aset tidak ditemukan';
        });
      } else if (response.statusCode == 500) {
        // Memeriksa apakah error terkait format file
        if (response.body
            .toLowerCase()
            .contains('format file tidak didukung')) {
          setState(() {
            _errorMessage = jsonResponse['errors'] ??
                'Format file tidak didukung. Gunakan: image/jpeg, image/jpg, atau image/png';
          });
        } else {
          setState(() {
            _errorMessage =
                jsonResponse['errors'] ?? 'Terjadi kesalahan pada server';
          });
        }
      } else {
        // Menampilkan pesan error umum
        setState(() {
          _errorMessage = 'Gagal mengirim komplain: ${response.statusCode}';
        });
      }
    } catch (e) {
      // Menampilkan pesan error untuk exception
      setState(() {
        _errorMessage = 'Error: $e';
      });
      print('Exception during complaint submission: $e');
    } finally {
      // Mengakhiri loading state
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

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
                      'Formulir Komplain Aset',
                      style: TextStyle(
                        fontFamily: 'Inter',
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
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF213268),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
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

                          // Asset ID Display
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
                                  widget.assetData?['asset_code'] ??
                                      widget.assetCode,
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

                          // Asset Name Display
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
                    const SizedBox(height: 24),

                    // Hidden Asset ID Field
                    TextFormField(
                      controller: _assetIdController,
                      decoration: const InputDecoration(
                        labelText: 'ID Aset',
                        border: InputBorder.none,
                      ),
                      style:
                          const TextStyle(height: 0, color: Colors.transparent),
                      obscureText: true,
                      enabled: false,
                    ),

                    // Description Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deskripsi Masalah',
                          style: TextStyle(
                            fontFamily: 'Inter',
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
                                'Jelaskan masalah yang Anda alami dengan aset ini',
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
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF666666),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '(Opsional)',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_selectedImage == null)
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
                                      fontFamily: 'Inter',
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
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImage = null;
                                    });
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

                    if (_errorMessage != null)
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
                                  _errorMessage!,
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
                        onPressed: _isLoading ? null : _submitComplaint,
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
                        child: _isLoading
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
                                'Kirim Komplain',
                                style: TextStyle(
                                  fontFamily: 'Inter',
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
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _assetIdController.dispose();
    super.dispose();
  }
}
