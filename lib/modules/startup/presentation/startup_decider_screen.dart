import 'package:flutter/material.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/constants/app_constants.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';

class StartupDeciderScreen extends StatefulWidget {
  const StartupDeciderScreen({super.key});

  @override
  State<StartupDeciderScreen> createState() => _StartupDeciderScreenState();
}

class _StartupDeciderScreenState extends State<StartupDeciderScreen> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    await CacheHelper.init();

    final String? localeCode = CacheHelper.getData<String>(key: PrefKeys.kLocaleCode);
    if (localeCode == null || localeCode.trim().isEmpty) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        RoutesName.firstLanguageScreen,
        (route) => false,
      );
      return;
    }

    final String? baseUrl = CacheHelper.getData<String>(key: PrefKeys.kBaseUrlCode);
    if (baseUrl != null && baseUrl.trim().isNotEmpty) {
      AppConstants.kBaseUrl = baseUrl.trim();
    }

    final String? token = CacheHelper.getData<String>(key: PrefKeys.kAccessToken);

    if (token != null && token.trim().isNotEmpty) {
      AppConstants.token = token;
    }

    if (!mounted) return;

    // Navigate based on login state
    if (token != null && token.trim().isNotEmpty) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RoutesName.chooseCarScreen,
        (route) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RoutesName.guestSplashScreen,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
