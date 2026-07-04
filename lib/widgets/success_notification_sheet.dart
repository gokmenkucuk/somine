import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';

class SuccessNotificationSheet extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback? onUndo;

  const SuccessNotificationSheet({
    super.key,
    required this.title,
    required this.message,
    this.onUndo,
  });

  static Future<void> show(BuildContext context, {
    required String title, 
    required String message,
    VoidCallback? onUndo,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SuccessNotificationSheet(
        title: title,
        message: message,
        onUndo: onUndo,
      ),
    );
  }

  @override
  State<SuccessNotificationSheet> createState() => _SuccessNotificationSheetState();
}

class _SuccessNotificationSheetState extends State<SuccessNotificationSheet> {
  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 4 seconds if undo is present, else 2
    Future.delayed(Duration(seconds: widget.onUndo != null ? 4 : 2), () {
      if (mounted) {
        _safePop();
      }
    });
  }

  /// Safely pops the bottom sheet only if it's the current route
  void _safePop() {
    final route = ModalRoute.of(context);
    if (route?.isCurrent == true) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primary,
            context.colors.secondary,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 56),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 32),

                // Icon Circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      PhosphorIconsBold.check,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
                if (widget.onUndo != null) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onUndo!();
                        _safePop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: context.colors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Geri Al",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Close Button
          Positioned(
            top: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _safePop,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    PhosphorIconsLight.x,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
