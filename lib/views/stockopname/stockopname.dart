import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../controllers/dashboard/dashboard_controller.dart';
import '../../utils/logger_util.dart';
import 'stockopname_scanner.dart';
import 'scan_result_screen.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:provider/provider.dart';
import '../../controllers/scan/stockopname_controller.dart';
import '../../models/scan/stockopname_model.dart';
import '../dashboard/dashboard.dart';

class StockopnameScreen extends StatefulWidget {
  const StockopnameScreen({super.key});

  @override
  State<StockopnameScreen> createState() => _StockopnameScreenState();
}

class _StockopnameScreenState extends State<StockopnameScreen> with RouteAware {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  late StockOpnameController _stockOpnameController;
  bool _firstLoad = true; // Untuk track apakah ini adalah load pertama
  bool _isRefreshing = false; // Untuk track apakah sedang refresh
  bool _isLoadingMoreBuildings = false; // Track load more state locally
  bool _isLoadingMoreRooms = false; // Track load more state for rooms

  // Tambahkan timer untuk debounce pencarian
  Timer? _buildingSearchDebounce;
  Timer? _roomSearchDebounce;

  @override
  void initState() {
    super.initState();
    // Set default locale for date formatting
    Intl.defaultLocale = 'id_ID';

    _stockOpnameController =
        Provider.of<StockOpnameController>(context, listen: false);

    // Defer state updates until after the build cycle is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFreshData();
    });
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
    LoggerUtil.d("Returned to StockopnameScreen");

    final dashboardController =
        Provider.of<DashboardController>(context, listen: false);
    // Make sure we're on the stockopname tab when returning to this screen
    if (dashboardController.selectedIndex != 1) {
      dashboardController.setSelectedIndex(1);
    }

    // Load fresh data seperti baru klik tab
    // Defer state updates until after the build cycle is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFreshData();
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
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

  Future<void> _loadData(
      {bool handleRefreshController = true, bool isRefresh = false}) async {
    try {
      if (!isRefresh) {
        setState(() {
          _firstLoad =
              true; // Set ke true saat mulai loading (kecuali saat refresh)
        });
      }

      await Future.wait([
        _stockOpnameController.fetchBuildings(context),
        _stockOpnameController.fetchPendingOpnames(context, resetList: true),
      ]);

      // Setelah data dimuat, tandai first load selesai
      if (!isRefresh) {
        setState(() {
          _firstLoad = false;
        });
      }

      if (handleRefreshController && _refreshController.isRefresh) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      print('Error loading data: $e');

      if (!isRefresh) {
        setState(() {
          _firstLoad =
              false; // Pastikan _firstLoad diset false bahkan jika terjadi error
        });
      }

      if (handleRefreshController && _refreshController.isRefresh) {
        _refreshController.refreshFailed();
      }
    }
  }

  // Method untuk load fresh data seperti baru klik tab di dashboard
  Future<void> _loadFreshData({bool fromRefresh = false}) async {
    try {
      // Reset semua state seperti baru masuk ke halaman
      if (fromRefresh) {
        setState(() {
          _isRefreshing = true;
          _firstLoad = true;
        });
      } else {
        setState(() {
          _firstLoad = true;
        });
      }

      // Reset semua controller state
      _stockOpnameController.clearError(); // Clear error state
      _stockOpnameController.resetSearch();
      _stockOpnameController.resetBuildingSelection();
      _stockOpnameController.resetRoomSelection();
      _stockOpnameController.resetItems(); // Reset scanned items

      // Clear local scanned counts cache yang mempengaruhi progress kartu
      _stockOpnameController.localScannedCounts.clear();

      // Reset pagination pending opnames ke halaman 1
      _resetPendingOpnamesPagination();

      // Load semua data dari awal
      await Future.wait([
        _stockOpnameController.fetchBuildings(context),
        _stockOpnameController.fetchPendingOpnames(context, resetList: true),
      ]);

      // Reset UI state setelah loading selesai
      setState(() {
        _firstLoad = false;
        if (fromRefresh) {
          _isRefreshing = false;
        }
      });

      if (fromRefresh) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      print('Error loading fresh data: $e');

      setState(() {
        _firstLoad = false;
        if (fromRefresh) {
          _isRefreshing = false;
        }
      });

      if (fromRefresh) {
        _refreshController.refreshFailed();
      }
    }
  }

  // Method untuk reset pagination pending opnames secara eksplisit
  void _resetPendingOpnamesPagination() {
    // Reset pagination state manually karena ada bug di fetchPendingOpnames
    // yang increment page bahkan saat resetList=true
    _stockOpnameController.resetPendingOpnamesPagination();
  }

  // Navigasi ke halaman scanner
  void _navigateToScanner(int opnameId, String opnameCode, int roomId,
      String roomName, int totalAssets) async {
    // Get building and floor info from server based on room ID
    String? buildingName;
    String? floorNumber;

    // First check if selectedBuilding is available (when creating new opname)
    if (_stockOpnameController.selectedBuilding?.name != null) {
      buildingName = _stockOpnameController.selectedBuilding!.name;
      print('DEBUG: Got building from selectedBuilding = $buildingName');
    }

    // Get building info from server based on room ID
    try {
      print(
          'DEBUG: Fetching room building info from server for roomId = $roomId');
      final roomBuildingInfo =
          await _stockOpnameController.fetchRoomBuildingInfo(roomId);

      final serverBuilding = roomBuildingInfo['building_name'];
      final serverFloor = roomBuildingInfo['floor_number'];

      print('DEBUG: Server building = $serverBuilding');
      print('DEBUG: Server floor = $serverFloor');

      // Use server data (more reliable than selectedBuilding)
      if (serverBuilding != null && serverBuilding.isNotEmpty) {
        buildingName = serverBuilding;
        print('DEBUG: Using building from server = $buildingName');
      }

      if (serverFloor != null && serverFloor.isNotEmpty) {
        floorNumber = serverFloor;
        print('DEBUG: Using floor from server = $floorNumber');
      }
    } catch (e) {
      print('DEBUG: Exception in fetchRoomBuildingInfo: $e');
    }

    print(
        'DEBUG: Final buildingName = $buildingName, floorNumber = $floorNumber');

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
          buildingName: buildingName,
          floorNumber: floorNumber,
        ),
      ),
    ).then((_) {
      // Refresh data setelah kembali dari scan
      _stockOpnameController.fetchPendingOpnames(context, resetList: true);
      // Also refresh the scanned items count for this specific opname
      _stockOpnameController.loadExistingScannedItems(opnameId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SmartRefresher(
        enablePullDown: true,
        enablePullUp: true, // Enable pull up for load more
        controller: _refreshController,
        onRefresh: _handleRefresh,
        onLoading: _handleLoadMore, // Add load more handler
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        footer: CustomFooter(
          builder: (BuildContext context, LoadStatus? mode) {
            Widget body;
            if (mode == LoadStatus.idle) {
              body = const SizedBox.shrink();
            } else if (mode == LoadStatus.loading) {
              body = const CircularProgressIndicator();
            } else if (mode == LoadStatus.failed) {
              body = const SizedBox.shrink();
            } else if (mode == LoadStatus.canLoading) {
              body = const SizedBox.shrink();
            } else {
              body = const SizedBox.shrink();
            }
            return Container(
              height: 55.0,
              child: Center(child: body),
            );
          },
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
                      (_firstLoad || _isRefreshing)
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
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                        style: GoogleFonts.poppins(
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
                                style: GoogleFonts.poppins(
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
                                  style: GoogleFonts.poppins(
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
                            style: GoogleFonts.poppins(
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
                                style: GoogleFonts.poppins(
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
                                  style: GoogleFonts.poppins(
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
                            style: GoogleFonts.poppins(
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
                          style: GoogleFonts.poppins(
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
                                  style: GoogleFonts.poppins(
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
                            style: GoogleFonts.poppins(
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

                // History opnames section
                Row(
                  children: [
                    const Icon(
                      Icons.history,
                      color: Color(0xFF213268),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Riwayat Stock Opname',
                      style: GoogleFonts.poppins(
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
                          'Gagal memuat Riwayat stock opname',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            controller.clearError();
                            controller.fetchPendingOpnames(context,
                                resetList: true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[800],
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            'Coba Lagi',
                            style: GoogleFonts.poppins(
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
                            'Tidak ada Riwayat stock opname',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpnameCard(
      StockOpname opname, StockOpnameController controller) {
    final localCount = controller.getLocalScannedCount(opname.opnameId);
    final progress =
        opname.totalAssets > 0 ? localCount / opname.totalAssets : 0.0;

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
          // Title without status badge
          Text(
            'Stock Opname ${opname.roomName}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF213268),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Date and time
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                opname.createdAt != null
                    ? DateFormat('dd MMM yyyy • HH:mm', 'id_ID')
                        .format(opname.createdAt!.toLocal())
                    : 'Tanggal tidak tersedia',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
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
                style: GoogleFonts.poppins(
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
                'Progress: ${controller.getLocalScannedCount(opname.opnameId)}/${opname.totalAssets} aset',
                style: GoogleFonts.poppins(
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
          // Tampilan seperti Riwayat - hanya tombol "Lihat Detail"
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigasi ke ScanResultScreen untuk melihat detail Riwayat
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScanResultScreen(
                          roomName: opname.roomName,
                          opnameId: opname.opnameId,
                          opnameCode: opname.opnameCode,
                        ),
                      ),
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
                  icon: const Icon(Icons.analytics, size: 16),
                  label: Text(
                    'Lihat Detail',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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
            style: GoogleFonts.poppins(
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
        style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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

    // Reset local state
    setState(() {
      _isLoadingMoreBuildings = false;
    });

    // Reset state controller untuk menghindari data lama
    controller.resetSearch();

    // Ambil data gedung terlebih dahulu
    await controller.fetchBuildings(context);

    // Status pencarian lokal
    String currentQuery = '';

    // Create a shared scroll controller outside of the consumer
    final ScrollController scrollController = ScrollController();

    // Custom bottom sheet dengan consumer untuk auto-refresh saat data berubah
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        // We'll set up the scroll listener in the StatefulBuilder

        return StatefulBuilder(
          builder: (builderContext, setSheetState) {
            return Consumer<StockOpnameController>(
              builder: (consumerContext, updatedController, _) {
                // Set up scroll listener in post-frame callback to ensure it's attached properly
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients) {
                    // Remove previous listeners to avoid duplicates
                    scrollController.removeListener(() {});

                    // Add the scroll listener
                    scrollController.addListener(() {
                      if (scrollController.position.pixels >=
                          scrollController.position.maxScrollExtent - 100) {
                        // Check if we can load more
                        if (!_isLoadingMoreBuildings &&
                            updatedController.hasMoreBuildings &&
                            !updatedController.isLoadingBuildings) {
                          LoggerUtil.d(
                              'Scroll threshold reached, loading more buildings');

                          // Set local loading state
                          setSheetState(() {
                            _isLoadingMoreBuildings = true;
                          });

                          // Load more data
                          updatedController
                              .loadMoreBuildings(context)
                              .then((_) {
                            // Reset local loading state
                            if (mounted) {
                              setSheetState(() {
                                _isLoadingMoreBuildings = false;
                              });
                            }
                          }).catchError((error) {
                            // Handle error and reset loading state
                            LoggerUtil.e('Error loading more buildings', error,
                                StackTrace.current);
                            if (mounted) {
                              setSheetState(() {
                                _isLoadingMoreBuildings = false;
                              });
                            }
                          });
                        }
                      }
                    });
                  }
                });

                return DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.5,
                  maxChildSize: 0.9,
                  expand: false,
                  builder: (_, controller) {
                    return NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        // Check if scrolling near the bottom
                        if (scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200) {
                          // Check if we can load more
                          if (!_isLoadingMoreBuildings &&
                              updatedController.hasMoreBuildings &&
                              !updatedController.isLoadingBuildings) {
                            LoggerUtil.d(
                                'NotificationListener: Loading more buildings');

                            // Set local loading state
                            setSheetState(() {
                              _isLoadingMoreBuildings = true;
                            });

                            // Load more data
                            updatedController
                                .loadMoreBuildings(context)
                                .then((_) {
                              // Reset local loading state
                              if (mounted) {
                                setSheetState(() {
                                  _isLoadingMoreBuildings = false;
                                });
                              }
                            }).catchError((error) {
                              // Handle error and reset loading state
                              LoggerUtil.e('Error loading more buildings',
                                  error, StackTrace.current);
                              if (mounted) {
                                setSheetState(() {
                                  _isLoadingMoreBuildings = false;
                                });
                              }
                            });
                          }
                        }
                        return false; // Allow the notification to continue
                      },
                      child: Column(
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Text(
                                  'Pilih Gedung',
                                  style: GoogleFonts.poppins(
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                onChanged: (query) {
                                  setSheetState(() {
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
                                      print(
                                          'Debounce search buildings: $query');
                                      // Reset pagination and clear previous results
                                      updatedController.searchBuildings(
                                          query, context);
                                    } else {
                                      // Jika query kosong, ambil semua gedung
                                      updatedController.fetchBuildings(context,
                                          resetList: true);
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
                                            // Refresh data with reset
                                            updatedController.resetSearch();
                                            updatedController.fetchBuildings(
                                                context,
                                                resetList: true);
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
                      ),
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
    // Add a placeholder to check building list length
    if (controller.buildings.isEmpty && !controller.isLoadingBuildings) {
      return _buildEmptyResults('');
    }

    // Show a different UI when we're loading more but already have some buildings
    final bool showLoadingMore =
        _isLoadingMoreBuildings && controller.hasMoreBuildings;

    return ListView.builder(
      controller: scrollController,
      // Add +1 for loading indicator if we're loading more or have more to load
      itemCount: controller.buildings.length +
          (controller.hasMoreBuildings || showLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show divider except for the last item if it's a loader
        if (index > 0 && index < controller.buildings.length) {
          return Column(
            children: [
              const Divider(height: 1),
              _buildBuildingItem(controller, index, context),
            ],
          );
        }

        // Tampilkan loader di item terakhir jika masih ada data atau sedang loading
        if (index == controller.buildings.length) {
          // Log to help debug
          LoggerUtil.d(
              'Showing loader at index $index, hasMore: ${controller.hasMoreBuildings}, isLoadingMore: $_isLoadingMoreBuildings');
          return _buildLoadMoreIndicator();
        }

        // Regular item
        return _buildBuildingItem(controller, index, context);
      },
    );
  }

  // Extracted building item widget for better organization
  Widget _buildBuildingItem(
      StockOpnameController controller, int index, BuildContext context) {
    // Safety check
    if (index >= controller.buildings.length) {
      return const SizedBox.shrink();
    }

    final building = controller.buildings[index];
    final isSelected = controller.selectedBuilding?.id == building.id;

    return ListTile(
      title: Text(
        building.name ?? 'Gedung Tidak Diketahui',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        '${building.address ?? ""}',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF213268))
          : null,
      onTap: () async {
        controller.selectRoom(null); // Reset room selection
        controller.selectBuilding(building);

        // Remove SnackBar and directly preload rooms
        await controller.preloadRoomsForBuilding(building.id, context);

        Navigator.pop(context);
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          if (_isLoadingMoreBuildings)
            Column(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF213268)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Memuat gedung lainnya...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            )
          else if (!_isLoadingMoreBuildings &&
              _stockOpnameController.hasMoreBuildings)
            Text(
              'Scroll untuk memuat lebih banyak gedung',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            )
          else
            Text(
              'Tidak ada gedung lagi',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
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
              style: GoogleFonts.poppins(
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
            style: GoogleFonts.poppins(
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

    // Reset local state
    setState(() {
      _isLoadingMoreRooms = false;
    });

    // Reset state controller untuk menghindari data lama
    controller.resetSearch();

    // Pastikan data ruangan sudah diambil sebelumnya saat memilih gedung
    // Tidak perlu menunggu loading lagi di sini

    // Status pencarian lokal
    String currentQuery = '';

    // Create a shared scroll controller
    final ScrollController scrollController = ScrollController();

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
                // Set up scroll listener in post-frame callback to ensure it's attached properly
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients) {
                    // Remove previous listeners to avoid duplicates
                    scrollController.removeListener(() {});

                    // Add the scroll listener
                    scrollController.addListener(() {
                      if (scrollController.position.pixels >=
                          scrollController.position.maxScrollExtent - 100) {
                        // Check if we can load more
                        if (!_isLoadingMoreRooms &&
                            !updatedController.isLoadingRooms) {
                          LoggerUtil.d(
                              'Scroll threshold reached, loading more rooms');

                          // Set local loading state
                          setSheetState(() {
                            _isLoadingMoreRooms = true;
                          });

                          // Load more data - currently no pagination for rooms, but structure is ready
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (mounted) {
                              setSheetState(() {
                                _isLoadingMoreRooms = false;
                              });
                            }
                          });
                        }
                      }
                    });
                  }
                });

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
                                'Pilih Ruangan',
                                style: GoogleFonts.poppins(
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
                                      style: GoogleFonts.poppins(
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
                                  currentQuery = query;
                                });

                                // Cancel previous debounce
                                if (_roomSearchDebounce?.isActive ?? false) {
                                  _roomSearchDebounce!.cancel();
                                }

                                // Create new debounce - filter locally instead of fetching
                                _roomSearchDebounce = Timer(
                                    const Duration(milliseconds: 300), () {
                                  if (query.isNotEmpty) {
                                    print('Filtering rooms locally: $query');
                                    // Filter rooms locally from preloaded data
                                    setSheetState(() {
                                      // Reset loading state
                                      _isLoadingMoreRooms = false;
                                    });
                                  } else {
                                    // If query is empty, show all rooms
                                    setSheetState(() {
                                      // Reset loading state
                                      _isLoadingMoreRooms = false;
                                    });
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
                                            // Reset loading state
                                            _isLoadingMoreRooms = false;
                                          });
                                          // Reset text field
                                          FocusScope.of(context).unfocus();
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Content - Results
                        Expanded(
                          child: updatedController.isLoadingRooms &&
                                  updatedController.rooms.isEmpty
                              ? _buildRoomSkeletonList() // Skeleton loader saat loading awal
                              : updatedController.rooms.isEmpty
                                  ? _buildEmptyRoomResults(currentQuery)
                                  : _buildRoomListWithLoadMore(
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
              style: GoogleFonts.poppins(
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
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan daftar ruangan dengan load more
  Widget _buildRoomListWithLoadMore(StockOpnameController controller,
      ScrollController scrollController, BuildContext context) {
    // Check if there are rooms to display
    if (controller.rooms.isEmpty && !controller.isLoadingRooms) {
      return _buildEmptyRoomResults('');
    }

    // Filter rooms based on current query if needed
    List<Room> filteredRooms = controller.rooms;

    return ListView.separated(
      controller: scrollController,
      itemCount: filteredRooms.length + (_isLoadingMoreRooms ? 1 : 0),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        // Show loader at the end if loading more
        if (index == filteredRooms.length) {
          return _buildRoomLoadMoreIndicator();
        }

        // Regular room item
        final room = filteredRooms[index];
        final isSelected = controller.selectedRoom?.id == room.id;

        return ListTile(
          title: Text(
            room.name ?? 'Ruangan Tidak Diketahui',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: Color(0xFF213268))
              : null,
          onTap: () {
            controller.selectRoom(room);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  // Widget untuk indikator loading ruangan
  Widget _buildRoomLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          if (_isLoadingMoreRooms)
            Column(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF213268)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Memuat ruangan lainnya...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            )
          else
            Text(
              'Tidak ada ruangan lagi',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  // Menangani refresh dengan lebih efisien - seperti baru klik tab
  Future<void> _handleRefresh() async {
    await _loadFreshData(fromRefresh: true);
  }

  Future<void> _handleLoadMore() async {
    try {
      // Only load more if there are more pending opnames to load
      if (_stockOpnameController.hasMorePendingOpnames) {
        await _stockOpnameController.loadMorePendingOpnames(context);
        _refreshController.loadComplete();
      } else {
        _refreshController.loadNoData();
      }
    } catch (e) {
      LoggerUtil.e('Error loading more pending opnames', e, StackTrace.current);
      _refreshController.loadFailed();
    }
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
