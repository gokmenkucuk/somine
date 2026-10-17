import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:somine_app/core/services/notification_service.dart';
import 'package:somine_app/core/services/reminder_scheduler_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  /// Gerçek iOS bildirim izni (Ayarlar'dan değiştirilebilir).
  bool _pushEnabled = false;
  bool _reminderEnabled = true;
  bool _weeklyDigest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kullanıcı iOS Ayarları'ndan dönünce izni yeniden oku.
    if (state == AppLifecycleState.resumed) _refreshPushPermission();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final reminders = await ReminderSchedulerService.remindersEnabled();
    if (!mounted) return;
    setState(() {
      _reminderEnabled = reminders;
      _weeklyDigest = prefs.getBool('notification_weekly') ?? false;
    });
    await _refreshPushPermission();
  }

  Future<bool> _systemPermissionGranted() async {
    try {
      final ios = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final options = await ios?.checkPermissions();
      return options?.isEnabled ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _refreshPushPermission() async {
    final granted = await _systemPermissionGranted();
    if (mounted) setState(() => _pushEnabled = granted);
  }

  Future<void> _openSystemSettings() async {
    final uri = Uri.parse('app-settings:');
    try {
      await launchUrl(uri);
    } catch (e) {
      debugPrint('Open app settings error: $e');
    }
  }

  /// İzin henüz sorulmadıysa sistem penceresini gösterir; reddedilmişse veya
  /// kullanıcı kapatmak istiyorsa (uygulama izni geri alamaz) iOS Ayarları açılır.
  Future<void> _onPushToggled(bool value) async {
    if (value) {
      final granted = await NotificationService().requestPermissions();
      if (granted) {
        await _refreshPushPermission();
        return;
      }
    }
    await _openSystemSettings();
  }

  Future<void> _onRemindersToggled(bool value) async {
    setState(() => _reminderEnabled = value);
    await ReminderSchedulerService().setRemindersEnabled(
      value,
      userId: FirebaseAuth.instance.currentUser?.uid,
    );
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.backgroundBottom,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundTop,
        elevation: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: Icon(CupertinoIcons.back, color: context.colors.headline),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.notificationSettingsTitle,
          style: GoogleFonts.poppins(
            color: context.colors.headline,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.colors.primary.withValues(alpha: 0.1),
                  context.colors.secondary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIconsFill.bell,
                    color: context.colors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.notificationsLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.colors.headline,
                        ),
                      ),
                      Text(
                        l10n.notificationSettingsHeaderSubtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: context.colors.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Push Notifications Section
          _buildSectionTitle(context, l10n.notificationSettingsPushSection),
          const SizedBox(height: 12),
          _buildToggleCard(
            context,
            icon: PhosphorIconsRegular.deviceMobile,
            title: l10n.notificationSettingsPushTitle,
            subtitle: l10n.notificationSettingsPushSubtitle,
            value: _pushEnabled,
            onChanged: _onPushToggled,
          ),
          if (!_pushEnabled) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                onPressed: _openSystemSettings,
                child: Text(
                  l10n.notificationSettingsPushOffHint,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.colors.primary,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          _buildToggleCard(
            context,
            icon: PhosphorIconsRegular.alarm,
            title: l10n.notificationSettingsRemindersTitle,
            subtitle: l10n.notificationSettingsRemindersSubtitle,
            value: _reminderEnabled,
            onChanged: _onRemindersToggled,
          ),

          const SizedBox(height: 24),

          const SizedBox(height: 12),

          _buildToggleCard(
            context,
            icon: PhosphorIconsRegular.calendar,
            title: l10n.notificationSettingsWeeklyDigestTitle,
            subtitle: l10n.notificationSettingsWeeklyDigestSubtitle,
            value: _weeklyDigest,
            onChanged: (value) {
              setState(() => _weeklyDigest = value);
              _saveSetting('notification_weekly', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.colors.body,
        ),
      ),
    );
  }

  Widget _buildToggleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    // Başlık + alt başlık + anahtar VoiceOver'da tek öğe olarak okunsun.
    return MergeSemantics(
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: context.colors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.colors.headline,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.colors.body,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: context.colors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    ),
    );
  }
}
