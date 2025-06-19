import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/scan_result_controller.dart';
import '../../models/scan_result_model.dart';

class ScanResultScreen extends StatefulWidget {
  final List<String>? scannedAssets;
  final String? roomName;
  final int opnameId;
  final String opnameCode;

  const ScanResultScreen({
    super.key,
    this.scannedAssets,
    this.roomName,
    required this.opnameId,
    required this.opnameCode,
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scanResultController =
        Provider.of<ScanResultController>(context, listen: false);
    _scanResultController.reset(); // Reset controller state
    _scanResultController.loadScanResults(widget.opnameId);

    // Listener untuk mengubah tab
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddNotesDialog(AssetScanDetail asset) {
    _notesController.text = asset.notes ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
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
              Text(
                'Catatan:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
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
                      onPressed: () async {
                        Navigator.pop(context);
                        final success = await _scanResultController.saveNotes(
                            asset.detailId, _notesController.text, context);

                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Catatan berhasil disimpan'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          // Refresh data
                          _scanResultController
                              .loadScanResults(widget.opnameId);
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
                      icon: const Icon(Icons.save),
                      label: Text(
                        'Simpan Catatan',
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanResultController>(builder: (context, controller, _) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'SCAN RESULT',
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
                ? Center(child: Text(controller.errorMessage!))
                : Column(
                    children: [
                      if (controller.summaryData != null)
                        _buildSummaryCard(controller),
                      // Tab Bar View
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
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
            tabs: const [
              Tab(
                icon: Icon(Icons.list_alt),
                text: 'Semua',
                iconMargin: EdgeInsets.only(bottom: 2),
              ),
              Tab(
                icon: Icon(Icons.content_paste_search),
                text: 'Aset Hilang',
                iconMargin: EdgeInsets.only(bottom: 2),
              ),
              Tab(
                icon: Icon(Icons.help_outline),
                text: 'Aset Pindah',
                iconMargin: EdgeInsets.only(bottom: 2),
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
            Text(
              'Ringkasan Aset - ${controller.roomInfo?.roomName ?? widget.roomName ?? ""}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF213268),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.black, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: Colors.black.withOpacity(0.5), width: 0.5),
          ),
          child: const Icon(
            Icons.qr_code,
            color: Color(0xFF213268),
          ),
        ),
        title: Text(
          assetId,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF213268),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                if (asset.notes != null && asset.notes!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.note, size: 16, color: Colors.grey),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_note, color: Color(0xFF213268)),
          onPressed: () => _showAddNotesDialog(asset),
        ),
        onTap: () {
          // Open asset details if needed
        },
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        "ID Tag Aset: ",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        asset.assetCode,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF213268),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 0.5),
                  ),
                  child: Row(
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
          _buildDetailRow(
              Icons.description, "Deskripsi:", asset.assetDescription),
          _buildDetailRow(Icons.room, "Lokasi Tercatat:",
              asset.expectedLocationName ?? "-"),
          if (asset.scanStatus == 'misplaced' && asset.actualLocationId != null)
            _buildDetailRow(Icons.location_on, "Lokasi Sekarang:",
                "Room ID: ${asset.actualLocationId}"),
          if (asset.notes != null && asset.notes!.isNotEmpty)
            _buildDetailRow(Icons.note, "Catatan:", asset.notes!),
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
              icon: const Icon(Icons.edit_note),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
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
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
