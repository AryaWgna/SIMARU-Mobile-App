import 'package:flutter/material.dart';
import '../../controllers/maintenance_controller.dart';

class MaintenanceListScreen extends StatefulWidget {
  const MaintenanceListScreen({Key? key}) : super(key: key);

  @override
  _MaintenanceListScreenState createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  List<dynamic> _maintenanceList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Menggunakan addPostFrameCallback untuk memastikan widget telah diinisialisasi sepenuhnya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMaintenanceList();
    });
  }

  Future<void> _loadMaintenanceList() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final list = await MaintenanceController.getMaintenanceList(context);
      if (!mounted) return;

      setState(() {
        _maintenanceList = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance List'),
        backgroundColor: const Color(0xFF213268),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadMaintenanceList,
        backgroundColor: const Color(0xFF25B1FF),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMaintenanceList,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_maintenanceList.isEmpty) {
      return const Center(
        child: Text('No maintenance items found'),
      );
    }

    return ListView.builder(
      itemCount: _maintenanceList.length,
      itemBuilder: (context, index) {
        final item = _maintenanceList[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(item['title'] ?? 'No Title'),
            subtitle: Text(item['status'] ?? 'Unknown Status'),
            trailing: Icon(
              _getStatusIcon(item['status']),
              color: _getStatusColor(item['status']),
            ),
            onTap: () {
              // Navigate to detail screen
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => MaintenanceDetailScreen(id: item['id']),
              //   ),
              // );
            },
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'Scheduled':
        return Icons.schedule;
      case 'In Progress':
        return Icons.engineering;
      case 'Completed':
        return Icons.check_circle;
      default:
        return Icons.info_outline;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Scheduled':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
