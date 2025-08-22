import 'package:flutter/material.dart';
import 'package:SIMARU/views/asset/asset_complaint_screen_new.dart';
import 'asset_document.dart';
import 'asset_history.dart';
import 'asset_mutation.dart';

import 'checkout.dart';
import 'checkin.dart';
import '../dashboard/dashboard.dart';
import '../../core/config/api_config.dart';
import 'package:provider/provider.dart';
import '../../controllers/asset/asset_details_controller.dart';
import '../../controllers/asset/asset_complaint_controller.dart';
import '../../controllers/dashboard/dashboard_controller.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../utils/logger_util.dart';

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

class _AssetDetailsState extends State<AssetDetails> with RouteAware {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  late AssetDetailsController _assetDetailsController;
  late DashboardController _dashboardController;

  @override
  void initState() {
    super.initState();
    _assetDetailsController =
        Provider.of<AssetDetailsController>(context, listen: false);
    _dashboardController =
        Provider.of<DashboardController>(context, listen: false);

    // Log data aset yang diterima untuk debugging
    LoggerUtil.d(
        '[ASSET_DETAILS] Widget dimuat dengan data: ${widget.assetData}');
    LoggerUtil.d('[ASSET_DETAILS] QR Data: ${widget.qrData}');
    LoggerUtil.d('[ASSET_DETAILS] Previous screen: ${widget.previousScreen}');

    // Add this screen to navigation history
    _dashboardController.pushToHistory('asset_details_${widget.qrData}');

    // Jika ada data aset yang diberikan, set ke controller
    if (widget.assetData != null) {
      _assetDetailsController
          .setAssetData(Map<String, dynamic>.from(widget.assetData!));

      // Cek apakah data aset sudah lengkap (memiliki asset_master)
      bool hasCompleteData = widget.assetData!['asset_master'] != null ||
          _assetDetailsController.masterAssetData != null;

      // Jika data belum lengkap, fetch dari API
      if (!hasCompleteData) {
        String assetCode = widget.assetData!['asset_code'] ?? widget.qrData;
        _assetDetailsController.fetchAssetData(assetCode, context: context);
      } else {
        // Data sudah lengkap, pastikan loading state di-reset
        _assetDetailsController.setLoading(false);
      }
    } else {
      // Tidak ada data aset, ambil dari API berdasarkan QR code
      _assetDetailsController.fetchAssetData(widget.qrData, context: context);
    }
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
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _onRefresh() async {
    // Aktifkan skeletonizer
    _assetDetailsController.setLoading(true);

    // Simpan data status dan updated_at sebelum refresh
    final currentAssetData =
        _assetDetailsController.assetData ?? widget.assetData;
    final currentStatus =
        currentAssetData?['current_status']?.toString().toLowerCase();
    final currentUpdatedAt = currentAssetData?['updated_at'];

    // Fetch data dengan controller
    String assetCode = currentAssetData?['asset_code'] ?? widget.qrData;
    await _assetDetailsController.fetchAssetData(assetCode, context: context);

    // Pastikan data updated_at tetap ada setelah refresh untuk status dispose dan lost
    if (_assetDetailsController.assetData != null) {
      final newStatus = _assetDetailsController.assetData!['current_status']
          ?.toString()
          .toLowerCase();

      // Jika status adalah dispose atau lost, pastikan updated_at tetap ada
      if ((newStatus == 'dispose' || newStatus == 'lost') &&
          currentUpdatedAt != null &&
          _assetDetailsController.assetData!['updated_at'] == null) {
        _assetDetailsController.assetData!['updated_at'] = currentUpdatedAt;
      }
    }

    // Reset refresh controller
    _refreshController.refreshCompleted();

    // Increment refresh count
    _assetDetailsController.incrementRefreshCount();

    // Jika refresh counter mencapai 3, reset tampilan untuk mencegah zoom
    if (_assetDetailsController.refreshCount == 0 && mounted) {
      // Simpan data aset saat ini sebelum rebuild
      final currentAssetDataAfterRefresh = _assetDetailsController.assetData;

      // Trigger rebuild dengan sedikit delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  AssetDetails(
                qrData: widget.qrData,
                previousScreen: widget.previousScreen,
                assetData: currentAssetDataAfterRefresh ?? widget.assetData,
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

  // Fungsi untuk navigasi kembali ke layar sebelumnya
  void _navigateBack() {
    // Pop this screen from navigation history
    _dashboardController.popFromHistory();

    // Navigate to dashboard with home tab
    _dashboardController.setSelectedIndex(0); // Set tab ke beranda (index 0)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const DashboardScreen(initialIndex: 0),
      ),
      (route) => false,
    );
  }

  // Navigate to asset history screen with proper navigation tracking
  void _navigateToAssetHistory(Map<String, dynamic> assetData) {
    // Add history screen to navigation stack
    _dashboardController
        .pushToHistory('asset_history_${assetData['asset_code']}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssetHistory(
          assetData: assetData,
          qrData: widget.qrData,
          previousScreen: widget.previousScreen,
        ),
      ),
    );
  }

  // Navigate to asset document screen with proper navigation tracking
  void _navigateToAssetDocument(Map<String, dynamic> assetData) {
    // Add document screen to navigation stack
    _dashboardController
        .pushToHistory('asset_document_${assetData['asset_code']}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssetDocument(
          assetData: assetData,
          previousScreen: widget.previousScreen,
        ),
      ),
    );
  }

  // Navigate to asset mutation screen with proper navigation tracking
  void _navigateToAssetMutation(Map<String, dynamic> assetData) {
    // Add mutation screen to navigation stack
    _dashboardController
        .pushToHistory('asset_mutation_${assetData['asset_code']}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssetMutation(
          assetData: assetData,
          previousScreen: widget.previousScreen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssetDetailsController>(
      builder: (context, controller, _) {
        // Ambil data aset dari controller atau gunakan default jika null
        final assetData = controller.assetData ?? widget.assetData ?? {};

        // Debugging: Tampilkan informasi data aset untuk troubleshooting
        print('[DETAIL DEBUG] Data aset yang diterima: $assetData');
        print(
            '[DETAIL DEBUG] Current status dari API: ${assetData['current_status']}');

        // Debugging khusus untuk brand data
        print('[BRAND DEBUG] Checking brand data paths:');
        print(
            '[BRAND DEBUG] assetData[\'brand_name\'] (ROOT LEVEL): ${assetData['brand_name']}');
        print(
            '[BRAND DEBUG] assetData[\'asset_master\']?[\'brands\']?[\'brand_name\']: ${assetData['asset_master']?['brands']?['brand_name']}');
        print(
            '[BRAND DEBUG] assetData[\'asset_master\']?[\'brand\']?[\'brand_name\']: ${assetData['asset_master']?['brand']?['brand_name']}');
        print(
            '[BRAND DEBUG] assetData[\'brands\']?[\'brand_name\']: ${assetData['brands']?['brand_name']}');
        print(
            '[BRAND DEBUG] assetData[\'brand\']?[\'brand_name\']: ${assetData['brand']?['brand_name']}');
        print(
            '[BRAND DEBUG] controller.masterAssetData?[\'brand_name\']: ${controller.masterAssetData?['brand_name']}');
        print(
            '[BRAND DEBUG] Full asset_master data: ${assetData['asset_master']}');
        print(
            '[BRAND DEBUG] Full controller.masterAssetData: ${controller.masterAssetData}');

        final assetCode = assetData['asset_code'] ?? widget.qrData;

        // Perbaikan untuk mengambil nama aset dari berbagai sumber yang mungkin
        final assetName = assetData['asset_name'] ??
            assetData['asset_master']?['asset_name'] ??
            controller.masterAssetData?['asset_name'] ??
            'Tidak diketahui';

        final assetMasterCode = assetData['asset_master_code'] ?? '-';

        // Perbaikan untuk current_status - agar sesuai dengan database
        // Gunakan nilai dari database atau 'available' sebagai default yang aman
        final assetStatus =
            assetData['current_status']?.toString().toLowerCase() ??
                'available';
        print('[DETAIL DEBUG] Status yang akan digunakan: $assetStatus');

        // Cek apakah aset memiliki tanggal dihapuskan, jika ada dan valid, override status menjadi 'dispose'
        final disposalDate =
            assetData['disposal_date'] ?? assetData['disposed_at'] ?? '-';
        final String effectiveStatus =
            disposalDate != null && disposalDate != '-'
                ? 'dispose'
                : assetStatus;

        print(
            '[DETAIL DEBUG] Status efektif yang akan digunakan: $effectiveStatus');

        // Ambil data kondisi langsung dari API dan terjemahkan
        final conditionRaw = assetData['condition'] ?? '-';
        final condition = controller.getIndonesianCondition(conditionRaw);

        // Perbaikan untuk mengambil data brand dengan benar dari berbagai sumber yang mungkin
        // Prioritas berdasarkan struktur API sebenarnya: root level brand_name terlebih dahulu
        String brand = controller.masterAssetData?['brand_name'] ??
            assetData['brand_name'] ?? // ROOT LEVEL - sesuai dokumentasi API
            assetData['brands']?['brand_name'] ??
            assetData['asset_master']?['brands']?['brand_name'] ??
            assetData['asset_master']?['brand']?['brand_name'] ??
            assetData['asset_master']?['brand_name'] ??
            assetData['brand']?['brand_name'] ??
            '-';

        print('[BRAND DEBUG] Final brand value: $brand');

        final modelNumber = assetData['model_number'] ?? '-';
        final warrantyDate = assetData['warranty_end_date'] ?? '-';
        final serialNumber = assetData['serial_number'] ?? '-';
        final purchasePrice = assetData['purchase_cost'] != null
            ? controller.formatCurrency(assetData['purchase_cost'])
            : assetData['purchase_price'] != null
                ? controller.formatCurrency(assetData['purchase_price'])
                : '-';
        final purchaseDate = assetData['purchase_date'] != null
            ? controller.formatDate(assetData['purchase_date'])
            : '-';

        // Gunakan employee_number untuk penanggung jawab
        final userInCharge = assetData['employee_number'] != null &&
                assetData['employee_number'].toString().isNotEmpty
            ? assetData['employee_number'].toString()
            : assetData['responsible_user'] != null
                ? assetData['responsible_user']['name'] ??
                    'User ID: ${assetData['responsible_user']['user_id'] ?? '-'}'
                : '-';

        // Kategori dan subcategori
        final subCategory =
            assetData['subcategory']?['subcategory_name'] ?? '-';

        // Ambil data tipe aset langsung dari API dan terjemahkan
        final assetTypeRaw = assetData['subcategory']?['asset_type'] ?? '-';
        final assetType = controller.getIndonesianAssetType(assetTypeRaw);

        // Fix untuk lokasi ruangan dan gedung
        final locationName =
            assetData['room']?['room_name'] ?? assetData['room_name'] ?? '-';
        final buildingName = assetData['room']?['building']?['building_name'] ??
            assetData['building_name'] ??
            '-';
        final description = assetData['description'] ?? '-';

        // Mengambil jalur gambar dan membangun URL lengkap
        final imagePath = assetData['picture_path'];
        final qrCode = assetData['picture_path'] ?? assetData['qr_code'];
        final imageUrl = qrCode != null && qrCode.toString().isNotEmpty
            ? qrCode.toString().startsWith('http')
                ? qrCode
                : '${ApiConfig.baseUrl}/public/images/$qrCode'
            : '${ApiConfig.baseUrl}/public/images/placeholder.png';

        print('[DETAIL DEBUG] Image URL: $imageUrl');

        return WillPopScope(
          onWillPop: () async {
            // Navigasi kembali ke dashboard dengan tab beranda
            _dashboardController.popFromHistory();
            _dashboardController
                .setSelectedIndex(0); // Set tab ke beranda (index 0)
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(initialIndex: 0),
              ),
              (route) => false,
            );
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
              child: controller.isLoadingMasterData
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
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        print('Error loading image: $error');
                                        print('Image URL: $imageUrl');

                                        // Coba fallback ke placeholder jika URL utama gagal
                                        if (!imageUrl
                                            .contains('placeholder.png')) {
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
                                        if (loadingProgress == null)
                                          return child;
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              assetCode,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF213268),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              assetName,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF213268),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: controller
                                              .getStatusColor(effectiveStatus),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          controller
                                              .getStatusText(effectiveStatus),
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
                          if (effectiveStatus.toLowerCase() != 'lost' &&
                              effectiveStatus.toLowerCase() != 'dispose' &&
                              effectiveStatus.toLowerCase() != 'under repair')
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildActionButton(
                                    icon: effectiveStatus.toLowerCase() ==
                                            'check out'
                                        ? Icons.login
                                        : Icons.logout,
                                    label: effectiveStatus.toLowerCase() ==
                                            'check out'
                                        ? 'Kembali'
                                        : 'Pinjam',
                                    onTap: () async {
                                      if (effectiveStatus.toLowerCase() ==
                                          'check out') {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  CheckInScreen(
                                                      assetData: assetData)),
                                        );
                                        if (result != null &&
                                            result is Map<String, dynamic>) {
                                          controller.setAssetData(result);
                                        }
                                      } else {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  CheckoutScreen(
                                                      assetData: assetData)),
                                        );
                                        if (result != null &&
                                            result is Map<String, dynamic>) {
                                          controller.setAssetData(result);
                                        }
                                      }
                                    },
                                  ),
                                  _buildActionButton(
                                    icon: Icons.report_problem_outlined,
                                    label: 'Keluhan',
                                    onTap: () async {
                                      // Reset complaint form state first via provider
                                      Provider.of<AssetComplaintController>(
                                              context,
                                              listen: false)
                                          .resetState();

                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                AssetComplaintScreen(
                                                  assetData: assetData,
                                                  assetCode: assetCode,
                                                )),
                                      );
                                      if (result != null &&
                                          result is Map<String, dynamic>) {
                                        controller.setAssetData(result);
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
                                color: controller
                                    .getStatusBackgroundColor(effectiveStatus),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: controller
                                        .getStatusBorderColor(effectiveStatus)),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    controller.getStatusIcon(effectiveStatus),
                                    color: controller
                                        .getStatusColor(effectiveStatus),
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    controller.getStatusUnavailableMessage(
                                        effectiveStatus),
                                    style: TextStyle(
                                      color: controller
                                          .getStatusColor(effectiveStatus),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tidak dapat melakukan tindakan pada aset ini',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: controller
                                          .getStatusColor(effectiveStatus),
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
                                      fontFamily: 'Poppins',
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
                                        'Kode Master Asset',
                                        controller.masterAssetData?[
                                                'asset_master_code'] ??
                                            assetData['asset_master']
                                                ?['asset_master_code'] ??
                                            assetData['asset_master_code'] ??
                                            '-'),
                                    _buildTableRow(
                                        'Nama Master Asset',
                                        controller.masterAssetData?[
                                                'asset_name'] ??
                                            assetData['asset_master']
                                                ?['asset_name'] ??
                                            assetData['asset_master_name'] ??
                                            assetName),
                                    _buildTableRow(
                                        'Tipe Asset',
                                        controller.getIndonesianAssetType(
                                            controller.masterAssetData?[
                                                    'asset_type'] ??
                                                assetData['asset_master']
                                                    ?['asset_type'] ??
                                                assetData['subcategory']
                                                    ?['asset_type'] ??
                                                assetTypeRaw)),
                                    _buildTableRow(
                                        'Kategori',
                                        controller.masterAssetData?[
                                                'subcategory_name'] ??
                                            assetData['asset_master']
                                                ?['subcategory_name'] ??
                                            assetData['subcategory']
                                                ?['subcategory_name'] ??
                                            subCategory),
                                    _buildTableRow(
                                        'Merek',
                                        controller.masterAssetData?[
                                                'brand_name'] ??
                                            assetData['asset_master']?['brands']
                                                ?['brand_name'] ??
                                            assetData['asset_master']?['brand']
                                                ?['brand_name'] ??
                                            assetData['brands']
                                                ?['brand_name'] ??
                                            assetData['brand']?['brand_name'] ??
                                            brand),
                                    _buildTableRow(
                                        'Perlu Kalibrasi',
                                        controller.formatBoolean(
                                            controller.masterAssetData?[
                                                    'needs_calibration'] ??
                                                assetData['asset_master']
                                                    ?['needs_calibration'] ??
                                                false)),
                                    _buildTableRow(
                                        'Dapat Didepresiasi',
                                        controller.formatBoolean(
                                            controller.masterAssetData?[
                                                    'is_depreciable'] ??
                                                assetData['asset_master']
                                                    ?['is_depreciable'] ??
                                                false)),
                                    _buildTableRow(
                                        'Deskripsi',
                                        controller.masterAssetData?[
                                                'description'] ??
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
                                      fontFamily: 'Poppins',
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
                                        'Garansi Berakhir', warrantyDate),
                                    _buildTableRow('Nomor Seri', serialNumber),
                                    _buildTableRow(
                                        'Penanggung Jawab', userInCharge),
                                    _buildTableRow('Harga Beli', purchasePrice),
                                    _buildTableRow(
                                        'Tanggal Beli', purchaseDate),
                                    // Tampilkan tanggal dimusnahkan atau tanggal hilang berdasarkan status
                                    if (effectiveStatus.toLowerCase() ==
                                        'dispose')
                                      _buildTableRow(
                                          'Tanggal Dimusnahkan',
                                          assetData['updated_at'] != null
                                              ? controller.formatDate(
                                                  assetData['updated_at'])
                                              : '-')
                                    else if (effectiveStatus.toLowerCase() ==
                                        'lost')
                                      _buildTableRow(
                                          'Tanggal Hilang',
                                          assetData['updated_at'] != null
                                              ? controller.formatDate(
                                                  assetData['updated_at'])
                                              : '-'),
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
      },
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
                2,
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
              fontFamily: 'Poppins',
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
              fontFamily: 'Poppins',
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
              fontFamily: 'Poppins',
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
            () => _navigateToAssetDocument(widget.assetData ?? {}),
          ),
          _buildNavItem(
            Icons.history,
            'Riwayat',
            false,
            () => _navigateToAssetHistory(widget.assetData ?? {}),
          ),
          _buildNavItem(
            Icons.swap_horiz,
            'Mutasi',
            false,
            () => _navigateToAssetMutation(widget.assetData ?? {}),
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
                fontFamily: 'Poppins',
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
}
