import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/models/notification_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:somine_app/core/utils/notification_display.dart';

class InAppNotificationBannerService {
  factory InAppNotificationBannerService() => _instance;

  InAppNotificationBannerService._();

  static final InAppNotificationBannerService _instance =
      InAppNotificationBannerService._();

  final Queue<_BannerRequest> _queue = Queue<_BannerRequest>();
  final Set<String> _queuedIds = <String>{};
  bool _isShowing = false;

  void show({
    required OverlayState overlay,
    required NotificationModel notification,
    VoidCallback? onTap,
  }) {
    final notificationId = notification.id;
    if (notificationId != null && _queuedIds.contains(notificationId)) {
      return;
    }

    final request = _BannerRequest(
      overlay: overlay,
      notification: notification,
      onTap: onTap,
    );
    _queue.add(request);
    if (notificationId != null) {
      _queuedIds.add(notificationId);
    }
    unawaited(_drainQueue());
  }

  Future<void> _drainQueue() async {
    if (_isShowing) {
      return;
    }

    _isShowing = true;
    try {
      while (_queue.isNotEmpty) {
        final request = _queue.removeFirst();
        final notificationId = request.notification.id;
        if (notificationId != null) {
          _queuedIds.remove(notificationId);
        }
        await _showRequest(request);
      }
    } finally {
      _isShowing = false;
    }
  }

  Future<void> _showRequest(_BannerRequest request) async {
    final completer = Completer<void>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (context) => _InAppNotificationBanner(
            notification: request.notification,
            onTap: request.onTap,
            onDismissed: () {
              if (!completer.isCompleted) {
                completer.complete();
              }
              entry.remove();
            },
          ),
    );

    request.overlay.insert(entry);
    await completer.future;
  }
}

class _BannerRequest {
  const _BannerRequest({
    required this.overlay,
    required this.notification,
    this.onTap,
  });

  final OverlayState overlay;
  final NotificationModel notification;
  final VoidCallback? onTap;
}

class _InAppNotificationBanner extends StatefulWidget {
  const _InAppNotificationBanner({
    required this.notification,
    required this.onDismissed,
    this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onDismissed;
  final VoidCallback? onTap;

  @override
  State<_InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<_InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _dismissTimer;
  bool _isClosing = false;
  bool _started = false;

  /// "Hareketi Azalt" açıksa kayma/solma animasyonu atlanır.
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 240),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _dismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!_started) {
      _started = true;
      if (_reduceMotion) {
        _controller.value = 1;
      } else {
        unawaited(_controller.forward());
      }
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_isClosing) {
      return;
    }

    _isClosing = true;
    _dismissTimer?.cancel();
    if (!_reduceMotion) {
      await _controller.reverse();
    }
    if (mounted) {
      widget.onDismissed();
    }
  }

  Future<void> _handleTap() async {
    widget.onTap?.call();
    await _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = _BannerAppearance.fromNotification(
      context,
      widget.notification,
    );

    return IgnorePointer(
      ignoring: false,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: _handleTap,
                    onVerticalDragEnd: (details) {
                      if ((details.primaryVelocity ?? 0) < -120) {
                        unawaited(_dismiss());
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 520),
                          padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                          decoration: BoxDecoration(
                            color: appearance.backgroundColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: appearance.borderColor,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: appearance.shadowColor,
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      appearance.accentColor,
                                      appearance.secondaryAccentColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  appearance.icon,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      NotificationDisplay.title(
                                        AppLocalizations.of(context)!,
                                        widget.notification,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: appearance.titleColor,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      NotificationDisplay.message(
                                        AppLocalizations.of(context)!,
                                        widget.notification,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: appearance.bodyColor,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 2),
                              // Görsel 24pt daire korunur; dokunma alanı 44pt.
                              Semantics(
                                button: true,
                                label: MaterialLocalizations.of(
                                  context,
                                ).closeButtonTooltip,
                                excludeSemantics: true,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => unawaited(_dismiss()),
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Center(
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color:
                                              appearance.dismissBackgroundColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          PhosphorIconsRegular.x,
                                          size: 12,
                                          color: appearance.dismissIconColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerAppearance {
  const _BannerAppearance({
    required this.icon,
    required this.accentColor,
    required this.secondaryAccentColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
    required this.titleColor,
    required this.bodyColor,
    required this.dismissBackgroundColor,
    required this.dismissIconColor,
  });

  final IconData icon;
  final Color accentColor;
  final Color secondaryAccentColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final Color titleColor;
  final Color bodyColor;
  final Color dismissBackgroundColor;
  final Color dismissIconColor;

  factory _BannerAppearance.fromNotification(
    BuildContext context,
    NotificationModel notification,
  ) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseSurface =
        isDark
            ? colors.surfaceWhite.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.92);
    final titleColor = colors.headline;
    // Saydamlık yok: body tokenı yüzeyine karşı ≥4.5:1 hesaplandı.
    final bodyColor = colors.body;
    final dismissBg =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : colors.backgroundTop.withValues(alpha: 0.9);
    final dismissIcon =
        isDark ? Colors.white.withValues(alpha: 0.8) : colors.hint;

    switch (notification.type) {
      case NotificationType.shareRequest:
        return _BannerAppearance(
          icon: PhosphorIconsRegular.shareNetwork,
          accentColor: colors.primary,
          secondaryAccentColor: colors.secondary,
          backgroundColor: baseSurface,
          borderColor: colors.primary.withValues(alpha: 0.18),
          shadowColor: colors.primary.withValues(alpha: 0.16),
          titleColor: titleColor,
          bodyColor: bodyColor,
          dismissBackgroundColor: dismissBg,
          dismissIconColor: dismissIcon,
        );
      case NotificationType.shareAccepted:
        return _BannerAppearance(
          icon: PhosphorIconsRegular.checkCircle,
          accentColor: colors.success,
          secondaryAccentColor: colors.secondary,
          backgroundColor: baseSurface,
          borderColor: colors.success.withValues(alpha: 0.18),
          shadowColor: colors.success.withValues(alpha: 0.14),
          titleColor: titleColor,
          bodyColor: bodyColor,
          dismissBackgroundColor: dismissBg,
          dismissIconColor: dismissIcon,
        );
      case NotificationType.shareRejected:
        return _BannerAppearance(
          icon: PhosphorIconsRegular.xCircle,
          accentColor: colors.danger,
          secondaryAccentColor: colors.secondary,
          backgroundColor: baseSurface,
          borderColor: colors.danger.withValues(alpha: 0.18),
          shadowColor: colors.danger.withValues(alpha: 0.14),
          titleColor: titleColor,
          bodyColor: bodyColor,
          dismissBackgroundColor: dismissBg,
          dismissIconColor: dismissIcon,
        );
      case NotificationType.reminder:
        return _BannerAppearance(
          icon: PhosphorIconsRegular.alarm,
          accentColor: colors.primary,
          secondaryAccentColor: colors.secondary,
          backgroundColor: baseSurface,
          borderColor: colors.primary.withValues(alpha: 0.18),
          shadowColor: colors.primary.withValues(alpha: 0.16),
          titleColor: titleColor,
          bodyColor: bodyColor,
          dismissBackgroundColor: dismissBg,
          dismissIconColor: dismissIcon,
        );
      case NotificationType.unknown:
        return _BannerAppearance(
          icon: PhosphorIconsRegular.bell,
          accentColor: colors.iconInactive,
          secondaryAccentColor: colors.secondary,
          backgroundColor: baseSurface,
          borderColor: colors.iconInactive.withValues(alpha: 0.18),
          shadowColor: colors.iconInactive.withValues(alpha: 0.14),
          titleColor: titleColor,
          bodyColor: bodyColor,
          dismissBackgroundColor: dismissBg,
          dismissIconColor: dismissIcon,
        );
    }
  }
}
