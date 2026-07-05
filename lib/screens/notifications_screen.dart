import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/models/notification_model.dart';
import 'package:somine_app/core/providers/notification_providers.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/screens/share_requests_screen.dart';
import 'package:somine_app/screens/my_shares_screen.dart';
import 'package:somine_app/widgets/error_state_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.colors.backgroundBottom,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundTop,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: context.colors.headline),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.notificationsLabel,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: context.colors.headline,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(context, ref),
            child: Text(
              l10n.notificationsMarkAllRead,
              style: GoogleFonts.poppins(
                color: context.colors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Dismissible(
                key: Key(notification.id ?? UniqueKey().toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(PhosphorIconsRegular.trash, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _deleteNotification(context, ref, notification.id!);
                },
                child: _NotificationCard(notification: notification),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(
          message: l10n.notificationsLoadError,
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.bellSlash,
            size: 64,
            color: context.colors.iconInactive,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.notificationsEmptyTitle,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colors.headline,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              l10n.notificationsEmptySubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: context.colors.body.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead(BuildContext context, WidgetRef ref) async {
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;
      
      await ref.read(notificationRepositoryProvider).markAllAsRead(user.uid);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _deleteNotification(BuildContext context, WidgetRef ref, String notificationId) async {
    try {
      await ref.read(notificationRepositoryProvider).deleteNotification(notificationId);
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.notificationsDeleteFailed(e.toString()))),
        );
      }
    }
  }
}

class _NotificationCard extends ConsumerWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.shareRequest:
        icon = PhosphorIconsRegular.shareNetwork;
        iconColor = Colors.blue;
        break;
      case NotificationType.shareAccepted:
        icon = PhosphorIconsRegular.checkCircle;
        iconColor = Colors.green;
        break;
      case NotificationType.shareRejected:
        icon = PhosphorIconsRegular.xCircle;
        iconColor = Colors.red;
        break;
    }

    return GestureDetector(
      onTap: () => _handleTap(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? context.colors.surfaceWhite
              : context.colors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: notification.isRead
              ? null
              : Border.all(color: context.colors.primary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: context.colors.headline,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: context.colors.body,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeago.format(notification.createdAt, locale: 'tr'),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: context.colors.hint,
                      // Tarih formatını 24 saatlik yapmak isterseniz locale dosyasını kontrol etmek gerekebilir
                      // timeago varsayılan 'tr' kullanır
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

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    // Mark as read
    if (!notification.isRead) {
      await ref.read(notificationRepositoryProvider).markAsRead(notification.id!);
    }

    // Navigate based on type
    if (context.mounted) {
      if (notification.type == NotificationType.shareRequest) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShareRequestsScreen()),
        );
      } else if (notification.type == NotificationType.shareAccepted || 
                 notification.type == NotificationType.shareRejected) {
        // Eğer kabul edildiyse veya reddedildiyse "Paylaştıklarım" ekranına gitmek mantıklı olabilir
        // Çünkü siz paylaştınız ve sonuçlandı
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MySharesScreen()),
        );
      }
    }
  }
}
