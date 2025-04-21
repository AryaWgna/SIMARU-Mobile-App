// stockopname_task_list.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'stockopname_scan_completed.dart';
import 'stockopname_scan_result.dart';

// Enum untuk status task
enum TaskStatus { scheduled, inProgress, done, completed }

class StockopnameTaskList extends StatefulWidget {
  const StockopnameTaskList({super.key});

  @override
  _StockopnameTaskListState createState() => _StockopnameTaskListState();
}

class _StockopnameTaskListState extends State<StockopnameTaskList> {
  // Data langsung didefinisikan di sini tanpa model terpisah
  late List<Map<String, dynamic>> tasks;

  @override
  void initState() {
    super.initState();
    // Data dummy
    tasks = [
      {
        'id': '1',
        'date': DateTime(2025, 3, 6),
        'location': 'Building A, ICU 1st Floor',
        'initiatedBy': 'John Doe',
        'description': 'Opname Desc',
        'status': TaskStatus.scheduled,
        'totalAssets': 50,
        'foundAssets': 0,
        'wrongLocation': 0,
        'slightlyDMG': 0,
        'highlyDMG': 0,
      },
      {
        'id': '2',
        'date': DateTime(2025, 3, 6),
        'location': 'Building A, ICU 1st Floor',
        'initiatedBy': 'John Doe',
        'description': 'Opname Desc',
        'status': TaskStatus.inProgress,
        'totalAssets': 50,
        'foundAssets': 15,
        'wrongLocation': 2,
        'slightlyDMG': 1,
        'highlyDMG': 0,
      },
      {
        'id': '3',
        'date': DateTime(2025, 3, 6),
        'location': 'Building A, ICU 1st Floor',
        'initiatedBy': 'John Doe',
        'description': 'Opname Desc',
        'status': TaskStatus.done,
        'totalAssets': 50,
        'foundAssets': 50,
        'wrongLocation': 3,
        'slightlyDMG': 2,
        'highlyDMG': 1,
      },
      {
        'id': '4',
        'date': DateTime(2025, 3, 8),
        'location': 'Building A, ICU 1st Floor',
        'initiatedBy': 'John Doe',
        'description': 'Opname Desc',
        'status': TaskStatus.completed,
        'totalAssets': 50,
        'foundAssets': 50,
        'wrongLocation': 0,
        'slightlyDMG': 0,
        'highlyDMG': 0,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return _buildTaskCard(tasks[index]);
        },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan tanggal dan status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tanggal di kiri
                Text(
                  DateFormat('dd MMMM yyyy').format(task['date']),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF25B1FF),
                  ),
                ),
                // Status di kanan
                _buildSimpleStatusBadge(task['status']),
              ],
            ),
          ),
          // Konten utama kartu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Opname Code',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF213268),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'End Date: ${DateFormat('dd MMMM yyyy').format(task['date'])}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF757575),
                  ),
                ),
                Text(
                  task['location'],
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Initiate by ${task['initiatedBy']}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF757575),
                  ),
                ),
                Text(
                  task['description'],
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF213268),
                  ),
                ),
              ],
            ),
          ),
          // Tombol aksi (jika bukan status completed)
          if (task['status'] != TaskStatus.completed) _buildActionButton(task),
        ],
      ),
    );
  }

  Widget _buildSimpleStatusBadge(TaskStatus status) {
    Color textColor;
    String statusText;
    IconData iconData;

    switch (status) {
      case TaskStatus.scheduled:
        textColor = Colors.grey;
        statusText = 'Scheduled';
        iconData = Icons.schedule;
        break;
      case TaskStatus.inProgress:
        textColor = Colors.blue;
        statusText = 'In Progress';
        iconData = Icons.refresh;
        break;
      case TaskStatus.done:
        textColor = const Color(0xFF659B09);
        statusText = 'Done';
        iconData = Icons.check_circle_outline;
        break;
      case TaskStatus.completed:
        textColor = const Color(0xFF659B09);
        statusText = 'Completed';
        iconData = Icons.check_circle;
        break;
      default:
        textColor = Colors.grey;
        statusText = 'Unknown';
        iconData = Icons.help_outline;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconData, color: textColor, size: 14),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(Map<String, dynamic> task) {
    Color buttonColor;
    String buttonText;

    switch (task['status']) {
      case TaskStatus.scheduled:
        buttonColor = const Color(0xFF25B1FF);
        buttonText = 'Work';
        break;
      case TaskStatus.inProgress:
        buttonColor = const Color(0xFF659B09);
        buttonText = 'Done';
        break;
      case TaskStatus.done:
        buttonColor = const Color(0xFF659B09);
        buttonText = 'Done';
        break;
      default:
        buttonColor = Colors.grey;
        buttonText = '';
    }

    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: TextButton(
        onPressed: () => _navigateToScan(task),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _navigateToScan(Map<String, dynamic> task) {
    // Jika tombol berteks "Done" (status inProgress atau done), langsung navigasi ke scan completed
    if (task['status'] == TaskStatus.done ||
        task['status'] == TaskStatus.inProgress) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StockopnameScanCompletedScreen(task: task),
        ),
      );
    } else {
      // Jika status scheduled (tombol "Work"), navigasi ke scan result seperti biasa
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StockopnameScanResultScreen(task: task),
        ),
      );
    }
  }
}
