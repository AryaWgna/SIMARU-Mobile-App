import 'package:flutter/material.dart';
import '../../../controllers/auth_controller.dart';
import '../../widgets/custom_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    // Use Future.microtask for better performance
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
      final profile = await ApiService.getProfile(context)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Connection timeout. Please try again later.');
      });

      // Extract first_name and last_name from employee data if available
      String fullName = '';
      if (profile.containsKey('employee') && profile['employee'] != null) {
        final employee = profile['employee'];
        final firstName = employee['first_name'] ?? '';
        final lastName = employee['last_name'] ?? '';
        fullName = '$firstName $lastName'.trim();
      } else {
        // Fallback to name field or empty string
        fullName = profile['name'] ?? '';
      }

      if (_mounted) {
        setState(() {
          _profile = profile;
          // Add the full name to the profile object for easy access
          _profile!['fullName'] = fullName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    if (!_mounted) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Ya, Keluar',
              style: TextStyle(color: Color(0xFF203268)),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Tampilkan loading indicator
      if (_mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
      }

      try {
        // Gunakan context pada fungsi logout yang sudah diperbarui
        await ApiService.logout(context);
        // Tutup dialog loading
        if (_mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        // Navigasi ke login screen
        if (_mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } catch (e) {
        // Tutup dialog loading
        if (_mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        if (_mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
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
        actions: [
          // Add refresh button in AppBar
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: const Color(0xFF213268),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 440,
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Profile Image with person icon
                      Container(
                        width: 150,
                        height: 150,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF213268),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Form Contact - Read-only fields
                      _buildFormContainer([
                        _buildReadOnlyField('Nama', _profile?['fullName'] ?? ''),
                        _buildReadOnlyField('Email', _profile?['email'] ?? ''),
                        _buildReadOnlyField(
                            'No. Telepon', _profile?['phone'] ?? ''),
                        // UPDATE button removed
                      ]),

                      const SizedBox(height: 24),

                      // Reset Password section removed

                      // Logout Form
                      _buildFormContainer([
                        _buildButton(
                          'Keluar',
                          onPressed: _logout,
                          color: const Color(0xFFFF0004),
                          icon: Icons.logout,
                        ),
                      ]),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFormContainer(List<Widget> children) {
    return Container(
      width: 415,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF213268),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[400]!),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    String text, {
    required VoidCallback onPressed,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
