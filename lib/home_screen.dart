import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _logout() async {
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
      try {
        await ApiService.logout();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background blur circles
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.white),
            ),
          ),
          _buildBlurCircle(-50, 100, 200, const Color(0xFFACC3EF)),
          _buildBlurCircle(
              screenSize.width - 150, 250, 150, const Color(0xFF7CE1FF)),
          _buildBlurCircle(
              screenSize.width - 180, -10, 180, const Color(0xFF25B1FF)),
          _buildBlurCircle(
              -60, screenSize.height - 200, 250, const Color(0xFF203268)),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF203268),
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.logout, color: Color(0xFF203268)),
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF203268)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(38),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 6.5,
                                  offset: const Offset(0, 11),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: const Color(0xFF203268),
                                  backgroundImage: _profile?['image'] != null
                                      ? NetworkImage(_profile!['image'])
                                      : null,
                                  child: _profile?['image'] == null
                                      ? const Icon(Icons.person,
                                          size: 50, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _profile?['name'] ?? 'Nama tidak tersedia',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF203268),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildProfileItem(Icons.email, 'Email',
                                    _profile?['email'] ?? '-'),
                                _buildProfileItem(Icons.phone, 'Phone',
                                    _profile?['phone'] ?? '-'),
                                _buildProfileItem(Icons.work, 'Position',
                                    _profile?['position'] ?? '-'),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF203268).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF203268)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF203268).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF203268),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurCircle(double left, double top, double size, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.6),
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }
}
