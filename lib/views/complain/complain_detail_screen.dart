import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_config.dart';
import '../../controllers/complaint/complaint_controller.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class ComplainDetailScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;

  const ComplainDetailScreen({
    super.key,
    required this.complaint,
  });

  @override
  State<ComplainDetailScreen> createState() => _ComplainDetailScreenState();
}

class _ComplainDetailScreenState extends State<ComplainDetailScreen> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  int _refreshCount = 0;

  @override
  void initState() {
    super.initState();
    // Ambil controller dan load data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller =
          Provider.of<ComplaintController>(context, listen: false);
      await controller.fetchComplaintDetail(widget.complaint['id']);

      // Force refresh UI after data is loaded
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final controller = Provider.of<ComplaintController>(context, listen: false);
    await controller.fetchComplaintDetail(widget.complaint['id']);
    _refreshController.refreshCompleted();

    // Langsung rebuild tanpa delay
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ComplainDetailScreen(
            complaint: widget.complaint,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')} March ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
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

  Widget _buildStatusBadge(String? status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    final complaintDetail =
        Provider.of<ComplaintController>(context).complaintDetail;

    // Check if repair exists and has approval_by
    if (complaintDetail != null &&
        complaintDetail.repair != null &&
        complaintDetail.repair!['approval_by'] != null &&
        complaintDetail.repair!['approval_by'].toString() != "null" &&
        complaintDetail.repair!['approval_by'].toString() != "") {
      backgroundColor = const Color(0xFFDCFCE7); // bg-green-100
      textColor = const Color(0xFF166534); // text-green-800
      statusText = 'Disetujui';
    } else {
      // Mengadaptasi logika status dari kode Laravel
      switch (status?.toLowerCase()) {
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
          backgroundColor =
              const Color(0xFFFEF9C3); // Similar to 'new' (yellow)
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
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF213268),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonDetail() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 150,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Image placeholder
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Detail items
          ...List.generate(5, (index) => _buildSkeletonDetailItem()),

          const SizedBox(height: 24),

          // Repair section title
          Container(
            width: 180,
            height: 20,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Repair image
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          // Repair details
          ...List.generate(8, (index) => _buildSkeletonDetailItem()),

          // Button placeholder
          Container(
            width: double.infinity,
            height: 45,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSkeletonDetailItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF213268),
        elevation: 0,
        title:
            const Text('Detail Keluhan', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Sebelum kembali, reset controller dan muat ulang data
            final controller =
                Provider.of<ComplaintController>(context, listen: false);

            // Hapus detail komplain yang sedang ditampilkan
            controller.clearComplaintDetail();

            // Muat ulang daftar komplain
            controller.fetchComplaints();

            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<ComplaintController>(
        builder: (context, controller, child) {
          return SmartRefresher(
            enablePullDown: true,
            enablePullUp: false,
            controller: _refreshController,
            onRefresh: _onRefresh,
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
                    child: _buildSkeletonDetail(),
                  )
                : controller.errorMessage != null
                    ? Center(
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
                              onPressed: () => controller
                                  .fetchComplaintDetail(widget.complaint['id']),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : _buildComplaintDetail(controller),
          );
        },
      ),
    );
  }

  Widget _buildComplaintDetail(ComplaintController controller) {
    final complaintDetail = controller.complaintDetail;
    if (complaintDetail == null) {
      return const Center(child: Text('Data tidak ditemukan'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Complaint Information
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detail Keluhan',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF213268),
                ),
              ),
              _buildStatusBadge(complaintDetail.status),
            ],
          ),
          const SizedBox(height: 16),
          if (complaintDetail.complaintPicturePath != null)
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _buildImageUrl(complaintDetail.complaintPicturePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error');
                    print(
                        'Image path: ${complaintDetail.complaintPicturePath}');
                    return Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.grey[400],
                        size: 50,
                      ),
                    );
                  },
                ),
              ),
            ),
          _buildDetailItem(
              'Tanggal Keluhan', _formatDate(complaintDetail.complaintDate)),
          _buildDetailItem('Kode Aset', complaintDetail.assetCode),
          _buildDetailItem('Nama Aset', complaintDetail.assetName),
          _buildDetailItem('Keluhan', complaintDetail.description),
          _buildDetailItem('Pelapor', complaintDetail.reporterNumber ?? "-"),

          // Repair Information
          if (complaintDetail.repair != null) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('Informasi Perbaikan'),
            if (complaintDetail.repair!['repair_picture_path'] != null)
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _buildImageUrl(
                        complaintDetail.repair!['repair_picture_path']),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading repair image: $error');
                      return Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.grey[400],
                          size: 50,
                        ),
                      );
                    },
                  ),
                ),
              ),
            _buildDetailItem('Tanggal Perbaikan',
                _formatDate(complaintDetail.repair!['repair_date'])),
            _buildDetailItem(
                'Hasil Akhir', complaintDetail.repair!['final_result'] ?? '-'),
            _buildDetailItem('Deskripsi Perbaikan',
                complaintDetail.repair!['repair_description'] ?? '-'),
            _buildDetailItem('Biaya Perbaikan',
                'Rp ${complaintDetail.repair!['repair_cost'] ?? '0'}'),
            _buildDetailItem('Teknisi',
                'ID: ${complaintDetail.repair!['technician_number'] ?? '-'}'),
            _buildDetailItem('Part yang Diganti',
                complaintDetail.repair!['parts_replaced'] ?? '-'),
            _buildDetailItem('Tanggal Selesai',
                _formatDate(complaintDetail.repair!['completion_date'])),
            _buildDetailItem('Disetujui Oleh',
                'ID: ${complaintDetail.repair!['approver_number'] ?? '-'}'),
            _buildDetailItem('Tanggal Persetujuan',
                _formatDate(complaintDetail.repair!['approval_date'])),
          ],

          // Add Approve button if status is 'finished' and approval_by is null/empty
          if (complaintDetail.status.toLowerCase() == 'finished' &&
              complaintDetail.status.toLowerCase() != 'approved' &&
              complaintDetail.repair != null &&
              (complaintDetail.repair!['approval_by'] == null ||
                  complaintDetail.repair!['approval_by'].toString() == "null" ||
                  complaintDetail.repair!['approval_by'].toString() == ""))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: controller.isApproving
                      ? null
                      : () async {
                          final success = await controller.approveRepair();
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Perbaikan berhasil disetujui')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF166534),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: controller.isApproving
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Setujui Perbaikan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          // Add additional padding at the bottom for safe area
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
