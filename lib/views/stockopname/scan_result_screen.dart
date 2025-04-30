import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../core/config/api_config.dart';
import '../../controllers/auth_controller.dart' as auth;
import 'package:http/http.dart' as http;

class AssetScanDetail {
  final int detailId;
  final int opnameId;
  final String opnameCode;
  final int assetId;
  final String assetCode;
  final String assetDescription;
  final String? scanDate;
  final String scanStatus;
  final int? actualLocationId;
  final int? expectedLocationId;
  final String? expectedLocationName;
  final int? scannedBy;
  final String? scannerName;
  final String? notes;

  AssetScanDetail({
    required this.detailId,
    required this.opnameId,
    required this.opnameCode,
    required this.assetId,
    required this.assetCode,
    required this.assetDescription,
    this.scanDate,
    required this.scanStatus,
    this.actualLocationId,
    this.expectedLocationId,
    this.expectedLocationName,
    this.scannedBy,
    this.scannerName,
    this.notes,
  });

  factory AssetScanDetail.fromJson(Map<String, dynamic> json) {
    return AssetScanDetail(
      detailId: json['detail_id'],
      opnameId: json['opname_id'],
      opnameCode: json['opname_code'],
      assetId: json['asset_id'],
      assetCode: json['asset_code'],
      assetDescription: json['asset_description'],
      scanDate: json['scan_date'],
      scanStatus: json['scan_status'],
      actualLocationId: json['actual_location_id'],
      expectedLocationId: json['expected_location_id'],
      expectedLocationName: json['expected_location_name'],
      scannedBy: json['scanned_by'],
      scannerName: json['scanner_name'],
      notes: json['notes'],
    );
  }
}

class SummaryData {
  final int totalAssets;
  final int scannedAssets;
  final int foundAssets;
  final int missingAssets;
  final int misplacedAssets;

  SummaryData({
    required this.totalAssets,
    required this.scannedAssets,
    required this.foundAssets,
    required this.missingAssets,
    required this.misplacedAssets,
  });

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    return SummaryData(
      totalAssets: json['total_assets'],
      scannedAssets: json['scanned_assets'],
      foundAssets: json['found_assets'],
      missingAssets: json['missing_assets'],
      misplacedAssets: json['misplaced_assets'],
    );
  }
}

class RoomInfo {
  final int roomId;
  final String roomName;

  RoomInfo({required this.roomId, required this.roomName});

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      roomId: json['room_id'],
      roomName: json['room_name'],
    );
  }
}

class ScanResultScreen extends StatefulWidget {
  final List<String>? scannedAssets;
  final String? roomName;
  final int opnameId;
  final String opnameCode;

  const ScanResultScreen({
    Key? key,
    this.scannedAssets,
    this.roomName,
    required this.opnameId,
    required this.opnameCode,
  }) : super(key: key);

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data dari API
  List<AssetScanDetail> foundAssets = [];
  List<AssetScanDetail> missingAssets = [];
  List<AssetScanDetail> misplacedAssets = [];
  SummaryData? summaryData;
  RoomInfo? roomInfo;
  bool isLoading = true;
  String? errorMessage;

  // Controller untuk input catatan
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadScanResults();

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

  // Mengambil data scan dari API
  Future<void> _loadScanResults() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Ambil data untuk setiap status scan
      await Future.wait([
        _fetchAssetsByStatus('found'),
        _fetchAssetsByStatus('missing'),
        _fetchAssetsByStatus('misplaced'),
      ]);
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data: $e';
        isLoading = false;
      });
    }
  }

  // Mengambil data aset berdasarkan status scan
  Future<void> _fetchAssetsByStatus(String status) async {
    try {
      final response = await auth.ApiService.get(
        '/asset-opname-details/opname/${widget.opnameId}?scan_status=$status',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == true) {
          final List<dynamic> assetsJson = data['data'];
          final List<AssetScanDetail> assets =
              assetsJson.map((json) => AssetScanDetail.fromJson(json)).toList();

          // Simpan data summary dan room info saat first call
          if (summaryData == null && data['summary'] != null) {
            summaryData = SummaryData.fromJson(data['summary']);
          }

          if (roomInfo == null && data['room_info'] != null) {
            roomInfo = RoomInfo.fromJson(data['room_info']);
          }

          setState(() {
            if (status == 'found') {
              foundAssets = assets;
            } else if (status == 'missing') {
              missingAssets = assets;
            } else if (status == 'misplaced') {
              misplacedAssets = assets;
            }
            isLoading = false;
          });
        } else {
          throw data['message'] ?? 'Gagal memuat data';
        }
      } else {
        throw 'Error status code: ${response.statusCode}';
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data: $e';
        isLoading = false;
      });
    }
  }

  // Menyimpan catatan untuk aset
  Future<void> _saveNotes(int detailId, String notes) async {
    try {
      setState(() {
        isLoading = true;
      });

      // Memperbaiki endpoint dari /asset-opname-details/{opname_id}/notes menjadi /asset-opname-details/{detail_id}/notes
      final response = await auth.ApiService.put(
        '/asset-opname-details/${detailId}/notes',
        body: {
          'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Catatan berhasil disimpan'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh data
          await _loadScanResults();
        } else {
          throw data['message'] ?? 'Gagal menyimpan catatan';
        }
      } else {
        throw 'Error status code: ${response.statusCode}';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan catatan: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
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
                      onPressed: () {
                        Navigator.pop(context);
                        _saveNotes(asset.detailId, _notesController.text);
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : Column(
                  children: [
                    if (summaryData != null) _buildSummaryCard(),
                    // Tab Bar View
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildFoundAssetsList(),
                          _buildMissingAssetsList(),
                          _buildMisplacedAssetsList(),
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
              icon: Icon(Icons.list_alt),
              text: 'Semua',
              iconMargin: const EdgeInsets.only(bottom: 2),
            ),
            Tab(
              icon: Icon(Icons.content_paste_search),
              text: 'Aset Hilang',
              iconMargin: const EdgeInsets.only(bottom: 2),
            ),
            Tab(
              icon: Icon(Icons.help_outline),
              text: 'Aset Pindah',
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
  }

  Widget _buildSummaryCard() {
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
              'Ringkasan Aset - ${roomInfo?.roomName ?? widget.roomName ?? ""}',
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
                    summaryData!.totalAssets.toString(),
                    Icons.inventory_2_outlined,
                  ),
                ),
                Expanded(
                  child: _buildBadgeItem(
                    'Ditemukan',
                    summaryData!.foundAssets.toString(),
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildBadgeItem(
                    'Hilang',
                    summaryData!.missingAssets.toString(),
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildBadgeItem(
                    'Pindah',
                    summaryData!.misplacedAssets.toString(),
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

  Widget _buildFoundAssetsList() {
    if (foundAssets.isEmpty) {
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
              itemCount: foundAssets.length,
              itemBuilder: (context, index) {
                final asset = foundAssets[index];
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

  Widget _buildMissingAssetsList() {
    if (missingAssets.isEmpty) {
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
              "Hasil: ${missingAssets.length} Aset",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: missingAssets.length,
              itemBuilder: (context, index) {
                final asset = missingAssets[index];
                return _buildDetailedAssetCard(asset);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMisplacedAssetsList() {
    if (misplacedAssets.isEmpty) {
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
              "Hasil: ${misplacedAssets.length} Aset",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: misplacedAssets.length,
              itemBuilder: (context, index) {
                final asset = misplacedAssets[index];
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
                  Icon(Icons.note, size: 16, color: Colors.grey),
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
                  side: BorderSide(color: const Color(0xFF213268)),
                ),
              ),
              icon: Icon(Icons.edit_note),
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
