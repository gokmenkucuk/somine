import 'package:flutter/material.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';

/// Uygulamanın standart yüzen daire buton dili.
///
/// İçeriğin üzerinde `Positioned` ile yüzer; açık zeminli, ince kenarlıklı
/// ve yumuşak gölgeli 44x44 daire. İkonlar phosphor ailesinden gelir.
///
/// Yalnız ikon içerdiği için [semanticLabel] zorunludur: VoiceOver bu
/// etiketi okur, uzun basışta da tooltip olarak gösterilir.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.iconSize = 20,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;

  /// VoiceOver etiketi ve tooltip metni (yerelleştirilmiş olmalı).
  final String semanticLabel;

  /// Devre dışıyken VoiceOver "soluk" okur; dokunma yine [onTap]'e gider
  /// (görsel soluklaştırmayı çağıran yapar).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          shape: BoxShape.circle,
          border: Border.all(
            color: context.colors.hint.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: iconSize, color: context.colors.headline),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(message: semanticLabel, child: button),
    );
  }
}
