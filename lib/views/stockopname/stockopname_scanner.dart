import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'scan_result_screen.dart';
import '../../controllers/scan/stockopname_controller.dart';
import '../../controllers/scan/scan_result_controller.dart';
import 'stockopname_scanner_stub.dart';
import '../../utils/logger_util.dart';
import '../../models/scan/stockopname_model.dart';
import 'dart:math' as math;
import '../../controllers/auth/auth_controller.dart' as auth;
import '../../core/config/api_config.dart';

class StockopnameScanner extends StatefulWidget {
  final String previousScreen;
  final int roomId;
  final String roomName;
  final int totalAssets;
  final int opnameId;
  final String opnameCode;
  final String? buildingName;
  final String? floorNumber;

  const StockopnameScanner({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.totalAssets,
    required this.opnameId,
    required this.opnameCode,
    this.previousScreen = 'stockopname',
    this.buildingName,
    this.floorNumber,
  });

  @override
  State<StockopnameScanner> createState() => _StockopnameScannerState();
}

// Class untuk melukis garis scanner
class ScannerLinePainter extends CustomPainter {
  final double yOffset;

  ScannerLinePainter(this.yOffset);

  @override
  void paint(Canvas canvas, Size size) {
    // Hitung ukuran dan posisi scanner
    const double scannerSize = 250;
    final double scannerLeft = (size.width - scannerSize) / 2;
    final double scannerTop = (size.height - scannerSize) / 2;

    // Posisi garis scanner dengan animasi
    final double lineY = scannerTop + (scannerSize / 2) + yOffset;

    // Buat paint untuk garis
    final Paint paint = Paint()
      ..color = const Color(0xFF213268)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Gambar garis utama
    canvas.drawLine(
      Offset(scannerLeft, lineY),
      Offset(scannerLeft + scannerSize, lineY),
      paint,
    );
  }

  @override
  bool shouldRepaint(ScannerLinePainter oldDelegate) {
    return oldDelegate.yOffset != yOffset;
  }
}

// Class untuk overlay pemindai
class ScannerOverlayShape extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;
  final Color overlayColor;

  ScannerOverlayShape({
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
    required this.cutOutSize,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final cutOutLeft = (width - cutOutSize) / 2;
    final cutOutTop = (height - cutOutSize) / 2;
    final cutOutRect = Rect.fromLTWH(
      cutOutLeft,
      cutOutTop,
      cutOutSize,
      cutOutSize,
    );
    final cutOutRRectPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
      );

    // Draw overlay
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addPath(cutOutRRectPath, Offset.zero)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(backgroundPath, Paint()..color = overlayColor);

    // Draw border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Top left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft, cutOutTop + borderLength)
        ..lineTo(cutOutLeft, cutOutTop + borderRadius)
        ..arcToPoint(
          Offset(cutOutLeft + borderRadius, cutOutTop),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(cutOutLeft + borderLength, cutOutTop),
      borderPaint,
    );

    // Top right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft + cutOutSize - borderLength, cutOutTop)
        ..lineTo(cutOutLeft + cutOutSize - borderRadius, cutOutTop)
        ..arcToPoint(
          Offset(cutOutLeft + cutOutSize, cutOutTop + borderRadius),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(cutOutLeft + cutOutSize, cutOutTop + borderLength),
      borderPaint,
    );

    // Bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft + cutOutSize, cutOutTop + cutOutSize - borderLength)
        ..lineTo(cutOutLeft + cutOutSize, cutOutTop + cutOutSize - borderRadius)
        ..arcToPoint(
          Offset(
              cutOutLeft + cutOutSize - borderRadius, cutOutTop + cutOutSize),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(
            cutOutLeft + cutOutSize - borderLength, cutOutTop + cutOutSize),
      borderPaint,
    );

    // Bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft + borderLength, cutOutTop + cutOutSize)
        ..lineTo(cutOutLeft + borderRadius, cutOutTop + cutOutSize)
        ..arcToPoint(
          Offset(cutOutLeft, cutOutTop + cutOutSize - borderRadius),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(cutOutLeft, cutOutTop + cutOutSize - borderLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _StockopnameScannerState extends State<StockopnameScanner>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  dynamic controller;
  Timer? debounceTimer;
  late StockOpnameController _stockOpnameController;

  // Variable to control bottom sheet state
  bool _isBottomSheetOpen = false;

  // Animasi untuk scanner
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Debug logging untuk melihat data yang diterima
    LoggerUtil.i('StockopnameScanner initialized with:');
    LoggerUtil.i('  roomName = ${widget.roomName}');
    LoggerUtil.i('  buildingName = ${widget.buildingName}');
    LoggerUtil.i('  floorNumber = ${widget.floorNumber}');
    WidgetsBinding.instance.addObserver(this);
    _stockOpnameController =
        Provider.of<StockOpnameController>(context, listen: false);

    // Setup animasi naik turun
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation =
        Tween<double>(begin: -35.0, end: 35.0).animate(_animationController);

    // Load existing scanned items and room assets after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // First, load existing scanned items from API to sync state
      _stockOpnameController
          .loadExistingScannedItems(widget.opnameId)
          .then((_) {
        // Ensure local count is initialized properly after loading existing items
        if (!_stockOpnameController.localScannedCounts
            .containsKey(widget.opnameId)) {
          _stockOpnameController.setLocalScannedCount(
              widget.opnameId, _stockOpnameController.scannedItems.length);
        }
      });

      // Try to fetch room assets from the API
      try {
        _stockOpnameController
            .fetchRoomAssets(widget.roomId, widget.opnameId, context)
            .catchError((error) {
          // If API call fails, use mock data as fallback
          LoggerUtil.w(
              'Failed to fetch room assets, using mock data instead', error);
          _stockOpnameController.mockRoomAssets(widget.roomId, widget.opnameId);
        });
      } catch (e) {
        // Use mock data as fallback
        LoggerUtil.w(
            'Exception while setting up room assets, using mock data', e);
        _stockOpnameController.mockRoomAssets(widget.roomId, widget.opnameId);
      }
    });
  }

  @override
  void dispose() {
    disposeController(controller);
    debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    handleReassemble(controller);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null) return;

    if (state == AppLifecycleState.resumed) {
      if (controller is MobileScannerController) {
        controller.start();
      }
    } else {
      if (controller is MobileScannerController) {
        controller.stop();
      }
    }
  }

  void _onBarcodeDetect(String? code) {
    if (code == null) return;

    if (!_stockOpnameController.processingQR) {
      // Langsung proses QR tanpa debounce untuk respons yang lebih cepat
      if (code != _stockOpnameController.lastScannedCode) {
        _stockOpnameController.setScannedCode(code);
        // Gunakan post-frame callback untuk menghindari setState selama build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_stockOpnameController.isLoading) {
            _processScannedQR(code);
          }
        });
      }
    }
  }

  Future<void> _processScannedQR(String qrCode) async {
    _stockOpnameController.setProcessingQR(true);

    try {
      // Validate and extract asset code from QR
      final String assetCode = _extractAssetCode(qrCode);

      bool success = await _stockOpnameController.processScannedQR(
          assetCode, widget.opnameId, widget.roomId, context);

      if (success) {
        // Dapatkan aset yang baru di-scan dari controller
        final scannedAsset = _stockOpnameController.scannedItems
                .where((item) => item.assetCode == assetCode)
                .isNotEmpty
            ? _stockOpnameController.scannedItems
                .firstWhere((item) => item.assetCode == assetCode)
            : null;

        if (scannedAsset != null) {
          // Notifikasi sukses singkat
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aset berhasil dipindai: $assetCode'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom > 0 ? 90.0 : 70.0,
                left: 20.0,
                right: 20.0,
              ),
              duration: const Duration(seconds: 1),
            ),
          );

          // Tunggu sebentar kemudian tampilkan detail bottomsheet
          await Future.delayed(const Duration(milliseconds: 500));

          // Tampilkan bottomsheet detail untuk aset yang baru di-scan
          if (mounted) {
            _showAssetDetailBottomSheet(scannedAsset, isNewlyScanned: true);
          }
        } else {
          // Fallback jika aset tidak ditemukan di scanned items
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aset berhasil dipindai: $assetCode'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom > 0 ? 90.0 : 70.0,
                left: 20.0,
                right: 20.0,
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (_stockOpnameController.error != null) {
        _showError(_stockOpnameController.error!);
      }
    } catch (e) {
      // Handle exceptions from QR code extraction or processing
      _showError(e.toString().replaceAll('Exception: ', ''));
      LoggerUtil.e('Error processing QR code', e, StackTrace.current);
    } finally {
      _stockOpnameController.setProcessingQR(false);
    }
  }

  // Extract asset code from QR code, handling different formats
  String _extractAssetCode(String code) {
    if (code.trim().isEmpty) {
      throw Exception('Format kode QR tidak valid: kode kosong');
    }

    String assetCode;

    try {
      // First, try to handle standard asset code format directly
      if (code.contains('-') && !code.contains('/')) {
        // This looks like our asset code format (e.g., MD-LSEQ-250718-0008-0001)
        return code.trim();
      }

      // If it contains a slash, it might be a URL or path
      if (code.contains('/')) {
        try {
          // Try parsing as URL
          final uri = Uri.tryParse(code);

          if (uri != null && uri.pathSegments.isNotEmpty) {
            // Get the last path segment as the asset code
            final candidate = uri.pathSegments.last;

            // If the last segment looks like an asset code, use it
            if (candidate.contains('-')) {
              return candidate;
            }
          }

          // If not parsed as URL or doesn't have valid segments,
          // try extracting from the string directly
          final parts = code.split('/');
          for (int i = parts.length - 1; i >= 0; i--) {
            // Look for something that looks like an asset code
            if (parts[i].contains('-')) {
              return parts[i].trim();
            }
          }

          // If we couldn't find a part with dashes, just use the last part
          if (parts.isNotEmpty) {
            return parts.last.trim();
          }
        } catch (e) {
          // Fallback for any URL parsing issues
          final parts = code.split('/');
          if (parts.isNotEmpty) {
            return parts.last.trim();
          }
        }
      }

      // If none of the above methods worked, just return the trimmed code
      assetCode = code.trim();

      // Final check to ensure we don't return empty string
      if (assetCode.isEmpty) {
        throw Exception('Kode aset tidak valid: kode kosong');
      }

      LoggerUtil.d('Extracted asset code: $assetCode from QR: $code');
      return assetCode;
    } catch (e) {
      LoggerUtil.e('Error extracting asset code', e, StackTrace.current);
      if (e is FormatException) {
        throw Exception(
            'Format kode QR tidak valid: bukan format yang dikenali');
      }
      throw e; // Re-throw other exceptions
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[900],
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom > 0 ? 90.0 : 70.0,
          left: 20.0,
          right: 20.0,
        ),
      ),
    );
  }

  // Show the scanned assets list bottom sheet with real data
  void _showScannedItemsBottomSheet() {
    setState(() {
      _isBottomSheetOpen = true;
    });

    // Show loading state initially
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Immediately fetch real data from API
            _fetchRealOpnameData(context, setModalState);

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: _buildLoadingAssetsList(),
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        _isBottomSheetOpen = false;
      });
    });
  }

  // Fetch real room asset data using room_id
  void _fetchRealOpnameData(BuildContext context, StateSetter setModalState) {
    // Use controller method to get ALL assets in the room
    _stockOpnameController.fetchAllRoomAssets(widget.roomId).then((allAssets) {
      // When data is loaded, update the bottom sheet
      if (mounted) {
        setModalState(() {
          // Replace loading view with actual content
          showBottomSheetContentWithAllAssets(context, allAssets);
        });
      }
    }).catchError((error) {
      // Show error state
      print('Error loading data: $error');

      if (mounted) {
        setModalState(() {
          // Show error view
          showBottomSheetError(context, error.toString());
        });
      }
    });
  }

  // Show the bottom sheet content with tabs, using all assets from API
  void showBottomSheetContentWithAllAssets(
      BuildContext context, List<Map<String, dynamic>> allAssets) {
    Navigator.pop(context); // Close the loading sheet

    // Open a new sheet with the actual content
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: DefaultTabController(
            length: 2,
            child: Consumer<StockOpnameController>(
              builder: (context, controller, _) {
                final scannedItems = controller.scannedItems;

                // Get scanned asset codes for filtering
                final scannedAssetCodes = scannedItems
                    .map((item) => item.assetCode.toLowerCase().trim())
                    .toSet();

                LoggerUtil.d(
                    'Scanned asset codes (${scannedAssetCodes.length}): $scannedAssetCodes');
                LoggerUtil.d('Total assets from API: ${allAssets.length}');

                // Filter unscanned assets:
                // 1. Assets from API that are NOT in locally scanned items (for real-time update)
                // 2. Missing assets that should be displayed as "belum dipindai"
                final unscannedAssets = <StockOpnameItem>[];

                for (var asset in allAssets) {
                  final assetCode =
                      asset['asset_code']?.toString().toLowerCase().trim() ??
                          '';
                  final scanStatus =
                      asset['scan_status']?.toString().toLowerCase() ?? '';

                  // Add to unscanned if:
                  // 1. Asset code is NOT in locally scanned items AND has valid code
                  // 2. AND asset is NOT with processed status (missing, found, misplaced belong to scan results)
                  // 3. Focus on 'pending' status or unprocessed assets that should appear as "belum dipindai"
                  if (assetCode.isNotEmpty &&
                      !scannedAssetCodes.contains(assetCode) &&
                      (scanStatus == 'pending' ||
                          scanStatus == '' ||
                          scanStatus == 'unknown')) {
                    // For unscanned assets, set pending status
                    String displayStatus = 'pending';
                    String displayName =
                        asset['asset_name']?.toString() ?? 'Unknown Asset';

                    unscannedAssets.add(StockOpnameItem(
                      assetId: asset['asset_id'] ?? 0,
                      assetCode: asset['asset_code']?.toString() ?? '',
                      assetName: displayName,
                      location: asset['actual_location_name']?.toString() ??
                          widget.roomName,
                      condition: asset['condition']?.toString() ?? 'unknown',
                      currentStatus: displayStatus,
                      scanTime: asset['scan_date'] != null
                          ? DateTime.tryParse(asset['scan_date']) ??
                              DateTime.now()
                          : DateTime.now(),
                      notes: asset['notes']?.toString(),
                    ));
                  }
                }

                LoggerUtil.d(
                    'Filtered unscanned assets: ${unscannedAssets.length}');
                for (var asset in unscannedAssets.take(5)) {
                  LoggerUtil.d(
                      'Unscanned asset: ${asset.assetCode} - ${asset.assetName} (${asset.currentStatus})');
                }

                // Count assets by scan status for display
                final scannedCount = scannedItems.length;
                final unscannedCount = unscannedAssets.length;

                // Calculate total assets
                final totalAssets = allAssets.length;

                // Calculate progress percentage
                final progressPercentage = totalAssets > 0
                    ? (scannedItems.length / totalAssets * 100)
                        .toStringAsFixed(0)
                    : "0";

                LoggerUtil.d(
                    'Summary - Total: $totalAssets, Scanned: $scannedCount, Unscanned: $unscannedCount');

                return Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Aset Ruangan',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF213268),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 40),
                                    child: Text(
                                      widget.roomName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      // Removed overflow and maxLines to allow wrapping
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  // Refresh button
                                  IconButton(
                                    icon: const Icon(Icons.refresh,
                                        color: Color(0xFF213268)),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showScannedItemsBottomSheet(); // Reload the bottom sheet
                                    },
                                  ),
                                  // Close button
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.grey),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        _isBottomSheetOpen = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Progress indicator
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progress: $scannedCount/$totalAssets',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      '$progressPercentage%',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF213268),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: totalAssets > 0
                                      ? scannedCount / totalAssets
                                      : 0,
                                  backgroundColor: Colors.grey[200],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF213268)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab bar
                    TabBar(
                      labelColor: const Color(0xFF213268),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF213268),
                      tabs: [
                        Tab(
                          text: 'Sudah Dipindai ($scannedCount)',
                          icon: const Icon(Icons.check_circle_outline),
                        ),
                        Tab(
                          text: 'Belum Dipindai ($unscannedCount)',
                          icon: const Icon(Icons.pending_actions),
                        ),
                      ],
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // Content
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Scanned assets
                          _buildScannedAssetsList(scannedItems, controller),

                          // Tab 2: Unscanned assets (filtered to exclude already scanned)
                          _buildUnscannedAssetsList(
                              unscannedAssets, controller),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    ).then((_) {
      setState(() {
        _isBottomSheetOpen = false;
      });
    });
  }

  // Show error in the bottom sheet
  void showBottomSheetError(BuildContext context, String error) {
    Navigator.pop(context); // Close the loading sheet

    // Show error sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gagal Memuat Data',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _isBottomSheetOpen = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Gagal memuat data aset',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          error,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showScannedItemsBottomSheet(); // Retry loading
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF213268),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          'Coba Lagi',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      setState(() {
        _isBottomSheetOpen = false;
      });
    });
  }

  // Update _getStatusBadge to match scan_result_screen colors
  Widget _getStatusBadge(String status) {
    Color badgeColor;
    String displayStatus;

    switch (status.toLowerCase()) {
      case 'found':
        badgeColor = Colors.green;
        displayStatus = 'Ditemukan';
        break;
      case 'missing':
        badgeColor = Colors.red;
        displayStatus = 'Hilang';
        break;
      case 'misplaced':
        badgeColor = Colors.orange;
        displayStatus = 'Pindah';
        break;
      case 'good':
        badgeColor = Colors.green;
        displayStatus = 'Baik';
        break;
      case 'damaged':
        badgeColor = Colors.orange;
        displayStatus = 'Rusak';
        break;
      case 'pending':
        badgeColor = Colors.amber[700]!;
        displayStatus = 'Belum Dipindai';
        break;
      default:
        badgeColor = Colors.blue;
        displayStatus = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor),
      ),
      child: Text(
        displayStatus,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: badgeColor,
        ),
      ),
    );
  }

  // Build loading assets list
  Widget _buildLoadingAssetsList() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aset Ruangan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF213268),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isBottomSheetOpen = false;
                  });
                },
              ),
            ],
          ),
        ),

        // Loading indicator
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF213268)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Memuat daftar aset...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Build list of scanned assets
  Widget _buildScannedAssetsList(
      List<StockOpnameItem> items, StockOpnameController controller) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada aset yang dipindai',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        final timeFormatted = _formatTime(item.scanTime);

        return Dismissible(
          key: Key(item.assetCode),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
            ),
          ),
          onDismissed: (direction) {
            controller.removeItem(item.assetCode);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.assetCode} dihapus'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: InkWell(
            onTap: () => _showAssetDetailBottomSheet(item),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add asset image/thumbnail section for scanned assets - Always show for consistency
                  Container(
                    width: double.infinity,
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildAssetThumbnail(item),
                    ),
                  ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF213268).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.qr_code,
                          color: Color(0xFF213268),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.assetName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF213268),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.assetCode,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            if (item.brandName != null || item.model != null)
                              const SizedBox(height: 2),
                            if (item.brandName != null || item.model != null)
                              Text(
                                '${item.brandName ?? ''} ${item.model ?? ''}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _getStatusBadge(item.currentStatus),
                          const SizedBox(height: 4),
                          Text(
                            'Dipindai: $timeFormatted',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (item.serialNumber != null || item.category != null)
                    const SizedBox(height: 8),
                  if (item.serialNumber != null || item.category != null)
                    Row(
                      children: [
                        if (item.serialNumber != null)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.confirmation_number,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'SN: ${item.serialNumber}',
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
                        if (item.category != null)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.label,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.category!,
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap untuk detail lengkap',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Build list of unscanned assets
  Widget _buildUnscannedAssetsList(
      List<StockOpnameItem> items, StockOpnameController controller) {
    // Debug info
    print('DEBUG: Building unscanned assets list with ${items.length} items');
    if (items.isNotEmpty) {
      // Print first few items for debugging
      for (int i = 0; i < math.min(3, items.length); i++) {
        print(
            'DEBUG: Unscanned item $i: ${items[i].assetName} (${items[i].assetCode}) - Status: ${items[i].currentStatus}');
      }
    }

    if (items.isEmpty) {
      print('DEBUG: No unscanned items to display');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Semua aset sudah dipindai',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Sort items by name (since these are all unscanned assets)
    final sortedItems = List<StockOpnameItem>.from(items);
    sortedItems.sort((a, b) => a.assetName.compareTo(b.assetName));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedItems.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final item = sortedItems[index];

        // All items in this list are unscanned, so use consistent styling
        const IconData statusIcon = Icons.pending_outlined;
        final Color statusColor = Colors.amber[700]!;

        return InkWell(
          onTap: () => _showAssetDetailBottomSheet(item),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add asset image/thumbnail section - Always show for consistency
                Container(
                  width: double.infinity,
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildAssetThumbnail(item),
                  ),
                ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.assetName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF213268),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.assetCode,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (item.brandName != null || item.model != null)
                            const SizedBox(height: 2),
                          if (item.brandName != null || item.model != null)
                            Text(
                              '${item.brandName ?? ''} ${item.model ?? ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        'Belum Dipindai',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.serialNumber != null || item.category != null)
                  const SizedBox(height: 8),
                if (item.serialNumber != null || item.category != null)
                  Row(
                    children: [
                      if (item.serialNumber != null)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.confirmation_number,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'SN: ${item.serialNumber}',
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
                      if (item.category != null)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.label,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.category!,
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tap untuk detail lengkap',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _completeScan() async {
    final success = await _stockOpnameController.completeStockOpname(
        widget.opnameId, context);

    if (success) {
      if (mounted) {
        // Navigate to scan result screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ScanResultScreen(
              scannedAssets: _stockOpnameController.scannedItems
                  .map((item) => item.assetCode)
                  .toList(),
              roomName: widget.roomName,
              opnameId: widget.opnameId,
              opnameCode: widget.opnameCode,
              scannedCount:
                  _stockOpnameController.getLocalScannedCount(widget.opnameId),
            ),
          ),
        );
      }
    } else {
      // Tampilkan error jika gagal
      if (_stockOpnameController.error != null) {
        _showError(_stockOpnameController.error!);
      }
    }
  }

  void _toggleFlash() {
    toggleFlash(controller);
    _stockOpnameController.toggleFlash();
  }

  void _flipCamera() {
    flipCamera(controller);
    _stockOpnameController.toggleCamera();
  }

  // Show detailed asset information bottom sheet
  void _showAssetDetailBottomSheet(StockOpnameItem asset,
      {bool isNewlyScanned = false}) {
    // Controller untuk input catatan
    final TextEditingController _notesController = TextEditingController();
    _notesController.text = asset.notes ?? '';

    // State untuk menyimpan detail asset yang sudah di-fetch
    StockOpnameItem? _detailedAsset;
    bool _isLoadingDetails = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  minHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Header with special indicator for newly scanned assets
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isNewlyScanned
                            ? const Color(0xFF213268)
                            : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isNewlyScanned) ...[
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Aset Baru Dipindai',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Scan berhasil - ${asset.assetCode}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child: Text(
                                'Detail Aset',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF213268),
                                ),
                              ),
                            ),
                          ],
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: isNewlyScanned
                                  ? Colors.white
                                  : const Color(0xFF213268),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content with detailed asset information
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          // Fetch details only once when the bottom sheet is first shown
                          if (_detailedAsset == null && !_isLoadingDetails) {
                            _isLoadingDetails = true;
                            // Use post-frame callback to avoid setState during build
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _stockOpnameController
                                  .fetchAssetDetails(asset.assetCode, context)
                                  .then((result) {
                                if (mounted) {
                                  setModalState(() {
                                    _detailedAsset = result;
                                    _isLoadingDetails = false;
                                  });
                                }
                              }).catchError((error) {
                                if (mounted) {
                                  setModalState(() {
                                    _isLoadingDetails = false;
                                  });
                                }
                              });
                            });
                          }

                          // Show loading state
                          if (_isLoadingDetails && _detailedAsset == null) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Color(0xFF213268),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Memuat detail aset...',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Use detailed data if available, otherwise fallback to original asset data
                          // Get the most up-to-date asset data from controller
                          StockOpnameItem? latestAsset;

                          // Try to find the latest asset data from scanned items first
                          final scannedIndex =
                              _stockOpnameController.scannedItems.indexWhere(
                                  (item) => item.assetCode == asset.assetCode);
                          if (scannedIndex != -1) {
                            latestAsset = _stockOpnameController
                                .scannedItems[scannedIndex];
                          } else {
                            // Try to find in all room assets
                            final roomIndex = _stockOpnameController
                                .allRoomAssets
                                .indexWhere((item) =>
                                    item.assetCode == asset.assetCode);
                            if (roomIndex != -1) {
                              latestAsset = _stockOpnameController
                                  .allRoomAssets[roomIndex];
                            }
                          }

                          // Use the most up-to-date asset data
                          final displayAsset =
                              latestAsset ?? _detailedAsset ?? asset;

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Asset Image - Always show container for consistency
                                Container(
                                  width: double.infinity,
                                  height: 200,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildAssetImage(displayAsset),
                                  ),
                                ),

                                // Asset Basic Information
                                _buildDetailSection(
                                  'Informasi Dasar',
                                  [
                                    _buildDetailRow(Icons.qr_code, 'Kode Aset:',
                                        displayAsset.assetCode),
                                    _buildDetailRow(Icons.inventory,
                                        'Nama Aset:', displayAsset.assetName),
                                    if (displayAsset.description != null &&
                                        displayAsset.description!.isNotEmpty)
                                      _buildDetailRow(
                                          Icons.description,
                                          'Deskripsi:',
                                          displayAsset.description!),
                                    if (displayAsset.assetType != null)
                                      _buildDetailRow(
                                          Icons.category,
                                          'Tipe Aset:',
                                          _getAssetTypeDisplay(
                                              displayAsset.assetType!)),
                                    if (displayAsset.category != null)
                                      _buildDetailRow(Icons.label, 'Kategori:',
                                          displayAsset.category!),
                                    if (displayAsset.subcategoryName != null)
                                      _buildDetailRow(
                                          Icons.label_outline,
                                          'Kategori:',
                                          displayAsset.subcategoryName!),
                                    _buildEditableConditionRow(
                                        displayAsset, setModalState),
                                    _buildDetailRow(
                                        Icons.info,
                                        'Status:',
                                        _getAssetStatusDisplay(
                                            displayAsset.currentStatus)),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Physical Details
                                if (displayAsset.brandName != null ||
                                    displayAsset.model != null ||
                                    displayAsset.serialNumber != null)
                                  _buildDetailSection(
                                    'Detail Fisik',
                                    [
                                      if (displayAsset.brandName != null)
                                        _buildDetailRow(Icons.business, 'Merk:',
                                            displayAsset.brandName!),
                                      if (displayAsset.model != null)
                                        _buildDetailRow(Icons.settings,
                                            'Model:', displayAsset.model!),
                                      if (displayAsset.serialNumber != null)
                                        _buildDetailRow(
                                            Icons.confirmation_number,
                                            'Serial Number:',
                                            displayAsset.serialNumber!),
                                    ],
                                  ),

                                const SizedBox(height: 16),

                                // Location Information
                                _buildDetailSection(
                                  'Informasi Lokasi',
                                  [
                                    // Show actual location data from scan process (ruangan sampai lokasi aktual dari proses scan)
                                    _buildDetailRow(Icons.room, 'Ruangan:',
                                        widget.roomName),
                                    if (widget.buildingName != null &&
                                        widget.buildingName!.isNotEmpty)
                                      _buildDetailRow(Icons.apartment,
                                          'Gedung:', widget.buildingName!),
                                    if (widget.floorNumber != null &&
                                        widget.floorNumber!.isNotEmpty)
                                      _buildDetailRow(Icons.layers, 'Lantai:',
                                          widget.floorNumber!),
                                    // Fallback building from asset data if widget building is empty
                                    if (displayAsset.buildingName != null &&
                                        displayAsset.buildingName!.isNotEmpty &&
                                        (widget.buildingName == null ||
                                            widget.buildingName!.isEmpty))
                                      _buildDetailRow(
                                          Icons.apartment,
                                          'Gedung:',
                                          displayAsset.buildingName!),
                                    if (displayAsset.floorNumber != null &&
                                        displayAsset.floorNumber!.isNotEmpty &&
                                        (widget.floorNumber == null ||
                                            widget.floorNumber!.isEmpty))
                                      _buildDetailRow(Icons.layers, 'Lantai:',
                                          displayAsset.floorNumber!),
                                    _buildDetailRow(Icons.location_on,
                                        'Lokasi Aktual:', widget.roomName),

                                    // Show expected location with complete information (lengkap dengan gedung dan lantai)
                                    if (displayAsset.expectedLocationName !=
                                            null &&
                                        displayAsset
                                            .expectedLocationName!.isNotEmpty)
                                      _buildDetailRow(
                                          Icons.location_searching,
                                          'Lokasi Diharapkan:',
                                          _buildExpectedLocationText(
                                              displayAsset)),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Employee/PIC Information
                                if (displayAsset.pic != null ||
                                    displayAsset.employeeName != null)
                                  _buildDetailSection(
                                    'Penanggung Jawab',
                                    [
                                      if (displayAsset.pic != null)
                                        _buildDetailRow(Icons.person, 'PIC:',
                                            displayAsset.pic!),
                                      if (displayAsset.employeeName != null)
                                        _buildDetailRow(
                                            Icons.person_outline,
                                            'Nama Karyawan:',
                                            displayAsset.employeeName!),
                                      if (displayAsset.employeeNumber != null)
                                        _buildDetailRow(
                                            Icons.badge,
                                            'No. Karyawan:',
                                            displayAsset.employeeNumber!),
                                    ],
                                  ),

                                const SizedBox(height: 16),

                                // Purchase Information
                                if (displayAsset.purchaseDate != null ||
                                    displayAsset.purchaseCost != null ||
                                    displayAsset.warrantyEndDate != null)
                                  _buildDetailSection(
                                    'Informasi Pembelian',
                                    [
                                      if (displayAsset.purchaseDate != null)
                                        _buildDetailRow(
                                            Icons.calendar_today,
                                            'Tanggal Beli:',
                                            _formatDate(
                                                displayAsset.purchaseDate!)),
                                      if (displayAsset.purchaseCost != null)
                                        _buildDetailRow(
                                            Icons.attach_money,
                                            'Harga Beli:',
                                            _formatCurrency(
                                                displayAsset.purchaseCost!)),
                                      if (displayAsset.warrantyEndDate != null)
                                        _buildDetailRow(
                                            Icons.shield,
                                            'Berakhir Garansi:',
                                            _formatDate(
                                                displayAsset.warrantyEndDate!)),
                                    ],
                                  ),

                                const SizedBox(height: 16),

                                // Asset Master Information
                                if (displayAsset.assetMasterCode != null ||
                                    displayAsset.isDepreciable != null ||
                                    displayAsset.needsCalibration != null)
                                  _buildDetailSection(
                                    'Informasi Master',
                                    [
                                      if (displayAsset.assetMasterCode != null)
                                        _buildDetailRow(
                                            Icons.qr_code_2,
                                            'Kode Master:',
                                            displayAsset.assetMasterCode!),
                                      if (displayAsset.isDepreciable != null)
                                        _buildDetailRow(
                                            Icons.trending_down,
                                            'Dapat Disusutkan:',
                                            displayAsset.isDepreciable!
                                                ? 'Ya'
                                                : 'Tidak'),
                                      if (displayAsset.needsCalibration != null)
                                        _buildDetailRow(
                                            Icons.tune,
                                            'Perlu Kalibrasi:',
                                            displayAsset.needsCalibration!
                                                ? 'Ya'
                                                : 'Tidak'),
                                    ],
                                  ),

                                const SizedBox(height: 16),

                                // Timestamps
                                if (displayAsset.createdAt != null ||
                                    displayAsset.updatedAt != null)
                                  _buildDetailSection(
                                    'Riwayat',
                                    [
                                      if (displayAsset.createdAt != null)
                                        _buildDetailRow(
                                            Icons.add_circle,
                                            'Dibuat:',
                                            _formatDateTime(
                                                displayAsset.createdAt!)),
                                      if (displayAsset.updatedAt != null)
                                        _buildDetailRow(
                                            Icons.update,
                                            'Diperbarui:',
                                            _formatDateTime(
                                                displayAsset.updatedAt!)),
                                      _buildDetailRow(
                                          Icons.access_time,
                                          'Waktu Scan:',
                                          _formatDateTime(displayAsset.scanTime
                                              .toIso8601String())),
                                    ],
                                  ),

                                const SizedBox(height: 16),

                                // Notes Section with Edit Capability
                                _buildNotesSection(displayAsset,
                                    _notesController, setModalState),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to build detail sections
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

  // Helper method to build detail rows
  Widget _buildDetailRow(IconData icon, String label, String value) {
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
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for formatting
  String _getAssetTypeDisplay(String assetType) {
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

  String _getConditionDisplay(String condition) {
    switch (condition.toLowerCase()) {
      case 'good':
        return 'Baik';
      case 'damaged':
        return 'Rusak';
      default:
        return condition;
    }
  }

  // Build editable condition row for asset details bottomsheet - konsisten dengan UI lainnya
  Widget _buildEditableConditionRow(
      StockOpnameItem asset, StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Icon(
              Icons.build,
              size: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              'Kondisi:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _showConditionSelector(asset, setModalState),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.grey[50],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getConditionDisplay(asset.condition),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _getConditionColor(asset.condition),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get color for condition display
  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'good':
        return Colors.green;
      case 'damaged':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  // Show condition selector dialog
  void _showConditionSelector(
      StockOpnameItem asset, StateSetter setModalState) {
    final List<Map<String, String>> conditions = [
      {'value': 'good', 'label': 'Baik'},
      {'value': 'damaged', 'label': 'Rusak'},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Pilih Kondisi Aset',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: conditions.map((condition) {
              final isSelected =
                  condition['value'] == asset.condition.toLowerCase();
              return ListTile(
                leading: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF213268)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF213268) : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                title: Text(
                  condition['label']!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color:
                        isSelected ? const Color(0xFF213268) : Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _updateAssetCondition(
                      asset, condition['value']!, setModalState);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Update asset condition to server
  Future<void> _updateAssetCondition(StockOpnameItem asset, String newCondition,
      StateSetter setModalState) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Mengubah kondisi aset...',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF213268),
        ),
      );

      LoggerUtil.d(
          'Updating asset condition: ${asset.assetCode} to $newCondition');
      LoggerUtil.d('Asset detailId: ${asset.detailId}');

      // Check if asset has detailId (for scanned assets)
      if (asset.detailId != null) {
        // Try multiple endpoints to find the correct one for updating condition
        http.Response? response;
        bool success = false;

        // Get required parameters for the correct endpoint
        final opnameId = widget.opnameId;
        final roomId = widget.roomId;

        // Use the correct endpoint format based on server specification
        final requestBody = {
          'opname_id': opnameId,
          'actual_location_id': roomId,
          'asset_code': asset.assetCode,
          'condition': newCondition, // 'good' or 'damaged'
        };

        // Add notes if asset has existing notes
        if (asset.notes != null && asset.notes!.isNotEmpty) {
          requestBody['notes'] = asset.notes!;
        }

        final attempts = [
          {
            'endpoint': '/asset-opname-details',
            'method': 'post',
            'body': requestBody,
            'description': 'Correct server endpoint with POST',
          },
        ];

        for (final attempt in attempts) {
          try {
            LoggerUtil.d('Trying: ${attempt['description']}');
            LoggerUtil.d('Endpoint: ${attempt['endpoint']}');
            LoggerUtil.d('Method: ${attempt['method']}');
            LoggerUtil.d('Body: ${attempt['body']}');

            // Use appropriate HTTP method
            if (attempt['method'] == 'post') {
              response = await auth.ApiService.post(
                attempt['endpoint'] as String,
                body: attempt['body'] as Map<String, dynamic>,
                context: context,
              );
            } else {
              response = await auth.ApiService.put(
                attempt['endpoint'] as String,
                body: attempt['body'] as Map<String, dynamic>,
                context: context,
              );
            }

            LoggerUtil.d('Response status: ${response.statusCode}');
            LoggerUtil.d('Response body: ${response.body}');

            if (response.statusCode == 200 || response.statusCode == 201) {
              final data = jsonDecode(response.body);
              if (data['success'] == true) {
                LoggerUtil.i('Success with: ${attempt['description']}');
                success = true;
                break;
              }
            }
          } catch (e) {
            LoggerUtil.d('Failed with ${attempt['description']}: $e');
            continue;
          }
        }

        if (!success) {
          LoggerUtil.w('All API update methods failed, updating locally only');
          // Update locally if all API methods fail
          _updateLocalAssetCondition(asset.assetCode, newCondition);

          // Also update scan result controller if available
          _updateScanResultController(asset.assetCode, newCondition);

          setModalState(() {
            // Force rebuild of the modal content with updated condition
          });

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Kondisi aset diubah secara lokal. Server update gagal.',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          return; // Exit early since we handled it locally
        }

        // If we reach here, one of the attempts was successful
        // Update local asset condition
        _updateLocalAssetCondition(asset.assetCode, newCondition);

        // Also update scan result controller if available
        _updateScanResultController(asset.assetCode, newCondition);

        // Update the modal state to reflect changes
        setModalState(() {
          // Force rebuild of the modal content with updated condition
        });

        // Show success message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kondisi aset berhasil diubah menjadi ${_getConditionDisplay(newCondition)}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        LoggerUtil.d(
            'Asset has no detailId, trying to update via server endpoint');

        // For non-scanned assets, try the same server endpoint
        final opnameId = widget.opnameId;
        final roomId = widget.roomId;

        try {
          final requestBody = {
            'opname_id': opnameId,
            'actual_location_id': roomId,
            'asset_code': asset.assetCode,
            'condition': newCondition,
          };

          // Add notes if asset has existing notes
          if (asset.notes != null && asset.notes!.isNotEmpty) {
            requestBody['notes'] = asset.notes!;
          }

          LoggerUtil.d('Updating non-scanned asset via server: $requestBody');

          final response = await auth.ApiService.post(
            '/asset-opname-details',
            body: requestBody,
            context: context,
          );

          LoggerUtil.d('Response status: ${response.statusCode}');
          LoggerUtil.d('Response body: ${response.body}');

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = jsonDecode(response.body);
            if (data['success'] == true) {
              // Server update successful
              _updateLocalAssetCondition(asset.assetCode, newCondition);

              // Also update scan result controller if available
              _updateScanResultController(asset.assetCode, newCondition);

              setModalState(() {
                // Force rebuild of the modal content with updated condition
              });

              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Kondisi aset berhasil diubah menjadi ${_getConditionDisplay(newCondition)}',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
            }
          }
        } catch (e) {
          LoggerUtil.w('Server update failed for non-scanned asset: $e');
        }

        // Fallback to local update if server fails
        LoggerUtil.d('Fallback: updating locally only');
        _updateLocalAssetCondition(asset.assetCode, newCondition);

        // Also update scan result controller if available
        _updateScanResultController(asset.assetCode, newCondition);

        setModalState(() {
          // Force rebuild of the modal content with updated condition
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kondisi aset diubah secara lokal: ${_getConditionDisplay(newCondition)}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      LoggerUtil.e('Error updating asset condition', e, StackTrace.current);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengubah kondisi aset: ${e.toString()}',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Update local asset condition in all relevant lists
  void _updateLocalAssetCondition(String assetCode, String newCondition) {
    LoggerUtil.d(
        'Updating local asset condition for $assetCode to $newCondition');

    bool updated = false;

    // Update in scanned items
    final scannedIndex = _stockOpnameController.scannedItems
        .indexWhere((item) => item.assetCode == assetCode);
    if (scannedIndex != -1) {
      final updatedItem = _stockOpnameController.scannedItems[scannedIndex]
          .copyWith(condition: newCondition);
      _stockOpnameController.scannedItems[scannedIndex] = updatedItem;
      LoggerUtil.d('Updated asset in scannedItems list');
      updated = true;
    }

    // Update in all room assets
    final allRoomIndex = _stockOpnameController.allRoomAssets
        .indexWhere((item) => item.assetCode == assetCode);
    if (allRoomIndex != -1) {
      final updatedItem = _stockOpnameController.allRoomAssets[allRoomIndex]
          .copyWith(condition: newCondition);
      _stockOpnameController.allRoomAssets[allRoomIndex] = updatedItem;
      LoggerUtil.d('Updated asset in allRoomAssets list');
      updated = true;
    }

    if (updated) {
      LoggerUtil.d('Successfully updated asset condition locally');
    } else {
      LoggerUtil.w('Asset $assetCode not found in any list for update');
    }
  }

  // Update scan result controller with new condition
  void _updateScanResultController(String assetCode, String newCondition) {
    try {
      // Get scan result controller instance
      final scanResultController =
          Provider.of<ScanResultController>(context, listen: false);

      // Update the condition in scan result controller
      scanResultController.updateAssetCondition(assetCode, newCondition);

      LoggerUtil.d(
          'Updated scan result controller for asset: $assetCode with condition: $newCondition');
    } catch (e) {
      LoggerUtil.w('Failed to update scan result controller: $e');
      // This is not critical, so we don't show error to user
    }
  }

  // Helper method to display status in Indonesian for basic information section
  String _getAssetStatusDisplay(String status) {
    // Normalize status to uppercase for comparison
    final normalizedStatus = status.trim().toUpperCase();

    switch (normalizedStatus) {
      case 'AVAILABLE':
        return 'TERSEDIA';
      case 'CHECK OUT':
      case 'CHECKOUT':
        return 'DIPINJAM';
      case 'UNDER REPAIR':
      case 'UNDERREPAIR':
        return 'PERBAIKAN';
      case 'DISPOSE':
      case 'DISPOSED':
        return 'DIHAPUSKAN';
      case 'LOST':
        return 'HILANG';
      case 'FOUND':
        return 'DITEMUKAN';
      case 'MISSING':
        return 'HILANG';
      case 'MISPLACED':
        return 'BERPINDAH';
      case 'PENDING':
        return 'BELUM DIPINDAI';
      case 'ACTIVE':
        return 'AKTIF';
      case 'INACTIVE':
        return 'TIDAK AKTIF';
      default:
        return status; // Return original if not found
    }
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'found':
        return 'Ditemukan';
      case 'missing':
        return 'Hilang';
      case 'misplaced':
        return 'Berpindah';
      case 'pending':
        return 'Belum Dipindai';
      case 'active':
        return 'Aktif';
      case 'inactive':
        return 'Tidak Aktif';
      default:
        return status;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateTimeString;
    }
  }

  String _formatCurrency(String costString) {
    try {
      final cost = double.parse(costString);
      return "Rp ${cost.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";
    } catch (e) {
      return "Rp $costString";
    }
  }

  // Helper method to build the notes section
  Widget _buildNotesSection(StockOpnameItem asset,
      TextEditingController notesController, StateSetter setModalState) {
    final bool isScannedAsset = _stockOpnameController.scannedItems
        .any((item) => item.assetCode == asset.assetCode);

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
              'Catatan',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isScannedAsset)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Catatan hanya dapat ditambahkan setelah aset dipindai',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.amber[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.keyboard,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Catatan akan ditampilkan di detail aset',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
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
                          controller: notesController,
                          maxLines: 4,
                          minLines: 3,
                          autofocus: false,
                          textInputAction: TextInputAction.newline,
                          keyboardType: TextInputType.multiline,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Ketik catatan untuk aset ini...\n\nGunakan enter untuk baris baru',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Close keyboard before processing
                            FocusScope.of(context).unfocus();

                            final String notes = notesController.text;

                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF213268),
                                  ),
                                );
                              },
                            );

                            try {
                              // Use the new saveAssetNotes method from controller
                              bool success =
                                  await _stockOpnameController.saveAssetNotes(
                                      asset.assetCode, notes, context);

                              // Close loading dialog
                              Navigator.pop(context);

                              if (success) {
                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Catatan berhasil disimpan untuk ${asset.assetCode}'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.only(
                                      bottom: MediaQuery.of(context)
                                                  .padding
                                                  .bottom >
                                              0
                                          ? 90.0
                                          : 70.0,
                                      left: 20.0,
                                      right: 20.0,
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );

                                // Close the bottom sheet
                                Navigator.pop(context);
                              } else {
                                // Show error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Gagal menyimpan catatan untuk ${asset.assetCode}'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.only(
                                      bottom: MediaQuery.of(context)
                                                  .padding
                                                  .bottom >
                                              0
                                          ? 90.0
                                          : 70.0,
                                      left: 20.0,
                                      right: 20.0,
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              // Close loading dialog
                              Navigator.pop(context);

                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.only(
                                    bottom:
                                        MediaQuery.of(context).padding.bottom >
                                                0
                                            ? 90.0
                                            : 70.0,
                                    left: 20.0,
                                    right: 20.0,
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: Text(
                            'Simpan Catatan',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF213268),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 8),

                // Show current notes if any
                if (asset.notes != null && asset.notes!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan saat ini:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          asset.notes!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blue[700],
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
    );
  }

  // Helper method to build the asset image
  Widget _buildAssetImage(StockOpnameItem asset) {
    final String? imageUrl = asset.referenceImagePath != null &&
            asset.referenceImagePath!.isNotEmpty
        ? asset.referenceImagePath!.startsWith('http')
            ? asset.referenceImagePath!
            : '${ApiConfig.baseUrl}/public/images/${_extractFilename(asset.referenceImagePath!)}'
        : null;

    // Always try server placeholder first for consistency
    final String fallbackUrl =
        '${ApiConfig.baseUrl}/public/images/placeholder.png';

    if (imageUrl == null) {
      // If no image URL, try loading server placeholder first
      return Image.network(
        fallbackUrl,
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
          // Fallback to local placeholder if server placeholder fails
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
      );
    }

    return Image.network(
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
        print('Error loading image: $error');
        print('Image URL: $imageUrl');

        // Try fallback to placeholder if main URL fails
        if (!imageUrl.contains('placeholder.png')) {
          return Image.network(
            fallbackUrl,
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
    );
  }

  // Helper method to extract filename from path (following asset_details.dart pattern)
  String _extractFilename(String path) {
    // If path doesn't contain '/', return as is
    if (!path.contains('/')) return path;

    // If it's a full path, extract the filename
    return path.split('/').last;
  }

  // Helper method to build asset thumbnail for list items
  Widget _buildAssetThumbnail(StockOpnameItem asset) {
    final String? imageUrl = asset.referenceImagePath != null &&
            asset.referenceImagePath!.isNotEmpty
        ? asset.referenceImagePath!.startsWith('http')
            ? asset.referenceImagePath!
            : '${ApiConfig.baseUrl}/public/images/${_extractFilename(asset.referenceImagePath!)}'
        : null;

    // Always try server placeholder first for consistency
    final String fallbackUrl =
        '${ApiConfig.baseUrl}/public/images/placeholder.png';

    if (imageUrl == null) {
      // If no image URL, try loading server placeholder first
      return Image.network(
        fallbackUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: const Color(0xFF213268),
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Loading...',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Fallback to local placeholder if server placeholder fails
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: 32,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tidak Ada Gambar',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: const Color(0xFF213268),
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Loading...',
                style: GoogleFonts.poppins(
                  fontSize: 10,
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
            fallbackUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tidak Ada Gambar',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
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
                size: 32,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 4),
              Text(
                'Tidak Ada Gambar',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to build complete expected location text
  String _buildExpectedLocationText(StockOpnameItem asset) {
    List<String> locationParts = [];

    // Add expected location name
    if (asset.expectedLocationName != null &&
        asset.expectedLocationName!.isNotEmpty) {
      locationParts.add(asset.expectedLocationName!);
    }

    // Add expected building name
    if (asset.expectedBuildingName != null &&
        asset.expectedBuildingName!.isNotEmpty) {
      locationParts.add(asset.expectedBuildingName!);
    }

    // Add expected floor number
    if (asset.expectedFloorNumber != null &&
        asset.expectedFloorNumber!.isNotEmpty) {
      locationParts.add('Lantai ${asset.expectedFloorNumber!}');
    }

    // Join with commas, or return just the location name if that's all we have
    return locationParts.isNotEmpty
        ? locationParts.join(', ')
        : 'Tidak diketahui';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StockOpnameController>(
      builder: (context, stockOpnameController, _) => Scaffold(
        body: Stack(
          children: [
            // QR Scanner View menggunakan implementasi kondisional
            buildScannerView(
              context,
              qrKey,
              _onBarcodeDetect,
              (scannerController) {
                // Gunakan post-frame callback untuk menghindari setState selama build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      controller = scannerController;
                    });
                  }
                });
              },
              stockOpnameController,
            ),

            // Animasi Garis Scanner (hanya ditampilkan jika bukan web)
            if (!kIsWeb)
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ScannerLinePainter(_animation.value),
                    size: Size.infinite,
                  );
                },
              ),

            // Top Bar dengan Informasi
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tombol Kembali
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            color: const Color(0xFF213268),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),

                        // Action Buttons
                        Row(
                          children: [
                            // Flash button pada posisi yang sama dengan tombol kamera sebelumnya
                            if (!kIsWeb)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    stockOpnameController.flashOn
                                        ? Icons.flash_on
                                        : Icons.flash_off,
                                  ),
                                  color: const Color(0xFF213268),
                                  onPressed: _toggleFlash,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Bar dengan Informasi dan Action
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.transparent,
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.of(context).padding.bottom > 0 ? 34.0 : 16.0,
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Info Panel
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.qr_code_scanner,
                                        color: Color(0xFF213268),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Stockopname: ${widget.roomName}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF213268),
                                        ),
                                        // Removed overflow and maxLines to allow wrapping
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Add button to show bottom sheet
                              GestureDetector(
                                onTap: _showScannedItemsBottomSheet,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF213268)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${stockOpnameController.scannedItems.length} Aset',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF213268),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        _isBottomSheetOpen
                                            ? Icons.keyboard_arrow_down
                                            : Icons.keyboard_arrow_up,
                                        size: 16,
                                        color: const Color(0xFF213268),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Progress
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Progress: ${stockOpnameController.getLocalScannedCount(widget.opnameId)}/${widget.totalAssets}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: widget.totalAssets > 0
                                          ? stockOpnameController
                                                  .getLocalScannedCount(
                                                      widget.opnameId) /
                                              widget.totalAssets
                                          : 0,
                                      backgroundColor: Colors.grey[200],
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF213268)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF213268),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: stockOpnameController.isLoading
                                    ? null
                                    : _completeScan,
                                child: Text(
                                  'Selesai',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading Indicator
            if (stockOpnameController.isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
