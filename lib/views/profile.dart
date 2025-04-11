import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'dart:convert';
import 'common/error_handling_screen.dart';

class ProfileScreen extends StatefulWidget implements ErrorHandlingCapable {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();

  @override
  String? get errorMessage => null;

  @override
  void clearError() {}
}

class _ProfileScreenState extends State<ProfileScreen>
    implements ErrorHandlingCapable {
  Map<String, dynamic> _profileData = {};
  bool _isLoading = true;
  String _errorMessage = '';
  String _fullName = '';

  // Added to prevent memory leaks
  bool _mounted = true;

  @override
  String? get errorMessage => _errorMessage.isEmpty ? null : _errorMessage;

  @override
  void clearError() {
    if (_errorMessage.isNotEmpty && _mounted) {
      setState(() {
        _errorMessage = '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to avoid calling setState during build
    Future.microtask(() => _loadProfile());
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!_mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Add timeout to prevent app hanging
      final response = await ApiService.get('/users/profile', context: context)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Koneksi timeout. Silakan coba lagi nanti.');
      });

      if (!_mounted) return;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == true) {
          final employee = responseData['data']['employee'] ?? {};
          final firstName = employee['first_name'] ?? '';
          final lastName = employee['last_name'] ?? '';

          if (_mounted) {
            setState(() {
              _profileData = responseData['data'];
              _fullName = '$firstName $lastName'.trim();
              _isLoading = false;
            });
          }
        } else {
          throw Exception(responseData['message'] ?? 'Gagal memuat profil');
        }
      } else {
        throw Exception('Gagal memuat profil: ${response.statusCode}');
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    if (!_mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              // Show loading indicator
              if (_mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              try {
                await ApiService.logout(context);
                // No need to navigate here as it's handled in ApiService.logout
              } catch (e) {
                // If there's an error, still close loading dialog
                if (_mounted && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }

                // Show error message
                if (_mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Kesalahan saat keluar: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: const Color(0xFF213268),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Stack(
        children: [
          // Main content area (empty or grayed out when error occurs)
          const Center(
            child: Text(
              'Tidak dapat memuat profil',
              style: TextStyle(color: Colors.grey),
            ),
          ),

          // Error notification at the top of the screen
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.red.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Kesalahan: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),

          // Retry button
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Coba Lagi'),
              ),
            ),
          ),
        ],
      );
    }

    // Extract this data once to avoid repeated lookups
    final employee = _profileData['employee'] ?? {};
    final firstName = employee['first_name'] ?? '';
    final lastName = employee['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = _profileData['email'] ?? '';
    final phone = employee['phone'] ?? '-';

    // Use Builder to improve performance
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF213268),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 32),

          // Nama Field
          const Text(
            'Nama',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            child: TextFormField(
              initialValue: fullName,
              readOnly: true,
              enabled: false,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.grey[200],
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
              ),
            ),
          ),

          // Email Field
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            child: TextFormField(
              initialValue: email,
              readOnly: true,
              enabled: false,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.grey[200],
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
              ),
            ),
          ),

          // No. Telepon Field - If displayed, make it read-only too
          const Text(
            'No. Telepon',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 24),
            child: TextFormField(
              initialValue: phone,
              readOnly: true,
              enabled: false,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.grey[200],
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
              ),
            ),
          ),

          // Add additional profile information
          const SizedBox(height: 16),
          _buildProfileCard(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    // Extract once to avoid repeated lookups
    final employee = _profileData['employee'] ?? {};
    final role = _profileData['role'] ?? {};
    final userId = _profileData['user_id']?.toString() ?? '-';
    final employeeId = employee['employee_id']?.toString() ?? '-';
    final position = employee['position'] ?? '-';
    final roleName = role['role_name'] ?? '-';
    final isActive =
        _profileData['is_active'] == true ? 'Aktif' : 'Tidak Aktif';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileItem('ID Pengguna', userId),
            _buildProfileItem('ID Karyawan', employeeId),
            _buildProfileItem('Posisi', position),
            _buildProfileItem('Peran', roleName),
            _buildProfileItem('Status', isActive),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
