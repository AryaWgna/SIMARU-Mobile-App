import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../controllers/calibration_controller.dart';
import '../../models/calibration_model.dart';
import 'package:intl/intl.dart';

class CalibrationDetailScreen extends StatefulWidget {
  final int calibrationId;
  final String status;
  final String performedBy;

  const CalibrationDetailScreen({
    super.key,
    required this.calibrationId,
    required this.status,
    required this.performedBy,
  });

  @override
  State<CalibrationDetailScreen> createState() =>
      _CalibrationDetailScreenState();
}

class _CalibrationDetailScreenState extends State<CalibrationDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadCalibrationDetails();
  }

  Future<void> _loadCalibrationDetails() async {
    final controller =
        Provider.of<CalibrationController>(context, listen: false);
    await controller.getCalibrationById(context, widget.calibrationId);
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd MMMM yyyy').format(parsedDate);
    } catch (e) {
      return date;
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    'Calibration',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF213268),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date and Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(
                                    calibration.planningCalibrationDate),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                'Task: ${calibration.taskCode}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          _buildStatusWidget(calibration.statusCalibration),
                        ],
                      ),

                      // Asset Info
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              calibration.assetCode,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              calibration.assetName,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${calibration.brandName} | SN: ${calibration.serialNumber}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              calibration.location.getFullLocation(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Calibration Details
                      const SizedBox(height: 24),
                      Text(
                        'Calibration Details',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF213268),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Planning Date',
                          _formatDate(calibration.planningCalibrationDate)),
                      if (calibration.actualCalibrationDate != null)
                        _buildDetailRow('Actual Date',
                            _formatDate(calibration.actualCalibrationDate)),
                      if (calibration.nextCalibrationDate != null)
                        _buildDetailRow('Next Date',
                            _formatDate(calibration.nextCalibrationDate)),
                      _buildDetailRow('Status', calibration.statusCalibration),
                      if (calibration.certificateNumber != null)
                        _buildDetailRow(
                            'Certificate No', calibration.certificateNumber!),
                      if (calibration.calibrationResult != null)
                        _buildDetailRow(
                            'Result', calibration.calibrationResult!),
                      if (calibration.calibrationPrice != null)
                        _buildDetailRow('Price',
                            'Rp ${NumberFormat('#,###').format(calibration.calibrationPrice)}'),
                      if (calibration.notes != null)
                        _buildDetailRow('Notes', calibration.notes!),

                      // Scheduled By
                      const SizedBox(height: 24),
                      Text(
                        'Scheduled by',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        calibration.scheduledByName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      // Completed By (if available)
                      if (calibration.completedByName != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Completed by',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          calibration.completedByName!,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
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

  Widget _buildStatusWidget(String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'scheduled':
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case 'completed':
        statusColor = const Color(0xFF76B947);
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Row(
      children: [
        Icon(
          statusIcon,
          color: statusColor,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          status,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    final controller =
        Provider.of<CalibrationController>(context, listen: false);
    controller.clearSelectedCalibration();
    super.dispose();
  }
}
