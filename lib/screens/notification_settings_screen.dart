import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _reminderEnabled = true;
  bool _weeklyDigest = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('notification_push') ?? true;
      _emailEnabled = prefs.getBool('notification_email') ?? false;
      _reminderEnabled = prefs.getBool('notification_reminder') ?? true;
      _weeklyDigest = prefs.getBool('notification_weekly') ?? false;
    });
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
            onChanged: (value) {
              setState(() => _pushEnabled = value);
              _saveSetting('notification_push', value);
            },
          ),

          const SizedBox(height: 12),

          _buildToggleCard(
            context,
            icon: PhosphorIconsRegular.alarm,
            title: l10n.notificationSettingsRemindersTitle,
            subtitle: l10n.notificationSettingsRemindersSubtitle,
            value: _reminderEnabled,
            onChanged: (value) {
              setState(() => _reminderEnabled = value);
              _saveSetting('notification_reminder', value);
            },
          ),

          const SizedBox(height: 24),

          // Email Notifications Section
          _buildSectionTitle(context, l10n.notificationSettingsEmailSection),
          const SizedBox(height: 12),
          _buildToggleCard(
            context,
            icon: PhosphorIconsRegular.envelope,
            title: l10n.notificationSettingsEmailSection,
            subtitle: l10n.notificationSettingsEmailSubtitle,
            value: _emailEnabled,
            onChanged: (value) {
              setState(() => _emailEnabled = value);
              _saveSetting('notification_email', value);
            },
          ),

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
    return Container(
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
    );
  }
}
