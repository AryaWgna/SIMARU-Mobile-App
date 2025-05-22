import 'package:flutter/material.dart';
import 'package:flutter_assets_monitoring/views/asset/asset_complaint_screen_new.dart';
import 'asset_document.dart';
import 'asset_history.dart';
import 'asset_mutation.dart';
import 'lost.dart';
import 'checkout.dart';
import 'checkin.dart';
import '../dashboard/dashboard.dart';
import '../../core/config/api_config.dart';
import 'dart:convert';
import '../../controllers/auth_controller.dart' as auth;
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AssetDetails extends StatefulWidget {
  final String qrData;
  final String previousScreen;
  final Map<String, dynamic>? assetData;

  const AssetDetails(
      {super.key,
      required this.qrData,
      this.previousScreen = 'home',
      this.assetData});

  @override
  State<AssetDetails> createState() => _AssetDetailsState();
}

class _AssetDetailsState extends State<AssetDetails> {
  Map<String, dynamic>? masterAssetData;
  bool isLoadingMasterData = false;
  bool hasMasterDataError = false;
  String masterDataErrorMessage = '';
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  int _refreshCount = 0;

  @override
  void initState() {
    super.initState();
    // Log data aset yang diterima untuk debugging
    print('[ASSET_DETAILS] Widget dimuat dengan data: ${widget.assetData}');
    print('[ASSET_DETAILS] QR Data: ${widget.qrData}');
    print('[ASSET_DETAILS] Previous screen: ${widget.previousScreen}');

    // Coba ambil data aset dari API berdasarkan QR code atau asset_code
    String assetCode = widget.assetData?['asset_code'] ?? widget.qrData;
    _fetchAssetData(assetCode);
  }

  void _onRefresh() async {
    // Segera aktifkan loading state
    if (mounted) {
      setState(() {
        isLoadingMasterData = true;
      });
    }

    // Fetch data dengan flag showLoading=false karena kita sudah mengaktifkan loading state
    String assetCode = widget.assetData?['asset_code'] ?? widget.qrData;
    await _fetchAssetData(assetCode);

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
                    AssetDetails(
                  qrData: widget.qrData,
                  previousScreen: widget.previousScreen,
                  assetData: widget.assetData,
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

  Future<void> _fetchAssetData(String assetCode) async {
    setState(() {
      isLoadingMasterData = true;
      hasMasterDataError = false;
    });

    try {
      print('[ASSET_DETAILS] Mengambil data aset untuk: $assetCode');

      // Gunakan endpoint untuk mengambil data aset berdasarkan kode/QR
      final endpoint = '/assets/qr/${Uri.encodeComponent(assetCode)}';

      print('[ASSET_DETAILS] Memanggil API endpoint: $endpoint');
      final response = await auth.ApiService.get(endpoint, context: context);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final fullAssetData = responseData['data'];

          // Update widget.assetData jika ada
          if (widget.assetData != null) {
            widget.assetData!.addAll(fullAssetData);
          }

          // Ambil data master aset
          if (fullAssetData['asset_master'] != null) {
            setState(() {
              masterAssetData = fullAssetData['asset_master'];
              isLoadingMasterData = false;
            });
          } else if (fullAssetData['asset_master_id'] != null) {
            // Jika ada asset_master_id tapi tidak ada nested asset_master, ambil data master
            _fetchMasterAssetData(fullAssetData['asset_master_id']);
          } else {
            setState(() {
              hasMasterDataError = true;
              masterDataErrorMessage = 'Data master aset tidak ditemukan';
              isLoadingMasterData = false;
            });
          }
        } else {
          setState(() {
            hasMasterDataError = true;
            masterDataErrorMessage =
                responseData['message'] ?? 'Gagal mengambil data aset';
            isLoadingMasterData = false;
          });
        }
      } else {
        setState(() {
          hasMasterDataError = true;
          masterDataErrorMessage =
              'Error ${response.statusCode}: Gagal mengambil data aset';
          isLoadingMasterData = false;
        });
      }
    } catch (e) {
      setState(() {
        hasMasterDataError = true;
        masterDataErrorMessage = 'Error: $e';
        isLoadingMasterData = false;
      });
      print('[ASSET_DETAILS] Error saat mengambil data aset: $e');
    }
  }

  Future<void> _fetchMasterAssetData(int assetMasterId) async {
    setState(() {
      isLoadingMasterData = true;
      hasMasterDataError = false;
    });

    try {
      print(
          '[ASSET_DETAILS] Mengambil data master aset dengan ID: $assetMasterId');

      // Gunakan endpoint untuk mengambil data master aset berdasarkan ID
      final endpoint = '/assets/$assetMasterId';

      print('[ASSET_DETAILS] Memanggil API endpoint: $endpoint');
      final response = await auth.ApiService.get(endpoint, context: context);

      print('[ASSET_DETAILS] Status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('[ASSET_DETAILS] Response data: $responseData');

        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            masterAssetData = responseData['data'];
            isLoadingMasterData = false;
          });
          print(
              '[ASSET_DETAILS] Data master aset berhasil diambil: $masterAssetData');
        } else {
          print(
              '[ASSET_DETAILS] Response sukses tapi data tidak valid: ${responseData['message']}');
          setState(() {
            hasMasterDataError = true;
            masterDataErrorMessage =
                responseData['message'] ?? 'Data master aset tidak ditemukan';
            isLoadingMasterData = false;
          });
        }
      } else {
        print('[ASSET_DETAILS] Error API: ${response.statusCode}');
        setState(() {
          hasMasterDataError = true;
          masterDataErrorMessage =
              'Error ${response.statusCode}: Gagal mengambil data master aset';
          isLoadingMasterData = false;
        });
      }
    } catch (e) {
      print('[ASSET_DETAILS] Exception saat mengambil data: $e');
      setState(() {
        hasMasterDataError = true;
        masterDataErrorMessage = 'Error: $e';
        isLoadingMasterData = false;
      });
    }
  }

  // Fungsi ini masih diperlukan untuk kompatibilitas
  Future<void> _fetchMasterAssetDataByCode(String assetCode) async {
    setState(() {
      isLoadingMasterData = true;
      hasMasterDataError = false;
    });

    try {
      print('[ASSET_DETAILS] Mencari data aset dengan kode: $assetCode');

      // Gunakan endpoint untuk mengambil data aset berdasarkan kode/QR
      final endpoint = '/assets/qr/${Uri.encodeComponent(assetCode)}';

      print('[ASSET_DETAILS] Memanggil API endpoint: $endpoint');
      final response = await auth.ApiService.get(endpoint, context: context);

      print('[ASSET_DETAILS] Status response: ${response.statusCode}');
      print('[ASSET_DETAILS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          print('[ASSET_DETAILS] Data aset berhasil diambil');

          // Simpan seluruh data aset
          final fullAssetData = responseData['data'];

          // Ambil data master asset dari respons
          if (fullAssetData['asset_master'] != null) {
            setState(() {
              // Simpan data master aset
              masterAssetData = fullAssetData['asset_master'];

              // Update widget.assetData jika ada
              if (widget.assetData != null) {
                // Perbarui atau tambahkan properti yang baru didapat
                widget.assetData!.addAll(fullAssetData);
              }

              isLoadingMasterData = false;
            });
            print(
                '[ASSET_DETAILS] Data master aset berhasil diambil: $masterAssetData');
          } else {
            print(
                '[ASSET_DETAILS] Data asset_master tidak ditemukan dalam respons');
            setState(() {
              hasMasterDataError = true;
              masterDataErrorMessage = 'Data master aset tidak ditemukan';
              isLoadingMasterData = false;
            });
          }
        } else {
          print(
              '[ASSET_DETAILS] Response sukses tapi data tidak valid: ${responseData['message']}');
          setState(() {
            hasMasterDataError = true;
            masterDataErrorMessage =
                responseData['message'] ?? 'Data tidak ditemukan';
            isLoadingMasterData = false;
          });
        }
      } else {
        print('[ASSET_DETAILS] Error API: ${response.statusCode}');
        setState(() {
          hasMasterDataError = true;
          masterDataErrorMessage =
              'Error ${response.statusCode}: Gagal mengambil data';
          isLoadingMasterData = false;
        });
      }
    } catch (e) {
      print('[ASSET_DETAILS] Exception saat mengambil data: $e');
      setState(() {
        hasMasterDataError = true;
        masterDataErrorMessage = 'Error: $e';
        isLoadingMasterData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data aset dari parameter atau gunakan default jika null
    final assetData = widget.assetData ?? {};

    // Debugging: Tampilkan informasi data aset untuk troubleshooting
    print('[DETAIL DEBUG] Data aset yang diterima: $assetData');
    print(
        '[DETAIL DEBUG] Current status dari API: ${assetData['current_status']}');

    final assetCode = assetData['asset_code'] ?? widget.qrData;
    final assetName = assetData['asset_name'] ?? 'Tidak diketahui';
    final assetMasterCode = assetData['asset_master_code'] ?? '-';

    // Perbaikan untuk current_status - agar sesuai dengan database
    // Gunakan nilai dari database atau 'available' sebagai default yang aman
    final assetStatus =
        assetData['current_status']?.toString().toLowerCase() ?? 'available';
    print('[DETAIL DEBUG] Status yang akan digunakan: $assetStatus');

    // Informasi tambahan dengan format yang diperbaiki hanya untuk Condition dan Asset Type
    final brand = assetData['brand']?['brand_name'] ?? '-';
    final modelNumber = assetData['model_number'] ?? '-';

    // Ambil data kondisi langsung dari API dan terjemahkan
    final conditionRaw = assetData['condition'] ?? '-';
    final condition = getIndonesianCondition(conditionRaw);

    final warrantyDate = assetData['warranty_end_date'] ?? '-';
    final serialNumber = assetData['serial_number'] ?? '-';
    final purchasePrice = assetData['purchase_price'] != null
        ? formatCurrency(assetData['purchase_price'])
        : '-';
    final purchaseDate = assetData['purchase_date'] != null
        ? formatDate(assetData['purchase_date'])
        : '-';
    final disposalDate = assetData['disposal_date'] != null
        ? formatDate(assetData['disposal_date'])
        : '-';
    final userInCharge = assetData['responsible_user'] != null
        ? 'User ID: ${assetData['responsible_user']['user_id'] ?? '-'}'
        : '-';

    // Kategori dan subcategori
    final subCategory = assetData['subcategory']?['subcategory_name'] ?? '-';

    // Ambil data tipe aset langsung dari API dan terjemahkan
    final assetTypeRaw = assetData['subcategory']?['asset_type'] ?? '-';
    final assetType = getIndonesianAssetType(assetTypeRaw);

    final locationName = assetData['room']?['room_name'] ?? '-';
    final buildingName =
        assetData['room']?['building']?['building_name'] ?? '-';
    final description = assetData['description'] ?? '-';

    // Mengambil jalur gambar dan membangun URL lengkap
    final imagePath = assetData['picture_path'];
    final imageUrl = imagePath != null && imagePath.toString().isNotEmpty
        ? '${ApiConfig.baseUrl}/public/images/$imagePath'
        : '${ApiConfig.baseUrl}/public/images/placeholder.png';

    print('[DETAIL DEBUG] Image URL: $imageUrl');

    return WillPopScope(
      onWillPop: () async {
        // Navigasi kembali ke dashboard dengan tab yang sesuai
        _navigateBack();
        return false; // Mencegah default back behavior
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: SmartRefresher(
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
          child: isLoadingMasterData
              ? Skeletonizer(
                  enabled: true,
                  effect: ShimmerEffect(
                    baseColor: Colors.grey.shade300,
                    highlightColor: const Color(0xFFE5EFFF),
                  ),
                  child: _buildSkeletonLayout(),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image and Asset Info Section
                            Container(
                              height: 220,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD9D9D9),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              // Gambar aset dengan URL yang diperbaiki dan border rounded
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading image: $error');
                                    print('Image URL: $imageUrl');

                                    // Coba fallback ke placeholder jika URL utama gagal
                                    if (!imageUrl.contains('placeholder.png')) {
                                      return Image.network(
                                        '${ApiConfig.baseUrl}/public/images/placeholder.png',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return _buildImagePlaceholder(
                                              'Gambar tidak tersedia',
                                              Icons.broken_image);
                                        },
                                      );
                                    }

                                    return _buildImagePlaceholder(
                                        'Gambar tidak dapat dimuat',
                                        Icons.broken_image);
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        _buildImagePlaceholder('', null),
                                        CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                          color: const Color(0xFF213268),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Asset Code & Name with Available Tag
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        assetCode,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF213268),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        assetName,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF213268),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(assetStatus),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      _getStatusText(assetStatus),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action Buttons jika diperlukan
                      if (assetStatus.toLowerCase() != 'lost' &&
                          assetStatus.toLowerCase() != 'dispose' &&
                          assetStatus.toLowerCase() != 'under repair')
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                icon: assetStatus.toLowerCase() == 'check out'
                                    ? Icons.login
                                    : Icons.logout,
                                label: assetStatus.toLowerCase() == 'check out'
                                    ? 'Kembali'
                                    : 'Pinjam',
                                onTap: () async {
                                  if (assetStatus.toLowerCase() ==
                                      'check out') {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => CheckInScreen(
                                              assetData: assetData)),
                                    );
                                    if (result != null &&
                                        result is Map<String, dynamic>) {
                                      setState(() {
                                        widget.assetData?.addAll(result);
                                      });
                                    }
                                  } else {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => CheckoutScreen(
                                              assetData: assetData)),
                                    );
                                    if (result != null &&
                                        result is Map<String, dynamic>) {
                                      setState(() {
                                        widget.assetData?.addAll(result);
                                      });
                                    }
                                  }
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.report_problem_outlined,
                                label: 'Komplain',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            AssetComplaintScreen(
                                              assetData: assetData,
                                              assetCode: assetCode,
                                            )),
                                  );
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.help_outline,
                                label: 'Hilang',
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            LostScreen(assetData: assetData)),
                                  );
                                  if (result != null &&
                                      result is Map<String, dynamic>) {
                                    setState(() {
                                      widget.assetData?.addAll(result);
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          decoration: BoxDecoration(
                            color: _getStatusBackgroundColor(assetStatus),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _getStatusBorderColor(assetStatus)),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _getStatusIcon(assetStatus),
                                color: _getStatusColor(assetStatus),
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getStatusUnavailableMessage(assetStatus),
                                style: TextStyle(
                                  color: _getStatusColor(assetStatus),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tidak dapat melakukan tindakan pada aset ini',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _getStatusColor(assetStatus),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Informasi Master Asset
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Judul Informasi Master Asset
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Informasi Master Asset',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF213268),
                                ),
                              ),
                            ),

                            // Tabel Informasi Master Asset
                            Table(
                              columnWidths: const {
                                0: FlexColumnWidth(1.2),
                                1: FlexColumnWidth(2.0),
                              },
                              border: TableBorder.all(
                                color: const Color(0xFFEEF1F4),
                                width: 1,
                              ),
                              children: [
                                _buildTableRow(
                                    'Asset Master Code',
                                    masterAssetData?['asset_master_code'] ??
                                        assetData['asset_master']
                                            ?['asset_master_code'] ??
                                        assetData['asset_master_code'] ??
                                        '-'),
                                _buildTableRow(
                                    'Nama Master Asset',
                                    masterAssetData?['asset_name'] ??
                                        assetData['asset_master']
                                            ?['asset_name'] ??
                                        assetData['asset_master_name'] ??
                                        assetName),
                                _buildTableRow(
                                    'Tipe Asset',
                                    getIndonesianAssetType(
                                        masterAssetData?['asset_type'] ??
                                            assetData['asset_master']
                                                ?['asset_type'] ??
                                            assetData['subcategory']
                                                ?['asset_type'] ??
                                            assetTypeRaw)),
                                _buildTableRow(
                                    'Kategori',
                                    masterAssetData?['subcategory_name'] ??
                                        assetData['asset_master']
                                            ?['subcategory_name'] ??
                                        assetData['subcategory']
                                            ?['subcategory_name'] ??
                                        subCategory),
                                _buildTableRow(
                                    'Merek',
                                    masterAssetData?['brand_name'] ??
                                        assetData['asset_master']?['brand']
                                            ?['brand_name'] ??
                                        assetData['brand']?['brand_name'] ??
                                        brand),
                                _buildTableRow(
                                    'Perlu Kalibrasi',
                                    formatBoolean(
                                        masterAssetData?['needs_calibration'] ??
                                            assetData['asset_master']
                                                ?['needs_calibration'] ??
                                            false)),
                                _buildTableRow(
                                    'Dapat Didepresiasi',
                                    formatBoolean(
                                        masterAssetData?['is_depreciable'] ??
                                            assetData['asset_master']
                                                ?['is_depreciable'] ??
                                            false)),
                                _buildTableRow(
                                    'Deskripsi',
                                    masterAssetData?['description'] ??
                                        assetData['asset_master']
                                            ?['description'] ??
                                        description),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Judul Informasi Asset
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Informasi Asset',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF213268),
                                ),
                              ),
                            ),

                            // Tabel Informasi Asset
                            Table(
                              columnWidths: const {
                                0: FlexColumnWidth(1.2),
                                1: FlexColumnWidth(2.0),
                              },
                              border: TableBorder.all(
                                color: const Color(0xFFEEF1F4),
                                width: 1,
                              ),
                              children: [
                                _buildTableRow('Ruangan', locationName),
                                _buildTableRow('Gedung', buildingName),
                                _buildTableRow('Kondisi', condition),
                                _buildTableRow(
                                    'Tanggal Berakhir Garansi', warrantyDate),
                                _buildTableRow('Nomor Seri', serialNumber),
                                _buildTableRow(
                                    'Karyawan Penanggung Jawab', userInCharge),
                                _buildTableRow('Harga Beli', purchasePrice),
                                _buildTableRow('Tanggal Beli', purchaseDate),
                                _buildTableRow(
                                    'Tanggal Dimusnahkan', disposalDate),
                              ],
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context, ''),
      ),
    );
  }

  // Fungsi untuk membuat skeleton layout
  Widget _buildSkeletonLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            margin: const EdgeInsets.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Skeleton untuk gambar
                Container(
                  height: 220,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),

                // Skeleton untuk kode dan nama aset
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 150,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 200,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 80,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Skeleton untuk tombol aksi
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (index) => Column(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Skeleton untuk informasi master asset
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 200,
                  height: 24,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                _buildSkeletonTable(8), // 8 baris untuk master asset

                const SizedBox(height: 24),

                Container(
                  width: 200,
                  height: 24,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                _buildSkeletonTable(9), // 9 baris untuk informasi asset

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk membuat skeleton table
  Widget _buildSkeletonTable(int rows) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(2.0),
      },
      border: TableBorder.all(
        color: const Color(0xFFEEF1F4),
        width: 1,
      ),
      children: List.generate(
        rows,
        (index) => TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ekstrak nama file dari path
  String _extractFilename(String path) {
    // Jika path sudah dalam format yang benar, langsung kembalikan
    if (!path.contains('/')) return path;

    // Jika path lengkap (misalnya: /images/image-1743491338132-d9861d34-4854-46ea-bd8a-4597d1bdf029.png)
    // Ambil bagian terakhir setelah slash terakhir
    return path.split('/').last;
  }

  // Format text hanya untuk Condition dan Asset Type
  String formatText(String text) {
    if (text == '-') return text;

    // Replace underscores and dashes with spaces
    String formatted = text.replaceAll('_', ' ').replaceAll('-', ' ');

    // Capitalize each word
    List<String> words = formatted.split(' ');
    words = words.map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
      return word;
    }).toList();

    return words.join(' ');
  }

  // Fungsi untuk menerjemahkan teks ke Bahasa Indonesia
  String translateToIndonesian(String text) {
    // Terjemahan untuk tipe aset
    Map<String, String> assetTypeTranslations = {
      'Fixed Asset': 'Aset Tetap',
      'Consumable': 'Barang Habis Pakai',
      'Equipment': 'Peralatan',
      'Furniture': 'Furnitur',
      'It Equipment': 'Peralatan IT',
      'Medical Equipment': 'Peralatan Medis',
      'Non Medical': 'Non Medis',
      'Non Medical Equipment': 'Peralatan Non Medis',
      'Office Equipment': 'Peralatan Kantor',
      'Vehicle': 'Kendaraan',
      'Building': 'Bangunan',
      'Land': 'Tanah',
    };

    // Terjemahan untuk kondisi
    Map<String, String> conditionTranslations = {
      'Good': 'Baik',
      'Fair': 'Cukup Baik',
      'Poor': 'Buruk',
      'Excellent': 'Sangat Baik',
      'New': 'Baru',
      'Used': 'Bekas',
      'Damaged': 'Rusak',
      'Broken': 'Rusak Berat',
      'Needs Repair': 'Perlu Perbaikan',
      'Under Maintenance': 'Dalam Pemeliharaan',
      'Obsolete': 'Usang',
    };

    // Gabungkan semua terjemahan
    Map<String, String> allTranslations = {};
    allTranslations.addAll(assetTypeTranslations);
    allTranslations.addAll(conditionTranslations);

    // Cek apakah ada terjemahan yang cocok
    return allTranslations[text] ?? text;
  }

  Color _getStatusColor(String status) {
    // Debug - tampilkan status yang diterima
    print('[DETAIL DEBUG] Mendapatkan warna untuk status: $status');

    // Gunakan status yang sudah dinormalisasi ke lowercase
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFF659B09); // Hijau
      case 'check out':
        return const Color(0xFF0086C3); // Biru
      case 'under repair':
        return const Color(0xFFFF9900); // Oranye
      case 'dispose':
        return const Color(0xFF7A7A7A); // Abu-abu
      case 'lost':
        return const Color(0xFFDC3545); // Merah
      default:
        print(
            '[DETAIL DEBUG] Status tidak dikenal: $status, menggunakan default');
        return const Color(0xFF659B09); // Default hijau
    }
  }

  String _getStatusText(String status) {
    // Debug - tampilkan status yang diterima
    print('[DETAIL DEBUG] Mendapatkan teks untuk status: $status');

    // Gunakan status yang sudah dinormalisasi ke lowercase
    switch (status.toLowerCase()) {
      case 'available':
        return 'Tersedia';
      case 'check out':
        return 'Dipinjam';
      case 'under repair':
        return 'Perbaikan';
      case 'dispose':
        return 'Dibuang';
      case 'lost':
        return 'Hilang';
      default:
        print(
            '[DETAIL DEBUG] Status tidak dikenal: $status, menggunakan default');
        return 'Tersedia';
    }
  }

  // Fungsi untuk navigasi kembali ke layar sebelumnya
  void _navigateBack() {
    // Cek previousScreen untuk menentukan tab dashboard yang akan dibuka
    int dashboardIndex = 0;

    switch (widget.previousScreen) {
      case 'home':
        dashboardIndex = 0;
        break;
      case 'stockopname':
        dashboardIndex = 1;
        break;
      case 'repair':
        dashboardIndex = 3;
        break;
      case 'profile':
        dashboardIndex = 4;
        break;
      default:
        dashboardIndex = 0;
    }

    // Navigasi kembali ke DashboardScreen dengan tab yang sesuai
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(initialIndex: dashboardIndex),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    // Ukur tinggi status bar
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return PreferredSize(
      preferredSize: const Size.fromHeight(82),
      child: Stack(
        children: [
          // Warna biru tua untuk AppBar
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

          // AppBar Content dengan logo di tengah tanpa tombol back
          Positioned(
            top: statusBarHeight,
            left: 0,
            right: 0,
            height: 82,
            child: Center(
              child: Image.asset(
                'images/Logo_RS_UMMI_white.png',
                width: 208.14,
                height: 55,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF213268), width: 2),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF213268),
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF213268),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF3D3D3D),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF3D3D3D),
            ),
          ),
        ),
      ],
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
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AssetMutation(
                        assetData: widget.assetData,
                        qrData: widget.qrData,
                        previousScreen: widget.previousScreen,
                      )),
            ),
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

  Widget _buildImagePlaceholder(String text, IconData? icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: 40,
              color: Colors.white70,
            ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Fungsi untuk mendapatkan ikon status
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'lost':
        return Icons.help_outline;
      case 'dispose':
        return Icons.delete_outline;
      case 'under repair':
        return Icons.build_outlined;
      default:
        return Icons.error_outline;
    }
  }

  // Fungsi untuk mendapatkan pesan status unavailable
  String _getStatusUnavailableMessage(String status) {
    switch (status.toLowerCase()) {
      case 'lost':
        return 'Aset Ini Dilaporkan Hilang';
      case 'dispose':
        return 'Aset Ini Telah Dibuang';
      case 'under repair':
        return 'Aset Ini Sedang Dalam Perbaikan';
      default:
        return 'Aset Tidak Tersedia';
    }
  }

  // Fungsi untuk mendapatkan warna background notifikasi
  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'lost':
        return Colors.red.shade50;
      case 'dispose':
        return Colors.grey.shade100;
      case 'under repair':
        return Colors.orange.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  // Fungsi untuk mendapatkan warna border notifikasi
  Color _getStatusBorderColor(String status) {
    switch (status.toLowerCase()) {
      case 'lost':
        return Colors.red.shade200;
      case 'dispose':
        return Colors.grey.shade300;
      case 'under repair':
        return Colors.orange.shade200;
      default:
        return Colors.grey.shade300;
    }
  }

  // Format mata uang
  String formatCurrency(dynamic value) {
    if (value == null) return '-';
    try {
      double numValue = double.parse(value.toString());
      return numValue.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    } catch (e) {
      return value.toString();
    }
  }

  // Format tanggal
  String formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return date;
    }
  }

  // Helper function untuk format boolean values
  String formatBoolean(bool value) {
    return value ? 'Ya' : 'Tidak';
  }

  // Fungsi untuk menerjemahkan kondisi ke Bahasa Indonesia
  String getIndonesianCondition(String condition) {
    if (condition == '-') return condition;

    // Format teks terlebih dahulu
    String formatted = formatText(condition);

    // Map terjemahan kondisi
    Map<String, String> conditionMap = {
      'Good': 'Baik',
      'Fair': 'Cukup Baik',
      'Poor': 'Buruk',
      'Excellent': 'Sangat Baik',
      'New': 'Baru',
      'Used': 'Bekas',
      'Damaged': 'Rusak',
      'Broken': 'Rusak Berat',
      'Needs Repair': 'Perlu Perbaikan',
      'Under Maintenance': 'Dalam Pemeliharaan',
      'Obsolete': 'Usang',
    };

    return conditionMap[formatted] ?? formatted;
  }

  // Fungsi untuk menerjemahkan tipe aset ke Bahasa Indonesia
  String getIndonesianAssetType(String assetType) {
    if (assetType == '-') return assetType;

    // Format teks terlebih dahulu
    String formatted = formatText(assetType);

    // Map terjemahan tipe aset
    Map<String, String> assetTypeMap = {
      'Fixed Asset': 'Aset Tetap',
      'Consumable': 'Barang Habis Pakai',
      'Equipment': 'Peralatan',
      'Furniture': 'Furnitur',
      'It Equipment': 'Peralatan IT',
      'Medical Equipment': 'Peralatan Medis',
      'Non Medical': 'Non Medis',
      'Non Medical Equipment': 'Peralatan Non Medis',
      'Office Equipment': 'Peralatan Kantor',
      'Vehicle': 'Kendaraan',
      'Building': 'Bangunan',
      'Land': 'Tanah',
    };

    return assetTypeMap[formatted] ?? formatted;
  }
}
