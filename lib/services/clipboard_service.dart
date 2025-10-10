import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:super_clipboard/super_clipboard.dart';

/// Service for copying widget snapshots to clipboard as PNG images
class ClipboardService {
  /// Copies a widget snapshot to clipboard as PNG
  ///
  /// [repaintKey] - GlobalKey for the RepaintBoundary wrapping the widget
  /// [context] - BuildContext for showing snackbars (optional)
  /// [backgroundToggle] - ValueNotifier to temporarily hide background (optional)
  /// [pixelRatio] - Image quality multiplier (default: 3.0)
  /// [successMessage] - Custom success message (default: "Copied. Paste in your story :)")
  /// [errorMessage] - Custom error message (default: "Failed to copy image")
  ///
  /// Returns true if successful, false otherwise
  static Future<bool> copyWidgetToClipboard({
    required GlobalKey repaintKey,
    BuildContext? context,
    ValueNotifier<bool>? backgroundToggle,
    double pixelRatio = 3.0,
    String successMessage = 'Copied. Paste in your story :)',
    String errorMessage = 'Failed to copy image',
  }) async {
    try {
      // Optionally hide background for export
      if (backgroundToggle != null) {
        backgroundToggle.value = true;
        // Wait one frame for the widget to rebuild without background
        await Future.delayed(const Duration(milliseconds: 16));
      }

      // Get the RepaintBoundary
      final renderObject = repaintKey.currentContext?.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        throw Exception('RepaintBoundary not found or invalid');
      }

      // Capture as image with high quality
      final ui.Image image = await renderObject.toImage(pixelRatio: pixelRatio);

      // Convert to PNG bytes
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Copy PNG bytes to system clipboard
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        throw Exception('Clipboard not available on this platform');
      }

      final item = DataWriterItem();
      item.add(Formats.png(pngBytes));
      await clipboard.write([item]);

      // Restore background if it was hidden
      if (backgroundToggle != null) {
        backgroundToggle.value = false;
      }

      // Show success snackbar if context provided
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      return true;
    } catch (e) {
      // Restore background on error
      if (backgroundToggle != null) {
        backgroundToggle.value = false;
      }

      // Show error snackbar if context provided
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Log error for debugging
      debugPrint('ClipboardService: Error copying to clipboard: $e');
      return false;
    }
  }
}
