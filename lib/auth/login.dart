import 'dart:ui';
import 'package:flutter/material.dart';
import '../controllers/auth/auth_controller.dart';
import '../views/dashboard/dashboard.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../services/firebase/firebase_messaging_service.dart';
import 'package:provider/provider.dart';
// Import untuk mengatasi masalah anti-screenshot
import 'dart:io';
import 'package:no_screenshot/no_screenshot.dart';
import '../utils/logger_util.dart'; // Import LoggerUtil

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _checkingToken = true;
  final NoScreenshot _noScreenshot = NoScreenshot();

  @override
  void initState() {
    super.initState();

    // Pastikan fitur anti-screenshot dinonaktifkan di login screen
    _disableAnyActiveScreenshotProtection();

    // Check if user is already logged in with valid token
    _checkExistingToken();
  }

  // Method untuk menonaktifkan fitur anti-screenshot yang mungkin masih aktif
  Future<void> _disableAnyActiveScreenshotProtection() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        LoggerUtil.i("LoginScreen: Memastikan anti-screenshot dinonaktifkan");
        await _noScreenshot.screenshotOn();
        LoggerUtil.i("LoginScreen: Anti-screenshot berhasil dinonaktifkan");
      }
    } catch (e) {
      LoggerUtil.e("LoginScreen: Error saat menonaktifkan anti-screenshot", e,
          StackTrace.current);
    }
  }

  Future<void> _checkExistingToken() async {
    setState(() => _checkingToken = true);

    try {
      LoggerUtil.d("Checking for existing login token...");
      // Check if user is already logged in
      final isLoggedIn = await ApiService.isLoggedIn();

      if (isLoggedIn && mounted) {
        LoggerUtil.d("Token found, verifying if it's still valid...");
        // Try to silently refresh the token to ensure it's still valid
        final refreshSuccess = await ApiService.refreshToken();

        if (refreshSuccess && mounted) {
          LoggerUtil.i(
              "Valid token found, navigating to dashboard automatically");

          // Set navigation callback for when token expires
          ApiService.navigateToLogin = (BuildContext ctx) {
            LoggerUtil.i(
                "Auto-redirecting to login screen due to expired session");
            Navigator.of(ctx).pushAndRemoveUntil(
              MaterialPageRoute(builder: (c) => const LoginScreen()),
              (route) => false,
            );
          };

          // Try to fetch user profile to ensure token is valid
          try {
            LoggerUtil.d("Fetching user profile to verify token validity");
            await ApiService.getProfile(context);
            LoggerUtil.i("Profile fetched successfully, token is valid");
          } catch (e) {
            LoggerUtil.e("Error fetching profile", e, StackTrace.current);
            // If profile fetch fails due to token issues, clear stored credentials
            if (e.toString().contains("401") ||
                (e is ApiException &&
                    (e.statusCode == 401 || e.code == 'SESSION_EXPIRED'))) {
              LoggerUtil.w("Token appears to be invalid, logging out");
              await ApiService.logout(context);
              setState(() => _checkingToken = false);
              return;
            }
            // Otherwise continue with auto-login despite profile fetch error
          }

          // Navigate to dashboard if token is valid
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const DashboardScreen(),
            ),
            (route) => false,
          );
        } else {
          LoggerUtil.w("Token refresh failed, staying on login screen");
          // Token refresh failed, clear any stored credentials
          await ApiService.logout(context);
        }
      } else {
        LoggerUtil.i("No valid login session found");
      }
    } catch (e) {
      LoggerUtil.e("Error checking token", e, StackTrace.current);
      // If there's an error, keep the user on the login page
    } finally {
      if (mounted) {
        setState(() => _checkingToken = false);
      }
    }
  }

  // Fungsi untuk logging error di terminal
  void _logError(dynamic error, StackTrace stackTrace) {
    LoggerUtil.e('====== ERROR LOGIN ======', error, stackTrace);

    LoggerUtil.e('--- Detail Error ---');

    if (error is ApiException) {
      LoggerUtil.e('Type: ApiException');
      LoggerUtil.e('Message: ${error.message}');
      LoggerUtil.e('Code: ${error.code ?? "null"}');
      LoggerUtil.e('Status Code: ${error.statusCode ?? "null"}');
      LoggerUtil.e('Details: ${error.details ?? "null"}');
    } else {
      LoggerUtil.e('Type: ${error.runtimeType}');
      LoggerUtil.e('Message: $error');
    }

    LoggerUtil.e('--- Stack Trace ---');

    // Format stack trace for better readability
    final formattedStackTrace = stackTrace
        .toString()
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(10) // Ambil 10 baris pertama saja
        .join('\n');

    LoggerUtil.e(formattedStackTrace);
    LoggerUtil.e('=======================');
  }

  Future<void> _login() async {
    // Validasi dasar
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Nomor karyawan dan password tidak boleh kosong';
      });
      return;
    }

    // Reset pesan error
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      LoggerUtil.d("Attempting login with: ${_emailController.text}");
      await ApiService.login(
        _emailController.text,
        _passwordController.text,
      );

      LoggerUtil.i("Login successful, navigating to dashboard");

      if (mounted) {
        // Set navigasi untuk auto login saat token expired
        ApiService.navigateToLogin = (BuildContext ctx) {
          Navigator.of(ctx).pushAndRemoveUntil(
            MaterialPageRoute(builder: (c) => const LoginScreen()),
            (route) => false,
          );
        };

        // Ambil profil pengguna setelah login berhasil
        try {
          LoggerUtil.d("Fetching user profile after successful login");
          await ApiService.getProfile(context);
          LoggerUtil.i("Profile fetched successfully");
        } catch (e) {
          LoggerUtil.e("Error fetching profile", e, StackTrace.current);
          // Lanjutkan proses meskipun gagal mengambil profil
        }

        // Send FCM token to server after successful login
        try {
          LoggerUtil.d("Preparing to send FCM token to server...");
          final firebaseMessagingService =
              Provider.of<FirebaseMessagingService>(context, listen: false);
          LoggerUtil.i("FirebaseMessagingService provider obtained");

          // Get auth token from ApiService
          final authToken = await ApiService.getAuthToken();
          LoggerUtil.i("Auth token obtained: ${authToken != null}");

          if (authToken != null) {
            LoggerUtil.d("Attempting to send FCM token to server...");
            await firebaseMessagingService.sendFcmTokenToServer(authToken);
            LoggerUtil.i("FCM token send attempt completed");
          } else {
            LoggerUtil.i("Auth token is null, cannot send FCM token");
          }
        } catch (e, stack) {
          LoggerUtil.e("Error sending FCM token", e, stack);
          // Don't let FCM token error stop the login flow
        }

        // Navigasi ke dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(initialIndex: 0),
          ),
          (route) => false,
        );
      }
    } catch (e, stackTrace) {
      LoggerUtil.e("Login error", e, stackTrace);
      _logError(e, stackTrace);

      if (mounted) {
        late String errorMsg;

        if (e is ApiException) {
          errorMsg = e.message;
          LoggerUtil.i("Api Exception message: ${e.message}");
          LoggerUtil.i("Full ApiException: ${e.toString()}");
        } else {
          errorMsg = 'Terjadi kesalahan: ${e.toString()}';
          LoggerUtil.i("Generic error: ${e.toString()}");
        }

        // Set error message
        setState(() {
          _errorMessage = errorMsg;
        });

        LoggerUtil.i("Error message is now: $_errorMessage");

        // Snackbar dihapus sesuai permintaan
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // Tampilkan halaman login langsung, tanpa loading spinner saat mengecek token
    return Scaffold(
      backgroundColor: Colors.white,
      // Prevent resizing which can cause jarring UI shifts
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            height: screenSize.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background elements
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                ),
                // Keep decorative circles visible even when keyboard appears
                _buildBlurCircle(-50, 100, 200, const Color(0xFFACC3EF)),
                _buildBlurCircle(
                    screenSize.width - 150, 250, 150, const Color(0xFF7CE1FF)),
                _buildBlurCircle(
                    screenSize.width - 180, -10, 180, const Color(0xFF25B1FF)),
                _buildBlurCircle(
                    -60, screenSize.height - 200, 250, const Color(0xFF203268)),

                // Content container with smooth animation for keyboard appearance
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuad,
                  top: keyboardVisible ? 30 : 96,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // Logo with adaptive size
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: keyboardVisible ? 220 : 313,
                        height: keyboardVisible ? 58 : 82,
                        child: Hero(
                          tag: 'logo',
                          child: Image.asset(
                            'images/Logo_RS_UMMI.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // Login form with adaptive positioning
                      AnimatedPadding(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.only(
                          top: keyboardVisible ? 20 : screenSize.height * 0.15,
                          left: 20,
                          right: 20,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(38),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 6.5,
                                offset: const Offset(0, 11),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Welcome text with adaptive visibility
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: keyboardVisible ? 0 : 1,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: keyboardVisible ? 0 : null,
                                  child: keyboardVisible
                                      ? const SizedBox.shrink()
                                      : TweenAnimationBuilder(
                                          duration:
                                              const Duration(milliseconds: 500),
                                          tween:
                                              Tween<double>(begin: 0, end: 1),
                                          builder:
                                              (context, double value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Transform.translate(
                                                offset:
                                                    Offset(0, 20 * (1 - value)),
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: const Column(
                                            children: [
                                              Text(
                                                'Selamat Datang,',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF203268),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                'Silakan Masuk Terlebih Dahulu!',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF203268),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: 20),
                                            ],
                                          ),
                                        ),
                                ),
                              ),

                              // Error container
                              _buildErrorContainer(),

                              // Login form fields
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      controller: _emailController,
                                      label: 'Nomor Karyawan',
                                      hint: 'Masukkan Nomor Karyawan Anda',
                                      icon: Icons.person_outline,
                                      keyboardType: TextInputType.text,
                                      onChanged: (_) {
                                        if (_errorMessage != null) {
                                          setState(() => _errorMessage = null);
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 15),
                                    _buildTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      hint: 'Masukkan Password Anda',
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      obscureText: _obscurePassword,
                                      toggleObscureText: () {
                                        setState(() => _obscurePassword =
                                            !_obscurePassword);
                                      },
                                      onChanged: (_) {
                                        if (_errorMessage != null) {
                                          setState(() => _errorMessage = null);
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      height: 45,
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF203268),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          elevation: _isLoading ? 0 : 2,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text(
                                                'Masuk',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    VoidCallback? toggleObscureText,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF203268),
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: isPassword && obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF203268)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF203268),
                    ),
                    onPressed: toggleObscureText,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF203268)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: const Color(0xFF203268).withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF203268), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // Widget error message yang lebih interaktif
  Widget _buildErrorContainer() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -10 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gagal Masuk',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                      fontSize: 16,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _errorMessage = null),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: Colors.red[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tombol bantuan
                TextButton.icon(
                  onPressed: () {
                    // Tampilkan dialog bantuan
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Bantuan'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Beberapa tips untuk masalah login:'),
                            const SizedBox(height: 8),
                            Text(
                                '• Pastikan nomor karyawan dan password benar'),
                            Text('• Periksa koneksi internet Anda'),
                            Text('• Hubungi admin jika masalah berlanjut'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Tutup'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.help_outline,
                      size: 16, color: Colors.red[700]),
                  label:
                      Text('Bantuan', style: TextStyle(color: Colors.red[700])),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol coba lagi
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      // Fokus pada field password
                      _passwordController.clear();
                      FocusScope.of(context).requestFocus(FocusNode());
                    });
                  },
                  icon: Icon(Icons.refresh, size: 16, color: Colors.red[700]),
                  label: Text('Coba Lagi',
                      style: TextStyle(color: Colors.red[700])),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
