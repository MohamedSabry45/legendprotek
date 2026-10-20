import 'package:flutter/material.dart';

import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/core/widgets/logo_image_widget.dart';
import 'package:reservation_workshop/modules/notifications/presentation/widgets/notification_unread_badge.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({
    super.key,
    required this.onNotificationsPressed,
    required this.onMenuPressed,
  });

  final VoidCallback onNotificationsPressed;
  final VoidCallback onMenuPressed;

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
       
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              InkWell(
                onTap: onNotificationsPressed,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brandSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const NotificationUnreadBadge(
                    child: Icon(
                      Icons.notifications_none,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: SizedBox(
                    height: 80,
                    child: LogoImageWidget(),
                  ),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandSurface,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: onMenuPressed,
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.menu,
                    color: Colors.black87,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
