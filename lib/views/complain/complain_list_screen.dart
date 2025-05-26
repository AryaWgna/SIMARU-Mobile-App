import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../core/config/api_config.dart';
import 'complain_detail_screen.dart';
import '../../controllers/auth_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class ComplainListScreen extends StatefulWidget {
  const ComplainListScreen({super.key});

  @override
  State<ComplainListScreen> createState() => _ComplainListScreenState();
}

class _ComplainListScreenState extends State<ComplainListScreen> {
  List<dynamic> _complaints = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _pagination;
  final _storage = const FlutterSecureStorage();
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _fetchComplaints() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = await ApiService.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      // Debug: Print all stored values
      final allValues = await _storage.readAll();
      print('All stored values: $allValues');

      // Ambil user_id dari Flutter Secure Storage
      final userId = await _storage.read(key: 'user_id');
      print('Retrieved user_id from storage: $userId');

      if (userId == null || userId.isEmpty) {
        // Coba ambil dari token
        final token = await ApiService.getAccessToken();
        if (token != null) {
          print('Trying to decode token: $token');
          // Decode token untuk mendapatkan user_id
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized =
                payload.replaceAll('-', '+').replaceAll('_', '/');
            final padded = normalized.padRight(
                normalized.length + (4 - normalized.length % 4) % 4, '=');
            final decoded = utf8.decode(base64Url.decode(padded));
            final decodedPayload = json.decode(decoded);
            print('Token payload: $decodedPayload');

            if (decodedPayload['user_id'] != null) {
              final userIdFromToken = decodedPayload['user_id'].toString();
              print('Found user_id in token: $userIdFromToken');
              await _storage.write(key: 'user_id', value: userIdFromToken);
              print('Saved user_id from token to storage');

              // Gunakan user_id dari token
              final response = await http.get(
                Uri.parse(
                    '${ApiConfig.baseUrl}/complaints/user/$userIdFromToken'),
                headers: {
                  'Authorization': 'Bearer $accessToken',
                  'Content-Type': 'application/json',
                },
              );

              _handleResponse(response);
              return;
            }
          }
        }
        throw Exception('User ID tidak ditemukan');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/complaints/user/$userId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      _handleResponse(response);
    } catch (e) {
      print('Error in _fetchComplaints: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      // Complete refresh if controller is active
      if (_refreshController.isRefresh) {
        _refreshController.refreshFailed();
      }
    }
  }

  Future<void> _onRefresh() async {
    // Menambahkan penundaan kecil sebelum refresh untuk mencegah tampilan mengganggu
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // Jangan set loading state saat refresh
      // setState(() {
      //   _isLoading = true;
      // });

      final accessToken = await ApiService.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      // Debug: Print all stored values
      final allValues = await _storage.readAll();
      print('All stored values: $allValues');

      // Ambil user_id dari Flutter Secure Storage
      final userId = await _storage.read(key: 'user_id');
      print('Retrieved user_id from storage: $userId');

      if (userId == null || userId.isEmpty) {
        // Coba ambil dari token
        final token = await ApiService.getAccessToken();
        if (token != null) {
          print('Trying to decode token: $token');
          // Decode token untuk mendapatkan user_id
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized =
                payload.replaceAll('-', '+').replaceAll('_', '/');
            final padded = normalized.padRight(
                normalized.length + (4 - normalized.length % 4) % 4, '=');
            final decoded = utf8.decode(base64Url.decode(padded));
            final decodedPayload = json.decode(decoded);
            print('Token payload: $decodedPayload');

            if (decodedPayload['user_id'] != null) {
              final userIdFromToken = decodedPayload['user_id'].toString();
              print('Found user_id in token: $userIdFromToken');
              await _storage.write(key: 'user_id', value: userIdFromToken);
              print('Saved user_id from token to storage');

              // Gunakan user_id dari token
              final response = await http.get(
                Uri.parse(
                    '${ApiConfig.baseUrl}/complaints/user/$userIdFromToken'),
                headers: {
                  'Authorization': 'Bearer $accessToken',
                  'Content-Type': 'application/json',
                },
              );

              _handleRefreshResponse(response);
              return;
            }
          }
        }
        throw Exception('User ID tidak ditemukan');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/complaints/user/$userId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      _handleRefreshResponse(response);
    } catch (e) {
      print('Error in _onRefresh: $e');
      // Gagal refresh
      if (_refreshController.isRefresh) {
        _refreshController.refreshFailed();
      }
      // Jangan ubah state karena kita hanya refresh
    }
  }

  void _handleResponse(http.Response response) {
    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        setState(() {
          _complaints = data['data'];
          _pagination = data['pagination'];
          _isLoading = false;
        });

        // Complete refresh if controller is active
        if (_refreshController.isRefresh) {
          _refreshController.refreshCompleted();
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch complaints');
      }
    } else {
      throw Exception('Failed to load complaints: ${response.statusCode}');
    }
  }

  void _handleRefreshResponse(http.Response response) {
    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        if (mounted) {
          setState(() {
            _complaints = data['data'];
            _pagination = data['pagination'];
          });
        }

        // Complete refresh jika controller aktif
        if (_refreshController.isRefresh) {
          _refreshController.refreshCompleted();
        }
      } else {
        if (_refreshController.isRefresh) {
          _refreshController.refreshFailed();
        }
        throw Exception(data['message'] ?? 'Failed to fetch complaints');
      }
    } else {
      if (_refreshController.isRefresh) {
        _refreshController.refreshFailed();
      }
      throw Exception('Failed to load complaints: ${response.statusCode}');
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')} March ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildStatusBadge(String? status, Map<String, dynamic> complaint) {
    Color backgroundColor;
    Color textColor = Colors.white;
    String statusText;

    // Check if repair exists and has approval_by
    if (complaint['repair'] != null &&
        complaint['repair']['approval_by'] != null &&
        complaint['repair']['approval_by'].toString() != "" &&
        complaint['repair']['approval_by'] != 0) {
      backgroundColor = Colors.green;
      statusText = 'APPROVED';
    } else {
      switch (status?.toLowerCase()) {
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
      statusText = status?.toUpperCase() ?? 'UNKNOWN';
    }

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
      body: SmartRefresher(
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
                child: _isLoading
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 160,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEBEEF5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 120,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEBEEF5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: 5,
                                itemBuilder: (context, index) {
                                  return Card(
                                    elevation: 3,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
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
                                                      BorderRadius.circular(8),
                                                  color:
                                                      const Color(0xFFEBEEF5),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
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
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      width: 80,
                                                      height: 12,
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFFEBEEF5),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Container(
                                                      width: 140,
                                                      height: 14,
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFFEBEEF5),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
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
                                                  color:
                                                      const Color(0xFFEBEEF5),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
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
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            key: const ValueKey('error'),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Error: $_errorMessage',
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchComplaints,
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          )
                        : _complaints.isEmpty
                            ? Center(
                                key: const ValueKey('empty'),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                        'Tidak ada keluhan yang ditemukan'),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _fetchComplaints,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        if (_pagination != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Total: ${_pagination!['total_items']} keluhan',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      itemCount: _complaints.length,
                                      itemBuilder: (context, index) {
                                        final complaint = _complaints[index];
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
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (complaint[
                                                            'complaint_picture_path'] !=
                                                        null)
                                                      Container(
                                                        width: 100,
                                                        height: 100,
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          border: Border.all(
                                                            color: Colors
                                                                .grey.shade200,
                                                          ),
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          child: Image.network(
                                                            '${ApiConfig.baseUrl}/public${complaint['complaint_picture_path']}',
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (context, error,
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
                                                                (context, child,
                                                                    loadingProgress) {
                                                              if (loadingProgress ==
                                                                  null)
                                                                return child;
                                                              return Center(
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  value: loadingProgress
                                                                              .expectedTotalBytes !=
                                                                          null
                                                                      ? loadingProgress
                                                                              .cumulativeBytesLoaded /
                                                                          loadingProgress
                                                                              .expectedTotalBytes!
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
                                                                      complaint[
                                                                          'complaint_date']),
                                                                  style:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                ),
                                                              ),
                                                              _buildStatusBadge(
                                                                  complaint[
                                                                      'status'],
                                                                  complaint),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          Text(
                                                            'ID: ${complaint['reporter_number'] ?? '-'}',
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 8),
                                                          Text(
                                                            'Asset Code:',
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                          Text(
                                                            complaint[
                                                                    'asset_code'] ??
                                                                '-',
                                                            style: GoogleFonts
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
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                          Text(
                                                            complaint[
                                                                    'asset_name'] ??
                                                                '',
                                                            style: GoogleFonts
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    top: BorderSide(
                                                      color:
                                                          Colors.grey.shade200,
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Complaint Desc:',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      complaint[
                                                              'description'] ??
                                                          '',
                                                      style: GoogleFonts.inter(
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
                                                        complaint: complaint,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 45,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Color(0xFF213268),
                                                    borderRadius:
                                                        BorderRadius.only(
                                                      bottomLeft:
                                                          Radius.circular(12),
                                                      bottomRight:
                                                          Radius.circular(12),
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      'Lihat Detail',
                                                      style: GoogleFonts.inter(
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
      ),
    );
  }
}
