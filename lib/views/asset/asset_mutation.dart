import 'package:flutter/material.dart';
import 'dart:convert';
import '../../controllers/auth_controller.dart';
import 'asset_document.dart';
import 'asset_history.dart';
import 'asset_details.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AssetMutation extends StatefulWidget {
  final Map<String, dynamic>? assetData;
  final String qrData;
  final String previousScreen;

  const AssetMutation({
    super.key,
    this.assetData,
    this.qrData = '',
    this.previousScreen = 'home',
  });

  @override
  State<AssetMutation> createState() => _AssetMutationState();
}

class _AssetMutationState extends State<AssetMutation> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> statusHistories = [];
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  // Tambahkan counter refresh untuk mengatasi efek zoom kumulatif
  int _refreshCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAssetStatusHistories();
  }

  void _onRefresh() async {
    // Segera aktifkan skeletonizer
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    // Fetch data dengan flag showLoading=false karena kita sudah mengaktifkan loading state
    await _fetchAssetStatusHistories(showLoading: false);

    // Reset refresh controller
    _refreshController.refreshCompleted();

    // Jika refresh counter mencapai 3, reset tampilan untuk mencegah zoom
    _refreshCount++;
    if (_refreshCount >= 3) {
      _refreshCount = 0;

      if (mounted) {
        // Trigger rebuild dengan sedikit delay
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    AssetMutation(
                  assetData: widget.assetData,
                  qrData: widget.qrData,
                  previousScreen: widget.previousScreen,
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
            Navigator.of(context).removeRoute(ModalRoute.of(context)!);
          }
        });
      }
    }
  }

  Future<void> _fetchAssetStatusHistories({bool showLoading = true}) async {
    if (widget.assetData == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Data aset tidak tersedia';
      });
      return;
    }

    if (showLoading) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      // Debug: tampilkan semua key yang tersedia di assetData
      print('Asset data keys available: ${widget.assetData!.keys.toList()}');
      print('Asset data: ${widget.assetData}');

      // Gunakan asset_id untuk konsistensi
      var assetId = widget.assetData!['asset_id']?.toString();

      // Jika asset_id tidak tersedia, coba ambil dari property lain
      if (assetId == null || assetId.isEmpty) {
        // Coba dari id
        assetId = widget.assetData!['id']?.toString();

        // Jika masih null, coba asset_master_id
        if (assetId == null || assetId.isEmpty) {
          assetId = widget.assetData!['asset_master_id']?.toString();
        }
      }

      if (assetId == null || assetId.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'ID aset tidak ditemukan (asset_id)';
        });
        return;
      }

      print('Mengambil riwayat status untuk aset dengan ID: $assetId');

      // Gunakan endpoint untuk riwayat status aset
      final endpoint = '/asset-histories/status/$assetId';
      print('Endpoint yang digunakan: $endpoint');

      final response = await ApiService.get(
        endpoint,
        context: context,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> histories = [];
          if (data['data'] != null) {
            if (data['data'] is List) {
              // Jika data adalah array langsung
              histories = data['data'];
            } else if (data['data']['histories'] != null &&
                data['data']['histories'] is List) {
              // Struktur data dengan histories
              histories = data['data']['histories'];
            } else if (data['data']['items'] != null &&
                data['data']['items'] is List) {
              // Struktur data dengan items
              histories = data['data']['items'];
            }
            print('Jumlah riwayat status ditemukan: ${histories.length}');
          }

          setState(() {
            statusHistories = histories;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage =
                data['message'] ?? 'Gagal memuat riwayat status aset';
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          isLoading = false;
          statusHistories = [];
        });
      } else if (response.statusCode == 500) {
        // Handle error 500 dengan pesan yang lebih jelas
        String serverError;
        try {
          final data = json.decode(response.body);
          serverError =
              data['message'] ?? 'Terjadi kesalahan pada server (500)';
        } catch (e) {
          serverError = 'Terjadi kesalahan pada server (500)';
        }

        print('Error 500: $serverError');
        setState(() {
          isLoading = false;
          errorMessage =
              'Kesalahan server: $serverError. Silakan coba dengan ID aset yang benar.';
        });

        // Coba endpoint alternatif jika error 500
        _tryAlternativeEndpoint(assetId);
      } else {
        setState(() {
          isLoading = false;
          errorMessage =
              'Gagal memuat riwayat status: Error ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error saat mengambil riwayat status aset: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    }
  }

  // Metode baru untuk mencoba endpoint alternatif
  Future<void> _tryAlternativeEndpoint(String assetId) async {
    print('Mencoba endpoint alternatif untuk riwayat status...');

    try {
      // Coba beberapa endpoint alternatif untuk riwayat status
      List<String> alternativeEndpoints = [
        '/mutations/asset/$assetId',
        '/asset-status-histories/$assetId',
        '/status-histories/asset/$assetId'
      ];

      for (var endpoint in alternativeEndpoints) {
        print('Mencoba endpoint alternatif: $endpoint');

        final response = await ApiService.get(
          endpoint,
          context: context,
        );

        print('Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);

            if (data['success'] == true && data['data'] != null) {
              List<dynamic> histories = [];

              if (data['data'] is List) {
                histories = data['data'];
              } else if (data['data']['histories'] != null &&
                  data['data']['histories'] is List) {
                histories = data['data']['histories'];
              } else if (data['data']['items'] != null &&
                  data['data']['items'] is List) {
                histories = data['data']['items'];
              } else {
                // Jika data adalah object tunggal
                histories = [data['data']];
              }

              print(
                  'Jumlah riwayat status ditemukan dengan endpoint alternatif: ${histories.length}');

              if (histories.isNotEmpty) {
                setState(() {
                  statusHistories = histories;
                  isLoading = false;
                  errorMessage = null; // Hapus pesan error sebelumnya
                });

                return; // Keluar dari loop jika berhasil
              }
            }
          } catch (e) {
            print('Error parsing response dari endpoint alternatif: $e');
          }
        }
      }
    } catch (e) {
      print('Error pada endpoint alternatif: $e');
      // Tidak mengubah state karena ini hanya upaya backup
    }
  }

  // Format tanggal dari API
  String formatAPIDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      return '$day/$month/$year';
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mendapatkan ukuran layar untuk responsivitas
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: isLoading
          ? Skeletonizer(
              enabled: true,
              effect: ShimmerEffect(
                baseColor: Colors.grey.shade300,
                highlightColor: const Color(0xFFE5EFFF),
              ),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    _buildSkeletonCard(),
                    const SizedBox(height: 24),
                    _buildSkeletonCard(),
                    const SizedBox(height: 24),
                    _buildSkeletonCard(),
                  ],
                ),
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[700],
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _fetchAssetStatusHistories,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF213268),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : statusHistories.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              color: Colors.grey[400],
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tidak ada riwayat mutasi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Aset ini belum memiliki riwayat peminjaman atau pengembalian',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF999999),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SmartRefresher(
                      enablePullDown: true,
                      enablePullUp: false,
                      physics: const ClampingScrollPhysics(),
                      controller: _refreshController,
                      onRefresh: _onRefresh,
                      footer: null,
                      header: const WaterDropMaterialHeader(
                        backgroundColor: Color(0xFF213268),
                        color: Colors.white,
                        distance: 60.0,
                      ),
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          overscroll: false,
                        ),
                        child: NotificationListener<
                            OverscrollIndicatorNotification>(
                          onNotification: (overscroll) {
                            overscroll.disallowIndicator();
                            return true;
                          },
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              width: screenSize.width,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                              ),
                              child: Column(
                                children: [
                                  // Jarak dari AppBar
                                  const SizedBox(height: 24),

                                  // Daftar riwayat status
                                  ...statusHistories.map<Widget>((history) {
                                    // Peminjaman (checked out)
                                    if (history['status']
                                            ?.toString()
                                            .toLowerCase() ==
                                        'checked out') {
                                      return _buildCheckoutCard(history);
                                    }
                                    // Pengembalian (return)
                                    else if (history['status']
                                            ?.toString()
                                            .toLowerCase() ==
                                        'return') {
                                      return _buildReturnCard(history);
                                    }
                                    return const SizedBox.shrink();
                                  }),

                                  // Tambahkan padding di bagian bawah
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
      bottomNavigationBar: _buildBottomNavigationBar(context, 'mutation'),
    );
  }

  // Widget skeleton untuk card
  Widget _buildSkeletonCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF213268).withOpacity(0.08),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan Icon dan Text
          Container(
            padding: const EdgeInsets.only(left: 15, top: 14, bottom: 14),
            child: Row(
              children: [
                // Ikon
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 11),
                  decoration: const BoxDecoration(
                    color: Color(0xFF213268),
                    shape: BoxShape.circle,
                  ),
                ),
                // Teks
                Container(
                  width: 120,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),

          // Divider horizontal
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey.shade200,
          ),

          // Info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSkeletonInfoRow(),
                const SizedBox(height: 12),
                _buildSkeletonInfoRow(),
                const SizedBox(height: 12),
                _buildSkeletonInfoRow(),
                const SizedBox(height: 12),
                _buildSkeletonInfoRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget skeleton untuk baris info
  Widget _buildSkeletonInfoRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label dengan lebar tetap
        Container(
          width: 120,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        // Value dengan lebar yang menyesuaikan
        Expanded(
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  // Widget untuk membuat kartu peminjaman
  Widget _buildCheckoutCard(Map<String, dynamic> history) {
    // Ambil detail info
    final detailInfo = history['detail_info'] as Map<String, dynamic>?;
    final user = detailInfo?['user'] as Map<String, dynamic>?;
    final location = detailInfo?['location'] as Map<String, dynamic>?;

    // Tanggal checkout
    final checkoutDate =
        formatAPIDate(detailInfo?['checkout_date']?.toString());

    // Informasi peminjam
    String borrower = '-';
    if (user != null && user['employee_number'] != null) {
      borrower = user['employee_number'].toString();
    }

    // Informasi lokasi
    String locationInfo = '-';
    if (location != null) {
      final roomName = location['room_name']?.toString() ?? '';
      final floorNumber = location['floor_number']?.toString() ?? '';
      final buildingName = location['building_name']?.toString() ?? '';

      List<String> locationParts = [];
      if (buildingName.isNotEmpty) locationParts.add(buildingName);
      if (floorNumber.isNotEmpty) locationParts.add(floorNumber);
      if (roomName.isNotEmpty) locationParts.add(roomName);

      locationInfo = locationParts.isNotEmpty ? locationParts.join(', ') : '-';
    }

    // Catatan
    final notes = detailInfo?['checkout_notes']?.toString() ?? '-';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan Icon dan Text
          Container(
            padding: const EdgeInsets.only(left: 15, top: 14, bottom: 14),
            child: Row(
              children: [
                // Ikon Logout
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 11),
                  child: const Icon(
                    Icons.logout,
                    color: Color(0xFF203268),
                    size: 24,
                  ),
                ),
                // Teks PEMINJAMAN
                const Text(
                  'PEMINJAMAN',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF56C5F1),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),

          // Divider horizontal
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFAAAAAA),
          ),

          // Info section dengan layout yang lebih responsif
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Tanggal Dipinjam:', checkoutDate),
                const SizedBox(height: 12),
                _buildInfoRow('Dipinjam oleh:', borrower),
                const SizedBox(height: 12),
                _buildInfoRow('Lokasi:', locationInfo),
                const SizedBox(height: 12),
                _buildInfoRow('Catatan:', notes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk membuat kartu pengembalian
  Widget _buildReturnCard(Map<String, dynamic> history) {
    // Tanggal pengembalian
    final returnDate = formatAPIDate(history['return_date']?.toString());

    // Catatan
    final notes = history['return_notes']?.toString() ?? '-';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan Icon dan Text
          Container(
            padding: const EdgeInsets.only(left: 15, top: 14, bottom: 14),
            child: Row(
              children: [
                // Ikon Login
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 11),
                  child: const Icon(
                    Icons.login,
                    color: Color(0xFF203268),
                    size: 24,
                  ),
                ),
                // Teks PENGEMBALIAN
                const Text(
                  'PENGEMBALIAN',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF659B09),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),

          // Divider horizontal
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFAAAAAA),
          ),

          // Info section dengan layout yang lebih responsif
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Tanggal Kembali:', returnDate),
                const SizedBox(height: 12),
                _buildInfoRow('Catatan:', notes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk membuat baris informasi yang lebih rapi dan responsif
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label dengan lebar tetap
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF757575),
              letterSpacing: 0.1,
            ),
          ),
        ),
        // Value dengan lebar yang menyesuaikan
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF757575),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return PreferredSize(
      preferredSize: const Size.fromHeight(82),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 82 + statusBarHeight,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF213268),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
            ),
          ),
          Positioned(
            top: statusBarHeight,
            left: 0,
            right: 0,
            height: 82,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 32),
                  onPressed: () {
                    // Navigasi langsung ke halaman AssetDetails ketika tombol kembali ditekan
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssetDetails(
                          qrData: widget.qrData,
                          previousScreen: widget.previousScreen,
                          assetData: widget.assetData,
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: Image.asset(
                        'images/Logo_RS_UMMI_white.png',
                        width: 208.14,
                        height: 55,
                        fit: BoxFit.contain,
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

  Widget _buildBottomNavigationBar(BuildContext context, String activePage) {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, -4),
            blurRadius: 4,
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            Icons.folder,
            'Dokumen',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AssetDocument(
                        assetData: widget.assetData,
                        qrData: widget.qrData,
                        previousScreen: widget.previousScreen,
                      )),
            ),
          ),
          _buildNavItem(
            Icons.history,
            'Riwayat',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AssetHistory(
                        assetData: widget.assetData,
                        qrData: widget.qrData,
                        previousScreen: widget.previousScreen,
                      )),
            ),
          ),
          _buildNavItem(
            Icons.swap_horiz,
            'Mutasi',
            activePage == 'mutation',
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isActive ? const Color(0xFF213268) : const Color(0xFF757575),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: isActive
                    ? const Color(0xFF213268)
                    : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
