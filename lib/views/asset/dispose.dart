import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DisposeScreen extends StatefulWidget {
  const DisposeScreen({super.key});

  @override
  State<DisposeScreen> createState() => _DisposeScreenState();
}

class _DisposeScreenState extends State<DisposeScreen> {
  DateTime? selectedDate;
  final TextEditingController reasonController = TextEditingController();

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final ThemeData theme = Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF213268),
        onPrimary: Colors.white,
        onSurface: Color(0xFF666666),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF213268),
        ),
      ),
    );

    final DateTime currentDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? currentDate,
      firstDate: currentDate,
      lastDate:
          DateTime(currentDate.year + 1, currentDate.month, currentDate.day),
      builder: (context, child) {
        return Theme(
          data: theme,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child!,
          ),
        );
      },
      helpText: 'SELECT DISPOSE DATE',
      cancelText: 'CANCEL',
      confirmText: 'SELECT',
      useRootNavigator: true,
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Dispose date: ${DateFormat('MM/dd/yyyy').format(picked)}'),
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(82),
        child: AppBar(
          backgroundColor: const Color(0xFF213268),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Center(
            child: Image.asset(
              'images/Logo_RS_UMMI_white.png',
              width: 208,
              height: 55,
            ),
          ),
          actions: const [
            SizedBox(width: 55),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(21),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DISPOSE',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF213268),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 25),

              // Dispose Date - border removed
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dispose Date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Color(0xFF757575)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedDate == null
                                  ? 'Choose Date'
                                  : DateFormat('MM/dd/yyyy')
                                      .format(selectedDate!),
                              style: TextStyle(
                                fontSize: 16,
                                color: selectedDate == null
                                    ? const Color(0xFF666666)
                                    : Colors.black87,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          if (selectedDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                setState(() {
                                  selectedDate = null;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: const Color(0xFF666666),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Dispose Reason - border removed
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dispose Reason',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: 'Enter the reason',
                      hintStyle: const TextStyle(color: Color(0xFF666666)),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [],
        ),
        padding: const EdgeInsets.only(left: 21, right: 21, bottom: 18),
        child: ElevatedButton(
          onPressed: selectedDate == null
              ? null
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dispose process successful'),
                      backgroundColor: Color(0xFF213268),
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF213268),
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
            'Dispose',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}
