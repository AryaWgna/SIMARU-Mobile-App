import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../controllers/calibration_controller.dart';
import 'package:intl/intl.dart';

class CalibrationFormScreen extends StatefulWidget {
  final int calibrationId;

  const CalibrationFormScreen({
    super.key,
    required this.calibrationId,
  });

  @override
  State<CalibrationFormScreen> createState() => _CalibrationFormScreenState();
}

class _CalibrationFormScreenState extends State<CalibrationFormScreen> {
  bool isPassed = true;
  final TextEditingController _actualDateController = TextEditingController();
  final TextEditingController _nextScheduleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _certificateNumberController =
      TextEditingController();
  final TextEditingController _institutionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCalibrationDetails();
  }

  Future<void> _loadCalibrationDetails() async {
    final controller =
        Provider.of<CalibrationController>(context, listen: false);
    await controller.getCalibrationById(context, widget.calibrationId);

    // Pre-fill form if data exists
    final calibration = controller.selectedCalibration;
    if (calibration != null) {
      if (calibration.actualCalibrationDate != null) {
        _actualDateController.text =
            _formatDate(calibration.actualCalibrationDate!);
      }
      if (calibration.nextCalibrationDate != null) {
        _nextScheduleController.text =
            _formatDate(calibration.nextCalibrationDate!);
      }
      if (calibration.calibrationPrice != null) {
        _priceController.text = calibration.calibrationPrice.toString();
      }
      if (calibration.certificateNumber != null) {
        _certificateNumberController.text = calibration.certificateNumber!;
      }
      setState(() {
        isPassed = calibration.calibrationResult?.toLowerCase() == 'pass';
      });
    }
  }

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
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

          final calibration = controller.selectedCalibration;
          if (calibration == null) {
            return const Center(child: Text('Calibration not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form Title
                Text(
                  'CALIBRATION FORM',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF213268),
                  ),
                ),
                Text(
                  calibration.taskCode,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // Asset Information Section
                Text(
                  'ASSET INFORMATION',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoField('ASSET NAME', calibration.assetName),
                _buildInfoField('LOCATION', calibration.location.roomName),
                _buildInfoField('ASSET CODE', calibration.assetCode),
                _buildInfoField('MERK/TYPE',
                    '${calibration.brandName} ${calibration.modelNumber}'),
                _buildInfoField('SN', calibration.serialNumber),

                // Calibration Section
                const SizedBox(height: 24),
                Text(
                  'CALIBRATION',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Planning Date
                _buildInfoField('PLANNING DATE',
                    _formatDate(calibration.planningCalibrationDate)),

                // Actual Date
                _buildDateField(
                  'ACTUAL DATE',
                  _actualDateController,
                  () => _selectDate(context, _actualDateController),
                ),

                // Institution
                _buildTextField(
                  'CALIBRATION INSTITUTION',
                  _institutionController,
                ),

                // Price
                _buildTextField(
                  'PRICE',
                  _priceController,
                  prefix: 'Rp',
                  keyboardType: TextInputType.number,
                ),

                // Next Schedule
                _buildDateField(
                  'NEXT SCHEDULE',
                  _nextScheduleController,
                  () => _selectDate(context, _nextScheduleController),
                ),

                // Calibration Result
                const SizedBox(height: 16),
                Text(
                  'CALIBRATION RESULT',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: isPassed,
                      onChanged: (value) => setState(() => isPassed = value!),
                    ),
                    Text(
                      'FAIL (Tidak Laik Pakai)',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    Radio<bool>(
                      value: true,
                      groupValue: isPassed,
                      onChanged: (value) => setState(() => isPassed = value!),
                    ),
                    Text(
                      'PASS (Laik Pakai)',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ],
                ),

                // Certificate Number
                _buildTextField(
                  'CERTIFICATE NUMBER',
                  _certificateNumberController,
                ),

                // Buttons
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'CLOSE',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement save functionality
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'SAVE & CLOSE',
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? prefix,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              prefixText: prefix,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              border: const UnderlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    TextEditingController controller,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onTap,
            child: AbsorbPointer(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  border: const UnderlineInputBorder(),
                  suffixIcon:
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
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
    _actualDateController.dispose();
    _nextScheduleController.dispose();
    _priceController.dispose();
    _certificateNumberController.dispose();
    _institutionController.dispose();
    super.dispose();
  }
}
