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

  @override
  void initState() {
    super.initState();
    // Menunda pemanggilan _loadProfile hingga widget sepenuhnya diinisialisasi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getProfile(context);

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

      setState(() {
        _profile = profile;
        // Add the full name to the profile object for easy access
        _profile!['fullName'] = fullName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      try {
        // Gunakan context pada fungsi logout yang sudah diperbarui
        await ApiService.logout(context);
        // Tutup dialog loading
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        // Navigasi ke login screen
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } catch (e) {
        // Tutup dialog loading
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
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
    // Calculate the initials from the full name
    String initials = '';
    if (_profile != null && (_profile!['fullName'] ?? '').isNotEmpty) {
      final fullName = _profile!['fullName'] as String;
      final nameParts = fullName.split(' ');

      // Get first letter of first name
      if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
        initials += nameParts[0][0].toUpperCase();
      }

      // Get first letter of last name (if exists)
      if (nameParts.length > 1 && nameParts[nameParts.length - 1].isNotEmpty) {
        initials += nameParts[nameParts.length - 1][0].toUpperCase();
      }

      // Fallback if we couldn't get two initials
      if (initials.isEmpty) {
        initials = fullName[0].toUpperCase();
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                width: 440,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Profile Image with initials
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
                          ? Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Form Contact
                    _buildFormContainer([
                      _buildInputField('Nama', _profile?['fullName'] ?? ''),
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

  Widget _buildInputField(String label, String value,
      {bool isPassword = false}) {
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
