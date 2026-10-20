import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

enum ToastType { success, error, info }

class Toasters {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static const Color _successColor = Color(0xFF2E7D32);
  static const Color _errorColor = Color(0xFFC62828);
  static const Color _infoColor = Color(0xFF21262D);

  static void show(String message) => _show(message, ToastType.info);

  static void success(String message) => _show(message, ToastType.success);

  static void error(String message) => _show(message, ToastType.error);

  /// Shows an error toast for a translation key.
  static void errorKey(String key, {List<String>? args}) =>
      error(key.tr(args: args));

  /// Shows a success toast for a translation key.
  static void successKey(String key, {List<String>? args}) =>
      success(key.tr(args: args));

  /// Cleans up raw exception/error strings coming from cubits
  /// (`e.toString()`), removing technical noise like "Exception: ".
  /// Returns null when nothing meaningful is left so callers can
  /// fall back to a localized named message.
  static String? cleanError(Object? error) {
    if (error == null) return null;
    var msg = error.toString().trim();
    if (msg.isEmpty) return null;

    const prefixes = [
      'Exception: ',
      'FormatException: ',
      'HttpException: ',
      'DioException: ',
      'DioError: ',
    ];
    for (final p in prefixes) {
      if (msg.startsWith(p)) {
        msg = msg.substring(p.length).trim();
        break;
      }
    }

    if (msg.isEmpty) return null;

    final lower = msg.toLowerCase();
    const technical = [
      'socketexception',
      'timeout',
      'timed out',
      'handshake',
      'certificate',
      'connection refused',
      'connection reset',
      'failed host lookup',
      'network is unreachable',
      'clientexception',
      'xmlhttprequest',
      'unauthorized',
      'unauthenticated',
      'forbidden',
      'not found',
      'server error',
      'bad gateway',
      'service unavailable',
      'bad request',
      'method not allowed',
      'csrf',
      'token mismatch',
      'unprocessable',
      'too many requests',
      'access denied',
      'no query results',
      'route not found',
      'the given data was invalid',
      '<!doctype',
      '<html',
      'subtype',
      'unexpected token',
      'cannot read',
      'range error',
    ];
    if (technical.any(lower.contains)) return null;
    const meaningless = {
      'required',
      'error',
      'request failed',
      'success',
      'ok',
      'null',
      'none',
      'true',
      'false',
      'unknown error',
    };
    if (meaningless.contains(lower)) {
      return null;
    }
    return msg;
  }

  /// Whether the error looks like a connectivity problem.
  static bool isNetworkError(Object? error) {
    if (error == null) return false;
    final msg = error.toString().toLowerCase();
    const markers = [
      'socketexception',
      'timeout',
      'timed out',
      'handshake',
      'certificate',
      'connection refused',
      'connection reset',
      'failed host lookup',
      'network is unreachable',
      'clientexception',
      'xmlhttprequest',
    ];
    return markers.any(msg.contains);
  }

  /// Shows an error toast for an arbitrary error object:
  /// meaningful backend messages are shown as-is (after cleanup),
  /// technical/empty ones fall back to the given localized key.
  static void errorFrom(
    Object? err, {
    String fallbackKey = 'common.something_went_wrong',
  }) {
    error(displayMessage(err, fallbackKey: fallbackKey));
  }

  /// Returns a user-facing message for an arbitrary error object:
  /// meaningful backend messages are returned as-is (after cleanup),
  /// technical/empty ones fall back to the given localized key.
  static String displayMessage(
    Object? err, {
    String fallbackKey = 'common.something_went_wrong',
  }) {
    if (isNetworkError(err)) {
      return 'common.network_error'.tr();
    }
    return cleanError(err) ?? fallbackKey.tr();
  }

  static void _show(String message, ToastType type) {
    final messenger = messengerKey.currentState;
    if (messenger == null) {
      return;
    }

    final (Color bg, IconData? icon) = switch (type) {
      ToastType.success => (_successColor, Icons.check_circle),
      ToastType.error => (_errorColor, Icons.error_outline),
      ToastType.info => (_infoColor, null),
    };

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
