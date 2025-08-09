import 'package:flutter/material.dart';
import '../../controllers/profile/profile_controller.dart';
import '../../controllers/dashboard/dashboard_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../auth/login.dart';
import '../../utils/logger_util.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../dashboard/dashboard.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    final profileController =
        Provider.of<ProfileController>(context, listen: false);
    Future.microtask(() => profileController.loadUserData(context));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    LoggerUtil.d("Returned to ProfileScreen");

    final dashboardController =
        Provider.of<DashboardController>(context, listen: false);
    if (dashboardController.selectedIndex != 4) {
      dashboardController.setSelectedIndex(4);
    }

    final profileController =
        Provider.of<ProfileController>(context, listen: false);
    profileController.loadUserData(context);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final profileController =
        Provider.of<ProfileController>(context, listen: false);
    await profileController.loadUserData(context);

    if (profileController.errorMessage != null) {
      _refreshController.refreshFailed();
    } else {
      _refreshController.refreshCompleted();
    }
  }

  Future<void> _logout(ProfileController controller) async {
    if (!mounted) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 1.5),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Konfirmasi Logout',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF213268),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari aplikasi?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF213268),
                      side: const BorderSide(color: Color(0xFF213268)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Ya, Keluar',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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

    if (shouldLogout == true) {
      try {
        final success = await controller.logout(context);

        if (mounted && success) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                controller.errorMessage ?? 'Gagal logout',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: $e',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildSkeletonProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 32),
          _buildSkeletonField(label: 'Nama Karyawan'),
          _buildSkeletonField(label: 'Nomor Karyawan'),
          _buildSkeletonField(label: 'Role'),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonField({required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SmartRefresher(
            enablePullDown: true,
            enablePullUp: false,
            controller: _refreshController,
            onRefresh: _onRefresh,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            header: const WaterDropMaterialHeader(
              backgroundColor: Colors.white,
              color: Color(0xFF213268),
              distance: 40.0,
            ),
            child: controller.isLoading
                ? Skeletonizer(
                    enabled: true,
                    containersColor: Colors.grey.shade300,
                    effect: ShimmerEffect(
                      baseColor: Colors.grey.shade300,
                      highlightColor: const Color(0xFFE5EFFF),
                    ),
                    child: _buildSkeletonProfile(),
                  )
                : controller.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: ${controller.errorMessage}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => controller.loadUserData(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF213268),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Coba Lagi',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
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
                              _buildProfileField(
                                label: 'Nama Karyawan',
                                value:
                                    controller.profile?['employee_name'] ?? '',
                              ),
                              _buildProfileField(
                                label: 'Nomor Karyawan',
                                value: controller.profile?['employee_number'] ??
                                    '',
                              ),
                              _buildProfileField(
                                label: 'Peran',
                                value: _getRoleNameFromRoles(
                                    controller.profile?['roles']),
                              ),
                              const SizedBox(height: 24),
                              // SizedBox(
                              //   width: double.infinity,
                              //   child: ElevatedButton.icon(
                              //     onPressed: () {
                              //       Navigator.push(
                              //         context,
                              //         MaterialPageRoute(
                              //           builder: (context) =>
                              //               const WebViewScreen(
                              //             initialUrl:
                              //                 'https://web-magangunbin2025.rsummi.co.id/',
                              //             title: 'Web Portal SIMARU',
                              //           ),
                              //         ),
                              //       );
                              //     },
                              //     icon: const Icon(Icons.web),
                              //     label: Text(
                              //       'Buka Web Portal',
                              //       style: GoogleFonts.poppins(
                              //         fontSize: 16,
                              //         fontWeight: FontWeight.bold,
                              //         color: Colors.white,
                              //       ),
                              //     ),
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: const Color(0xFF213268),
                              //       foregroundColor: Colors.white,
                              //       padding: const EdgeInsets.symmetric(
                              //           vertical: 16),
                              //       shape: RoundedRectangleBorder(
                              //         borderRadius: BorderRadius.circular(8),
                              //       ),
                              //       elevation: 2,
                              //     ),
                              //   ),
                              // ),
                              // const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _logout(controller),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    'Logout',
                                    style: GoogleFonts.poppins(
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
          ),
        );
      },
    );
  }

  Widget _buildProfileField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  String _getInitials() {
    final employeeNumber =
        Provider.of<ProfileController>(context, listen: false)
                .profile?['employee_number'] ??
            '';
    if (employeeNumber.isEmpty) return '?';

    if (employeeNumber.length >= 2) {
      return employeeNumber.substring(0, 2).toUpperCase();
    } else {
      return employeeNumber.toUpperCase();
    }
  }

  String _getRoleNameFromRoles(dynamic roles) {
    if (roles == null || (roles is List && roles.isEmpty)) {
      return 'Unknown';
    }

    try {
      if (roles is List && roles.isNotEmpty) {
        final firstRole = roles[0];
        return firstRole['role_name'] ?? 'Unknown';
      }
    } catch (e) {
      LoggerUtil.e('Error extracting role name', e);
    }

    return 'Unknown';
  }
}
