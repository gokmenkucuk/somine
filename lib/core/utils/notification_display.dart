import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:somine_app/core/models/notification_model.dart';

/// Sunucudan gelen bildirim metinleri Türkçe üretiliyor (eski istemcilerin
/// bozulmaması için öyle kalmalı). İstemci, tipini tanıdığı bildirimleri
/// `data` alanındaki yapısal bilgiden kendi dilinde yeniden yazar; alan
/// eksikse sunucunun metnine düşer.
class NotificationDisplay {
  static String title(AppLocalizations l10n, NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.shareRequest:
        return l10n.notificationShareRequestTitle;
      case NotificationType.shareAccepted:
        return l10n.notificationShareAcceptedTitle;
      case NotificationType.shareRejected:
        return l10n.notificationShareRejectedTitle;
      case NotificationType.reminder:
      // Hatırlatıcıda başlık, sunucunun ürettiği bir metin değil, içeriğin
      // kendi başlığı — çevrilmez.
      case NotificationType.unknown:
        return notification.title;
    }
  }

  static String message(AppLocalizations l10n, NotificationModel notification) {
    final sender = _stringOrNull(notification.data['fromUserName']);
    final collection = _stringOrNull(notification.data['categoryName']);

    switch (notification.type) {
      case NotificationType.shareRequest:
        if (sender == null || collection == null) return notification.message;
        return l10n.notificationShareRequestMessage(sender, collection);
      case NotificationType.shareAccepted:
        if (collection == null) return notification.message;
        return l10n.notificationShareAcceptedMessage(collection);
      case NotificationType.shareRejected:
        if (collection == null) return notification.message;
        return l10n.notificationShareRejectedMessage(collection);
      case NotificationType.reminder:
        return l10n.notificationReminderMessage;
      case NotificationType.unknown:
        return notification.message;
    }
  }

  static String? _stringOrNull(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }
}
