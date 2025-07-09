import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/asset/asset_mutation_controller.dart';
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
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  late AssetMutationController _mutationController;

  @override
  void initState() {
    super.initState();
    _mutationController =
        Provider.of<AssetMutationController>(context, listen: false);
    _fetchAssetStatusHistories();
  }

  void _onRefresh() async {
    // Fetch data dengan controller
    if (_getAssetId() != null) {
      await _mutationController.fetchAssetStatusHistories(_getAssetId()!,
          context: context);
    }

    // Reset refresh controller
    _refreshController.refreshCompleted();

    // Increment refresh count
    _mutationController.incrementRefreshCount();

    // Jika refresh counter mencapai 3, reset tampilan untuk mencegah zoom
    if (_mutationController.refreshCount == 0 && mounted) {
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

  String? _getAssetId() {
    if (widget.assetData == null) {
      _mutationController.setError('Data aset tidak tersedia');
      return null;
    }

    // Coba ambil asset_id dari berbagai properti yang mungkin
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
      _mutationController.setError('ID aset tidak ditemukan (asset_id)');
      return null;
    }

    return assetId;
  }

  Future<void> _fetchAssetStatusHistories({bool showLoading = true}) async {
    final assetId = _getAssetId();
    if (assetId != null) {
      await _mutationController.fetchAssetStatusHistories(assetId,
          context: context, showLoading: showLoading);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssetMutationController>(
      builder: (context, controller, _) {
        return Scaffold(
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
            child: controller.isLoading
                ? Skeletonizer(
                    enabled: true,
                    effect: ShimmerEffect(
                      baseColor: Colors.grey.shade300,
                      highlightColor: const Color(0xFFE5EFFF),
                    ),
                    child: _buildSkeletonLayout(),
                  )
                : controller.error != null
                    ? _buildErrorWidget(controller.error!)
                    : controller.statusHistories.isEmpty
                        ? _buildEmptyWidget()
                        : _buildStatusHistoryList(controller),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(context, 'mutasi'),
        );
      },
    );
  }

  // Format tanggal dari API
  String formatAPIDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    return _mutationController.formatAPIDate(dateString);
  }

  Widget _buildSkeletonLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          _buildSkeletonCard(),
          const SizedBox(height: 24),
          _buildSkeletonCard(),
          const SizedBox(height: 24),
          _buildSkeletonCard(),
        ],
      ),
    );
  }

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
          Container(
            padding: const EdgeInsets.only(left: 15, top: 14, bottom: 14),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 11),
                  decoration: const BoxDecoration(
                    color: Color(0xFF213268),
                    shape: BoxShape.circle,
                  ),
                ),
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
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey.shade200,
          ),
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

  Widget _buildSkeletonInfoRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
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

  Widget _buildErrorWidget(String errorMessage) {
    return Center(
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
              errorMessage,
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
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
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
    );
  }

  Widget _buildStatusHistoryList(AssetMutationController controller) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        overscroll: false,
      ),
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (overscroll) {
          overscroll.disallowIndicator();
          return true;
        },
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                ...controller.statusHistories.map<Widget>((history) {
                  final status =
                      history['status']?.toString().toLowerCase() ?? '';

                  switch (status) {
                    case 'checked out':
                      // Check if it's checkout to user/employee or location
                      final detailInfo =
                          history['detail_info'] as Map<String, dynamic>?;
                      if (detailInfo != null &&
                          detailInfo.containsKey('user')) {
                        return _buildCheckoutToEmployeeCard(history);
                      } else {
                        return _buildCheckoutCard(history);
                      }
                    case 'return':
                      return _buildReturnCard(history);
                    case 'loss':
                      return _buildLossCard(history);
                    case 'found':
                      return _buildFoundCard(history);
                    case 'dispose':
                      return _buildDisposeCard(history);
                    default:
                      return const SizedBox.shrink();
                  }
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutCard(Map<String, dynamic> history) {
    final detailInfo = history['detail_info'] as Map<String, dynamic>?;
    final location = detailInfo?['location'] as Map<String, dynamic>?;

    final checkoutDate =
        formatAPIDate(detailInfo?['checkout_date']?.toString());

    String locationInfo = '-';
    if (location != null) {
      final roomName = location['room_name']?.toString() ?? '';
      final floorNumber = location['floor_number']?.toString() ?? '';
      final buildingName = location['building_name']?.toString() ?? '';

      List<String> locationParts = [];
      if (buildingName.isNotEmpty) locationParts.add(buildingName);
      if (roomName.isNotEmpty) locationParts.add(roomName);
      if (floorNumber.isNotEmpty) locationParts.add('Lantai $floorNumber');

      locationInfo = locationParts.isNotEmpty ? locationParts.join(', ') : '-';
    }

    final notes = detailInfo?['checkout_notes']?.toString() ?? '-';

    return _buildStatusCard(
      title: 'DIPINJAM KE LOKASI',
      icon: Icons.logout,
      color: _mutationController.getStatusColor('CHECKED OUT'),
      children: [
        _buildInfoRow('Tanggal:', checkoutDate),
        const SizedBox(height: 12),
        _buildInfoRow('Ruangan:', location?['room_name']?.toString() ?? '-'),
        const SizedBox(height: 12),
        _buildInfoRow('Gedung:', location?['building_name']?.toString() ?? '-'),
        const SizedBox(height: 12),
        _buildInfoRow(
            'Lantai:',
            location?['floor_number'] != null
                ? 'Lantai ${location?['floor_number']}'
                : '-'),
        const SizedBox(height: 12),
        _buildInfoRow('Catatan:', notes),
      ],
    );
  }

  Widget _buildReturnCard(Map<String, dynamic> history) {
    final returnDate = formatAPIDate(history['return_date']?.toString());
    final notes = history['return_notes']?.toString() ?? '-';

    return _buildStatusCard(
      title: 'DIKEMBALIKAN',
      icon: Icons.arrow_back_outlined,
      iconWidget: Transform(
        alignment: Alignment.center,
        // Apply horizontal flip
        transform: Matrix4.rotationY(3.14159),
        child: const Icon(
          Icons.login,
          color: Color(0xFF203268),
          size: 24,
        ),
      ),
      color: _mutationController.getStatusColor('RETURN'),
      children: [
        _buildInfoRow('Tanggal Kembali:', returnDate),
        const SizedBox(height: 12),
        _buildInfoRow('Catatan:', notes),
      ],
    );
  }

  Widget _buildLossCard(Map<String, dynamic> history) {
    final lossDate = formatAPIDate(history['loss_date']?.toString());
    final notes = history['loss_notes']?.toString() ?? '-';

    return _buildStatusCard(
      title: 'HILANG',
      icon: Icons.report_problem_outlined,
      color: _mutationController.getStatusColor('LOSS'),
      children: [
        _buildInfoRow('Tanggal Hilang:', lossDate),
        const SizedBox(height: 12),
        _buildInfoRow('Catatan:', notes),
      ],
    );
  }

  Widget _buildFoundCard(Map<String, dynamic> history) {
    final foundDate = formatAPIDate(history['found_date']?.toString());
    final notes = history['found_notes']?.toString() ?? '-';

    return _buildStatusCard(
      title: 'DITEMUKAN',
      icon: Icons.check_circle_outlined,
      color: _mutationController.getStatusColor('FOUND'),
      children: [
        _buildInfoRow('Tanggal Ditemukan:', foundDate),
        const SizedBox(height: 12),
        _buildInfoRow('Catatan:', notes),
      ],
    );
  }

  Widget _buildDisposeCard(Map<String, dynamic> history) {
    final disposeDate = formatAPIDate(history['dispose_date']?.toString());
    final notes = history['dispose_notes']?.toString() ?? '-';

    return _buildStatusCard(
      title: 'DIHAPUSKAN',
      icon: Icons.delete_outline,
      iconWidget: const Icon(
        Icons.delete_outline,
        color: Color(0xFF203268),
        size: 24,
      ),
      color: _mutationController.getStatusColor('DISPOSE'),
      children: [
        _buildInfoRow('Tanggal Penghapusan:', disposeDate),
        const SizedBox(height: 12),
        _buildInfoRow('Catatan:', notes),
      ],
    );
  }

  Widget _buildCheckoutToEmployeeCard(Map<String, dynamic> history) {
    final detailInfo = history['detail_info'] as Map<String, dynamic>?;
    final user = detailInfo?['user'] as Map<String, dynamic>?;

    final checkoutDate =
        formatAPIDate(detailInfo?['checkout_date']?.toString());

    final employeeNumber = user?['employee_number']?.toString() ?? '-';
    final notes = detailInfo?['checkout_notes']?.toString() ?? '-';

    return _buildStatusCard(
      title: 'DIPINJAM KE KARYAWAN',
      icon: Icons.login,
      color: _mutationController.getStatusColor('CHECKED OUT'),
      children: [
        _buildInfoRow('Tanggal:', checkoutDate),
        const SizedBox(height: 12),
        _buildInfoRow('Dipinjam kepada:', employeeNumber),
        const SizedBox(height: 12),
        _buildInfoRow('No. Karyawan:', employeeNumber),
        const SizedBox(height: 12),
        _buildInfoRow('Catatan:', notes),
      ],
    );
  }

  Widget _buildStatusCard({
    required String title,
    required IconData icon,
    Widget? iconWidget,
    required Color color,
    required List<Widget> children,
  }) {
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
          Container(
            padding: const EdgeInsets.only(left: 15, top: 14, bottom: 14),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 11),
                  child: iconWidget ??
                      Icon(
                        icon,
                        color: const Color(0xFF203268),
                        size: 24,
                      ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: color,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFAAAAAA),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF757575),
              letterSpacing: 0.1,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
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
            activePage == 'mutasi',
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
}
