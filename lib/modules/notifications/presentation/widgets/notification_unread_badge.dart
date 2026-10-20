import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/modules/notifications/presentation/cubit/user_notifications_badge_cubit.dart';

class NotificationUnreadBadge extends StatelessWidget {
  const NotificationUnreadBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserNotificationsBadgeCubit, int>(
      builder: (context, count) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: IgnorePointer(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
