import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'api_exception.dart';

/// Central error handler that maps ApiException errorCode to UI actions.
class ErrorHandler {
  ErrorHandler._();

  /// Shows the appropriate snackbar/dialog and optionally navigates.
  static void handle(
    BuildContext context,
    ApiException error, {
    VoidCallback? onKycRequired,
    VoidCallback? onUnauthorized,
  }) {
    if (!context.mounted) return;

    if (error.isKycRequired) {
      // KYC required → prompt and navigate to KYC page
      _showSnack(context, error.message, isError: true);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (context.mounted) context.push('/kyc');
      });
      onKycRequired?.call();
      return;
    }

    if (error.isUnauthorized) {
      _showSnack(context, 'Session expirée. Reconnectez-vous.', isError: true);
      onUnauthorized?.call();
      return;
    }

    if (error.isConflict) {
      _showSnack(context, error.message, isError: true);
      return;
    }

    if (error.isRateLimit) {
      _showSnack(context, error.message, isError: true);
      return;
    }

    if (error.isNetwork) {
      _showSnack(context, 'Pas de connexion internet.', isError: true);
      return;
    }

    // Generic fallback
    _showSnack(context, error.message, isError: true);
  }

  static void _showSnack(
    BuildContext context,
    String msg, {
    bool isError = true,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg, style: const TextStyle(fontSize: 13)),
          ),
        ]),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
