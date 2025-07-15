import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../controllers/dashboard/dashboard_controller.dart';
import 'dart:io' show Platform;

class WebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String title;

  const WebViewScreen({
    Key? key,
    required this.initialUrl,
    this.title = 'Web Portal',
  }) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  WebViewController? controller;
  bool isLoading = true;
  String currentUrl = '';
  final storage = const FlutterSecureStorage();
  Timer? _tokenRefreshTimer;
  Timer? _connectionCheckTimer;
  bool _isConnectionError = false;
  int _connectionRetryCount = 0;
  static const int _maxRetryAttempts = 3;

  @override
  void initState() {
    super.initState();
    initWebView();
    // Set up token refresh timer - check every 24 hours
    _tokenRefreshTimer = Timer.periodic(const Duration(hours: 24), (_) {
      _refreshToken();
    });

    // Set up connection check timer - check every 30 seconds
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnection();
    });
  }

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    _connectionCheckTimer?.cancel();
    super.dispose();
  }

  // Navigate back to home screen (dashboard index 0)
  void _navigateToHomeScreen() {
    if (mounted) {
      // Get the dashboard controller and set index to 0 (home)
      final dashboardController =
          Provider.of<DashboardController>(context, listen: false);

      // Set the selected index to 0 (home)
      dashboardController.setSelectedIndex(0);

      // Pop back to the dashboard screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _refreshToken() async {
    final token = await storage.read(key: 'token');
    final tokenExpiryString = await storage.read(key: 'token_expiry');

    if (token != null && token.isNotEmpty) {
      // Check if token is still valid
      if (tokenExpiryString != null) {
        final tokenExpiry = DateTime.parse(tokenExpiryString);
        final now = DateTime.now();

        // If token is still valid, inject it again
        if (tokenExpiry.isAfter(now)) {
          _injectTokenToWebView(token);
        } else {
          // Token expired, try to refresh it (implementation depends on your auth system)
          _handleTokenRefresh();
        }
      } else {
        // If no expiry date is set, set one for 7 days from now
        final expiryDate = DateTime.now().add(const Duration(days: 7));
        await storage.write(
            key: 'token_expiry', value: expiryDate.toIso8601String());
        _injectTokenToWebView(token);
      }
    }
  }

  Future<void> _handleTokenRefresh() async {
    // This method would implement your token refresh logic
    // For now, we'll just extend the expiry date
    final token = await storage.read(key: 'token');
    if (token != null && token.isNotEmpty) {
      final expiryDate = DateTime.now().add(const Duration(days: 7));
      await storage.write(
          key: 'token_expiry', value: expiryDate.toIso8601String());
      _injectTokenToWebView(token);
    }
  }

  void _injectTokenToWebView(String token) {
    if (controller != null) {
      controller!.runJavaScript('''
        try {
          localStorage.setItem('token', '$token');
          localStorage.setItem('token_expiry', '${DateTime.now().add(const Duration(days: 7)).toIso8601String()}');
          console.log('Token injected successfully');
        } catch (e) {
          console.error('Error injecting token: ' + e);
        }
      ''');
    }
  }

  // Fix UI rendering issues in WebView
  void _fixWebViewUIRendering() {
    if (controller == null) return;

    controller!.runJavaScript('''
      // Fix dropdown positioning and visibility
      (function() {
        // Add meta viewport for proper scaling
        var meta = document.querySelector('meta[name="viewport"]');
        if (!meta) {
          meta = document.createElement('meta');
          meta.name = 'viewport';
          meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
          document.getElementsByTagName('head')[0].appendChild(meta);
        } else {
          meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        }
        
        // Fix dropdown menus and filters
        var style = document.createElement('style');
        style.textContent = `
          .dropdown-menu, .filter-dropdown, .select2-dropdown, .select-options, .ui-selectmenu-menu {
            position: absolute !important;
            max-height: 50vh !important;
            overflow-y: auto !important;
            z-index: 99999 !important;
            width: auto !important;
            min-width: 200px !important;
          }
          
          select, .select2-container, .filter-select {
            max-width: 100% !important;
          }
          
          .modal, .modal-backdrop {
            position: fixed !important;
            top: 0 !important;
            right: 0 !important;
            bottom: 0 !important;
            left: 0 !important;
          }
          
          body {
            overflow-x: hidden !important;
          }
        `;
        document.head.appendChild(style);
        
        console.log('WebView UI fixes applied');
      })();
    ''');
  }

  Future<void> _checkConnection() async {
    if (controller == null) return;

    try {
      // Try to evaluate JavaScript to check if the page is responsive
      await controller!.runJavaScript('1+1').timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Connection timeout');
        },
      );

      // If we get here, the connection is working
      if (_isConnectionError) {
        setState(() {
          _isConnectionError = false;
          _connectionRetryCount = 0;
        });
      }
    } catch (e) {
      // Connection issue detected
      _connectionRetryCount++;

      if (_connectionRetryCount <= _maxRetryAttempts) {
        // Try to reload the page
        _handleConnectionRetry();
      } else {
        // Show connection error UI after max retries
        setState(() {
          _isConnectionError = true;
        });
      }
    }
  }

  void _handleConnectionRetry() {
    // Wait 2 seconds before retry
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && controller != null) {
        controller!.reload();
      }
    });
  }

  Future<void> initWebView() async {
    // Get the token from secure storage
    final token = await storage.read(key: 'token');
    final tokenExpiryString = await storage.read(key: 'token_expiry');

    // If no expiry date is set, set one for 7 days from now
    if (token != null && token.isNotEmpty && tokenExpiryString == null) {
      final expiryDate = DateTime.now().add(const Duration(days: 7));
      await storage.write(
          key: 'token_expiry', value: expiryDate.toIso8601String());
    }

    // Set up platform-specific settings
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    // Create the controller
    final webViewController =
        WebViewController.fromPlatformCreationParams(params);

    // Configure the controller
    webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                isLoading = true;
                currentUrl = url;
                _isConnectionError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                isLoading = false;
                currentUrl = url;
              });

              // Fix UI rendering issues
              _fixWebViewUIRendering();

              // Check if the current page is a login page
              _checkIfLoginPage(url);

              // Inject token to localStorage if available
              if (token != null && token.isNotEmpty) {
                _injectTokenToWebView(token);

                // Also try to extract token from web localStorage to keep them in sync
                _extractTokenFromWebView();
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');

            // Check if it's a connection error
            if (error.errorCode == -2 || // iOS connection error
                error.errorCode == -8 || // Android connection error
                error.description.toLowerCase().contains('net::err_internet') ||
                error.description.toLowerCase().contains('connection') ||
                error.description.toLowerCase().contains('timeout')) {
              setState(() {
                _isConnectionError = true;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Check if the navigation is to a login page
            if (_isLoginPage(request.url)) {
              // If we have a valid token, try to use it instead of showing login page
              _handlePotentialLoginRedirect(request.url);
            }

            // Allow all navigation
            return NavigationDecision.navigate;
          },
        ),
      );

    // Configure platform-specific features
    if (webViewController.platform is AndroidWebViewController) {
      final androidController =
          webViewController.platform as AndroidWebViewController;

      // Enable JavaScript
      androidController.setMediaPlaybackRequiresUserGesture(false);

      // Enable file download/upload
      androidController
          .setOnShowFileSelector((FileSelectorParams params) async {
        return <String>[]; // Return empty list to let the system handle file selection
      });
    } else if (webViewController.platform is WebKitWebViewController) {
      final webKitController =
          webViewController.platform as WebKitWebViewController;

      // Enable all WebKit features
      webKitController.setAllowsBackForwardNavigationGestures(true);
    }

    // Load the initial URL
    await webViewController.loadRequest(Uri.parse(widget.initialUrl));

    // Set the controller
    if (mounted) {
      setState(() {
        controller = webViewController;
      });
    }
  }

  bool _isLoginPage(String url) {
    // Check if URL contains login indicators
    return url.toLowerCase().contains('login') ||
        url.toLowerCase().contains('signin') ||
        url.toLowerCase().contains('auth');
  }

  Future<void> _checkIfLoginPage(String url) async {
    if (_isLoginPage(url)) {
      // If we're on a login page but have a valid token, try to use it
      final token = await storage.read(key: 'token');
      final tokenExpiryString = await storage.read(key: 'token_expiry');

      if (token != null && token.isNotEmpty && tokenExpiryString != null) {
        final tokenExpiry = DateTime.parse(tokenExpiryString);
        if (tokenExpiry.isAfter(DateTime.now())) {
          // Token is still valid, try to bypass login
          _injectTokenToWebView(token);

          // Try to redirect to home or dashboard
          String baseUrl = Uri.parse(url).origin;
          controller?.loadRequest(Uri.parse('$baseUrl/dashboard'));
        }
      }
    }
  }

  Future<void> _handlePotentialLoginRedirect(String url) async {
    final token = await storage.read(key: 'token');
    final tokenExpiryString = await storage.read(key: 'token_expiry');

    if (token != null && token.isNotEmpty && tokenExpiryString != null) {
      final tokenExpiry = DateTime.parse(tokenExpiryString);
      if (tokenExpiry.isAfter(DateTime.now())) {
        // We have a valid token, try to use it instead of showing login
        _injectTokenToWebView(token);
      }
    }
  }

  Future<void> _extractTokenFromWebView() async {
    if (controller == null) return;

    try {
      // Extract token from web localStorage
      final result = await controller!
          .runJavaScriptReturningResult("localStorage.getItem('token')");

      String? webToken;
      if (result != null && result != 'null') {
        webToken = result.toString().replaceAll('"', '');
      }

      if (webToken != null && webToken.isNotEmpty) {
        // Store the web token in secure storage
        await storage.write(key: 'token', value: webToken);

        // Also extract and store token expiry if available
        final expiryResult = await controller!.runJavaScriptReturningResult(
            "localStorage.getItem('token_expiry')");

        if (expiryResult != null && expiryResult != 'null') {
          String webTokenExpiry = expiryResult.toString().replaceAll('"', '');
          await storage.write(key: 'token_expiry', value: webTokenExpiry);
        } else {
          // If no expiry in web localStorage, set default 7 days
          final expiryDate = DateTime.now().add(const Duration(days: 7));
          await storage.write(
              key: 'token_expiry', value: expiryDate.toIso8601String());
        }
      }
    } catch (e) {
      debugPrint('Error extracting token from web: $e');
    }
  }

  void _showActionOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh, color: Color(0xFF213268)),
                  title: const Text('Refresh Page'),
                  onTap: () {
                    Navigator.pop(context);
                    controller?.reload();
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.arrow_back, color: Color(0xFF213268)),
                  title: const Text('Go Back'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (controller != null && await controller!.canGoBack()) {
                      await controller!.goBack();
                    } else {
                      _navigateToHomeScreen();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.home, color: Color(0xFF213268)),
                  title: const Text('Back to Home'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToHomeScreen();
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.fit_screen, color: Color(0xFF213268)),
                  title: const Text('Fix UI Display'),
                  onTap: () {
                    Navigator.pop(context);
                    _fixWebViewUIRendering();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (controller != null && await controller!.canGoBack()) {
          await controller!.goBack();
          return false;
        }
        // Always go to home screen when exiting WebView
        _navigateToHomeScreen();
        return false; // We handle the navigation ourselves
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Status bar height padding
            Container(
              height: MediaQuery.of(context).padding.top,
              color: const Color(0xFF213268),
            ),

            // WebView with padding for status bar
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: controller != null
                  ? WebViewWidget(controller: controller!)
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF213268),
                      ),
                    ),
            ),

            // Connection error overlay
            if (_isConnectionError)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.9),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.signal_wifi_off,
                        size: 64,
                        color: Color(0xFF213268),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Connection lost',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF213268),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please check your internet connection',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF213268),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _isConnectionError = false;
                            _connectionRetryCount = 0;
                          });
                          controller?.reload();
                        },
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF213268),
          onPressed: _showActionOptions,
          child: const Icon(Icons.menu, color: Colors.white),
        ),
      ),
    );
  }
}
