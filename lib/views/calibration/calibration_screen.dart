import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../controllers/calibration_controller.dart';
import '../../models/calibration_model.dart';
import 'calibration_detail_progress_screen.dart';
import 'calibration_detail_work_screen.dart';
import 'calibration_assist_screen.dart';
import 'package:intl/intl.dart';
import 'calibration_detail_screen.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  @override
  void initState() {
    super.initState();
    final controller =
        Provider.of<CalibrationController>(context, listen: false);
    controller.loadCalibrations(context);
  }

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd MMMM yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.grey;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return const Color(0xFF76B947);
      default:
        return Colors.grey;
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
                    onPressed: () {
                      controller.clearError();
                      controller.loadCalibrations(context);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (controller.calibrations.isEmpty) {
            return const Center(
              child: Text('No calibrations found'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadCalibrations(context),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.calibrations.length,
              itemBuilder: (context, index) {
                final calibration = controller.calibrations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCalibrationItem(
                    context: context,
                    calibration: calibration,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalibrationItem({
    required BuildContext context,
    required Calibration calibration,
  }) {
    String buttonText;
    Color buttonColor;
    VoidCallback onButtonTap;

    switch (calibration.statusCalibration.toLowerCase()) {
      case 'scheduled':
        buttonText = 'Assist';
        buttonColor = const Color(0xFF213268);
        onButtonTap = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalibrationDetailScreen(
                calibrationId: calibration.id,
                status: calibration.statusCalibration,
                performedBy: calibration.completedByName ?? 'Not assigned',
              ),
            ),
          );
        };
        break;
      case 'in_progress':
        buttonText = 'Work';
        buttonColor = Colors.blue;
        onButtonTap = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalibrationDetailScreen(
                calibrationId: calibration.id,
                status: calibration.statusCalibration,
                performedBy: calibration.completedByName ?? 'Technician',
              ),
            ),
          );
        };
        break;
      case 'completed':
        buttonText = 'Done';
        buttonColor = const Color(0xFF76B947);
        onButtonTap = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalibrationDetailScreen(
                calibrationId: calibration.id,
                status: calibration.statusCalibration,
                performedBy: calibration.completedByName ?? 'Unknown',
              ),
            ),
          );
        };
        break;
      default:
        buttonText = 'View';
        buttonColor = Colors.grey;
        onButtonTap = () {};
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(calibration.planningCalibrationDate),
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
                Row(
                  children: [
                    Icon(
                      calibration.statusCalibration.toLowerCase() ==
                              'in_progress'
                          ? Icons.sync
                          : Icons.schedule,
                      color: _getStatusColor(calibration.statusCalibration),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      calibration.statusCalibration,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _getStatusColor(calibration.statusCalibration),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[300],
                ),
                const SizedBox(width: 16),
                Expanded(
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scheduled by',
                  style: GoogleFonts.inter(
                    fontSize: 14,
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
              ],
            ),
          ),
          GestureDetector(
            onTap: onButtonTap,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Center(
                child: Text(
                  buttonText,
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
}
