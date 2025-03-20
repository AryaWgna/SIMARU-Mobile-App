import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/custom_app_bar.dart';

class MaintenanceFormScreen extends StatefulWidget {
  const MaintenanceFormScreen({super.key});

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final TextEditingController _findingsController = TextEditingController();
  final TextEditingController _actionTakenController = TextEditingController();
  final TextEditingController _partReplacementController =
      TextEditingController();
  final TextEditingController _costController = TextEditingController();
  DateTime? _nextMaintenanceDate;
  DateTime? _tempDate;

  @override
  void dispose() {
    _findingsController.dispose();
    _actionTakenController.dispose();
    _partReplacementController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    // Tutup keyboard terlebih dahulu
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));

    // Buat tema khusus untuk kalender
    final ThemeData theme = Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF213268), // Warna header kalender
        onPrimary: Colors.white, // Warna teks pada header
        onSurface: Color(0xFF666666), // Warna teks tanggal
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF213268), // Warna tombol
        ),
      ),
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _nextMaintenanceDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        // Menggunakan MediaQuery untuk mengatur skala teks dan mencegah overflow
        return Theme(
          data: theme,
          child: MediaQuery(
            // Tetapkan skala teks ke 1.0 untuk mencegah text overflow
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child!,
          ),
        );
      },
      // Gunakan root navigator untuk menghindari masalah layout
      useRootNavigator: true,
    );

    if (picked != null) {
      setState(() {
        _nextMaintenanceDate = picked;
      });

      // Tampilkan pesan konfirmasi jika perlu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Tanggal maintenance berikutnya: ${picked.day}/${picked.month}/${picked.year}'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF213268),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
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
          // Judul di bawah AppBar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'MAINTENANCE DETAIL',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF213268),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Asset Image
                  Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Form Fields
                  _buildFormField('Findings', _findingsController),
                  const SizedBox(height: 16),

                  _buildFormField('Action Taken', _actionTakenController),
                  const SizedBox(height: 16),

                  _buildFormField(
                      'Part Replacement', _partReplacementController),
                  const SizedBox(height: 16),

                  _buildFormField('Cost', _costController),
                  const SizedBox(height: 16),

                  // Date Picker
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
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                _nextMaintenanceDate != null
                                    ? '${_nextMaintenanceDate!.day}/${_nextMaintenanceDate!.month}/${_nextMaintenanceDate!.year}'
                                    : 'Choose Date',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _nextMaintenanceDate != null
                                      ? Colors.black
                                      : Colors.grey[600],
                                ),
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

          // Submit Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // Validate and submit form
                  if (_validateForm()) {
                    _submitForm();
                  }
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    const Color(0xFF213268),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                child: Text(
                  'Submit',
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

  Widget _buildFormField(String label, TextEditingController controller) {
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
          maxLines: label == 'Findings' || label == 'Action Taken' ? 3 : 1,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[400],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF213268)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }

  bool _validateForm() {
    // Add validation logic here
    return true;
  }

  void _submitForm() {
    // Add form submission logic here
    Navigator.pop(context);
  }
}
