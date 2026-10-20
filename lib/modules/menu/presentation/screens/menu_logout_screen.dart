import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'menu_placeholder_screen.dart';

class MenuLogoutScreen extends StatelessWidget {
  const MenuLogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuPlaceholderScreen(title: 'menu.logout'.tr());
  }
}
