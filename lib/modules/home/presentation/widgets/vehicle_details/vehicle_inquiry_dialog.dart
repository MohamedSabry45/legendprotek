import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;

import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/constants/app_constants.dart';
import 'package:reservation_workshop/core/network/api_endpoints.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'dart:convert';

class VehicleInquiryDialog extends StatefulWidget {
  final int vehicleId;

  const VehicleInquiryDialog({super.key, required this.vehicleId});

  @override
  State<VehicleInquiryDialog> createState() => _VehicleInquiryDialogState();
}

class _VehicleInquiryDialogState extends State<VehicleInquiryDialog> {
  final messageController = TextEditingController();
  final priceController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    messageController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> _submitInquiry() async {
    if (messageController.text.trim().isEmpty) return;

    setState(() => isLoading = true);
    try {
      final baseUrl = AppConstants.kBaseUrl.trim();
      final token =
          AppConstants.token ??
          CacheHelper.getData<String>(key: PrefKeys.kAccessToken);

      final uri = Uri.parse(
        '$baseUrl${ApiEndpoints.vehicleInquiry(vehicleId: widget.vehicleId)}',
      );

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      if (token != null && token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final priceText = priceController.text.trim();
      final price = priceText.isNotEmpty ? (int.tryParse(priceText) ?? 0) : 0;

      final body = jsonEncode({
        'message': messageController.text.trim(),
        'inquiry_type': 'whatsapp',
        'offered_price': price,
      });

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.of(context).pop();
          Toasters.successKey('buy_car.inquiry_success');
        }
      } else {
        throw Exception('Failed to submit inquiry');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        Toasters.errorKey('buy_car.inquiry_failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Simple header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.handshake_outlined,
                      color: AppColors.brandPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'buy_car.make_offer'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.locale.languageCode == 'ar'
                        ? 'اكتب رسالتك وعرضك المقترح'
                        : 'Write your message and proposed offer',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF0F0F0)),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: messageController,
                    maxLines: 4,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Color(0xFF1A1A1A),
                    ),
                    decoration: InputDecoration(
                      hintText: context.locale.languageCode == 'ar'
                          ? 'رسالتك...'
                          : 'Your message...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.brandPrimary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    decoration: InputDecoration(
                      hintText: context.locale.languageCode == 'ar'
                          ? 'السعر المعروض (اختياري)'
                          : 'Offered price (optional)',
                      hintStyle: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 15,
                      ),
                      prefixText: context.locale.languageCode == 'ar'
                          ? 'ج.م '
                          : 'EGP ',
                      prefixStyle: TextStyle(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.brandPrimary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF0F0F0)),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'buy_car.cancel'.tr(),
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: isLoading ? null : _submitInquiry,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              context.locale.languageCode == 'ar'
                                  ? 'إرسال'
                                  : 'Send',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
