import 'dart:ui';
import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../views/dashboard/dashboard.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../services/firebase_messaging_service.dart';
import 'package:provider/provider.dart';
// Import untuk mengatasi masalah anti-screenshot
import 'dart:io';
import 'package:no_screenshot/no_screenshot.dart';

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
        print("LoginScreen: Memastikan anti-screenshot dinonaktifkan");
        await _noScreenshot.screenshotOn();
        print("LoginScreen: Anti-screenshot berhasil dinonaktifkan");
      }
    } catch (e) {
      print("LoginScreen: Error saat menonaktifkan anti-screenshot: $e");
    }
  }

  Future<void> _checkExistingToken() async {
    setState(() => _checkingToken = true);

    try {
      // Cek apakah user sudah login dengan timeout yang lebih pendek
      final isLoggedIn = await ApiService.isLoggedIn();

      if (isLoggedIn && mounted) {
        // Coba refresh token secara silent untuk memastikan masih valid
        final refreshSuccess = await ApiService.refreshToken();

        if (refreshSuccess && mounted) {
          print("Valid token found, navigating to dashboard automatically");

          // Set navigasi untuk auto login saat token expired
          ApiService.navigateToLogin = (BuildContext ctx) {
            Navigator.of(ctx).pushAndRemoveUntil(
              MaterialPageRoute(builder: (c) => const LoginScreen()),
              (route) => false,
            );
          };

          // Navigasi ke dashboard jika token valid
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const DashboardScreen(),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print("Error checking token: $e");
      // Jika ada error, biarkan user tetap di halaman login
    } finally {
      if (mounted) {
        setState(() => _checkingToken = false);
      }
    }
  }

  // Fungsi untuk logging error di terminal
  void _logError(dynamic error, StackTrace stackTrace) {
    developer.log(
      '====== ERROR LOGIN ======',
      name: 'LOGIN_ERROR',
      error: error,
    );

    developer.log(
      '--- Detail Error ---',
      name: 'LOGIN_ERROR',
    );

    if (error is ApiException) {
      developer.log(
        'Type: ApiException',
        name: 'LOGIN_ERROR',
      );
      developer.log(
        'Message: ${error.message}',
        name: 'LOGIN_ERROR',
      );
      developer.log(
        'Code: ${error.code ?? "null"}',
        name: 'LOGIN_ERROR',
      );
      developer.log(
        'Status Code: ${error.statusCode ?? "null"}',
        name: 'LOGIN_ERROR',
      );
      developer.log(
        'Details: ${error.details ?? "null"}',
        name: 'LOGIN_ERROR',
      );
    } else {
      developer.log(
        'Type: ${error.runtimeType}',
        name: 'LOGIN_ERROR',
      );
      developer.log(
        'Message: $error',
        name: 'LOGIN_ERROR',
      );
    }

    developer.log(
      '--- Stack Trace ---',
      name: 'LOGIN_ERROR',
    );

    // Format stack trace for better readability
    final formattedStackTrace = stackTrace
        .toString()
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(10) // Ambil 10 baris pertama saja
        .join('\n');

    developer.log(
      formattedStackTrace,
      name: 'LOGIN_ERROR',
    );

    developer.log(
      '=======================',
      name: 'LOGIN_ERROR',
    );
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
      print("Attempting login with: ${_emailController.text}");
      await ApiService.login(
        _emailController.text,
        _passwordController.text,
      );

      print("Login successful, navigating to dashboard");

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
          print("Fetching user profile after successful login");
          await ApiService.getProfile(context);
          print("Profile fetched successfully");
        } catch (e) {
          print("Error fetching profile: $e");
          // Lanjutkan proses meskipun gagal mengambil profil
        }

        // Send FCM token to server after successful login
        try {
          print("Preparing to send FCM token to server...");
          final firebaseMessagingService =
              Provider.of<FirebaseMessagingService>(context, listen: false);
          print("FirebaseMessagingService provider obtained");

          // Get auth token from ApiService
          final authToken = await ApiService.getAuthToken();
          print("Auth token obtained: ${authToken != null}");

          if (authToken != null) {
            print("Attempting to send FCM token to server...");
            await firebaseMessagingService.sendFcmTokenToServer(authToken);
            print("FCM token send attempt completed");
          } else {
            print("Auth token is null, cannot send FCM token");
          }
        } catch (e, stack) {
          print("Error sending FCM token: $e");
          print("Stack trace: $stack");
          // Don't let FCM token error stop the login flow
        }

        // Navigasi ke dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e, stackTrace) {
      print("Login error: $e");
      _logError(e, stackTrace);

      if (mounted) {
        late String errorMsg;

        if (e is ApiException) {
          errorMsg = e.message;
          print("Api Exception message: ${e.message}");
          print("Full ApiException: ${e.toString()}");
        } else {
          errorMsg = 'Terjadi kesalahan: ${e.toString()}';
          print("Generic error: ${e.toString()}");
        }

        // Set error message
        setState(() {
          _errorMessage = errorMsg;
        });

        print("Error message is now: $_errorMessage");

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

    // Tampilkan halaman login langsung, tanpa loading spinner saat mengecek token
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.white,
              ),
            ),
          ),
          _buildBlurCircle(-50, 100, 200, const Color(0xFFACC3EF)),
          _buildBlurCircle(
              screenSize.width - 150, 250, 150, const Color(0xFF7CE1FF)),
          _buildBlurCircle(
              screenSize.width - 180, -10, 180, const Color(0xFF25B1FF)),
          _buildBlurCircle(
              -60, screenSize.height - 200, 250, const Color(0xFF203268)),
          Positioned(
            top: 96,
            left: screenSize.width / 2 - 156.5,
            child: Hero(
              tag: 'logo',
              child: Image.asset(
                'images/Logo_RS_UMMI.png',
                width: 313,
                height: 82,
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: screenSize.height * 0.3,
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
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 500),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Ganti container error dengan widget error yang lebih interaktif
                  _buildErrorContainer(),
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
                            setState(
                                () => _obscurePassword = !_obscurePassword);
                          },
                          onChanged: (_) {
                            if (_errorMessage != null) {
                              setState(() => _errorMessage = null);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 45,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF203268),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: _isLoading ? 0 : 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
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
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
