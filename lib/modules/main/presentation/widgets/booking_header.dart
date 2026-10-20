import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/style/app_colors.dart';

class BookingHeader extends StatelessWidget {
  const BookingHeader({
    super.key,
    required this.userName,
    required this.onEdit,
    required this.onTheme,
    required this.onNotifications,
  });

  final String userName;
  final VoidCallback onEdit;
  final VoidCallback onTheme;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.brandPrimary, AppColors.brandDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'booking.subtitle'.tr(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _IconCircleButton(icon: Icons.work_outline, onPressed: onEdit),
        const SizedBox(width: 8),
        _IconCircleButton(
          icon: Icons.request_quote_outlined,
          onPressed: onTheme,
        ),
        const SizedBox(width: 8),
        _IconCircleButton(
          icon: Icons.notifications_none,
          onPressed: onNotifications,
        ),
      ],
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white2,
      elevation: 0,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18, color: Colors.black87),
        ),
      ),
    );
  }
}
