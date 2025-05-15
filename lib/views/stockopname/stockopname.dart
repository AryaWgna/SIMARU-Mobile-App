import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pages/qr_scanner_screen.dart';
import 'dart:convert';
import '../../controllers/auth_controller.dart';
import 'stockopname_scanner.dart';

class Building {
  final int id;
  final String name;

  Building({required this.id, required this.name});

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Room {
  final int id;
  final String name;
  final int buildingId;

  Room({required this.id, required this.name, required this.buildingId});

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      buildingId: json['building_id'],
    );
  }
}

class StockOpname {
  final int opnameId;
  final String opnameCode;
  final int roomId;
  final String roomName;
  final int totalAssets;
  final int scannedAssets;

  StockOpname({
    required this.opnameId,
    required this.opnameCode,
    required this.roomId,
    required this.roomName,
    required this.totalAssets,
    required this.scannedAssets,
  });

  factory StockOpname.fromJson(Map<String, dynamic> json) {
    return StockOpname(
      opnameId: json['opname_id'],
      opnameCode: json['opname_code'],
      roomId: json['room_id'],
      roomName: json['room_name'],
      totalAssets: json['total_assets'],
      scannedAssets: json['scanned_assets'],
    );
  }
}

class StockopnameScreen extends StatefulWidget {
  const StockopnameScreen({super.key});

  @override
  State<StockopnameScreen> createState() => _StockopnameScreenState();
}

class _StockopnameScreenState extends State<StockopnameScreen> {
  Building? selectedBuilding;
  Room? selectedRoom;
  List<Building> buildings = [];
  List<Room> rooms = [];
  List<Room> filteredRooms = [];
  bool isLoadingBuildings = false;
  bool isLoadingRooms = false;
  bool isCreatingOpname = false;
  String? errorMessage;
  List<StockOpname> pendingOpnames = [];
  final TextEditingController buildingSearchController =
      TextEditingController();
  final TextEditingController roomSearchController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _fetchBuildings();
    _fetchPendingOpnames();
  }

  @override
  void dispose() {
    buildingSearchController.dispose();
    roomSearchController.dispose();
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

  Future<void> _fetchBuildings() async {
    setState(() {
      isLoadingBuildings = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.get('/buildings');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> buildingsJson = data['data'] ?? [];
          setState(() {
            buildings =
                buildingsJson.map((json) => Building.fromJson(json)).toList();
            isLoadingBuildings = false;
          });
        } else {
          // Gunakan data simulasi jika success tidak true
          setState(() {
            isLoadingBuildings = false;
            buildings = [
              Building(id: 1, name: 'Gedung Utama'),
              Building(id: 2, name: 'Gedung Rawat Inap'),
              Building(id: 3, name: 'Gedung Poliklinik'),
            ];
          });
        }
      } else {
        // Gunakan data simulasi jika status code bukan 200
        setState(() {
          isLoadingBuildings = false;
          buildings = [
            Building(id: 1, name: 'Gedung Utama'),
            Building(id: 2, name: 'Gedung Rawat Inap'),
            Building(id: 3, name: 'Gedung Poliklinik'),
          ];
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = null; // Tidak perlu menampilkan error di state
        isLoadingBuildings = false;

        // Simulasi data gedung untuk pengembangan
        buildings = [
          Building(id: 1, name: 'Gedung Utama'),
          Building(id: 2, name: 'Gedung Rawat Inap'),
          Building(id: 3, name: 'Gedung Poliklinik'),
        ];
      });

      // Hindari menampilkan error menggunakan snackbar
      // _showError('Gagal memuat daftar gedung: $e');
      print('Error saat memuat gedung: $e'); // Hanya log error
    }
  }

  Future<void> _fetchRoomsByBuilding(int buildingId) async {
    setState(() {
      isLoadingRooms = true;
      selectedRoom = null;
      rooms = [];
      filteredRooms = [];
      errorMessage = null;
      roomSearchController.clear();
    });

    try {
      final response = await ApiService.get('/rooms?building_id=$buildingId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> roomsJson = data['data'];
          setState(() {
            rooms = roomsJson.map((json) => Room.fromJson(json)).toList();
            filteredRooms = List.from(rooms);
            isLoadingRooms = false;
          });
        } else {
          // Gunakan data simulasi jika success tidak true
          _setSimulatedRooms(buildingId);
        }
      } else {
        // Gunakan data simulasi jika status code bukan 200
        _setSimulatedRooms(buildingId);
      }
    } catch (e) {
      // Gunakan data simulasi jika terjadi error
      _setSimulatedRooms(buildingId);

      // Hanya log error, tidak perlu menampilkan snackbar error
      print('Error saat memuat ruangan: $e');
    }
  }

  // Fungsi helper untuk mengeset data ruangan simulasi
  void _setSimulatedRooms(int buildingId) {
    setState(() {
      isLoadingRooms = false;

      // Simulasi data ruangan untuk pengembangan
      if (buildingId == 1) {
        rooms = [
          Room(id: 1, name: 'Ruang IGD', buildingId: 1),
          Room(id: 2, name: 'Ruang ICU-01', buildingId: 1),
          Room(id: 3, name: 'Ruang ICU-02', buildingId: 1),
        ];
      } else if (buildingId == 2) {
        rooms = [
          Room(id: 4, name: 'Kamar 101', buildingId: 2),
          Room(id: 5, name: 'Kamar 102', buildingId: 2),
          Room(id: 6, name: 'Kamar 201', buildingId: 2),
        ];
      } else {
        rooms = [
          Room(id: 7, name: 'Poli Umum', buildingId: 3),
          Room(id: 8, name: 'Poli Gigi', buildingId: 3),
          Room(id: 9, name: 'Poli Anak', buildingId: 3),
        ];
      }
      filteredRooms = List.from(rooms);
    });
  }

  void _filterRooms(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredRooms = List.from(rooms);
      } else {
        filteredRooms = rooms
            .where(
                (room) => room.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _fetchPendingOpnames() async {
    try {
      final response = await ApiService.get('/asset-opnames?status=pending');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> opnamesJson = data['data'];
          setState(() {
            pendingOpnames =
                opnamesJson.map((json) => StockOpname.fromJson(json)).toList();
          });
        } else {
          // Gunakan data simulasi jika success tidak true
          _setSimulatedPendingOpnames();
        }
      } else {
        // Gunakan data simulasi jika status code bukan 200
        _setSimulatedPendingOpnames();
      }
    } catch (e) {
      // Gunakan data simulasi untuk pengembangan jika terjadi error
      _setSimulatedPendingOpnames();

      // Hanya log error
      print('Error saat memuat pending opnames: $e');
    }
  }

  // Fungsi helper untuk mengeset data opname simulasi
  void _setSimulatedPendingOpnames() {
    setState(() {
      pendingOpnames = [
        StockOpname(
          opnameId: 1,
          opnameCode: 'OPN25040001',
          roomId: 2,
          roomName: 'ICU-01',
          totalAssets: 5,
          scannedAssets: 3,
        ),
      ];
    });
  }

  Future<StockOpname?> _createStockOpname(int roomId) async {
    setState(() {
      isCreatingOpname = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.post(
        '/asset-opnames',
        body: {'room_id': roomId},
        context: context,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Refresh daftar opname yang sedang berjalan
          _fetchPendingOpnames();

          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Stock opname berhasil dibuat'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom > 0 ? 90.0 : 70.0,
                left: 20.0,
                right: 20.0,
              ),
            ),
          );

          // Return data untuk diteruskan ke StockopnameScanner
          return StockOpname.fromJson(data['data']);
        } else {
          throw data['message'] ?? 'Gagal membuat stock opname';
        }
      } else {
        final data = jsonDecode(response.body);
        throw data['message'] ?? 'Gagal membuat stock opname';
      }
    } catch (e) {
      _showError('Gagal membuat stock opname: $e');
      return null;
    } finally {
      setState(() {
        isCreatingOpname = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hitung tinggi bottom navigation bar untuk padding
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomNavBarHeight = bottomPadding > 0 ? 90.0 : 70.0;

    return Scaffold(
      key: _scaffoldMessengerKey,
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: bottomNavBarHeight + 16, top: 16),
            child: Container(
              color: Colors.white,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF213268).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    const Color(0xFF213268).withOpacity(0.1)),
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
                              if (isLoadingBuildings)
                                const Center(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    // Pencarian gedung
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: TextField(
                                        controller: buildingSearchController,
                                        decoration: InputDecoration(
                                          hintText: 'Cari gedung...',
                                          border: InputBorder.none,
                                          prefixIcon: const Icon(
                                            Icons.search,
                                            color: Color(0xFF213268),
                                            size: 20,
                                          ),
                                          suffixIcon: buildingSearchController
                                                  .text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(
                                                    Icons.clear,
                                                    size: 18,
                                                    color: Colors.grey,
                                                  ),
                                                  onPressed: () {
                                                    buildingSearchController
                                                        .clear();
                                                    setState(() {});
                                                  },
                                                )
                                              : null,
                                          hintStyle: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 10),
                                        ),
                                        onChanged: (value) {
                                          setState(() {});
                                        },
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Gedung list
                                    _buildBuildingList(),
                                  ],
                                ),
                              if (selectedBuilding != null && isLoadingRooms)
                                const Padding(
                                  padding: EdgeInsets.only(top: 16.0),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                )
                              else if (selectedBuilding != null &&
                                  rooms.isNotEmpty) ...[
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: TextField(
                                    controller: roomSearchController,
                                    decoration: InputDecoration(
                                      hintText: 'Cari ruangan...',
                                      border: InputBorder.none,
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: Color(0xFF213268),
                                        size: 20,
                                      ),
                                      suffixIcon: roomSearchController
                                              .text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.clear,
                                                size: 18,
                                                color: Colors.grey,
                                              ),
                                              onPressed: () {
                                                roomSearchController.clear();
                                                _filterRooms('');
                                              },
                                            )
                                          : null,
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 10),
                                    ),
                                    onChanged: _filterRooms,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Room list
                                if (filteredRooms.isEmpty &&
                                    roomSearchController.text.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Tidak ada ruangan yang ditemukan',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    constraints: const BoxConstraints(
                                      maxHeight: 180,
                                    ),
                                    child: ListView.separated(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: filteredRooms.length,
                                      separatorBuilder: (context, index) =>
                                          Divider(
                                        height: 1,
                                        color: Colors.grey.shade200,
                                      ),
                                      itemBuilder: (context, index) {
                                        final room = filteredRooms[index];
                                        return ListTile(
                                          dense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 0),
                                          title: Text(
                                            room.name,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: Colors.black87,
                                              fontWeight:
                                                  selectedRoom?.id == room.id
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                          trailing: selectedRoom?.id == room.id
                                              ? const Icon(Icons.check_circle,
                                                  color: Color(0xFF213268),
                                                  size: 20)
                                              : null,
                                          onTap: () {
                                            setState(() {
                                              selectedRoom = room;
                                              roomSearchController.clear();
                                              _filterRooms('');
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                              ],
                              if (selectedRoom != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF213268)
                                        .withOpacity(0.1),
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
                                          'Lokasi: ${selectedBuilding!.name} - ${selectedRoom!.name}',
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
                                  onPressed: (isCreatingOpname ||
                                          selectedRoom == null)
                                      ? null
                                      : () async {
                                          final stockOpname =
                                              await _createStockOpname(
                                                  selectedRoom!.id);

                                          if (stockOpname != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    StockopnameScanner(
                                                  roomId: selectedRoom!.id,
                                                  roomName: selectedRoom!.name,
                                                  totalAssets:
                                                      stockOpname.totalAssets,
                                                  opnameId:
                                                      stockOpname.opnameId,
                                                  opnameCode:
                                                      stockOpname.opnameCode,
                                                  previousScreen: 'stockopname',
                                                ),
                                              ),
                                            ).then((result) {
                                              if (result == true) {
                                                // Refresh data setelah selesai scan
                                                _fetchPendingOpnames();
                                              }
                                            });
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF213268),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey,
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                  ),
                                  icon: isCreatingOpname
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.qr_code_scanner,
                                          size: 24),
                                  label: Text(
                                    isCreatingOpname
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
                        pendingOpnames.isEmpty
                            ? Center(
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
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: pendingOpnames.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final opname = pendingOpnames[index];
                                  return _buildOpnameCard(opname);
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpnameCard(StockOpname opname) {
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QRScannerScreen(
                          previousScreen: 'stockopname',
                        ),
                      ),
                    ).then((_) {
                      // Refresh data setelah kembali dari scan
                      _fetchPendingOpnames();
                    });
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

  Widget _buildBuildingList() {
    final filteredBuildings = buildings
        .where((building) => building.name
            .toLowerCase()
            .contains(buildingSearchController.text.toLowerCase()))
        .toList();

    if (filteredBuildings.isEmpty && buildingSearchController.text.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: Text(
          'Tidak ada gedung yang ditemukan',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    if (buildingSearchController.text.isEmpty && selectedBuilding != null) {
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
            selectedBuilding!.name,
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
                  setState(() {
                    selectedBuilding = null;
                    selectedRoom = null;
                  });
                },
                child: const Icon(Icons.close, color: Colors.grey, size: 20),
              ),
            ],
          ),
        ),
      );
    }

    if (buildingSearchController.text.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: Text(
          'Ketik untuk mencari gedung',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      constraints: const BoxConstraints(
        maxHeight: 180,
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: filteredBuildings.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final building = filteredBuildings[index];
          return ListTile(
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            title: Text(
              building.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: selectedBuilding?.id == building.id
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            trailing: selectedBuilding?.id == building.id
                ? const Icon(Icons.check_circle,
                    color: Color(0xFF213268), size: 20)
                : null,
            onTap: () {
              setState(() {
                selectedBuilding = building;
                selectedRoom = null;
                buildingSearchController.clear();
              });
              _fetchRoomsByBuilding(building.id);
            },
          );
        },
      ),
    );
  }

  Future<void> _loadData() async {
    await _fetchBuildings();
    await _fetchPendingOpnames();
  }
}
