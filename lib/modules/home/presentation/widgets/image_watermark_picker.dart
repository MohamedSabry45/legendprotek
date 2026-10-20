import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/core/components/toasters.dart';

class ImageWatermarkPicker extends StatefulWidget {
  final List<String> initialImages;
  final ValueChanged<List<String>> onImagesChanged;

  const ImageWatermarkPicker({
    super.key,
    this.initialImages = const <String>[],
    required this.onImagesChanged,
  });

  @override
  State<ImageWatermarkPicker> createState() => _ImageWatermarkPickerState();
}

class _ImageWatermarkPickerState extends State<ImageWatermarkPicker> {
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _imagesDataUrls = <String>[];
  ui.Image? _watermarkLogo;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _imagesDataUrls
      ..clear()
      ..addAll(widget.initialImages);
    _loadWatermarkLogo();
  }

  Future<void> _loadWatermarkLogo() async {
    try {
      final byteData = await rootBundle.load('assets/images/logo.png');
      final bytes = byteData.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      if (!mounted) return;
      setState(() {
        _watermarkLogo = frameInfo.image;
      });
      print(
        'Watermark logo loaded successfully: ${_watermarkLogo?.width}x${_watermarkLogo?.height}',
      );
    } catch (e) {
      print('Failed to load watermark logo: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (_watermarkLogo == null) {
        if (!mounted) return;
        Toasters.errorKey('image_picker.wait_logo');
        return;
      }

      setState(() => _isProcessing = true);
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image != null) {
        final Uint8List originalBytes = await image.readAsBytes();
        final Uint8List compressedBytes = await _compressImage(originalBytes);
        final watermarkedDataUrl = await _applyWatermark(compressedBytes);
        if (!mounted) return;
        setState(() {
          _imagesDataUrls.add(watermarkedDataUrl);
        });
        widget.onImagesChanged(List<String>.unmodifiable(_imagesDataUrls));
      }
      if (!mounted) return;
      setState(() => _isProcessing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      Toasters.errorKey('image_picker.pick_failed');
    }
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    final out = await FlutterImageCompress.compressWithList(
      bytes,
      quality: 75,
      minWidth: 1280,
      minHeight: 1280,
      format: CompressFormat.jpeg,
    );
    return Uint8List.fromList(out);
  }

  Future<String> _applyWatermark(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frameInfo = await codec.getNextFrame();
    final ui.Image original = frameInfo.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImage(original, Offset.zero, Paint());

    final logo = _watermarkLogo;
    if (logo != null) {
      final double targetWidth = original.width * 0.5;
      final double scale = targetWidth / logo.width;
      final double targetHeight = logo.height * scale;

      final Rect dst = Rect.fromLTWH(
        (original.width - targetWidth) / 2,
        (original.height - targetHeight) / 2,
        targetWidth,
        targetHeight,
      );
      final Rect src = Rect.fromLTWH(
        0,
        0,
        logo.width.toDouble(),
        logo.height.toDouble(),
      );

      // Draw logo with high transparency
      final paint = Paint()..color = Colors.white.withOpacity(0.3);
      canvas.drawImageRect(logo, src, dst, paint);
      print(
        'Watermark applied: logo(${logo.width}x${logo.height}) at pos(${dst.left},${dst.top}) size(${dst.width}x${dst.height})',
      );
    } else {
      // Fallback: draw text watermark if logo fails to load
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'LOGO',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: (original.width * 0.08).clamp(24, 72),
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.8),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      final watermarkX = (original.width - textPainter.width) / 2;
      final watermarkY = (original.height - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(watermarkX, watermarkY));
      print('Fallback text watermark applied at ($watermarkX,$watermarkY)');
    }

    final picture = recorder.endRecording();
    final watermarked = await picture.toImage(original.width, original.height);
    final bytes = await watermarked.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = bytes!.buffer.asUint8List();
    return 'data:image/png;base64,${base64Encode(pngBytes)}';
  }

  Future<void> _showImagesPreview() async {
    if (_imagesDataUrls.isEmpty) return;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.locale.languageCode == 'ar'
                        ? 'معاينة الصور'
                        : 'Images Preview',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 320,
                width: double.infinity,
                child: GridView.builder(
                  itemCount: _imagesDataUrls.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final dataUrl = _imagesDataUrls[index];
                    final bytes = base64Decode(dataUrl.split(',')[1]);
                    return GestureDetector(
                      onTap: () => _showSingleImagePreview(dataUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(bytes, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSingleImagePreview(String dataUrl) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.9),
              ),
            ),
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.memory(
                  base64Decode(dataUrl.split(',')[1]),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandPrimary.withOpacity(0.08),
            AppColors.brandPrimary.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandPrimary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_rounded,
            color: AppColors.brandPrimary,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            context.locale.languageCode == 'ar'
                ? 'ارفع صورة للسيارة'
                : 'Upload Vehicle Image',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.brandPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.locale.languageCode == 'ar'
                ? 'اختر صورة من الكاميرا أو المعرض'
                : 'Choose image from camera or gallery',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.brandPrimary,
                      size: 20,
                    ),
                    label: Text(
                      context.locale.languageCode == 'ar' ? 'كاميرا' : 'Camera',
                      style: TextStyle(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.brandPrimary.withOpacity(0.4),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.brandPrimary,
                      size: 20,
                    ),
                    label: Text(
                      context.locale.languageCode == 'ar' ? 'معرض' : 'Gallery',
                      style: TextStyle(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.brandPrimary.withOpacity(0.4),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isProcessing) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  context.locale.languageCode == 'ar'
                      ? 'جاري تجهيز الصورة...'
                      : 'Processing image...',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (_imagesDataUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.locale.languageCode == 'ar'
                              ? 'تم اختيار ${_imagesDataUrls.length} صورة'
                              : '${_imagesDataUrls.length} images selected',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showImagesPreview,
                          icon: const Icon(
                            Icons.preview,
                            color: AppColors.brandPrimary,
                            size: 16,
                          ),
                          label: Text(
                            context.locale.languageCode == 'ar'
                                ? 'معاينة'
                                : 'Preview',
                            style: const TextStyle(
                              color: AppColors.brandPrimary,
                              fontSize: 12,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.brandPrimary.withOpacity(0.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _imagesDataUrls.clear();
                            });
                            widget.onImagesChanged(const <String>[]);
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: const Color(0xFFD4AF37),
                            size: 16,
                          ),
                          label: Text(
                            context.locale.languageCode == 'ar'
                                ? 'حذف'
                                : 'Remove',
                            style: const TextStyle(
                              color: const Color(0xFFD4AF37),
                              fontSize: 12,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: const Color(0xFFD4AF37).withOpacity(0.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
