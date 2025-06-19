import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../core/config/api_config.dart';
import 'complain_detail_screen.dart';
import '../../controllers/complaint_controller.dart';
import '../../models/complaint_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class ComplainListScreen extends StatefulWidget {
  const ComplainListScreen({super.key});

  @override
  State<ComplainListScreen> createState() => _ComplainListScreenState();
}

class _ComplainListScreenState extends State<ComplainListScreen> {
  final _storage = const FlutterSecureStorage();
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  late ComplaintController _complaintController;

  @override
  void initState() {
    super.initState();
    _complaintController =
        Provider.of<ComplaintController>(context, listen: false);
    _loadComplaints();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    await _complaintController.fetchComplaints();

    if (_refreshController.isRefresh) {
      if (_complaintController.hasError) {
        _refreshController.refreshFailed();
      } else {
        _refreshController.refreshCompleted();
      }
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
      return '';
    }
  }

  Widget _buildStatusBadge(String status, ComplaintModel complaint) {
    Color backgroundColor;
    Color textColor = Colors.white;
    String statusText;

    // Mengadaptasi logika status dari versi lama
    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green;
        break;
      case 'pending':
        backgroundColor = Colors.orange;
        break;
      case 'rejected':
        backgroundColor = Colors.red;
        break;
      case 'finished':
        backgroundColor = Colors.blue;
        break;
      default:
        backgroundColor = Colors.grey;
    }
    statusText = status.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          kBottomNavigationBarHeight -
                          MediaQuery.of(context).padding.top -
                          82,
                    ),
                    child: (controller.isLoading &&
                            controller.complaints.isEmpty)
                        ? Skeletonizer(
                            enabled: true,
                            effect: ShimmerEffect(
                              baseColor: Colors.grey.shade300,
                              highlightColor: const Color(0xFFE5EFFF),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 160,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEBEEF5),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: 120,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEBEEF5),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: ListView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(16),
                                    itemCount: 5,
                                    itemBuilder: (context, index) {
                                      return Card(
                                        elevation: 3,
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 100,
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      color: const Color(
                                                          0xFFEBEEF5),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Container(
                                                              width: 100,
                                                              height: 14,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                    0xFFEBEEF5),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4),
                                                              ),
                                                            ),
                                                            Container(
                                                              width: 60,
                                                              height: 20,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                    0xFFEBEEF5),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Container(
                                                          width: 80,
                                                          height: 12,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: const Color(
                                                                0xFFEBEEF5),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 12),
                                                        Container(
                                                          width: 140,
                                                          height: 14,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: const Color(
                                                                0xFFEBEEF5),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
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
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: double.infinity,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFEBEEF5),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
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
                                                  bottomLeft:
                                                      Radius.circular(12),
                                                  bottomRight:
                                                      Radius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          )
                        : controller.hasError
                            ? Center(
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
                              )
                            : controller.complaints.isEmpty
                                ? Center(
                                    key: const ValueKey('empty'),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                            'Tidak ada keluhan yang ditemukan'),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: _loadComplaints,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Refresh'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF213268),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Daftar Keluhan',
                                              style: GoogleFonts.inter(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF213268),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Total: ${controller.complaints.length} keluhan',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          itemCount:
                                              controller.complaints.length,
                                          itemBuilder: (context, index) {
                                            final complaint =
                                                controller.complaints[index];
                                            return Card(
                                              elevation: 3,
                                              margin: const EdgeInsets.only(
                                                  bottom: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        if (complaint
                                                                .picturePath !=
                                                            null)
                                                          Container(
                                                            width: 100,
                                                            height: 100,
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              border:
                                                                  Border.all(
                                                                color: Colors
                                                                    .grey
                                                                    .shade200,
                                                              ),
                                                            ),
                                                            child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              child:
                                                                  Image.network(
                                                                '${ApiConfig.baseUrl}${complaint.picturePath}',
                                                                fit: BoxFit
                                                                    .cover,
                                                                errorBuilder:
                                                                    (context,
                                                                        error,
                                                                        stackTrace) {
                                                                  print(
                                                                      'Error loading image: $error');
                                                                  return Center(
                                                                    child: Icon(
                                                                      Icons
                                                                          .error_outline,
                                                                      color: Colors
                                                                              .grey[
                                                                          400],
                                                                      size: 40,
                                                                    ),
                                                                  );
                                                                },
                                                                loadingBuilder:
                                                                    (context,
                                                                        child,
                                                                        loadingProgress) {
                                                                  if (loadingProgress ==
                                                                      null)
                                                                    return child;
                                                                  return Center(
                                                                    child:
                                                                        CircularProgressIndicator(
                                                                      value: loadingProgress.expectedTotalBytes !=
                                                                              null
                                                                          ? loadingProgress.cumulativeBytesLoaded /
                                                                              loadingProgress.expectedTotalBytes!
                                                                          : null,
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                        const SizedBox(
                                                            width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Expanded(
                                                                    child: Text(
                                                                      _formatDate(
                                                                          complaint
                                                                              .reportDate),
                                                                      style: GoogleFonts
                                                                          .inter(
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        color: Colors
                                                                            .black,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  _buildStatusBadge(
                                                                      complaint
                                                                          .status,
                                                                      complaint),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                  height: 4),
                                                              Text(
                                                                'ID: ${complaint.reporterEmployeeNumber ?? '-'}',
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 8),
                                                              Text(
                                                                'Asset Code:',
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                          .grey[
                                                                      600],
                                                                ),
                                                              ),
                                                              Text(
                                                                complaint
                                                                    .assetCode,
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 4),
                                                              Text(
                                                                'Asset Name:',
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                          .grey[
                                                                      600],
                                                                ),
                                                              ),
                                                              Text(
                                                                complaint
                                                                    .assetName,
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        top: BorderSide(
                                                          color: Colors
                                                              .grey.shade200,
                                                          width: 1,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Complaint Desc:',
                                                          style:
                                                              GoogleFonts.inter(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          complaint.description,
                                                          style:
                                                              GoogleFonts.inter(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
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
                                                          builder: (context) =>
                                                              ComplainDetailScreen(
                                                            complaint: {
                                                              'id':
                                                                  complaint.id,
                                                              'asset_id':
                                                                  complaint
                                                                      .assetId,
                                                              'asset_code':
                                                                  complaint
                                                                      .assetCode,
                                                              'asset_name':
                                                                  complaint
                                                                      .assetName,
                                                              'description':
                                                                  complaint
                                                                      .description,
                                                              'status':
                                                                  complaint
                                                                      .status,
                                                              'complaint_picture_path':
                                                                  complaint
                                                                      .picturePath,
                                                              'reporter_name':
                                                                  complaint
                                                                      .reporterName,
                                                              'reporter_employee_number':
                                                                  complaint
                                                                      .reporterEmployeeNumber,
                                                              'report_date':
                                                                  complaint
                                                                      .reportDate
                                                                      .toIso8601String(),
                                                              'resolved_by':
                                                                  complaint
                                                                      .resolvedBy,
                                                              'resolved_date':
                                                                  complaint
                                                                      .resolvedDate
                                                                      ?.toIso8601String(),
                                                              'resolution':
                                                                  complaint
                                                                      .resolution,
                                                            },
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      width: double.infinity,
                                                      height: 45,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color:
                                                            Color(0xFF213268),
                                                        borderRadius:
                                                            BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  12),
                                                          bottomRight:
                                                              Radius.circular(
                                                                  12),
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          'Lihat Detail',
                                                          style:
                                                              GoogleFonts.inter(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
