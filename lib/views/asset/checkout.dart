import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic>? assetData;

  const CheckoutScreen({super.key, this.assetData});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final DateTime currentDate = DateTime.now();
  String? selectedBuilding;
  String? selectedRoom;
  TextEditingController notesController = TextEditingController();
  bool isEmployeeSelected = true; // Default ke Employee
  bool isLoading = false;
  String? errorMessage;
  final _storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> roomList = [];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    try {
      final response = await ApiService.get('/rooms', context: context);
      print('Room response: ${response.statusCode}');
      print('Room body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bool isSuccess =
            data['success'] == true || data['status'] == true;

        if (isSuccess && data['data'] != null) {
          setState(() {
            if (data['data'] is List) {
              roomList = List<Map<String, dynamic>>.from(data['data']);
              print('Rooms loaded: ${roomList.length}');
            }
          });
        } else {
          print('Failed to load rooms: ${data['message']}');
        }
      } else {
        print('Failed to load rooms: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching rooms: $e');
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _processCheckout() async {
    if (notesController.text.isEmpty) {
      setState(() {
        errorMessage = 'Catatan tidak boleh kosong';
      });
      return;
    }

    final assetId = widget.assetData?['asset_id'];
    if (assetId == null) {
      setState(() {
        errorMessage = 'ID aset tidak ditemukan';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      Map<String, dynamic> requestBody;

      if (isEmployeeSelected) {
        // Checkout ke karyawan - format sesuai dengan contoh
        requestBody = {
          "asset_id": assetId,
          "checkout_notes": notesController.text,
        };
      } else {
        // Checkout ke lokasi - format sesuai dengan contoh
        if (selectedRoom == null) {
          setState(() {
            isLoading = false;
            errorMessage = 'Silakan pilih ruangan';
          });
          return;
        }

        requestBody = {
          "asset_id": assetId,
          "room_id": int.parse(selectedRoom!),
          "checkout_notes": notesController.text,
        };
      }

      print('Sending checkout request: $requestBody');

      final response = await ApiService.post(
        '/asset-transfers/checkout',
        body: requestBody,
        context: context,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final bool isSuccess =
            data['success'] == true || data['status'] == true;

        if (isSuccess) {
          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Peminjaman berhasil'),
              backgroundColor: Color(0xFF213268),
            ),
          );

          // Modifikasi data status asset untuk diupdate
          if (widget.assetData != null) {
            final updatedAssetData =
                Map<String, dynamic>.from(widget.assetData!);
            updatedAssetData['current_status'] = 'check out';

            // Kembali ke halaman detail dengan data yang diperbarui
            Navigator.pop(context, updatedAssetData);
          } else {
            Navigator.pop(context, true); // Return true for success
          }
        } else {
          throw Exception(data['message'] ?? 'Peminjaman gagal');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(
            data['message'] ?? 'Peminjaman gagal: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(82),
        child: AppBar(
          backgroundColor: const Color(0xFF213268),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Center(
            child: Image.asset(
              'images/Logo_RS_UMMI_white.png',
              width: 208,
              height: 55,
            ),
          ),
          actions: const [
            SizedBox(width: 55),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(21),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PEMINJAMAN ASET',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF213268),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 25),

              // Asset Info
              if (widget.assetData != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asset: ${widget.assetData!['asset_name'] ?? 'Tidak diketahui'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF213268),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kode: ${widget.assetData!['asset_code'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 25),

              // Error message if any
              if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),

              // Tanggal checkout - fixed to today
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanggal Peminjaman',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: Color(0xFF757575)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(currentDate),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Radio Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pinjam Ke',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Radio(
                        value: true,
                        groupValue: isEmployeeSelected,
                        onChanged: (value) {
                          setState(() {
                            isEmployeeSelected = true;
                          });
                        },
                        activeColor: const Color(0xFF25B1FF),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const Text(
                        'Karyawan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 45),
                      Radio(
                        value: false,
                        groupValue: isEmployeeSelected,
                        onChanged: (value) {
                          setState(() {
                            isEmployeeSelected = false;
                          });
                        },
                        activeColor: const Color(0xFF25B1FF),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const Text(
                        'Lokasi',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Conditional content berdasarkan pemilihan
              if (!isEmployeeSelected) ...[
                // Room Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ruangan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: roomList.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              child: Text(
                                'Memuat data ruangan...',
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : DropdownButtonFormField<String>(
                              dropdownColor: Colors.white,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                border: InputBorder.none,
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              hint: const Text('Pilih Ruangan'),
                              value: selectedRoom,
                              icon: const Icon(Icons.arrow_drop_down),
                              isExpanded: true,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedRoom = newValue;
                                });
                              },
                              items: roomList
                                  .map<DropdownMenuItem<String>>((room) {
                                return DropdownMenuItem<String>(
                                  value: room['room_id'].toString(),
                                  child: Text(room['room_name'] ??
                                      'Ruangan Tidak Diketahui'),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],

              // Notes - border removed
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan catatan',
                      hintStyle: const TextStyle(color: Color(0xFF666666)),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [],
        ),
        padding: const EdgeInsets.only(left: 21, right: 21, bottom: 18),
        child: ElevatedButton(
          onPressed: isLoading ? null : _processCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF213268),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade500,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Pinjam',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
        ),
      ),
    );
  }
}
