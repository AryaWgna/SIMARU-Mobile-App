import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/scan/scan_result_controller.dart';
import '../../models/scan/scan_result_model.dart';
import '../../core/config/api_config.dart';

class ScanResultScreen extends StatefulWidget {
  final List<String>? scannedAssets;
  final String? roomName;
  final int opnameId;
  final String opnameCode;
  final int? scannedCount;

  const ScanResultScreen({
    super.key,
    this.scannedAssets,
    this.roomName,
    required this.opnameId,
    required this.opnameCode,
    this.scannedCount,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScanResultController _scanResultController;

  // Controller untuk input catatan
  final TextEditingController _notesController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scanResultController =
        Provider.of<ScanResultController>(context, listen: false);

    // Listener untuk mengubah tab
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    // Load data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanResultController.reset(); // Reset controller state after build
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await _scanResultController.loadScanResults(widget.opnameId);
    // Force refresh UI after data is loaded
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddNotesDialog(AssetScanDetail asset) {
    _notesController.text = asset.notes ?? '';
    bool _isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      isDismissible: !_isSaving, // Tidak bisa ditutup saat menyimpan
      enableDrag: !_isSaving, // Tidak bisa di-drag saat menyimpan
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Aset',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF213268),
                          ),
                        ),
                        Text(
                          asset.assetCode,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (!_isSaving)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Deskripsi Aset:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  asset.assetDescription,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Catatan:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(akan ditampilkan di detail aset)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _notesController,
                    enabled: !_isSaving,
                    decoration: InputDecoration(
                      hintText: 'Tambahkan catatan untuk aset ini...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    maxLines: 4,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                final notes = _notesController.text;

                                // Atur status menyimpan
                                setState(() {
                                  _isSaving = true;
                                });

                                final success = await _scanResultController
                                    .saveNotes(asset.detailId, notes, context);

                                if (success && mounted) {
                                  // Tutup dialog jika berhasil
                                  Navigator.pop(dialogContext);

                                  // Tampilkan pesan sukses
                                  ScaffoldMessenger.of(this.context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Catatan berhasil disimpan'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );

                                  // Perbarui UI
                                  this.setState(() {
                                    // Memaksa widget untuk memperbarui tampilan
                                  });
                                } else if (mounted) {
                                  // Reset status menyimpan jika gagal
                                  setState(() {
                                    _isSaving = false;
                                  });

                                  // Tampilkan pesan error
                                  ScaffoldMessenger.of(this.context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          _scanResultController.errorMessage ??
                                              'Gagal menyimpan catatan'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF213268),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        icon: _isSaving
                            ? Container(
                                width: 20,
                                height: 20,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _isSaving ? 'Menyimpan...' : 'Simpan Catatan',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanResultController>(builder: (context, controller, _) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'HASIL OPNAME',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF213268),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : controller.errorMessage != null
                ? _buildErrorView(controller.errorMessage!)
                : Column(
                    children: [
                      if (controller.summaryData != null)
                        _buildSummaryCard(controller),
                      // Tab Bar View
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          physics: _isInitialized
                              ? null
                              : const NeverScrollableScrollPhysics(),
                          children: [
                            _buildFoundAssetsList(controller),
                            _buildMissingAssetsList(controller),
                            _buildMisplacedAssetsList(controller),
                          ],
                        ),
                      ),
                    ],
                  ),
        backgroundColor: Colors.white,
        bottomNavigationBar: Container(
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF213268),
            labelColor: const Color(0xFF213268),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                icon: const Icon(Icons.list_alt),
                text: 'Ditemukan (${controller.foundAssets.length})',
                iconMargin: const EdgeInsets.only(bottom: 2),
              ),
              Tab(
                icon: const Icon(Icons.content_paste_search),
                text: 'Hilang (${controller.missingAssets.length})',
                iconMargin: const EdgeInsets.only(bottom: 2),
              ),
              Tab(
                icon: const Icon(Icons.help_outline),
                text: 'Pindah (${controller.misplacedAssets.length})',
                iconMargin: const EdgeInsets.only(bottom: 2),
              ),
            ],
            labelStyle: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    });
  }

  // Error view with retry button
  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF213268),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: Text(
                'Coba Lagi',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ScanResultController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Ringkasan Aset - ${controller.roomInfo?.roomName ?? widget.roomName ?? ""}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF213268),
                    ),
                    // Removed overflow and maxLines to allow wrapping
                  ),
                ),
                const SizedBox(width: 8),
                if (controller.opnameInfo != null)
                  Expanded(
                    flex: 2,
                    child: Text(
                      controller.opnameInfo!.opnameCode,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            if (controller.roomInfo?.building != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${controller.roomInfo!.building} - Lantai ${controller.roomInfo!.floor ?? ""}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  // Removed overflow to allow wrapping
                ),
              ),
            if (controller.opnameInfo != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Tanggal: ${_formatDateTime(controller.opnameInfo!.opnameCreatedAt)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  // Removed overflow to allow wrapping
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Aset',
                    controller.summaryData!.totalAssets.toString(),
                    Icons.inventory_2_outlined,
                  ),
                ),
                Expanded(
                  child: _buildBadgeItem(
                    'Ditemukan',
                    controller.summaryData!.foundAssets.toString(),
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildBadgeItem(
                    'Hilang',
                    controller.summaryData!.missingAssets.toString(),
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildBadgeItem(
                    'Pindah',
                    controller.summaryData!.misplacedAssets.toString(),
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF213268).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF213268), size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF213268),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFoundAssetsList(ScanResultController controller) {
    if (controller.foundAssets.isEmpty) {
      return _buildEmptyState("Tidak ada aset yang ditemukan");
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.foundAssets.length,
              itemBuilder: (context, index) {
                final asset = controller.foundAssets[index];
                return _buildAssetCard(
                  asset.assetCode,
                  asset.assetDescription,
                  "Ditemukan",
                  asset,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingAssetsList(ScanResultController controller) {
    if (controller.missingAssets.isEmpty) {
      return _buildEmptyState(
          "Tidak ada aset yang hilang di Lokasi yang dipilih");
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Hasil: ${controller.missingAssets.length} Aset",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.missingAssets.length,
              itemBuilder: (context, index) {
                final asset = controller.missingAssets[index];
                return _buildDetailedAssetCard(asset);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMisplacedAssetsList(ScanResultController controller) {
    if (controller.misplacedAssets.isEmpty) {
      return _buildEmptyState(
          "Tidak ada aset yang berpindah di Lokasi yang dipilih");
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Hasil: ${controller.misplacedAssets.length} Aset",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.misplacedAssets.length,
              itemBuilder: (context, index) {
                final asset = controller.misplacedAssets[index];
                return _buildDetailedAssetCard(asset);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssetCard(String assetId, String description, String status,
      AssetScanDetail asset) {
    // Periksa apakah aset memiliki catatan
    final bool hasNotes = asset.notes != null && asset.notes!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.black, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Asset Image at the top for found assets too
          _buildCompactAssetImage(asset),

          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.black.withOpacity(0.5), width: 0.5),
              ),
              child: const Icon(
                Icons.qr_code,
                color: Color(0xFF213268),
              ),
            ),
            title: Text(
              asset.assetName,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF213268),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assetId,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Description
                if (asset.description != null && asset.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      asset.description!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Brand and Model information
                if (asset.brandName != null || asset.model != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${asset.brandName ?? ''} ${asset.model ?? ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Serial Number
                if (asset.serialNumber != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.confirmation_number,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'SN: ${asset.serialNumber}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Category information
                if (asset.category != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.label,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            asset.category!,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Condition information
                if (asset.condition != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.build,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Kondisi: ${_getConditionDisplay(asset.condition)}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: _getConditionColor(asset.condition),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: Colors.black.withOpacity(0.3), width: 0.5),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                hasNotes ? Icons.edit_note : Icons.add_comment,
                color: const Color(0xFF213268),
              ),
              onPressed: () => _showAddNotesDialog(asset),
            ),
          ),

          // Additional asset details in compact format - Always show to include current location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                // First row: PIC and Condition
                if (asset.pic != null || asset.condition != null)
                  Row(
                    children: [
                      if (asset.pic != null)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'PIC: ${asset.pic!}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (asset.condition != null)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.build,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Kondisi: ${_getConditionDisplay(asset.condition)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                // Second row: Employee Name and Current Location (Always show current location)
                Padding(
                  padding: EdgeInsets.only(
                      top: (asset.pic != null || asset.condition != null)
                          ? 4
                          : 0),
                  child: Row(
                    children: [
                      if (asset.employeeName != null)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  asset.employeeName!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Always show current location for found assets
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Lokasi: ${_getCurrentLocation(asset)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tampilkan informasi kondisi untuk found assets
          if (asset.originalCondition != null || asset.condition != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  // Kondisi sebelumnya
                  if (asset.originalCondition != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          child: Icon(
                            Icons.history,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 70,
                          child: Text(
                            "Kondisi Awal:",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getConditionColor(asset.originalCondition)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color:
                                    _getConditionColor(asset.originalCondition)
                                        .withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _getConditionDisplay(asset.originalCondition),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color:
                                    _getConditionColor(asset.originalCondition),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Kondisi sekarang
                  if (asset.condition != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            child: Icon(
                              Icons.build,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 70,
                            child: Text(
                              "Kondisi Saat Ini:",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getConditionColor(asset.condition)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _getConditionColor(asset.condition),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getConditionDisplay(asset.condition),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getConditionColor(asset.condition),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Status perubahan kondisi
                  if (asset.originalCondition != null &&
                      asset.condition != null &&
                      asset.originalCondition!.toLowerCase() !=
                          asset.condition!.toLowerCase())
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.orange[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Kondisi telah diubah dari ${_getConditionDisplay(asset.originalCondition)} menjadi ${_getConditionDisplay(asset.condition)}",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // Tampilkan catatan dalam format yang sama dengan detail
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Icon(
                    Icons.note,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 70,
                  child: Text(
                    "Catatan:",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    hasNotes ? asset.notes! : "Tidak ada catatan",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontStyle: hasNotes ? FontStyle.normal : FontStyle.italic,
                      color: hasNotes ? Colors.black87 : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAssetCard(AssetScanDetail asset) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Asset Image at the top
          _buildAssetImage(asset),

          // Header with asset code and status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Kode Aset:",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        asset.assetCode,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF213268),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: asset.scanStatus == 'missing'
                              ? Colors.red
                              : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        asset.scanStatus == 'missing' ? "Hilang" : "Pindah",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: asset.scanStatus == 'missing'
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Basic Asset Information Section
          _buildDetailSection(
            'Informasi Dasar',
            [
              _buildDetailRow(Icons.inventory, 'Nama Aset:', asset.assetName),
              if (asset.description != null && asset.description!.isNotEmpty)
                _buildDetailRow(
                    Icons.description, 'Deskripsi:', asset.description!),
              if (asset.assetType != null)
                _buildDetailRow(Icons.category, 'Tipe Aset:',
                    _getAssetTypeDisplay(asset.assetType!)),
              if (asset.category != null)
                _buildDetailRow(Icons.label, 'Kategori:', asset.category!),
              if (asset.subcategoryName != null)
                _buildDetailRow(Icons.label_outline, 'Sub Kategori:',
                    asset.subcategoryName!),
              if (asset.currentStatus != null)
                _buildDetailRow(Icons.info, 'Status:',
                    _getAssetStatusDisplay(asset.currentStatus!)),
            ],
          ),

          const SizedBox(height: 16),

          // Condition Information Section
          _buildDetailSection(
            'Informasi Kondisi',
            [
              if (asset.originalCondition != null)
                _buildConditionDetailRow(Icons.history, 'Kondisi Sebelumnya:',
                    asset.originalCondition!),
              if (asset.condition != null)
                _buildConditionDetailRow(
                    Icons.build, 'Kondisi Sekarang:', asset.condition!),
              if (asset.originalCondition != null &&
                  asset.condition != null &&
                  asset.originalCondition!.toLowerCase() !=
                      asset.condition!.toLowerCase())
                _buildDetailRow(Icons.info_outline, 'Status Perubahan:',
                    'Kondisi telah diubah'),
            ],
          ),

          const SizedBox(height: 16),

          // Physical Details Section
          if (asset.brandName != null ||
              asset.model != null ||
              asset.serialNumber != null)
            _buildDetailSection(
              'Detail Fisik',
              [
                if (asset.brandName != null)
                  _buildDetailRow(Icons.business, 'Merk:', asset.brandName!),
                if (asset.model != null)
                  _buildDetailRow(Icons.settings, 'Model:', asset.model!),
                if (asset.serialNumber != null)
                  _buildDetailRow(Icons.confirmation_number, 'Serial Number:',
                      asset.serialNumber!),
              ],
            ),

          const SizedBox(height: 16),

          // Location Information Section
          _buildDetailSection(
            'Informasi Lokasi',
            [
              // Always show current location for all assets
              _buildDetailRow(Icons.location_on, 'Lokasi Sekarang:',
                  _getCurrentLocation(asset)),
              if (asset.roomName != null)
                _buildDetailRow(Icons.room, 'Ruangan:', asset.roomName!),
              if (asset.buildingName != null)
                _buildDetailRow(
                    Icons.apartment, 'Gedung:', asset.buildingName!),
              if (asset.floorNumber != null)
                _buildDetailRow(Icons.layers, 'Lantai:', asset.floorNumber!),
              _buildDetailRow(Icons.location_searching, 'Lokasi Diharapkan:',
                  asset.expectedLocationName ?? "-"),
              if (asset.expectedBuildingName != null)
                _buildDetailRow(Icons.apartment_outlined, 'Gedung Diharapkan:',
                    asset.expectedBuildingName!),
              if (asset.expectedFloorNumber != null)
                _buildDetailRow(Icons.layers_outlined, 'Lantai Diharapkan:',
                    asset.expectedFloorNumber!),
            ],
          ),

          const SizedBox(height: 16),

          // Employee/PIC Information Section
          if (asset.pic != null ||
              asset.employeeName != null ||
              asset.employeeNumber != null)
            _buildDetailSection(
              'Penanggung Jawab',
              [
                if (asset.pic != null)
                  _buildDetailRow(Icons.person, 'PIC:', asset.pic!),
                if (asset.employeeName != null)
                  _buildDetailRow(Icons.person_outline, 'Nama Karyawan:',
                      asset.employeeName!),
                if (asset.employeeNumber != null)
                  _buildDetailRow(
                      Icons.badge, 'No. Karyawan:', asset.employeeNumber!),
              ],
            ),

          const SizedBox(height: 16),

          // Purchase Information Section
          if (asset.purchaseDate != null ||
              asset.purchaseCost != null ||
              asset.warrantyEndDate != null)
            _buildDetailSection(
              'Informasi Pembelian',
              [
                if (asset.purchaseDate != null)
                  _buildDetailRow(Icons.calendar_today, 'Tanggal Beli:',
                      _formatDate(asset.purchaseDate!)),
                if (asset.purchaseCost != null)
                  _buildDetailRow(Icons.attach_money, 'Harga Beli:',
                      _formatCurrency(asset.purchaseCost!)),
                if (asset.warrantyEndDate != null)
                  _buildDetailRow(Icons.shield, 'Berakhir Garansi:',
                      _formatDate(asset.warrantyEndDate!)),
              ],
            ),

          const SizedBox(height: 16),

          // Asset Master Information Section
          if (asset.assetMasterCode != null ||
              asset.isDepreciable != null ||
              asset.needsCalibration != null)
            _buildDetailSection(
              'Informasi Master',
              [
                if (asset.assetMasterCode != null)
                  _buildDetailRow(
                      Icons.qr_code_2, 'Kode Master:', asset.assetMasterCode!),
                if (asset.isDepreciable != null)
                  _buildDetailRow(Icons.trending_down, 'Dapat Disusutkan:',
                      asset.isDepreciable! ? 'Ya' : 'Tidak'),
                if (asset.needsCalibration != null)
                  _buildDetailRow(Icons.tune, 'Perlu Kalibrasi:',
                      asset.needsCalibration! ? 'Ya' : 'Tidak'),
              ],
            ),

          const SizedBox(height: 16),

          // Scan Information Section
          _buildDetailSection(
            'Informasi Scan',
            [
              if (asset.scanDate != null)
                _buildDetailRow(Icons.calendar_today, 'Tanggal Scan:',
                    _formatScanDate(asset.scanDate!)),
              if (asset.scannerName != null)
                _buildDetailRow(
                    Icons.person_outline, 'Dipindai Oleh:', asset.scannerName!),
              _buildDetailRow(Icons.info_outline, 'Status Scan:',
                  _getScanStatusDisplay(asset.scanStatus)),
            ],
          ),

          const SizedBox(height: 16),

          // Timestamps Section
          if (asset.createdAt != null || asset.updatedAt != null)
            _buildDetailSection(
              'Riwayat',
              [
                if (asset.createdAt != null)
                  _buildDetailRow(Icons.add_circle, 'Dibuat:',
                      _formatScanDate(asset.createdAt!)),
                if (asset.updatedAt != null)
                  _buildDetailRow(Icons.update, 'Diperbarui:',
                      _formatScanDate(asset.updatedAt!)),
              ],
            ),

          const SizedBox(height: 16),

          // Notes Section
          _buildDetailSection(
            'Catatan',
            [
              _buildDetailRow(
                  Icons.note,
                  "Catatan:",
                  asset.notes != null && asset.notes!.isNotEmpty
                      ? asset.notes!
                      : "Tidak ada catatan"),
            ],
          ),

          // Add/Edit Notes Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _showAddNotesDialog(asset),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF213268),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF213268)),
                ),
              ),
              icon: Icon(
                asset.notes == null || asset.notes!.isEmpty
                    ? Icons.add_comment
                    : Icons.edit_note,
              ),
              label: Text(
                asset.notes == null || asset.notes!.isEmpty
                    ? "Tambah Catatan"
                    : "Edit Catatan",
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    // Cek apakah ini adalah baris catatan
    final bool isNoteRow = label == "Catatan:";
    final bool isEmptyNote = value == "Tidak ada catatan";

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Icon(
              icon,
              size: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                // Gunakan gaya khusus untuk catatan kosong
                fontStyle: isNoteRow && isEmptyNote
                    ? FontStyle.italic
                    : FontStyle.normal,
                color: isNoteRow && isEmptyNote ? Colors.grey : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: isNoteRow ? 5 : 2,
            ),
          ),
        ],
      ),
    );
  }

  // Build detail row specifically for condition display with color
  Widget _buildConditionDetailRow(
      IconData icon, String label, String condition) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Icon(
              icon,
              size: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getConditionColor(condition).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _getConditionColor(condition).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _getConditionDisplay(condition),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _getConditionColor(condition),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk memformat tanggal scan
  String _formatScanDate(String scanDateStr) {
    try {
      final scanDate = DateTime.parse(scanDateStr).toLocal();
      return "${scanDate.day}/${scanDate.month}/${scanDate.year} ${scanDate.hour}:${scanDate.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      print('Error parsing scan date: $e');
      return scanDateStr;
    }
  }

  // Helper untuk memformat tanggal
  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      print('Error parsing date time: $e');
      return dateTimeStr;
    }
  }

  // Helper method to build the asset image for AssetScanDetail
  Widget _buildAssetImage(AssetScanDetail asset) {
    final String? imageUrl = asset.referenceImagePath != null &&
            asset.referenceImagePath!.isNotEmpty
        ? asset.referenceImagePath!.startsWith('http')
            ? asset.referenceImagePath!
            : '${ApiConfig.baseUrl}/public/images/${_extractFilename(asset.referenceImagePath!)}'
        : null;

    if (imageUrl == null) {
      return const SizedBox.shrink(); // Don't show anything if no image
    }

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: const Color(0xFF213268),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Memuat gambar...',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Try fallback to placeholder if main URL fails
            if (!imageUrl.contains('placeholder.png')) {
              return Image.network(
                '${ApiConfig.baseUrl}/public/images/placeholder.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gambar tidak dapat dimuat',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gambar tidak tersedia',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper method to build a compact asset image for found assets
  Widget _buildCompactAssetImage(AssetScanDetail asset) {
    final String? imageUrl = asset.referenceImagePath != null &&
            asset.referenceImagePath!.isNotEmpty
        ? asset.referenceImagePath!.startsWith('http')
            ? asset.referenceImagePath!
            : '${ApiConfig.baseUrl}/public/images/${_extractFilename(asset.referenceImagePath!)}'
        : null;

    if (imageUrl == null) {
      return const SizedBox.shrink(); // Don't show anything if no image
    }

    return Container(
      width: double.infinity,
      height: 80, // Smaller height for compact view
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: const Color(0xFF213268),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Memuat gambar...',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Try fallback to placeholder if main URL fails
            if (!imageUrl.contains('placeholder.png')) {
              return Image.network(
                '${ApiConfig.baseUrl}/public/images/placeholder.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gambar tidak dapat dimuat',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gambar tidak tersedia',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper method to extract filename from path (following asset_details.dart pattern)
  String _extractFilename(String path) {
    // If path doesn't contain '/', return as is
    if (!path.contains('/')) return path;

    // If it's a full path, extract the filename
    return path.split('/').last;
  }

  String _getAssetTypeDisplay(String? assetType) {
    if (assetType == null) return 'Unknown';

    switch (assetType.toLowerCase()) {
      case 'medical':
        return 'Medis';
      case 'non_medical':
        return 'Non-Medis';
      case 'furniture':
        return 'Furniture';
      case 'electronic':
        return 'Electronic';
      case 'vehicle':
        return 'Vehicle';
      case 'building':
        return 'Building';
      case 'land':
        return 'Land';
      case 'other':
        return 'Other';
      default:
        return assetType;
    }
  }

  String _getConditionDisplay(String? condition) {
    if (condition == null) return 'Tidak Diketahui';

    switch (condition.toLowerCase()) {
      case 'good':
        return 'Baik';
      case 'damaged':
        return 'Rusak';
      default:
        return 'Tidak Diketahui';
    }
  }

  // Get color for condition display
  Color _getConditionColor(String? condition) {
    if (condition == null) return Colors.grey;

    switch (condition.toLowerCase()) {
      case 'good':
        return Colors.green;
      case 'damaged':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getAssetStatusDisplay(String? status) {
    if (status == null) return 'Unknown';

    switch (status.toLowerCase()) {
      case 'active':
        return 'Aktif';
      case 'inactive':
        return 'Tidak Aktif';
      case 'damaged':
        return 'Rusak';
      case 'lost':
        return 'Hilang';
      case 'retired':
        return 'Pensiun';
      default:
        return status;
    }
  }

  String _getScanStatusDisplay(String scanStatus) {
    if (scanStatus == 'found') return 'Ditemukan';
    if (scanStatus == 'missing') return 'Hilang';
    if (scanStatus == 'misplaced') return 'Pindah';
    return scanStatus;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      print('Error parsing date: $e');
      return dateStr;
    }
  }

  String _formatCurrency(String? costString) {
    if (costString == null || costString.isEmpty) return 'N/A';
    try {
      final cost = double.parse(costString);
      return "Rp ${cost.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";
    } catch (e) {
      return "Rp $costString";
    }
  }

  // Helper method to build detail sections (same as in stockopname_scanner.dart)
  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF213268).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF213268),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentLocation(AssetScanDetail asset) {
    // For found assets, current location is where they were scanned (the room being scanned)
    if (asset.scanStatus.toLowerCase() == 'found') {
      if (asset.actualLocationName != null &&
          asset.actualLocationName!.isNotEmpty) {
        return asset.actualLocationName!;
      } else if (widget.roomName != null && widget.roomName!.isNotEmpty) {
        return widget.roomName!; // Use the room being scanned
      } else if (asset.roomName != null && asset.roomName!.isNotEmpty) {
        return asset.roomName!;
      }
      return "Ditemukan di ruangan scan";
    }

    // For misplaced assets, show where they were actually found
    if (asset.scanStatus.toLowerCase() == 'misplaced') {
      if (asset.actualLocationName != null &&
          asset.actualLocationName!.isNotEmpty) {
        return asset.actualLocationName!;
      }
      return "Lokasi tidak diketahui";
    }

    // For missing assets, they are not found anywhere
    if (asset.scanStatus.toLowerCase() == 'missing') {
      return "Tidak ditemukan";
    }

    // Default fallback
    if (asset.actualLocationName != null &&
        asset.actualLocationName!.isNotEmpty) {
      return asset.actualLocationName!;
    } else if (asset.roomName != null && asset.roomName!.isNotEmpty) {
      return asset.roomName!;
    }

    return "Lokasi tidak diketahui";
  }
}
