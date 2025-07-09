import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../core/config/api_config.dart';
import 'complain_detail_screen.dart';
import '../../controllers/complaint/complaint_controller.dart';
import '../../controllers/dashboard/dashboard_controller.dart';
import '../../models/complaint/complaint_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../../controllers/auth/auth_controller.dart';
import '../../utils/logger_util.dart';
import '../dashboard/dashboard.dart';

class ComplainListScreen extends StatefulWidget {
  const ComplainListScreen({super.key});

  @override
  State<ComplainListScreen> createState() => _ComplainListScreenState();
}

class _ComplainListScreenState extends State<ComplainListScreen>
    with RouteAware {
  final _storage = const FlutterSecureStorage();
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  late ComplaintController _complaintController;
  String? _employeeNumber;

  @override
  void initState() {
    super.initState();
    _complaintController =
        Provider.of<ComplaintController>(context, listen: false);
    _loadComplaints();
    _loadEmployeeNumber();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route observer
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // This is called when the user returns to this screen
    LoggerUtil.d("Returned to ComplainListScreen");

    final dashboardController =
        Provider.of<DashboardController>(context, listen: false);
    // Make sure we're on the complain tab when returning to this screen
    if (dashboardController.selectedIndex != 3) {
      dashboardController.setSelectedIndex(3);
    }

    // Refresh data
    _loadComplaints();
  }

  Future<void> _loadEmployeeNumber() async {
    final employeeNumber = await ApiService.getEmployeeNumber();
    if (mounted) {
      setState(() {
        _employeeNumber = employeeNumber;
      });
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    try {
      if (mounted) {
        // Set loading state directly before fetch
        setState(() {
          _complaintController.setLoading(true);
        });
      }

      await _complaintController.fetchComplaints();

      if (_refreshController.isRefresh) {
        if (_complaintController.hasError) {
          _refreshController.refreshFailed();
        } else {
          _refreshController.refreshCompleted();
        }
      }

      // Ensure loading state is set to false after fetch completes
      if (mounted) {
        setState(() {
          _complaintController.setLoading(false);
        });
      }
    } catch (e) {
      // Handle any exceptions and ensure loading state is reset
      if (mounted) {
        setState(() {
          _complaintController.setLoading(false);
        });
      }
      LoggerUtil.e('Error loading complaints in UI', e, StackTrace.current);
    }
  }

  Future<void> _onRefresh() async {
    await _loadComplaints();
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    try {
      return '${dateTime.day.toString().padLeft(2, '0')} March ${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error formatting date: $e');
      return '';
    }
  }

  Widget _buildStatusBadge(String status, ComplaintModel complaint) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    // Mengadaptasi logika status dari kode Laravel
    switch (status.toLowerCase()) {
      case 'new':
        backgroundColor = const Color(0xFFFEF9C3); // bg-yellow-100
        textColor = const Color(0xFF854D0E); // text-yellow-800
        statusText = 'Baru';
        break;
      case 'in progress':
        backgroundColor = const Color(0xFFDDEDFE); // bg-blue-100
        textColor = const Color(0xFF1E429F); // text-blue-800
        statusText = 'Sedang Diproses';
        break;
      case 'finished':
        backgroundColor = const Color(0xFFD1FAE5); // bg-emerald-100
        textColor = const Color(0xFF065F46); // text-emerald-800
        statusText = 'Selesai';
        break;
      case 'approved':
        backgroundColor = const Color(0xFFDCFCE7); // bg-green-100
        textColor = const Color(0xFF166534); // text-green-800
        statusText = 'Disetujui';
        break;
      case 'pending':
        backgroundColor = const Color(0xFFFEF9C3); // Similar to 'new' (yellow)
        textColor = const Color(0xFF854D0E);
        statusText = 'Tertunda';
        break;
      case 'rejected':
        backgroundColor = const Color(0xFFFEE2E2); // bg-red-100
        textColor = const Color(0xFFB91C1C); // text-red-800
        statusText = 'Ditolak';
        break;
      default:
        backgroundColor = const Color(0xFFF3F4F6); // bg-gray-100
        textColor = const Color(0xFF1F2937); // text-gray-800
        statusText = 'Tidak Diketahui';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<ComplaintController>(
        builder: (context, controller, _) {
          return SmartRefresher(
            enablePullDown: true,
            enablePullUp: false,
            controller: _refreshController,
            onRefresh: _onRefresh,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            footer: ClassicFooter(
              loadStyle: LoadStyle.ShowWhenLoading,
              completeDuration: const Duration(milliseconds: 500),
            ),
            header: const WaterDropMaterialHeader(
              backgroundColor: Colors.white,
              color: Color(0xFF213268),
              distance: 40.0,
            ),
            child: (controller.isLoading)
                ? Skeletonizer(
                    enabled: true,
                    containersColor: Colors.grey.shade300,
                    effect: ShimmerEffect(
                      baseColor: Colors.grey.shade300,
                      highlightColor: const Color(0xFFE5EFFF),
                    ),
                    child: _buildSkeletonLayout(),
                  )
                : controller.hasError
                    ? _buildErrorView(controller)
                    : controller.complaints.isEmpty
                        ? _buildEmptyView()
                        : _buildComplaintsList(controller),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonLayout() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 160,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Skeleton items
        ...List.generate(
          5,
          (index) => Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFEBEEF5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 100,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEBEEF5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Container(
                                  width: 60,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEBEEF5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 80,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBEEF5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: 140,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBEEF5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBEEF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE5E9F2),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(ComplaintController controller) {
    return Center(
      key: const ValueKey('error'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Error: ${controller.errorMessage}',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadComplaints,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      key: const ValueKey('empty'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Tidak ada keluhan yang ditemukan'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadComplaints,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF213268),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsList(ComplaintController controller) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daftar Keluhan',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF213268),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total: ${controller.complaints.length} keluhan',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        ...controller.complaints.map((complaint) {
          return Card(
            elevation: 3,
            color: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (complaint.picturePath != null)
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _buildImageUrl(complaint.picturePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                print('Image path: ${complaint.picturePath}');
                                print(
                                    'Attempted URL: ${_buildImageUrl(complaint.picturePath)}');
                                return Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: Colors.grey[400],
                                    size: 40,
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatDate(complaint.reportDate),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                _buildStatusBadge(complaint.status, complaint),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pegawai: ${_employeeNumber ?? '-'}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Kode Aset:',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              complaint.assetCode,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nama Aset:',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              complaint.assetName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keluhan:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        complaint.description,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ComplainDetailScreen(
                          complaint: {
                            'id': complaint.id,
                            'asset_id': complaint.assetId,
                            'asset_code': complaint.assetCode,
                            'asset_name': complaint.assetName,
                            'description': complaint.description,
                            'status': complaint.status,
                            'complaint_picture_path': complaint.picturePath,
                            'reporter_name': complaint.reporterName,
                            'reporter_employee_number':
                                complaint.reporterEmployeeNumber,
                            'report_date':
                                complaint.reportDate.toIso8601String(),
                            'resolved_by': complaint.resolvedBy,
                            'resolved_date':
                                complaint.resolvedDate?.toIso8601String(),
                            'resolution': complaint.resolution,
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 45,
                    decoration: const BoxDecoration(
                      color: Color(0xFF213268),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Lihat Detail',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return '${ApiConfig.baseUrl}/public/images/placeholder.png';
    }

    // Jika path sudah berisi URL lengkap
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Jika path dimulai dengan /public/
    if (path.startsWith('/public/')) {
      return '${ApiConfig.baseUrl}$path';
    }

    // Jika path dimulai dengan /images/ atau images/
    if (path.startsWith('/images/') || path.startsWith('images/')) {
      String normalizedPath = path;
      if (path.startsWith('/')) {
        normalizedPath = path.substring(1); // Hapus / di awal
      }
      return '${ApiConfig.baseUrl}/public/$normalizedPath';
    }

    // Default case
    return '${ApiConfig.baseUrl}/public/images/$path';
  }
}
