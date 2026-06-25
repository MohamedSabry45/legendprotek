import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/core/functions/localization_helper.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/core/widgets/slide_up_widget.dart';
import 'package:reservation_workshop/core/widgets/video_background.dart';

/// Guest Splash Screen مع فيديو background
class GuestSplashScreen extends StatefulWidget {
  const GuestSplashScreen({super.key});

  @override
  State<GuestSplashScreen> createState() => _GuestSplashScreenState();
}

class _GuestSplashScreenState extends State<GuestSplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    await CacheHelper.init();
  }

  void _toggleLanguage() {
    if (context.locale.languageCode == 'en') {
      context.setLocale(const Locale('ar'));
    } else {
      context.setLocale(const Locale('en'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLtrValue = isLtr(context);

    return Directionality(
      textDirection: isLtrValue ? ui.TextDirection.ltr : ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: VideoBackground(
          videoPath: 'assets/videos/geust_login.mp4',
          fallbackColor: Colors.black,
          overlayColor: Colors.black.withValues(alpha: 0.65),
          child: SafeArea(
            child: Column(
              children: [
                // ── Language Toggle ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: isLtrValue ? Alignment.topRight : Alignment.topLeft,
                    child: GestureDetector(
                      onTap: _toggleLanguage,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.public,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Main Content ───────────────────────────────────────────
                Expanded(
                  child: Column(
                    children: [
                      // ── Logo (Centered) ─────────────────────────────────────
                      Expanded(
                        child: Center(
                          child: SlideUpWidget(
                            delay: 800,
                            duration: 700,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 300,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── Bottom Content ─────────────────────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SlideUpWidget(
                            delay: 1100,
                            duration: 700,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                isLtrValue
                                    ? 'Login to Unlock\nawesome new features'
                                    : 'تسجيل الدخول لاكتشاف\nمميزات جديدة رائعة',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Norsal',
                                  fontSize: 16,
                                  color: Colors.white,
                                  height: 1.3,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Login Button ────────────────────────────────────
                          SlideUpWidget(
                            delay: 2100,
                            duration: 700,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: SizedBox(
                                width: double.infinity,
                                height: 54, // زيادة الارتفاع
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    RoutesName.loginScreen,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(204, 148, 114, 11),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      
                                    ),
                                    elevation: 0,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      isLtrValue ? 'Login' : 'تسجيـل الدخـول',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Norsal',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ── Footer Links ────────────────────────────────────
                          SlideUpWidget(
                            delay: 2300,
                            duration: 700,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      RoutesName.menuAboutCenterScreen,
                                    ),
                                    child: Text(
                                      isLtrValue
                                          ? 'Terms & Conditions'
                                          : 'الشروط والأحكام',
                                      style: TextStyle(
                                        fontFamily: 'Norsal',
                                        color: Colors.white70,
                                        fontSize: 14,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await CacheHelper.saveData(key: PrefKeys.kIsGuestMode, value: true);
                                      if (!mounted) return;
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        RoutesName.homeScreen,
                                        (route) => false,
                                      );
                                    },
                                    child: Text(
                                      isLtrValue ? 'Skip Login' : 'تخطي تسجيل الدخول',
                                      style: TextStyle(
                                        fontFamily: 'Norsal',
                                        color: Colors.white70,
                                        fontSize: 14,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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
    )));
  }
}
