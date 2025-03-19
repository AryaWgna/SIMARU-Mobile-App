import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'asset_history.dart';
import 'asset_schedule.dart';
import 'asset_mutation.dart';
import 'asset_depreciation.dart';
import 'asset_details.dart';
import 'package:dotted_border/dotted_border.dart';

class AssetDocument extends StatefulWidget {
  const AssetDocument({super.key});

  @override
  State<AssetDocument> createState() => _AssetDocumentState();
}

class _AssetDocumentState extends State<AssetDocument> {
  final titleController = TextEditingController();
  File? selectedFile;
  String fileName = '';

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'png',
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'csv'
      ],
    );

    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        fileName = result.files.single.name;
      });
    }
  }

  Future<void> _showAddDocumentDialog() async {
    // Reset state setiap kali dialog dibuka
    setState(() {
      titleController.text = '';
      selectedFile = null;
      fileName = '';
    });

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        // Mendapatkan ukuran layar
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 600;

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          // Menyesuaikan padding sesuai ukuran layar
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 24,
            vertical: isSmallScreen ? 24 : 40,
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: isSmallScreen ? screenSize.width - 32 : 600,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 24 : 35,
                      horizontal: isSmallScreen ? 20 : 40,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header - dengan ukuran font yang responsif
                        Text(
                          'ADD NEW DOCUMENT',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : 32,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF203268),
                            fontFamily: 'Inter',
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 24 : 40),

                        // Title field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Title',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF666666),
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: titleController,
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Inter',
                                color: Color(0xFF666666),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type here',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 16,
                                  fontFamily: 'Inter',
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFCCCCCC)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFCCCCCC)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF213268)),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // File upload section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title Section
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Insert Your File',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF666666),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Maximum file size allowed: 10 MB',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF6D6D6D),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Upload area dengan border dashed menggunakan package dotted_border
                            GestureDetector(
                              onTap: () async {
                                await _pickFile();
                                setDialogState(() {});
                              },
                              child: DottedBorder(
                                color: const Color(0xFF213268),
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(8),
                                padding: EdgeInsets.zero,
                                strokeWidth: 1,
                                dashPattern: const [6, 3],
                                child: Container(
                                  width: double.infinity,
                                  height: isSmallScreen ? 120 : 144,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (selectedFile == null) ...[
                                        const Icon(
                                          Icons.cloud_upload_outlined,
                                          color: Color(0xFF213268),
                                          size: 32,
                                        ),
                                        const SizedBox(height: 8),
                                        const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Drag your file(s) or ',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF1C1C1C),
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                            Text(
                                              'browse',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF213268),
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: Text(
                                            'jpg, png, pdf, doc, docx, xls, xlsx or csv',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFAFAFAF),
                                              fontFamily: 'Inter',
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ] else ...[
                                        const Icon(
                                          Icons.insert_drive_file_outlined,
                                          color: Color(0xFF213268),
                                          size: 32,
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(
                                            fileName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF213268),
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () {
                                            setDialogState(() {
                                              selectedFile = null;
                                              fileName = '';
                                            });
                                          },
                                          child: const Text(
                                            'Remove',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.red,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: (titleController.text.isNotEmpty &&
                                    selectedFile != null)
                                ? () {
                                    // Logika penyimpanan dokumen
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Document saved successfully'),
                                        backgroundColor: Color(0xFF213268),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF203268),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade500,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Inter',
                                color: Color(0xFFF5F5F5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            // Document List - Lebih dekat dengan appbar
            Positioned(
              left: 22,
              right: 22,
              top: 24, // Lebih dekat dengan appbar (sebelumnya 40)
              child: Container(
                height: 144,
                width: 392,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 4.5,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Document Header
                    const Padding(
                      padding: EdgeInsets.only(
                          left: 9, right: 9, top: 10, bottom: 9),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Document Title',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.download,
                                  color: Color(0xFF25B1FF), size: 24),
                              SizedBox(width: 18),
                              Icon(Icons.delete_outline,
                                  color: Colors.red, size: 24),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    const Divider(
                        color: Color(0xFF757575), thickness: 1, height: 1),

                    // Document Details
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _buildDetailRow('File Name'),
                          const SizedBox(height: 12),
                          _buildDetailRow('Type'),
                          const SizedBox(height: 12),
                          _buildDetailRow('Upload Date'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating Action Button - untuk menampilkan dialog Add New Document
            Positioned(
              right: 22,
              bottom: 15, // Sangat dekat dengan tab bar
              child: GestureDetector(
                onTap: _showAddDocumentDialog,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25B1FF),
                    borderRadius: BorderRadius.circular(27),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, 'document'),
    );
  }

  Widget _buildDetailRow(String text) {
    return SizedBox(
      width: double.infinity,
      height: 15,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: Colors.black,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return PreferredSize(
      preferredSize: const Size.fromHeight(82),
      child: Stack(
        children: [
          // Warna biru tua untuk AppBar
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
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AssetDetails(qrData: '')),
                  ),
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
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, String activePage) {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, -4),
            blurRadius: 4,
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            Icons.folder,
            'Document',
            activePage == 'document',
            () {},
          ),
          _buildNavItem(
            Icons.history,
            'History',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssetHistory()),
            ),
          ),
          _buildNavItem(
            Icons.calendar_today,
            'Schedule',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssetSchedule()),
            ),
          ),
          _buildNavItem(
            Icons.swap_horiz,
            'Mutasi',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssetMutation()),
            ),
          ),
          _buildNavItem(
            Icons.trending_down,
            'Depreciation',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AssetDepreciation()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isActive ? const Color(0xFF213268) : const Color(0xFF757575),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: isActive
                    ? const Color(0xFF213268)
                    : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
