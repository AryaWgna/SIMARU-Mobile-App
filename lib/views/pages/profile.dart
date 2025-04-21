import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _mounted = true;
  String _userId = "1"; // Default user ID

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadUserData());
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!_mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print("Fetching user data for ID: $_userId...");
      final userData = await ApiService.getUserById(_userId, context);
      print("User data received: $userData");

      if (_mounted) {
        setState(() {
          _profile = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
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
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Ya, Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Show loading indicator
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
        await ApiService.logout(context);
        if (_mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        if (_mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } catch (e) {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Profile Picture
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4D4D4D),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Name Field
                    _buildProfileField(
                      label: 'Name',
                      value: _profile?['employee_number'] ?? '',
                    ),

                    // Phone Number Field
                    _buildProfileField(
                      label: 'Phone Number',
                      value: '123456789',
                    ),

                    const SizedBox(height: 24),

                    // Logout Button (previously Update button)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getInitials() {
    final employeeNumber = _profile?['employee_number'] ?? '';
    if (employeeNumber.isEmpty) return '?';

    if (employeeNumber.length >= 2) {
      return employeeNumber.substring(0, 2).toUpperCase();
    } else {
      return employeeNumber.toUpperCase();
    }
  }
}
