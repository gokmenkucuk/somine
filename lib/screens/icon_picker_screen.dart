import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/services/icon_service.dart';
import 'package:somine_app/core/providers/subscription_provider.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/screens/paywall_screen.dart';

class IconPickerScreen extends ConsumerStatefulWidget {
  const IconPickerScreen({super.key});

  @override
  ConsumerState<IconPickerScreen> createState() => _IconPickerScreenState();
}

class _IconPickerScreenState extends ConsumerState<IconPickerScreen> {
  final IconService _iconService = IconService();
  String? _currentIcon;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentIcon();
  }

  Future<void> _loadCurrentIcon() async {
    final iconName = await _iconService.getCurrentIcon();
    if (mounted) {
      setState(() {
        _currentIcon = iconName ?? 'default';
        _isLoading = false;
      });
    }
  }

  Future<void> _changeIcon(AppIcon icon) async {
    // Premium check
    final subscriptionState = ref.read(subscriptionProvider);
    if (icon.isPremium && !subscriptionState.isPremium) {
      // Show Paywall
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const PaywallScreen(),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      // 'default' passed to setIcon will reset it (handled in service)
      await _iconService.setIcon(icon.key);
      await _loadCurrentIcon();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${icon.name} uygulandı!'),
            backgroundColor: context.colors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error changing icon: $e');
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final isPremium = subscriptionState.isPremium;

    return Scaffold(
      backgroundColor: context.colors.backgroundTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: context.colors.headline),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Uygulama İkonu",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: context.colors.headline,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85, 
              ),
              itemCount: IconService.icons.length,
              itemBuilder: (context, index) {
                final icon = IconService.icons[index];
                final isSelected = _currentIcon == icon.key;
                final isLocked = icon.isPremium && !isPremium;

                return GestureDetector(
                  onTap: () => _changeIcon(icon),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? context.colors.primary.withOpacity(0.1) 
                          : context.colors.surfaceWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected 
                            ? context.colors.primary 
                            : (isLocked ? context.colors.secondary.withOpacity(0.2) : Colors.transparent),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: context.colors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
                          : [BoxShadow(color: context.colors.premiumShadow.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            // Icon Preview
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: context.colors.backgroundTop, // Placeholder bg
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  icon.previewAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Center(
                                    child: Icon(PhosphorIconsDuotone.image, size: 32, color: context.colors.hint),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Lock Overlay
                            if (isLocked)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Center(
                                    child: Icon(PhosphorIconsFill.lockKey, color: Colors.white, size: 28),
                                  ),
                                ),
                              ),
                              

                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          icon.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? context.colors.primary : context.colors.headline,
                          ),
                        ),
                        if (isLocked) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Premium",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: context.colors.secondary,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
