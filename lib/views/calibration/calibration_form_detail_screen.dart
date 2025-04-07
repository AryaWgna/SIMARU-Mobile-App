import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../controllers/calibration_controller.dart';
import 'package:intl/intl.dart';

class CalibrationFormDetailScreen extends StatefulWidget {
  final int calibrationId;

  const CalibrationFormDetailScreen({
    super.key,
    required this.calibrationId,
  });

  @override
  State<CalibrationFormDetailScreen> createState() =>
      _CalibrationFormDetailScreenState();
}

class _CalibrationFormDetailScreenState
    extends State<CalibrationFormDetailScreen> {
  final TextEditingController _actualDateController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _nextScheduleController = TextEditingController();
  final TextEditingController _certificateNumberController =
      TextEditingController();
  bool isPassed = true;

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
        _actualDateController.text = calibration.actualCalibrationDate ?? '';
        _nextScheduleController.text = calibration.nextCalibrationDate ?? '';
        _priceController.text = calibration.calibrationPrice?.toString() ?? '0';
        _certificateNumberController.text = calibration.certificateNumber ?? '';
        isPassed = calibration.calibrationResult?.toLowerCase() == 'pass';
      });
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
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
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

          final calibration = controller.selectedCalibration;
          if (calibration == null) {
            return const Center(child: Text('Calibration not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                const SizedBox(height: 16),
                const Divider(),

                // Asset Information
                Text(
                  'ASSET INFORMATION',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                _buildInfoField('ASSET NAME', calibration.assetName),
                _buildInfoField('LOCATION', calibration.location.roomName),
                _buildInfoField('ASSET CODE', calibration.assetCode),
                _buildInfoField('MERK/TYPE', calibration.brandName),
                _buildInfoField('SN', calibration.serialNumber),
                const Divider(),

                // Calibration Section
                Text(
                  'CALIBRATION',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                _buildInfoField(
                    'PLANNING DATE', calibration.planningCalibrationDate),

                // Actual Date with Calendar Icon
                _buildDateField(
                  'ACTUAL DATE',
                  _actualDateController,
                  () => _selectDate(context, _actualDateController),
                ),

                // Institution with Building Icon
                _buildTextField(
                  'CALIBRATION INSTITUTION',
                  _institutionController,
                  suffixIcon: Icons.business,
                ),

                // Price
                _buildTextField(
                  'PRICE',
                  _priceController,
                  prefix: 'Rp',
                  keyboardType: TextInputType.number,
                ),

                // Next Schedule with Calendar Icon
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
                    fontSize: 12,
                    color: Colors.grey[600],
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

                // Task Assignment Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'You are assigned to this task',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Buttons
                const SizedBox(height: 16),
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
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleSubmit(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'SAVE & CLOSE',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
    IconData? suffixIcon,
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
              suffixIcon: suffixIcon != null
                  ? Icon(suffixIcon, color: Colors.grey)
                  : null,
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
                  suffixIcon:
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  border: const UnderlineInputBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    final controller =
        Provider.of<CalibrationController>(context, listen: false);

    final data = {
      'actual_calibration_date': _actualDateController.text,
      'next_calibration_date': _nextScheduleController.text,
      'calibration_price': double.tryParse(_priceController.text) ?? 0,
      'certificate_number': _certificateNumberController.text,
      'calibration_result': isPassed ? 'pass' : 'fail',
      'calibration_institution': _institutionController.text,
    };

    final success =
        await controller.updateCalibration(context, widget.calibrationId, data);

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update calibration')),
      );
    }
  }

  @override
  void dispose() {
    _actualDateController.dispose();
    _institutionController.dispose();
    _priceController.dispose();
    _nextScheduleController.dispose();
    _certificateNumberController.dispose();
    super.dispose();
  }
}
