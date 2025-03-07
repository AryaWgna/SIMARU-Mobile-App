import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../controllers/auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Navbar
          Container(
            width: double.infinity,
            height: 82,
            decoration: const BoxDecoration(
              color: Color(0xFF213268),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF56C5F1),
                  blurRadius: 7.3,
                  offset: Offset(0, 3),
                  spreadRadius: 3,
                ),
              ],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Center(
              child: Image.asset(
                'images/Logo_RS_UMMI_white.png',
                width: 208.14,
                height: 55,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Error loading image');
                },
              ),
            ),
          ),

          // Profile Content
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: 440,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Profile Image
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF213268),
                        image: _profile?['image'] != null
                            ? DecorationImage(
                                image: NetworkImage(_profile!['image']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profile?['image'] == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Form Contact
                    _buildFormContainer([
                      _buildInputField('Nama', _profile?['name'] ?? ''),
                      _buildInputField('Email', _profile?['email'] ?? ''),
                      _buildInputField('No. Telepon', _profile?['phone'] ?? ''),
                      _buildButton('UPDATE',
                          onPressed: () {}, color: const Color(0xFF213268)),
                    ]),

                    const SizedBox(height: 24),

                    // Reset Password Text
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        color: Color(0xFF213268),
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Password Form
                    _buildFormContainer([
                      _buildInputField('Password Lama', '', isPassword: true),
                      _buildInputField('Password Baru', '', isPassword: true),
                      _buildButton('Ubah Password',
                          onPressed: () {}, color: const Color(0xFF213268)),
                    ]),

                    const SizedBox(height: 24),

                    // Logout Form
                    _buildFormContainer([
                      _buildButton(
                        'Logout',
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
        ],
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildInputField(String label, String value, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            height: 1.4, // line-height: 140%
            color: Color(0xFF1E1E1E),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD9D9D9)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            obscureText: isPassword,
            style: const TextStyle(
              fontSize: 16,
              height: 1.0, // line-height: 100%
              color: Color(0xFF1E1E1E),
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: InputBorder.none,
              hintText: value,
              hintStyle: const TextStyle(
                color: Color(0xFF1E1E1E),
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildButton(
    String text, {
    required VoidCallback onPressed,
    required Color color,
    IconData? icon,
  }) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.0,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

