import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/notifications/notification_service.dart';
import 'package:reservation_workshop/core/widgets/app_header.dart';
import 'package:reservation_workshop/modules/notifications/data/models/user_notification_model.dart';
import 'package:reservation_workshop/modules/notifications/presentation/cubit/user_notifications_badge_cubit.dart';
import 'package:reservation_workshop/modules/notifications/presentation/cubit/user_notifications_cubit.dart';
import 'package:reservation_workshop/modules/notifications/presentation/cubit/user_notifications_state.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserNotificationsCubit>().refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'notifications.title'.tr(),
                onBack: () => Navigator.pop(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.brandSurface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.brandDark,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.brandDark,
                    ),
                    tabs: [
                      Tab(text: 'notifications.unread'.tr()),
                      Tab(text: 'notifications.read'.tr()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<UserNotificationsCubit,
                    UserNotificationsState>(
                  builder: (context, state) {
                    if (state is UserNotificationsLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (state is UserNotificationsError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            Toasters.displayMessage(state.message),
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey7,
                            ),
                          ),
                        ),
                      );
                    }

                    final items = state is UserNotificationsSuccess
                        ? state.notifications
                        : const <UserNotificationModel>[];
                    final unread = items.where((n) => !n.isRead).toList();
                    final read = items.where((n) => n.isRead).toList();

                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          'notifications.empty'.tr(),
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey7,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.grey7,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await context
                                      .read<UserNotificationsCubit>()
                                      .markAllRead();
                                  if (!context.mounted) return;
                                  context
                                      .read<UserNotificationsBadgeCubit>()
                                      .refresh();
                                },
                                child: Text(
                                  'notifications.mark_all_read'.tr(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _NotificationsList(
                                items: unread,
                                emptyText:
                                    'notifications.empty_unread'.tr(),
                                isLoadingMore: state
                                        is UserNotificationsSuccess &&
                                    state.isLoadingMore,
                                hasMore: state is UserNotificationsSuccess &&
                                    state.hasMore,
                                onLoadMore: () => context
                                    .read<UserNotificationsCubit>()
                                    .loadMore(),
                                onRefresh: () => context
                                    .read<UserNotificationsCubit>()
                                    .refresh(),
                                onRemove: (id) => context
                                    .read<UserNotificationsCubit>()
                                    .remove(id),
                                onTap: (item) => _onItemTap(context, item),
                              ),
                              _NotificationsList(
                                items: read,
                                emptyText: 'notifications.empty_read'.tr(),
                                isLoadingMore: state
                                        is UserNotificationsSuccess &&
                                    state.isLoadingMore,
                                hasMore: state is UserNotificationsSuccess &&
                                    state.hasMore,
                                onLoadMore: () => context
                                    .read<UserNotificationsCubit>()
                                    .loadMore(),
                                onRefresh: () => context
                                    .read<UserNotificationsCubit>()
                                    .refresh(),
                                onRemove: (id) => context
                                    .read<UserNotificationsCubit>()
                                    .remove(id),
                                onTap: (item) => _onItemTap(context, item),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Future<void> _onItemTap(
    BuildContext context,
    UserNotificationModel item,
  ) async {
    if (!item.isRead) {
      await context.read<UserNotificationsCubit>().markRead(item.id);
      if (!context.mounted) return;
      context.read<UserNotificationsBadgeCubit>().refresh();
    }
    NotificationService.handleNotificationData(<String, dynamic>{
      ...?item.data,
      'type': item.type,
      'reference_id': item.referenceId,
    });
  }
}

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({
    required this.items,
    required this.emptyText,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onRemove,
    required this.onTap,
  });

  final List<UserNotificationModel> items;
  final String emptyText;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final void Function(String id) onRemove;
  final void Function(UserNotificationModel item) onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          onLoadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      emptyText,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey7,
                      ),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: items.length + (isLoadingMore || hasMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final item = items[index];
                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => onRemove(item.id),
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                    ),
                    child: _NotificationTile(
                      item: item,
                      onTap: () => onTap(item),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final UserNotificationModel item;
  final VoidCallback onTap;

  bool get _isChatType {
    final t = item.type.toLowerCase();
    return t.contains('chat');
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = item.title.trim().isNotEmpty
        ? item.title
        : 'notifications.new_notification'.tr();
    final date = _formatDate(item.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.brandSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.brandOutline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.isRead
                      ? const Color(0xFFE5E7EB)
                      : AppColors.brandPrimarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isChatType
                      ? Icons.chat_bubble_outline
                      : Icons.notifications,
                  color: item.isRead ? AppColors.grey7 : AppColors.brandPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandDark,
                      ),
                    ),
                    if (item.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey7,
                        ),
                      ),
                    ],
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        date,
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey7,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!item.isRead)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.brandPrimary,
                      shape: BoxShape.circle,
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
