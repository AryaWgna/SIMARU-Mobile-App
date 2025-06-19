import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pages/qr_scanner_screen.dart';
import 'dart:convert';
import 'dart:async';
import '../../controllers/auth_controller.dart' as auth;
import 'stockopname_scanner.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/stockopname_controller.dart';
import '../../models/stockopname_model.dart';
import 'package:drop_down_list/drop_down_list.dart';
import 'package:drop_down_list/model/selected_list_item.dart';

class StockopnameScreen extends StatefulWidget {
  const StockopnameScreen({super.key});

  @override
  State<StockopnameScreen> createState() => _StockopnameScreenState();
}

class _StockopnameScreenState extends State<StockopnameScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  late StockOpnameController _stockOpnameController;
  bool _firstLoad = true; // Untuk track apakah ini adalah load pertama

  // Tambahkan timer untuk debounce pencarian
  Timer? _buildingSearchDebounce;
  Timer? _roomSearchDebounce;

  @override
  void initState() {
    super.initState();
    _stockOpnameController =
        Provider.of<StockOpnameController>(context, listen: false);
    _loadData();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    // Pastikan untuk membatalkan timer debounce saat widget dihapus
    _buildingSearchDebounce?.cancel();
    _roomSearchDebounce?.cancel();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[900],
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom > 0 ? 90.0 : 70.0,
          left: 20.0,
          right: 20.0,
        ),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Tutup',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom > 0 ? 90.0 : 70.0,
          left: 20.0,
          right: 20.0,
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _firstLoad = true; // Set ke true saat mulai loading
      });

      await Future.wait([
        _stockOpnameController.fetchBuildings(context),
        _stockOpnameController.fetchPendingOpnames(context),
      ]);

      // Setelah data dimuat, tandai first load selesai
      setState(() {
        _firstLoad = false;
      });

      if (_refreshController.isRefresh) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      print('Error loading data: $e');

      setState(() {
        _firstLoad =
            false; // Pastikan _firstLoad diset false bahkan jika terjadi error
      });

      if (_refreshController.isRefresh) {
        _refreshController.refreshFailed();
      }
    }
  }

  // Navigasi ke halaman scanner
  void _navigateToScanner(int opnameId, String opnameCode, int roomId,
      String roomName, int totalAssets) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockopnameScanner(
          opnameId: opnameId,
          opnameCode: opnameCode,
          roomId: roomId,
          roomName: roomName,
          totalAssets: totalAssets,
          previousScreen: 'stockopname',
        ),
      ),
    ).then((_) {
      // Refresh data setelah kembali dari scan
      _stockOpnameController.fetchPendingOpnames(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Hitung tinggi bottom navigation bar untuk padding
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomNavBarHeight = bottomPadding > 0 ? 90.0 : 70.0;

    return Container(
      color: Colors.white,
      child: SmartRefresher(
        enablePullDown: true,
        enablePullUp: false,
        controller: _refreshController,
        onRefresh: _handleRefresh,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
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
              child: Consumer<StockOpnameController>(
                  builder: (context, controller, _) {
                return Container(
                  color: Colors.white,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        kBottomNavigationBarHeight -
                        MediaQuery.of(context).padding.top -
                        82,
                  ),
                  child: Stack(
                    children: [
                      // Main content
                      (_firstLoad &&
                              (controller.isLoadingBuildings ||
                                  controller.isLoadingRooms))
                          ? Skeletonizer(
                              enabled: true,
                              effect: ShimmerEffect(
                                baseColor: Colors.grey.shade300,
                                highlightColor: const Color(0xFFE5EFFF),
                              ),
                              child: _buildSkeletonContent(),
                            )
                          : _buildMainContent(controller),

                      // Help button
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: controller.error != null
                            ? FloatingActionButton(
                                heroTag: "helpBtn",
                                backgroundColor: Colors.orange,
                                child: const Icon(Icons.help_outline,
                                    color: Colors.white),
                                onPressed: () =>
                                    _showTroubleshootingDialog(controller),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF213268).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 200,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
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
    );
  }

  Widget _buildMainContent(StockOpnameController controller) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih gedung dan ruangan untuk memulai stock opname',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),

                // Building selection
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF213268).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF213268).withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gedung',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF213268),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (controller.error != null &&
                          controller.buildings.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Gagal memuat data gedung',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  controller.clearError();
                                  _loadData();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[800],
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  'Coba Lagi',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (!_firstLoad &&
                          controller.buildings.isEmpty &&
                          !controller.isLoadingBuildings)
                        Container(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          child: Text(
                            'Tidak ada gedung yang tersedia',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            // Pencarian gedung
                            _buildBuildingSearchField(controller),

                            const SizedBox(height: 8),

                            // Gedung list
                            _buildBuildingList(controller),
                          ],
                        ),
                      if (controller.selectedBuilding != null &&
                          controller.error != null &&
                          controller.rooms.isEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Gagal memuat data ruangan',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  controller.clearError();
                                  controller.fetchRoomsByBuilding(
                                      controller.selectedBuilding!.id, context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[800],
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  'Coba Lagi',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (controller.selectedBuilding != null &&
                          !controller.isLoadingRooms &&
                          controller.rooms.isEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          child: Text(
                            'Tidak ada ruangan yang tersedia di gedung ini',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else if (controller.selectedBuilding != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Ruangan',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF213268),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Pencarian ruangan
                        _buildRoomSearchField(controller),

                        const SizedBox(height: 8),

                        // Room list tidak perlu lagi ditampilkan karena sudah menggunakan dropdown
                      ],
                      if (controller.selectedRoom != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF213268).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF213268),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Lokasi: ${controller.selectedBuilding!.name} - ${controller.selectedRoom!.name}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF213268),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: (controller.isCreatingOpname ||
                                  controller.selectedRoom == null)
                              ? null
                              : () async {
                                  final stockOpname =
                                      await controller.createStockOpname(
                                    controller.selectedRoom!.id,
                                    context,
                                  );

                                  if (stockOpname != null) {
                                    // Tampilkan pesan sukses
                                    _showSuccess(
                                        'Stock opname berhasil dibuat');

                                    // Navigasi ke halaman scanner
                                    _navigateToScanner(
                                      stockOpname.opnameId,
                                      stockOpname.opnameCode,
                                      stockOpname.roomId,
                                      stockOpname.roomName,
                                      stockOpname.totalAssets,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF213268),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          icon: controller.isCreatingOpname
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.qr_code_scanner, size: 24),
                          label: Text(
                            controller.isCreatingOpname
                                ? 'Memproses...'
                                : 'Mulai Scan Stock Opname',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 24),

                // Pending opnames section
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Color(0xFF213268),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stock Opname Berlangsung',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF213268),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Pending opnames list
                if (controller.error != null &&
                    controller.pendingOpnames.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Gagal memuat data stock opname',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            controller.clearError();
                            controller.fetchPendingOpnames(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[800],
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            'Coba Lagi',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (controller.pendingOpnames.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada stock opname yang sedang berlangsung',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.pendingOpnames.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final opname = controller.pendingOpnames[index];
                      return _buildOpnameCard(opname, controller);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpnameCard(
      StockOpname opname, StockOpnameController controller) {
    final progress = opname.totalAssets > 0
        ? opname.scannedAssets / opname.totalAssets
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Stock Opname ${opname.roomName}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF213268),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Sedang Berlangsung',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.qr_code,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                opname.opnameCode,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Progress: ${opname.scannedAssets}/${opname.totalAssets} aset',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF213268)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _navigateToScanner(
                      opname.opnameId,
                      opname.opnameCode,
                      opname.roomId,
                      opname.roomName,
                      opname.totalAssets,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF213268),
                    minimumSize: const Size(double.infinity, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: Color(0xFF213268)),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.qr_code_scanner, size: 16),
                  label: Text(
                    'Lanjutkan Scan',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF213268),
                  minimumSize: const Size(100, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: const BorderSide(color: Color(0xFF213268)),
                  ),
                ),
                child: Text(
                  'Detail',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingList(StockOpnameController controller) {
    if (controller.selectedBuilding != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            controller.selectedBuilding!.name ?? 'Gedung Tidak Diketahui',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  color: Color(0xFF213268), size: 20),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  try {
                    // Pastikan kita reset pilihan ruangan terlebih dahulu
                    controller.resetRoomSelection();
                    controller.resetBuildingSelection();
                    setState(() {}); // Memastikan UI diperbarui
                  } catch (e) {
                    print('Error saat reset building selection: $e');
                    _showError(
                        'Terjadi kesalahan saat menghapus pilihan gedung');
                  }
                },
                child: const Icon(Icons.close, color: Colors.grey, size: 20),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      child: Text(
        'Klik untuk memilih gedung',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Modifikasi widget untuk pencarian gedung
  Widget _buildBuildingSearchField(StockOpnameController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () {
          _showBuildingDropdown(context, controller);
        },
        child: Row(
          children: [
            const Icon(
              Icons.business,
              color: Color(0xFF213268),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.selectedBuilding?.name ?? 'Pilih gedung...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: controller.selectedBuilding != null
                      ? Colors.black87
                      : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (controller.isLoadingBuildings)
              Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(6),
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            else if (controller.selectedBuilding != null)
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.grey,
                ),
                onPressed: () {
                  try {
                    // Pastikan kita reset pilihan ruangan terlebih dahulu
                    controller.resetRoomSelection();
                    controller.resetBuildingSelection();
                    setState(() {}); // Memastikan UI diperbarui
                  } catch (e) {
                    print('Error saat reset building selection: $e');
                    _showError(
                        'Terjadi kesalahan saat menghapus pilihan gedung');
                  }
                },
              )
            else
              const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF213268),
              ),
          ],
        ),
      ),
    );
  }

  // Modifikasi widget untuk pencarian ruangan
  Widget _buildRoomSearchField(StockOpnameController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: controller.selectedBuilding == null
            ? Colors.grey.shade100
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () {
          if (controller.selectedBuilding != null) {
            _showRoomDropdown(context, controller);
          }
        },
        child: Row(
          children: [
            const Icon(
              Icons.meeting_room,
              color: Color(0xFF213268),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.selectedRoom?.name ?? 'Pilih ruangan...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: controller.selectedRoom != null
                      ? Colors.black87
                      : controller.selectedBuilding == null
                          ? Colors.grey[400]
                          : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (controller.isLoadingRooms)
              Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(6),
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            else if (controller.selectedRoom != null)
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.grey,
                ),
                onPressed: () {
                  try {
                    controller.resetRoomSelection();
                    setState(() {}); // Memastikan UI diperbarui
                  } catch (e) {
                    print('Error saat reset room selection: $e');
                    _showError(
                        'Terjadi kesalahan saat menghapus pilihan ruangan');
                  }
                },
              )
            else if (controller.selectedBuilding != null)
              const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF213268),
              ),
          ],
        ),
      ),
    );
  }

  // Menampilkan dropdown untuk gedung
  void _showBuildingDropdown(
      BuildContext context, StockOpnameController controller) async {
    FocusScope.of(context).unfocus();

    // Reset state controller untuk menghindari data lama
    controller.resetSearch();

    // Ambil data gedung terlebih dahulu
    controller.fetchBuildings(context);

    // Status pencarian lokal
    bool isSearching = false;
    String currentQuery = '';

    // Custom bottom sheet dengan consumer untuk auto-refresh saat data berubah
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setSheetState) {
            return Consumer<StockOpnameController>(
              builder: (consumerContext, updatedController, _) {
                final ScrollController scrollController = ScrollController();

                // Add scroll listener for infinite scrolling
                if (!scrollController.hasListeners) {
                  scrollController.addListener(() {
                    if (scrollController.position.pixels >=
                            scrollController.position.maxScrollExtent - 200 &&
                        !updatedController.isLoadingMoreBuildings &&
                        updatedController.hasMoreBuildings) {
                      updatedController.loadMoreBuildings(context);
                    }
                  });
                }

                return DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.5,
                  maxChildSize: 0.9,
                  expand: false,
                  builder: (_, controller) {
                    return Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Text(
                                'Pilih Gedung',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF213268),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),

                        // Search bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              onChanged: (query) {
                                setSheetState(() {
                                  isSearching = true;
                                  currentQuery = query;
                                });

                                // Cancel previous debounce
                                if (_buildingSearchDebounce?.isActive ??
                                    false) {
                                  _buildingSearchDebounce!.cancel();
                                }

                                // Create new debounce
                                _buildingSearchDebounce = Timer(
                                    const Duration(milliseconds: 500), () {
                                  if (query.isNotEmpty) {
                                    print('Debounce search buildings: $query');
                                    updatedController.fetchBuildings(context,
                                        searchQuery: query);
                                  } else {
                                    // Jika query kosong, ambil semua gedung
                                    updatedController.fetchBuildings(context);
                                  }
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Cari gedung...',
                                prefixIcon: const Icon(Icons.search),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                suffixIcon: currentQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setSheetState(() {
                                            currentQuery = '';
                                          });
                                          // Reset text field
                                          FocusScope.of(context).unfocus();
                                          // Refresh data
                                          updatedController
                                              .fetchBuildings(context);
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Content - Skeleton or results
                        Expanded(
                          child: updatedController.isLoadingBuildings &&
                                  updatedController.buildings.isEmpty
                              ? _buildSkeletonList() // Skeleton loader saat loading awal
                              : updatedController.buildings.isEmpty &&
                                      !updatedController.isLoadingBuildings
                                  ? _buildEmptyResults(currentQuery)
                                  : _buildBuildingListWithLoadMore(
                                      updatedController,
                                      scrollController,
                                      context),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // Widget untuk menampilkan daftar gedung dengan load more
  Widget _buildBuildingListWithLoadMore(StockOpnameController controller,
      ScrollController scrollController, BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      itemCount:
          controller.buildings.length + (controller.hasMoreBuildings ? 1 : 0),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        // Tampilkan loader di item terakhir jika masih ada data
        if (index == controller.buildings.length) {
          return _buildLoadMoreIndicator();
        }

        final building = controller.buildings[index];
        final isSelected = controller.selectedBuilding?.id == building.id;

        return ListTile(
          title: Text(
            building.name ?? 'Gedung Tidak Diketahui',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            '${building.address}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: Color(0xFF213268))
              : null,
          onTap: () {
            controller.selectRoom(null); // Reset room selection
            controller.selectBuilding(building);
            controller.fetchRoomsByBuilding(building.id, context);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  // Widget untuk menampilkan indikator loading more
  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 8),
          Text(
            'Memuat gedung lainnya...',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan skeleton loading list
  Widget _buildSkeletonList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'Mencari gedung...',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Skeletonizer(
              enabled: true,
              effect: ShimmerEffect(
                baseColor: Colors.grey.shade300,
                highlightColor: const Color(0xFFE5EFFF),
              ),
              child: ListView.separated(
                itemCount: 6,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) => ListTile(
                  title: Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan hasil kosong
  Widget _buildEmptyResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            query.isEmpty
                ? 'Tidak ada gedung yang tersedia'
                : 'Tidak ditemukan gedung "$query"',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Menampilkan dropdown untuk ruangan
  void _showRoomDropdown(
      BuildContext context, StockOpnameController controller) async {
    FocusScope.of(context).unfocus();

    if (controller.selectedBuilding == null) {
      _showError('Pilih gedung terlebih dahulu');
      return;
    }

    // Reset state controller untuk menghindari data lama
    controller.resetSearch();

    // Ambil data ruangan terlebih dahulu jika belum ada
    if (controller.rooms.isEmpty) {
      controller.fetchRoomsByBuilding(controller.selectedBuilding!.id, context);

      // Tunggu hingga data selesai diambil
      await Future.delayed(const Duration(milliseconds: 500));

      // Jika masih loading atau error, tampilkan pesan
      if (controller.isLoadingRooms) {
        _showError('Sedang memuat data ruangan...');
        return;
      }

      if (controller.error != null) {
        _showError(controller.error!);
        return;
      }
    }

    // Konversi data ruangan ke format yang dibutuhkan oleh dropdown
    List<SelectedListItem<Room>> roomItems = controller.rooms
        .map((room) => SelectedListItem<Room>(
              data: room,
            ))
        .toList();

    // Jika tidak ada data ruangan, return
    if (roomItems.isEmpty) {
      _showError('Tidak ada data ruangan yang tersedia');
      return;
    }

    // Status pencarian lokal
    bool isSearching = false;
    String currentQuery = '';

    // Custom bottom sheet dengan consumer untuk auto-refresh saat data berubah
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setSheetState) {
            return Consumer<StockOpnameController>(
              builder: (consumerContext, updatedController, _) {
                // Update items jika ada perubahan data
                if (!isSearching || !updatedController.isLoadingRooms) {
                  roomItems = updatedController.rooms
                      .map((room) => SelectedListItem<Room>(
                            data: room,
                          ))
                      .toList();
                }

                return DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.5,
                  maxChildSize: 0.9,
                  expand: false,
                  builder: (_, scrollController) {
                    return Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Text(
                                'Pilih Ruangan',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF213268),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),

                        // Gedung yang dipilih
                        if (updatedController.selectedBuilding != null)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF213268).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.business,
                                    color: Color(0xFF213268),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Gedung: ${updatedController.selectedBuilding!.name}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF213268),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 8),

                        // Search bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              onChanged: (query) {
                                setSheetState(() {
                                  isSearching = true;
                                  currentQuery = query;
                                });

                                // Cancel previous debounce
                                if (_roomSearchDebounce?.isActive ?? false) {
                                  _roomSearchDebounce!.cancel();
                                }

                                // Create new debounce
                                _roomSearchDebounce = Timer(
                                    const Duration(milliseconds: 500), () {
                                  if (query.isNotEmpty) {
                                    print('Debounce search rooms: $query');
                                    updatedController.fetchRoomsByBuilding(
                                      updatedController.selectedBuilding!.id,
                                      context,
                                      searchQuery: query,
                                    );
                                  } else {
                                    // Jika query kosong, ambil semua ruangan
                                    updatedController.fetchRoomsByBuilding(
                                      updatedController.selectedBuilding!.id,
                                      context,
                                    );
                                  }
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Cari ruangan...',
                                prefixIcon: const Icon(Icons.search),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                suffixIcon: currentQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setSheetState(() {
                                            currentQuery = '';
                                          });
                                          // Reset text field
                                          FocusScope.of(context).unfocus();
                                          // Refresh data
                                          updatedController
                                              .fetchRoomsByBuilding(
                                            updatedController
                                                .selectedBuilding!.id,
                                            context,
                                          );
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Content - Skeleton or results
                        Expanded(
                          child: updatedController.isLoadingRooms
                              ? _buildRoomSkeletonList() // Skeleton loader saat loading
                              : roomItems.isEmpty
                                  ? _buildEmptyRoomResults(currentQuery)
                                  : ListView.separated(
                                      controller: scrollController,
                                      itemCount: roomItems.length,
                                      separatorBuilder: (context, index) =>
                                          const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final room = roomItems[index].data;
                                        final isSelected = updatedController
                                                .selectedRoom?.id ==
                                            room.id;

                                        return ListTile(
                                          title: Text(
                                            room.name ??
                                                'Ruangan Tidak Diketahui',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          trailing: isSelected
                                              ? const Icon(Icons.check_circle,
                                                  color: Color(0xFF213268))
                                              : null,
                                          onTap: () {
                                            updatedController.selectRoom(room);
                                            Navigator.pop(context);
                                          },
                                        );
                                      },
                                    ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // Widget untuk menampilkan skeleton loading list ruangan
  Widget _buildRoomSkeletonList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'Mencari ruangan...',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Skeletonizer(
              enabled: true,
              effect: ShimmerEffect(
                baseColor: Colors.grey.shade300,
                highlightColor: const Color(0xFFE5EFFF),
              ),
              child: ListView.separated(
                itemCount: 6,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) => ListTile(
                  title: Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan hasil kosong untuk ruangan
  Widget _buildEmptyRoomResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            query.isEmpty
                ? 'Tidak ada ruangan yang tersedia'
                : 'Tidak ditemukan ruangan "$query"',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Menangani refresh dengan lebih efisien
  Future<void> _handleRefresh() async {
    // Reset pencarian terlebih dahulu
    _stockOpnameController.resetSearch();

    // Tidak perlu menggunakan Skeletonizer saat refresh
    await _stockOpnameController.loadAllData(context);
    _refreshController.refreshCompleted();
  }

  // Dialog bantuan troubleshooting
  void _showTroubleshootingDialog(StockOpnameController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Bantuan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masalah terdeteksi:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(controller.error ?? 'Tidak dapat memuat data',
                style: GoogleFonts.poppins()),
            const SizedBox(height: 16),
            Text(
              'Solusi yang bisa dicoba:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildTroubleshootingStep('1. Pastikan koneksi internet aktif'),
            _buildTroubleshootingStep(
                '2. Pastikan Anda sudah login dengan benar'),
            _buildTroubleshootingStep('3. Coba refresh halaman'),
            _buildTroubleshootingStep('4. Restart aplikasi'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF213268),
            ),
            onPressed: () {
              Navigator.pop(context);
              _handleRefresh();
            },
            child: Text('Coba Lagi',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}
