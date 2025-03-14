import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_app_bar.dart';

class ComplainWorkFormScreen extends StatefulWidget {
  final String assetCode;
  final String assetName;

  const ComplainWorkFormScreen({
    Key? key,
    required this.assetCode,
    required this.assetName,
  }) : super(key: key);

  @override
  State<ComplainWorkFormScreen> createState() => _ComplainWorkFormScreenState();
}

class _ComplainWorkFormScreenState extends State<ComplainWorkFormScreen> {
  final TextEditingController _findingsController = TextEditingController();
  final TextEditingController _actionTakenController = TextEditingController();
  final TextEditingController _partReplacementController =
      TextEditingController();
  final TextEditingController _costController = TextEditingController();
  DateTime? _nextMaintenanceDate;

  @override
  void dispose() {
    _findingsController.dispose();
    _actionTakenController.dispose();
    _partReplacementController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextMaintenanceDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF213268),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _nextMaintenanceDate) {
      setState(() {
        _nextMaintenanceDate = picked;
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'Report Teknisi',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF213268),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MAINTENANCE DETAIL Header
                    Text(
                      'MAINTENANCE DETAIL',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF213268),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Asset Image Placeholder
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Findings Field
                    _buildFormField(
                      label: 'Findings',
                      controller: _findingsController,
                      hintText: 'Enter Findings',
                    ),

                    const SizedBox(height: 16),

                    // Action Taken Field
                    _buildFormField(
                      label: 'Action Taken',
                      controller: _actionTakenController,
                      hintText: 'Enter Action Taken',
                    ),

                    const SizedBox(height: 16),

                    // Part Replacement Field
                    _buildFormField(
                      label: 'Part Replacement',
                      controller: _partReplacementController,
                      hintText: 'Enter Part Replacement',
                    ),

                    const SizedBox(height: 16),

                    // Cost Field
                    _buildFormField(
                      label: 'Cost',
                      controller: _costController,
                      hintText: 'Enter Maintenance Cost',
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    // Next Maintenance Date Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Maintenance Date',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _nextMaintenanceDate == null
                                      ? 'Choose Date'
                                      : DateFormat('dd MMM yyyy')
                                          .format(_nextMaintenanceDate!),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: _nextMaintenanceDate == null
                                        ? Colors.grey.shade600
                                        : Colors.black,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Submit Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // Handle submit action
                  Navigator.pop(context);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    const Color(0xFF213268),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                child: Text(
                  'SUBMIT',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF213268)),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 14),
        ),
      ],
    );
  }
}
