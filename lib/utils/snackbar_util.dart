import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SnackbarUtil {
  /// Shows a snackbar with consistent styling that doesn't interfere with the floating action button
  static void showSnackbar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        backgroundColor: backgroundColor ?? const Color(0xFF213268),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: _getBottomMargin(context),
          left: 20.0,
          right: 20.0,
        ),
        action: action,
      ),
    );
  }

  /// Shows an error snackbar with red background
  static void showError(BuildContext context, String message) {
    showSnackbar(
      context,
      message,
      backgroundColor: Colors.red[900],
      action: SnackBarAction(
        label: 'Tutup',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );
  }

  /// Shows a success snackbar with green background
  static void showSuccess(BuildContext context, String message) {
    showSnackbar(
      context,
      message,
      backgroundColor: Colors.green[700],
    );
  }

  /// Shows a warning snackbar with orange background
  static void showWarning(BuildContext context, String message) {
    showSnackbar(
      context,
      message,
      backgroundColor: Colors.orange[700],
    );
  }

  /// Shows an info snackbar with blue background (default)
  static void showInfo(BuildContext context, String message) {
    showSnackbar(
      context,
      message,
      backgroundColor: const Color(0xFF213268),
    );
  }

  /// Calculate the appropriate bottom margin to avoid interfering with UI elements
  static double _getBottomMargin(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // Base margin for bottom navigation bar (56) + floating action button (84) + extra space (10)
    double margin = 90.0;

    // Add extra margin if there's bottom padding (e.g., on devices with gesture navigation)
    if (mediaQuery.padding.bottom > 0) {
      margin += 20.0;
    }

    return margin;
  }
}
