import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;

import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';

class MenuChangeLanguageScreen extends StatelessWidget {
  const MenuChangeLanguageScreen({super.key});

  Future<void> _selectLocale(BuildContext context, String code) async {
    await CacheHelper.saveData(key: PrefKeys.kLocaleCode, value: code);
    if (!context.mounted) return;
    await context.setLocale(Locale(code));
  }

  @override
  Widget build(BuildContext context) {
    final currentCode = context.locale.languageCode;
    final isAr = currentCode == 'ar';

    return Directionality(
      textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF050505),
          elevation: 0,
          title: Text(
            'language.title'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Arabic Option
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF050505),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.3),
                  ),
                ),
                child: RadioListTile<String>(
                  value: 'ar',
                  groupValue: currentCode,
                  activeColor: const Color(0xFFD4AF37),
                  title: Text(
                    'language.arabic'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    'العربية',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  onChanged: (value) async {
                    if (value == null) return;
                    await _selectLocale(context, value);
                  },
                ),
              ),
              // English Option
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF050505),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.3),
                  ),
                ),
                child: RadioListTile<String>(
                  value: 'en',
                  groupValue: currentCode,
                  activeColor: const Color(0xFFD4AF37),
                  title: Text(
                    'language.english'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    'English',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  onChanged: (value) async {
                    if (value == null) return;
                    await _selectLocale(context, value);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
