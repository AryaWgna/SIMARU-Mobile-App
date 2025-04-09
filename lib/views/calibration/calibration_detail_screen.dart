import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../controllers/calibration_controller.dart';
import '../../models/calibration_model.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class CalibrationDetailScreen extends StatefulWidget {
  final int calibrationId;

  const CalibrationDetailScreen({
    super.key,
    required this.calibrationId,
  });

  @override
  State<CalibrationDetailScreen> createState() =>
      _CalibrationDetailScreenState();
}

class _CalibrationDetailScreenState extends State<CalibrationDetailScreen> {
  bool isPassed = true;
  String? selectedFilePath;
  String? fileName;

  final TextEditingController _actualDateController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _nextScheduleController = TextEditingController();
  final TextEditingController _certificateNumberController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCalibrationDetails();
  }

  Future<void> _loadCalibrationDetails() async {
    final controller =
        Provider.of<CalibrationController>(context, listen: false);
    await controller.getCalibrationById(context, widget.calibrationId);

    final calibration = controller.selectedCalibration;
    if (calibration != null) {
      setState(() {
        isPassed = calibration.calibrationResult?.toLowerCase() == 'pass';
        _actualDateController.text = calibration.actualCalibrationDate ?? '';
        _nextScheduleController.text = calibration.nextCalibrationDate ?? '';
        _priceController.text = calibration.calibrationPrice != null
            ? calibration.calibrationPrice.toString()
            : '0';
        _certificateNumberController.text = calibration.certificateNumber ?? '';
        _notesController.text = calibration.notes ?? '';
        fileName = calibration.certificateFilePath?.split('/').last;
      });
    }
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        selectedFilePath = result.files.single.path;
        fileName = result.files.single.name;
      });
    }
  }

  Future<void> _saveCalibrationData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final controller =
          Provider.of<CalibrationController>(context, listen: false);

      final Map<String, dynamic> data = {
        'actual_calibration_date': _actualDateController.text,
        'next_calibration_date': _nextScheduleController.text,
        'calibration_price': int.tryParse(
                _priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
            0,
        'certificate_number': _certificateNumberController.text,
        'calibration_result': isPassed ? 'pass' : 'fail',
        'notes': _notesController.text,
        'calibration_institution': _institutionController.text,
      };

      final success = await controller.updateCalibration(
          context, widget.calibrationId, data,
          filePath: selectedFilePath);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calibration updated successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(controller.error ?? 'Failed to update calibration')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
      body: Consumer<CalibrationController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  ElevatedButton(
                    onPressed: _loadCalibrationDetails,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final calibration = controller.selectedCalibration;
          if (calibration == null) {
            return const Center(child: Text('Calibration not found'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CALIBRATION FORM',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF213268),
                        ),
                      ),
                      Text(
                        'CAL-${calibration.taskCode}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFDCDCDC)),

                // Asset Information Section
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'ASSET INFORMATION',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0D6EFD),
                    ),
                  ),
                ),

                _buildTableRow('ASSET NAME', calibration.assetName),
                _buildTableRow('LOCATION', calibration.location.roomName),
                _buildTableRow('ASSET CODE', calibration.assetCode),
                _buildTableRow('MERK/TYPE', calibration.brandName),
                _buildTableRow('SN', calibration.serialNumber),

                // Calibration Section
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'CALIBRATION',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0D6EFD),
                    ),
                  ),
                ),

                _buildTableRow('PLANNING DATE',
                    _formatDate(calibration.planningCalibrationDate)),
                _buildEditableDateRow(
                    'ACTUAL DATE', _actualDateController, _selectDate),
                _buildEditableRow('CALIBRATION INSTITUTION',
                    _institutionController, Icons.business),
                _buildEditableRow('PRICE', _priceController, null,
                    prefix: 'Rp'),
                _buildEditableDateRow(
                    'NEXT SCHEDULE', _nextScheduleController, _selectDate),

                // Calibration Result with radio buttons
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFDCDCDC), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 150,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        color: const Color(0xFFF2F2F2),
                        child: Text(
                          'CALIBRATION RESULT',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Radio<bool>(
                              value: false,
                              groupValue: isPassed,
                              onChanged: (value) {
                                setState(() {
                                  isPassed = value!;
                                });
                              },
                              activeColor: Colors.red,
                            ),
                            Text(
                              'FAIL (Tidak Laik Pakai)',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            const SizedBox(width: 16),
                            Radio<bool>(
                              value: true,
                              groupValue: isPassed,
                              onChanged: (value) {
                                setState(() {
                                  isPassed = value!;
                                });
                              },
                              activeColor: Colors.red,
                            ),
                            Text(
                              'PASS (Laik Pakai)',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                _buildEditableRow(
                    'CERTIFICATE NUMBER', _certificateNumberController, null),

                // Certificate File Upload Section
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Please provide PDF File or Photo\'s of Calibration Certificate below',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFDCDCDC), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 150,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        color: const Color(0xFFF2F2F2),
                        child: Text(
                          'CERTIFICATE FILE',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      fileName ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (fileName != null)
                                    Icon(
                                      Icons.picture_as_pdf,
                                      color: Colors.red,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ElevatedButton(
                                onPressed: _pickFile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D6EFD),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                                child: Text(
                                  'Add Certificate File',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Notes
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFDCDCDC), width: 1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        color: const Color(0xFFF2F2F2),
                        child: Text(
                          'NOTES',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              isLoading ? null : () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'CLOSE',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _saveCalibrationData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6EFD),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : Text(
                                  'SAVE & CLOSE',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
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
        },
      ),
    );
  }

  Widget _buildTableRow(String label, String value) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFDCDCDC), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 150,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF2F2F2),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow(
      String label, TextEditingController controller, IconData? icon,
      {String? prefix}) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFDCDCDC), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 150,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF2F2F2),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (prefix != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      prefix,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(icon, color: Colors.blue, size: 24),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDateRow(String label, TextEditingController controller,
      Function(TextEditingController) onTap) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFDCDCDC), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 150,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF2F2F2),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today,
                      color: Colors.red, size: 24),
                  onPressed: () => onTap(controller),
                  padding: const EdgeInsets.only(right: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _actualDateController.dispose();
    _institutionController.dispose();
    _priceController.dispose();
    _nextScheduleController.dispose();
    _certificateNumberController.dispose();
    _notesController.dispose();

    final controller =
        Provider.of<CalibrationController>(context, listen: false);
    controller.clearSelectedCalibration();
    super.dispose();
  }
}
