TASK 1: Design Tokens (Temel)
📁 Dosya: lib/core/design/design_tokens.dart
📝 Trae'ye Komut:

"Bu dosyayı tamamen sil ve aşağıdaki kod ile değiştir. So Mine uygulaması için Soft UI design token'ları."

dartimport 'package:flutter/material.dart';

/// So Mine Design Tokens
/// "Soft & Cozy" tasarım dili için temel değerler
class SoMineTokens {
  SoMineTokens._();

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Zemin rengi - Asla çiğ beyaz değil, hafif puslu lila-gri
  static const Color background = Color(0xFFF2F1F6);
  
  /// Kart rengi - Saf beyaz, zeminle kontrast için
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  /// Metin rengi - Simsiyah değil, asil lacivert
  static const Color textPrimary = Color(0xFF1A1E38);
  static const Color textSecondary = Color(0xFF6B7080);
  static const Color textTertiary = Color(0xFF9CA3AF);
  
  /// Accent Gradient - Turkuazdan maviye
  static const Color accentStart = Color(0xFF22D3EE); // Turkuaz
  static const Color accentEnd = Color(0xFF0EA5E9);   // Mavi
  
  /// Gradient preset
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentStart, accentEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SHOWCASE CATEGORY GRADIENTS (5 özel gradient)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const LinearGradient gradientSunset = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientOcean = LinearGradient(
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientForest = LinearGradient(
    colors: [Color(0xFF38EF7D), Color(0xFF11998E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientPurple = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientRose = LinearGradient(
    colors: [Color(0xFFFB7185), Color(0xFFFDA4AF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<LinearGradient> showcaseGradients = [
    gradientSunset,
    gradientOcean,
    gradientForest,
    gradientPurple,
    gradientRose,
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // SHADOWS - Soft, bulanık, pastel gölgeler
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Kart gölgesi - Havada asılı hissi
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF1A1E38).withOpacity(0.04),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0xFF1A1E38).withOpacity(0.02),
      blurRadius: 40,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];
  
  /// Yükseltilmiş kart gölgesi (hover/press state)
  static List<BoxShadow> get cardShadowElevated => [
    BoxShadow(
      color: const Color(0xFF1A1E38).withOpacity(0.08),
      blurRadius: 30,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0xFF1A1E38).withOpacity(0.04),
      blurRadius: 60,
      offset: const Offset(0, 16),
      spreadRadius: 0,
    ),
  ];

  /// Bottom navigation gölgesi
  static List<BoxShadow> get bottomNavShadow => [
    BoxShadow(
      color: const Color(0xFF1A1E38).withOpacity(0.06),
      blurRadius: 20,
      offset: const Offset(0, -4),
      spreadRadius: 0,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS - Yuvarlak hatlar
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 24.0;
  static const double radiusRound = 100.0; // Tam yuvarlak

  // ═══════════════════════════════════════════════════════════════════════════
  // SPACING
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingSection = 32.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT CARD ASPECT RATIOS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double aspectRatioPinterest = 3 / 4;   // Dikey
  static const double aspectRatioInstagram = 1 / 1;   // Kare
  static const double aspectRatioYouTube = 16 / 9;    // Yatay
  static const double aspectRatioDefault = 4 / 3;     // Varsayılan

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATION DURATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVacuum = Duration(milliseconds: 800);

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY SIZES
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double fontSizeXS = 11.0;
  static const double fontSizeS = 13.0;
  static const double fontSizeM = 15.0;
  static const double fontSizeL = 17.0;
  static const double fontSizeXL = 20.0;
  static const double fontSizeXXL = 24.0;
  static const double fontSizeHeading = 28.0;
}

🎯 TASK 2: App Theme
📁 Dosya: lib/core/design/app_theme.dart
📝 Trae'ye Komut:

"Bu dosyayı tamamen sil ve aşağıdaki kod ile değiştir. Poppins font kullanan Soft UI tema."

dartimport 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Scaffold & Background
      scaffoldBackgroundColor: SoMineTokens.background,
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: SoMineTokens.accentEnd,
        secondary: SoMineTokens.accentStart,
        surface: SoMineTokens.cardBackground,
        background: SoMineTokens.background,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: SoMineTokens.textPrimary,
        onBackground: SoMineTokens.textPrimary,
      ),
      
      // Typography - Poppins
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: SoMineTokens.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: SoMineTokens.fontSizeHeading,
          fontWeight: FontWeight.w600,
          color: SoMineTokens.textPrimary,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: SoMineTokens.fontSizeXXL,
          fontWeight: FontWeight.w600,
          color: SoMineTokens.textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: SoMineTokens.fontSizeXL,
          fontWeight: FontWeight.w600,
          color: SoMineTokens.textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: SoMineTokens.fontSizeL,
          fontWeight: FontWeight.w600,
          color: SoMineTokens.textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: SoMineTokens.fontSizeM,
          fontWeight: FontWeight.w500,
          color: SoMineTokens.textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: SoMineTokens.fontSizeM,
          fontWeight: FontWeight.w400,
          color: SoMineTokens.textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: SoMineTokens.fontSizeS,
          fontWeight: FontWeight.w400,
          color: SoMineTokens.textSecondary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: SoMineTokens.fontSizeXS,
          fontWeight: FontWeight.w400,
          color: SoMineTokens.textTertiary,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: SoMineTokens.fontSizeS,
          fontWeight: FontWeight.w500,
          color: SoMineTokens.textPrimary,
        ),
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: SoMineTokens.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: SoMineTokens.fontSizeXL,
          fontWeight: FontWeight.w600,
          color: SoMineTokens.textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: SoMineTokens.textPrimary,
        ),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: SoMineTokens.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SoMineTokens.cardBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SoMineTokens.spacingL,
          vertical: SoMineTokens.spacingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
          borderSide: const BorderSide(
            color: SoMineTokens.accentEnd,
            width: 2,
          ),
        ),
        hintStyle: GoogleFonts.poppins(
          color: SoMineTokens.textTertiary,
          fontSize: SoMineTokens.fontSizeM,
        ),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SoMineTokens.accentEnd,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: SoMineTokens.spacingXXL,
            vertical: SoMineTokens.spacingL,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: SoMineTokens.fontSizeM,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: SoMineTokens.cardBackground,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: SoMineTokens.accentEnd,
        unselectedItemColor: SoMineTokens.textTertiary,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: SoMineTokens.fontSizeXS,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: SoMineTokens.fontSizeXS,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
        space: 1,
      ),
    );
  }
}

🎯 TASK 3: Soft Card Widget
📁 Dosya: lib/widgets/soft_card.dart (YENİ)
📝 Trae'ye Komut:

"Yeni dosya oluştur. Havada asılı görünen, blur gölgeli temel kart bileşeni."

dartimport 'package:flutter/material.dart';
import 'package:somine_app/core/design/design_tokens.dart';

/// Soft UI kart bileşeni
/// Havada asılı görünüm için blur shadow kullanır
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool elevated;

  const SoftCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: SoMineTokens.cardBackground,
        borderRadius: BorderRadius.circular(
          borderRadius ?? SoMineTokens.radiusLarge,
        ),
        boxShadow: elevated 
            ? SoMineTokens.cardShadowElevated 
            : SoMineTokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          borderRadius ?? SoMineTokens.radiusLarge,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            borderRadius ?? SoMineTokens.radiusLarge,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(SoMineTokens.spacingL),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Gradient arka planlı soft card
class GradientSoftCard extends StatelessWidget {
  final Widget child;
  final LinearGradient gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;

  const GradientSoftCard({
    super.key,
    required this.child,
    required this.gradient,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(
          borderRadius ?? SoMineTokens.radiusLarge,
        ),
        boxShadow: SoMineTokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          borderRadius ?? SoMineTokens.radiusLarge,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            borderRadius ?? SoMineTokens.radiusLarge,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(SoMineTokens.spacingL),
            child: child,
          ),
        ),
      ),
    );
  }
}

🎯 TASK 4: Content Card (Platform-Aware)
📁 Dosya: lib/widgets/item_card.dart
📝 Trae'ye Komut:

"Bu dosyayı tamamen sil ve aşağıdaki kod ile değiştir. Pinterest/Instagram/YouTube için farklı aspect ratio kullanan içerik kartı."

dartimport 'package:flutter/material.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/models/item_model.dart';

/// Platform tipine göre aspect ratio döndürür
double getAspectRatioForPlatform(String? platform) {
  switch (platform?.toLowerCase()) {
    case 'pinterest':
      return SoMineTokens.aspectRatioPinterest; // 3:4 Dikey
    case 'instagram':
      return SoMineTokens.aspectRatioInstagram; // 1:1 Kare
    case 'youtube':
      return SoMineTokens.aspectRatioYouTube;   // 16:9 Yatay
    case 'twitter':
    case 'x':
      return SoMineTokens.aspectRatioInstagram; // 1:1 Kare
    default:
      return SoMineTokens.aspectRatioDefault;   // 4:3
  }
}

/// Platform ikonunu döndürür
IconData getPlatformIcon(String? platform) {
  switch (platform?.toLowerCase()) {
    case 'pinterest':
      return Icons.push_pin_rounded;
    case 'instagram':
      return Icons.camera_alt_rounded;
    case 'youtube':
      return Icons.play_circle_rounded;
    case 'twitter':
    case 'x':
      return Icons.alternate_email_rounded;
    case 'spotify':
      return Icons.music_note_rounded;
    default:
      return Icons.link_rounded;
  }
}

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback? onTap;
  final double? width;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final aspectRatio = getAspectRatioForPlatform(item.platform);
    final cardWidth = width ?? 160.0;
    final cardHeight = cardWidth / aspectRatio;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight + 56, // Başlık için ekstra alan
        decoration: BoxDecoration(
          color: SoMineTokens.cardBackground,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
          boxShadow: SoMineTokens.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Görsel Alanı
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(SoMineTokens.radiusLarge),
              ),
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Görsel
                    _buildImage(),
                    
                    // Platform Badge
                    Positioned(
                      top: SoMineTokens.spacingS,
                      right: SoMineTokens.spacingS,
                      child: _buildPlatformBadge(),
                    ),
                    
                    // Bookmark Icon
                    Positioned(
                      top: SoMineTokens.spacingS,
                      left: SoMineTokens.spacingS,
                      child: _buildBookmarkIcon(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Başlık Alanı
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(SoMineTokens.spacingM),
                child: Text(
                  item.title ?? item.domain ?? 'Başlıksız',
                  style: Theme.of(context).textTheme.labelLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return Image.network(
        item.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingPlaceholder();
        },
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: SoMineTokens.background,
      child: Center(
        child: Icon(
          getPlatformIcon(item.platform),
          size: 40,
          color: SoMineTokens.textTertiary,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: SoMineTokens.background,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: SoMineTokens.accentEnd,
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformBadge() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(SoMineTokens.radiusSmall),
      ),
      child: Icon(
        getPlatformIcon(item.platform),
        size: 14,
        color: Colors.white,
      ),
    );
  }

  Widget _buildBookmarkIcon() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(SoMineTokens.radiusSmall),
      ),
      child: const Icon(
        Icons.bookmark_rounded,
        size: 14,
        color: Colors.white,
      ),
    );
  }
}

TASK 5: Content Swimlane Widget
📁 Dosya: lib/widgets/content_swimlane.dart
📝 Trae'ye Komut:

"Bu dosyayı tamamen sil ve aşağıdaki kod ile değiştir. Netflix tarzı yatay kaydırmalı içerik rafı."

dartimport 'package:flutter/material.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/widgets/item_card.dart';

/// Yatay kaydırmalı içerik rafı (Swimlane)
/// Netflix/Apple Photos tarzı layout
class ContentSwimlane extends StatelessWidget {
  final CategoryModel category;
  final List<ItemModel> items;
  final VoidCallback? onSeeAllTap;
  final Function(ItemModel)? onItemTap;
  final double cardWidth;

  const ContentSwimlane({
    super.key,
    required this.category,
    required this.items,
    this.onSeeAllTap,
    this.onItemTap,
    this.cardWidth = 160,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(context),
        
        const SizedBox(height: SoMineTokens.spacingM),
        
        // Horizontal List
        SizedBox(
          height: _calculateMaxHeight(),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: SoMineTokens.spacingL,
            ),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(
              width: SoMineTokens.spacingM,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return ItemCard(
                item: item,
                width: cardWidth,
                onTap: () => onItemTap?.call(item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SoMineTokens.spacingL,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Kategori adı ve emoji
          Row(
            children: [
              Text(
                category.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (category.emoji != null) ...[
                const SizedBox(width: SoMineTokens.spacingS),
                Text(
                  category.emoji!,
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ],
          ),
          
          // "Tümü" butonu
          GestureDetector(
            onTap: onSeeAllTap,
            child: Row(
              children: [
                Text(
                  'Tümü',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: SoMineTokens.accentEnd,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: SoMineTokens.accentEnd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Farklı aspect ratio'lar için maksimum yüksekliği hesapla
  double _calculateMaxHeight() {
    double maxHeight = 0;
    for (final item in items) {
      final aspectRatio = getAspectRatioForPlatform(item.platform);
      final cardHeight = cardWidth / aspectRatio + 56; // +56 başlık için
      if (cardHeight > maxHeight) {
        maxHeight = cardHeight;
      }
    }
    return maxHeight > 0 ? maxHeight : 250;
  }
}

/// Kompakt swimlane - daha küçük kartlar için
class CompactSwimlane extends StatelessWidget {
  final String title;
  final String? emoji;
  final List<ItemModel> items;
  final VoidCallback? onSeeAllTap;
  final Function(ItemModel)? onItemTap;

  const CompactSwimlane({
    super.key,
    required this.title,
    this.emoji,
    required this.items,
    this.onSeeAllTap,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SoMineTokens.spacingL,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (emoji != null) ...[
                    const SizedBox(width: SoMineTokens.spacingS),
                    Text(emoji!, style: const TextStyle(fontSize: 20)),
                  ],
                ],
              ),
              GestureDetector(
                onTap: onSeeAllTap,
                child: Row(
                  children: [
                    Text(
                      'Tümü',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SoMineTokens.accentEnd,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: SoMineTokens.accentEnd,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: SoMineTokens.spacingM),
        
        // Compact horizontal list
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: SoMineTokens.spacingL,
            ),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(
              width: SoMineTokens.spacingM,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _CompactItemCard(
                item: item,
                onTap: () => onItemTap?.call(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CompactItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback? onTap;

  const _CompactItemCard({
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: SoMineTokens.cardBackground,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
          boxShadow: SoMineTokens.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Görsel
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(SoMineTokens.radiusMedium),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            
            // Başlık
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(SoMineTokens.spacingS),
                child: Text(
                  item.title ?? item.domain ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: SoMineTokens.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: SoMineTokens.background,
      child: Center(
        child: Icon(
          getPlatformIcon(item.platform),
          color: SoMineTokens.textTertiary,
        ),
      ),
    );
  }
}

🎯 TASK 6: Showcase Section (Vitrin)
📁 Dosya: lib/widgets/showcase_section.dart (YENİ)
📝 Trae'ye Komut:

"Yeni dosya oluştur. Ana sayfanın üstündeki 5 özel kategori vitrini - gradient ikonlu, yatay kaydırmalı."

dartimport 'package:flutter/material.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/models/category_model.dart';

/// Showcase kategorileri için özel ikonlar
class ShowcaseIcons {
  static const IconData travel = Icons.flight_rounded;
  static const IconData food = Icons.restaurant_rounded;
  static const IconData watch = Icons.play_circle_rounded;
  static const IconData read = Icons.auto_stories_rounded;
  static const IconData shop = Icons.shopping_bag_rounded;
  static const IconData music = Icons.headphones_rounded;
  static const IconData fitness = Icons.fitness_center_rounded;
  static const IconData home = Icons.home_rounded;
  static const IconData style = Icons.checkroom_rounded;
  static const IconData tech = Icons.devices_rounded;
}

/// Showcase verisi
class ShowcaseItem {
  final String id;
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final int itemCount;

  const ShowcaseItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.gradient,
    this.itemCount = 0,
  });
}

/// Ana sayfa vitrini - 5 özel kategori
class ShowcaseSection extends StatelessWidget {
  final List<ShowcaseItem> items;
  final Function(ShowcaseItem)? onItemTap;

  const ShowcaseSection({
    super.key,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: SoMineTokens.spacingL,
        ),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(
          width: SoMineTokens.spacingM,
        ),
        itemBuilder: (context, index) {
          return ShowcaseCard(
            item: items[index],
            onTap: () => onItemTap?.call(items[index]),
          );
        },
      ),
    );
  }
}

/// Tek bir showcase kartı
class ShowcaseCard extends StatelessWidget {
  final ShowcaseItem item;
  final VoidCallback? onTap;

  const ShowcaseCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          gradient: item.gradient,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: item.gradient.colors.first.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Dekoratif daireler
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              left: -10,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            
            // İçerik
            Padding(
              padding: const EdgeInsets.all(SoMineTokens.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İkon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(
                        SoMineTokens.radiusSmall,
                      ),
                    ),
                    child: Icon(
                      item.icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Başlık
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Sayaç
                  if (item.itemCount > 0)
                    Text(
                      '${item.itemCount} öğe',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
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
}

/// Büyük showcase kartı (detay sayfası için)
class LargeShowcaseCard extends StatelessWidget {
  final ShowcaseItem item;
  final VoidCallback? onTap;

  const LargeShowcaseCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: item.gradient,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: item.gradient.colors.first.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Dekoratif elementler
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            
            // İçerik
            Padding(
              padding: const EdgeInsets.all(SoMineTokens.spacingXXL),
              child: Row(
                children: [
                  // Sol - İkon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(
                        SoMineTokens.radiusMedium,
                      ),
                    ),
                    child: Icon(
                      item.icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  
                  const SizedBox(width: SoMineTokens.spacingXL),
                  
                  // Sağ - Metin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: SoMineTokens.spacingXS),
                        Text(
                          '${item.itemCount} kayıtlı içerik',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Ok ikonu
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 28,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

🎯 TASK 7: Inbox Card Widget
📁 Dosya: lib/widgets/inbox_card.dart (YENİ)
📝 Trae'ye Komut:

"Yeni dosya oluştur. Studio'ya (Pano) yönlendiren, bekleyen içerik sayısını gösteren inbox kartı."

dartimport 'package:flutter/material.dart';
import 'package:somine_app/core/design/design_tokens.dart';

/// Inbox/Studio kartı
/// Kategorize edilmemiş içerikleri gösterir
class InboxCard extends StatelessWidget {
  final int pendingCount;
  final VoidCallback? onTap;

  const InboxCard({
    super.key,
    required this.pendingCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: SoMineTokens.spacingL,
        ),
        padding: const EdgeInsets.all(SoMineTokens.spacingL),
        decoration: BoxDecoration(
          color: SoMineTokens.cardBackground,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
          boxShadow: SoMineTokens.cardShadow,
        ),
        child: Row(
          children: [
            // Gradient ikon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: SoMineTokens.primaryGradient,
                borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
              ),
              child: const Icon(
                Icons.inbox_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            
            const SizedBox(width: SoMineTokens.spacingL),
            
            // Metin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inbox',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    pendingCount > 0
                        ? '$pendingCount yeni öğe'
                        : 'Tüm içerikler düzenlendi',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: pendingCount > 0
                          ? SoMineTokens.accentEnd
                          : SoMineTokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Ok ikonu
            Icon(
              Icons.chevron_right_rounded,
              color: SoMineTokens.textTertiary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge'li inbox ikonu (bottom nav için)
class InboxBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const InboxBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                gradient: SoMineTokens.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

🎯 TASK 8: Home Header
📁 Dosya: lib/widgets/home_header.dart
📝 Trae'ye Komut:

"Bu dosyayı tamamen sil ve aşağıdaki kod ile değiştir. Kullanıcı selamlama ve ayarlar butonlu header."

dartimport 'package:flutter/material.dart';
import 'package:somine_app/core/design/design_tokens.dart';

class HomeHeader extends StatelessWidget {
  final String? userName;
  final String? userPhotoUrl;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onProfileTap;

  const HomeHeader({
    super.key,
    this.userName,
    this.userPhotoUrl,
    this.onSettingsTap,
    this.onProfileTap,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'İyi geceler';
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  String get _displayName {
    if (userName == null || userName!.isEmpty) return '';
    final firstName = userName!.split(' ').first;
    return firstName;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SoMineTokens.spacingL,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Selamlama
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$_greeting${_displayName.isNotEmpty ? ", $_displayName" : ""}!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: SoMineTokens.spacingS),
                  const Text('👋', style: TextStyle(fontSize: 24)),
                ],
              ),
            ],
          ),
          
          // Sağ taraf butonlar
          Row(
            children: [
              // Ayarlar butonu
              _HeaderIconButton(
                icon: Icons.tune_rounded,
                onTap: onSettingsTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool hasBadge;

  const _HeaderIconButton({
    required this.icon,
    this.onTap,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: SoMineTokens.cardBackground,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
          boxShadow: SoMineTokens.cardShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: SoMineTokens.textPrimary,
              size: 22,
            ),
            if (hasBadge)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    gradient: SoMineTokens.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

🎯 TASK 9: Home Screen
📁 Dosya: lib/screens/home_screen.dart
📝 Trae'ye Komut:

"Bu dosyayı tamamen sil ve aşağıdaki kod ile değiştir. PRD'deki Soft UI tasarımına uygun ana ekran."

dartimport 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/screens/item_detail_screen.dart';
import 'package:somine_app/screens/settings_screen.dart';
import 'package:somine_app/widgets/home_header.dart';
import 'package:somine_app/widgets/inbox_card.dart';
import 'package:somine_app/widgets/showcase_section.dart';
import 'package:somine_app/widgets/content_swimlane.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final allItems = ref.watch(itemsProvider).valueOrNull ?? [];
    
    // Kategorize edilmemiş öğeler (inbox)
    final pendingItems = allItems.where((item) => 
      item.categoryId == null || item.categoryId!.isEmpty
    ).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: SoMineTokens.accentEnd,
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
            ref.invalidate(itemsProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Üst boşluk
              const SliverToBoxAdapter(
                child: SizedBox(height: SoMineTokens.spacingXL),
              ),
              
              // Header
              SliverToBoxAdapter(
                child: HomeHeader(
                  userName: user?.displayName,
                  userPhotoUrl: user?.photoUrl,
                  onSettingsTap: () => _openSettings(context),
                ),
              ),
              
              const SliverToBoxAdapter(
                child: SizedBox(height: SoMineTokens.spacingXXL),
              ),
              
              // Inbox Card
              SliverToBoxAdapter(
                child: InboxCard(
                  pendingCount: pendingItems.length,
                  onTap: () => _openStudio(context, ref),
                ),
              ),
              
              const SliverToBoxAdapter(
                child: SizedBox(height: SoMineTokens.spacingSection),
              ),
              
              // Showcase Section
              SliverToBoxAdapter(
                child: _buildShowcaseSection(context, categories, allItems),
              ),
              
              const SliverToBoxAdapter(
                child: SizedBox(height: SoMineTokens.spacingSection),
              ),
              
              // Category Swimlanes
              ..._buildCategorySwimlanes(context, ref, categories, allItems),
              
              // Alt boşluk
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShowcaseSection(
    BuildContext context,
    List<CategoryModel> categories,
    List<ItemModel> allItems,
  ) {
    // İlk 5 kategoriyi showcase olarak göster
    final showcaseCategories = categories.take(5).toList();
    
    if (showcaseCategories.isEmpty) {
      return _buildEmptyShowcase(context);
    }

    final showcaseItems = showcaseCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final itemCount = allItems.where((i) => i.categoryId == category.id).length;
      
      return ShowcaseItem(
        id: category.id,
        title: category.name,
        icon: _getCategoryIcon(category.name),
        gradient: SoMineTokens.showcaseGradients[index % 5],
        itemCount: itemCount,
      );
    }).toList();

    return ShowcaseSection(
      items: showcaseItems,
      onItemTap: (item) {
        // Kategori detay sayfasına git
      },
    );
  }

  Widget _buildEmptyShowcase(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SoMineTokens.spacingL,
      ),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          gradient: SoMineTokens.primaryGradient,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: SoMineTokens.spacingS),
              Text(
                'Koleksiyonunu oluşturmaya başla!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategorySwimlanes(
    BuildContext context,
    WidgetRef ref,
    List<CategoryModel> categories,
    List<ItemModel> allItems,
  ) {
    final widgets = <Widget>[];

    for (final category in categories) {
      final categoryItems = allItems
          .where((item) => item.categoryId == category.id)
          .toList();

      if (categoryItems.isEmpty) continue;

      widgets.add(
        SliverToBoxAdapter(
          child: ContentSwimlane(
            category: category,
            items: categoryItems,
            onItemTap: (item) => _openItemDetail(context, item),
            onSeeAllTap: () {
              // Kategori detay sayfasına git
            },
          ),
        ),
      );

      widgets.add(
        const SliverToBoxAdapter(
          child: SizedBox(height: SoMineTokens.spacingSection),
        ),
      );
    }

    return widgets;
  }

  IconData _getCategoryIcon(String name) {
    final lowered = name.toLowerCase();
    if (lowered.contains('tatil') || lowered.contains('gezi')) {
      return ShowcaseIcons.travel;
    }
    if (lowered.contains('yemek') || lowered.contains('tarif')) {
      return ShowcaseIcons.food;
    }
    if (lowered.contains('izle') || lowered.contains('film') || lowered.contains('dizi')) {
      return ShowcaseIcons.watch;
    }
    if (lowered.contains('oku') || lowered.contains('kitap')) {
      return ShowcaseIcons.read;
    }
    if (lowered.contains('alışveriş') || lowered.contains('shop')) {
      return ShowcaseIcons.shop;
    }
    if (lowered.contains('müzik') || lowered.contains('music')) {
      return ShowcaseIcons.music;
    }
    if (lowered.contains('spor') || lowered.contains('fitness')) {
      return ShowcaseIcons.fitness;
    }
    if (lowered.contains('ev') || lowered.contains('dekor')) {
      return ShowcaseIcons.home;
    }
    if (lowered.contains('moda') || lowered.contains('stil')) {
      return ShowcaseIcons.style;
    }
    return ShowcaseIcons.tech;
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openStudio(BuildContext context, WidgetRef ref) {
    // RootShell'deki tab'ı değiştir
    // Bu kısım RootShell'e bağlı
  }

  void _openItemDetail(BuildContext context, ItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(item: item),
      ),
    );
  }
}

0: Root Shell (Custom Bottom Navigation)
📁 Dosya: lib/screens/root_shell.dart
📝 Trae'ye Komut:

"Bu dosyayı tamamen sil ve aşağıdaki kod ile değiştir. Gradient aktif state'li, havada asılı custom bottom navigation."

dartimport 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/screens/home_screen.dart';
import 'package:somine_app/screens/discover_screen.dart';
import 'package:somine_app/screens/studio_screen.dart';
import 'package:somine_app/screens/category_manager_screen.dart';
import 'package:somine_app/screens/settings_screen.dart';
import 'package:somine_app/widgets/vacuum_fab.dart';

/// Bottom navigation tab indeksi için global provider
final currentTabProvider = StateProvider<int>((ref) => 0);

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  late final PageController _pageController;

  final List<Widget> _screens = const [
    HomeScreen(),
    DiscoverScreen(),
    CategoryManagerScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    ref.read(currentTabProvider.notifier).state = index;
    _pageController.animateToPage(
      index,
      duration: SoMineTokens.animationNormal,
      curve: Curves.easeOutCubic,
    );
    
    // Haptic feedback
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);
    final allItems = ref.watch(itemsProvider).valueOrNull ?? [];
    
    // Inbox'taki bekleyen öğe sayısı
    final pendingCount = allItems.where((item) => 
      item.categoryId == null || item.categoryId!.isEmpty
    ).length;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      
      // Floating Action Button (Vakum)
      floatingActionButton: const VacuumFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // Custom Bottom Navigation
      bottomNavigationBar: _SoMineBottomNav(
        currentIndex: currentTab,
        onTap: _onTabChanged,
        pendingCount: pendingCount,
      ),
    );
  }
}

/// Custom Bottom Navigation Bar
class _SoMineBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int pendingCount;

  const _SoMineBottomNav({
    required this.currentIndex,
    required this.onTap,
    this.pendingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SoMineTokens.cardBackground,
        boxShadow: SoMineTokens.bottomNavShadow,
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(
            horizontal: SoMineTokens.spacingL,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Ana Sayfa',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              
              // Search / Discover
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Ara',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              
              // Ortadaki FAB için boşluk
              const SizedBox(width: 56),
              
              // Categories / Library
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Kategoriler',
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
                badgeCount: pendingCount,
              ),
              
              // Profile / Settings
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tek bir navigation item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkon container
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: SoMineTokens.animationFast,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: isSelected 
                        ? SoMineTokens.primaryGradient 
                        : null,
                    borderRadius: BorderRadius.circular(
                      SoMineTokens.radiusSmall,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected 
                        ? Colors.white 
                        : SoMineTokens.textTertiary,
                  ),
                ),
                
                // Badge
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected 
                    ? SoMineTokens.accentEnd 
                    : SoMineTokens.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

🎯 TASK 11: Vacuum FAB (Merkez Buton)
📁 Dosya: lib/widgets/vacuum_fab.dart (YENİ)
📝 Trae'ye Komut:

"Yeni dosya oluştur. Ortadaki gradient floating action button - içerik ekleme için vakum efekti tetikleyici."

dartimport 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/screens/capture_screen.dart';

/// Merkezdeki Vakum FAB
/// İçerik ekleme işlemini başlatır
class VacuumFAB extends StatefulWidget {
  const VacuumFAB({super.key});

  @override
  State<VacuumFAB> createState() => _VacuumFABState();
}

class _VacuumFABState extends State<VacuumFAB> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTap() {
    HapticFeedback.mediumImpact();
    _showAddOptions();
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _AddContentBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: SoMineTokens.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: SoMineTokens.accentEnd.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// İçerik ekleme bottom sheet
class _AddContentBottomSheet extends StatefulWidget {
  const _AddContentBottomSheet();

  @override
  State<_AddContentBottomSheet> createState() => _AddContentBottomSheetState();
}

class _AddContentBottomSheetState extends State<_AddContentBottomSheet> {
  final _urlController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Otomatik focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaptureScreen(url: url),
      ),
    );
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _urlController.text = data.text!;
      _onSubmit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(SoMineTokens.spacingL),
      decoration: BoxDecoration(
        color: SoMineTokens.cardBackground,
        borderRadius: BorderRadius.circular(SoMineTokens.radiusXLarge),
        boxShadow: SoMineTokens.cardShadowElevated,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: SoMineTokens.spacingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SoMineTokens.textTertiary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(SoMineTokens.spacingXXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: SoMineTokens.primaryGradient,
                        borderRadius: BorderRadius.circular(
                          SoMineTokens.radiusMedium,
                        ),
                      ),
                      child: const Icon(
                        Icons.link_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: SoMineTokens.spacingM),
                    Text(
                      'İçerik Ekle',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                
                const SizedBox(height: SoMineTokens.spacingXXL),
                
                // URL Input
                Container(
                  decoration: BoxDecoration(
                    color: SoMineTokens.background,
                    borderRadius: BorderRadius.circular(
                      SoMineTokens.radiusMedium,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Link yapıştır veya yaz...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: SoMineTokens.spacingL,
                              vertical: SoMineTokens.spacingM,
                            ),
                            hintStyle: TextStyle(
                              color: SoMineTokens.textTertiary,
                            ),
                          ),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.go,
                          onSubmitted: (_) => _onSubmit(),
                        ),
                      ),
                      
                      // Yapıştır butonu
                      GestureDetector(
                        onTap: _pasteFromClipboard,
                        child: Container(
                          padding: const EdgeInsets.all(SoMineTokens.spacingM),
                          child: Icon(
                            Icons.content_paste_rounded,
                            color: SoMineTokens.accentEnd,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: SoMineTokens.spacingL),
                
                // Kaydet butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: SoMineTokens.spacingL,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt_rounded, size: 20),
                        SizedBox(width: SoMineTokens.spacingS),
                        Text('Vakumla'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: SoMineTokens.spacingM),
                
                // İpucu
                Center(
                  child: Text(
                    'Instagram, Pinterest, YouTube ve daha fazlası...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          
          // Safe area padding
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

🎯 TASK 12: Studio Screen (Kart Destesi)
📁 Dosya: lib/screens/studio_screen.dart
📝 Trae'ye Komut:

"Bu dosyayı tamamen sil ve aşağıdaki kod ile değiştir. Tinder tarzı swipe ile kategorize etme ekranı."

dartimport 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
import 'package:somine_app/widgets/item_card.dart';

class StudioScreen extends ConsumerStatefulWidget {
  const StudioScreen({super.key});

  @override
  ConsumerState<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends ConsumerState<StudioScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(itemsProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    
    // Kategorize edilmemiş öğeler
    final pendingItems = allItems.where((item) => 
      item.categoryId == null || item.categoryId!.isEmpty
    ).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, pendingItems.length),
            
            const SizedBox(height: SoMineTokens.spacingXL),
            
            // Kart destesi veya boş durum
            Expanded(
              child: pendingItems.isEmpty
                  ? _buildEmptyState(context)
                  : _buildCardStack(context, pendingItems, categories),
            ),
            
            // Kategori balonları
            if (pendingItems.isNotEmpty)
              _buildCategoryBubbles(context, categories, pendingItems),
            
            const SizedBox(height: SoMineTokens.spacingXXL),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.all(SoMineTokens.spacingL),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: SoMineTokens.primaryGradient,
              borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: SoMineTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Studio',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  count > 0 
                      ? '$count içerik düzenlenmek için bekliyor'
                      : 'Tüm içerikler düzenlendi!',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SoMineTokens.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: SoMineTokens.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: SoMineTokens.accentEnd,
              ),
            ),
            const SizedBox(height: SoMineTokens.spacingXXL),
            Text(
              'Harika iş! 🎉',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: SoMineTokens.spacingS),
            Text(
              'Tüm içeriklerini kategorize ettin.\nYeni içerik eklemek için (+) butonunu kullan.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStack(
    BuildContext context,
    List<ItemModel> items,
    List<CategoryModel> categories,
  ) {
    if (_currentIndex >= items.length) {
      _currentIndex = 0;
    }

    return Center(
      child: SizedBox(
        width: 280,
        height: 400,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Arka plan kartları (perspektif efekti)
            for (int i = 2; i >= 0; i--)
              if (_currentIndex + i < items.length)
                Positioned(
                  top: i * 8.0,
                  child: Transform.scale(
                    scale: 1 - (i * 0.05),
                    child: Opacity(
                      opacity: 1 - (i * 0.2),
                      child: _buildCard(
                        context,
                        items[_currentIndex + i],
                        isTop: i == 0,
                        categories: categories,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    ItemModel item, {
    required bool isTop,
    required List<CategoryModel> categories,
  }) {
    final card = Container(
      width: 280,
      height: 380,
      decoration: BoxDecoration(
        color: SoMineTokens.cardBackground,
        borderRadius: BorderRadius.circular(SoMineTokens.radiusXLarge),
        boxShadow: SoMineTokens.cardShadowElevated,
      ),
      child: Column(
        children: [
          // Görsel
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(SoMineTokens.radiusXLarge),
              ),
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(item),
                    )
                  : _placeholder(item),
            ),
          ),
          
          // Bilgiler
          Padding(
            padding: const EdgeInsets.all(SoMineTokens.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SoMineTokens.spacingS,
                    vertical: SoMineTokens.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: SoMineTokens.background,
                    borderRadius: BorderRadius.circular(
                      SoMineTokens.radiusSmall,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        getPlatformIcon(item.platform),
                        size: 14,
                        color: SoMineTokens.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.domain ?? item.platform ?? 'Link',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: SoMineTokens.spacingS),
                
                // Başlık
                Text(
                  item.title ?? 'Başlıksız',
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!isTop) return card;

    // Draggable sadece en üstteki kart için
    return Draggable<ItemModel>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: card,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: card,
      ),
      onDragStarted: () => HapticFeedback.lightImpact(),
      child: card,
    );
  }

  Widget _placeholder(ItemModel item) {
    return Container(
      color: SoMineTokens.background,
      child: Center(
        child: Icon(
          getPlatformIcon(item.platform),
          size: 48,
          color: SoMineTokens.textTertiary,
        ),
      ),
    );
  }

  Widget _buildCategoryBubbles(
    BuildContext context,
    List<CategoryModel> categories,
    List<ItemModel> pendingItems,
  ) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(
        horizontal: SoMineTokens.spacingL,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(
          width: SoMineTokens.spacingM,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          final gradient = SoMineTokens.showcaseGradients[
            index % SoMineTokens.showcaseGradients.length
          ];

          return DragTarget<ItemModel>(
            onAcceptWithDetails: (details) {
              _assignCategory(details.data, category);
            },
            onWillAcceptWithDetails: (details) {
              HapticFeedback.selectionClick();
              return true;
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              
              return AnimatedScale(
                scale: isHovering ? 1.1 : 1.0,
                duration: SoMineTokens.animationFast,
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(
                      SoMineTokens.radiusMedium,
                    ),
                    border: isHovering
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.4),
                        blurRadius: isHovering ? 20 : 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category.emoji ?? '📁',
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: SoMineTokens.spacingXS),
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _assignCategory(ItemModel item, CategoryModel category) async {
    HapticFeedback.mediumImpact();
    
    try {
      final itemRepo = ref.read(itemRepositoryProvider);
      await itemRepo.updateItem(
        item.copyWith(categoryId: category.id),
      );
      
      setState(() {
        // Kart kaydırıldı, bir sonrakine geç
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${category.emoji} ${category.name} kategorisine eklendi'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: SoMineTokens.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error assigning category: $e');
    }
  }
}

🎯 TASK 13: Discover/Search Screen
📁 Dosya: lib/screens/discover_screen.dart
📝 Trae'ye Komut:

"Bu dosyayı tamamen sil ve aşağıdaki kod ile değiştir. Soft UI tarzında arama ekranı."

dartimport 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/screens/item_detail_screen.dart';
import 'package:somine_app/widgets/item_card.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(itemsProvider).valueOrNull ?? [];
    
    // Arama filtresi
    final filteredItems = _searchQuery.isEmpty
        ? allItems
        : allItems.where((item) {
            final query = _searchQuery.toLowerCase();
            return (item.title?.toLowerCase().contains(query) ?? false) ||
                   (item.domain?.toLowerCase().contains(query) ?? false) ||
                   (item.platform?.toLowerCase().contains(query) ?? false);
          }).toList();

    // Popüler aramalar
    final recentPlatforms = allItems
        .map((e) => e.platform)
        .where((p) => p != null && p.isNotEmpty)
        .toSet()
        .take(5)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Başlık
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(SoMineTokens.spacingL),
                child: Text(
                  'Ne arıyorsun?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            
            // Arama kutusu
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SoMineTokens.spacingL,
                ),
                child: _buildSearchBox(context),
              ),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: SoMineTokens.spacingXXL),
            ),
            
            // Sık arananlar veya sonuçlar
            if (_searchQuery.isEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SoMineTokens.spacingL,
                  ),
                  child: Text(
                    'Sık Arananlar',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: SoMineTokens.spacingM),
              ),
              SliverToBoxAdapter(
                child: _buildPopularTags(context, recentPlatforms),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: SoMineTokens.spacingSection),
              ),
              SliverToBoxAdapter(
                child: _buildIllustration(context),
              ),
            ] else ...[
              // Arama sonuçları
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SoMineTokens.spacingL,
                  ),
                  child: Text(
                    '${filteredItems.length} sonuç bulundu',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: SoMineTokens.spacingL),
              ),
              _buildSearchResults(filteredItems),
            ],
            
            // Alt boşluk
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SoMineTokens.cardBackground,
        borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
        boxShadow: SoMineTokens.cardShadow,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: SoMineTokens.spacingL),
            child: Icon(
              Icons.search_rounded,
              color: SoMineTokens.textTertiary,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: const InputDecoration(
                hintText: 'Başlık, platform veya site ara...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: SoMineTokens.spacingM,
                  vertical: SoMineTokens.spacingL,
                ),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Padding(
                padding: EdgeInsets.only(right: SoMineTokens.spacingL),
                child: Icon(
                  Icons.close_rounded,
                  color: SoMineTokens.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPopularTags(BuildContext context, List<String?> platforms) {
    final tags = [
      'Pinterest',
      'Instagram',
      'YouTube',
      'Twitter',
      'Spotify',
      ...platforms.whereType<String>(),
    ].toSet().take(8).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SoMineTokens.spacingL,
      ),
      child: Wrap(
        spacing: SoMineTokens.spacingS,
        runSpacing: SoMineTokens.spacingS,
        children: tags.map((tag) {
          return GestureDetector(
            onTap: () {
              _searchController.text = tag;
              setState(() => _searchQuery = tag);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SoMineTokens.spacingL,
                vertical: SoMineTokens.spacingS,
              ),
              decoration: BoxDecoration(
                color: SoMineTokens.cardBackground,
                borderRadius: BorderRadius.circular(SoMineTokens.radiusRound),
                boxShadow: SoMineTokens.cardShadow,
              ),
              child: Text(
                tag,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SoMineTokens.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIllustration(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // Basit bir illüstrasyon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: SoMineTokens.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.saved_search_rounded,
              size: 56,
              color: SoMineTokens.accentEnd.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: SoMineTokens.spacingXL),
          Text(
            'Aradığın içeriği bul',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: SoMineTokens.textSecondary,
            ),
          ),
          const SizedBox(height: SoMineTokens.spacingS),
          Text(
            'Başlık, platform veya site adıyla\niçeriklerini ara',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<ItemModel> items) {
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(SoMineTokens.spacingXXL),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: SoMineTokens.textTertiary,
                ),
                const SizedBox(height: SoMineTokens.spacingL),
                Text(
                  'Sonuç bulunamadı',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: SoMineTokens.spacingL,
      ),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: SoMineTokens.spacingM,
          crossAxisSpacing: SoMineTokens.spacingM,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return ItemCard(
              item: item,
              width: double.infinity,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(item: item),
                  ),
                );
              },
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}
```

---

## 📋 ÖZET: Trae İçin Görev Listesi

| Task | Dosya | Durum |
|------|-------|-------|
| 1 | `lib/core/design/design_tokens.dart` | ✅ Hazır |
| 2 | `lib/core/design/app_theme.dart` | ✅ Hazır |
| 3 | `lib/widgets/soft_card.dart` | ✅ Hazır |
| 4 | `lib/widgets/item_card.dart` | ✅ Hazır |
| 5 | `lib/widgets/content_swimlane.dart` | ✅ Hazır |
| 6 | `lib/widgets/showcase_section.dart` | ✅ Hazır |
| 7 | `lib/widgets/inbox_card.dart` | ✅ Hazır |
| 8 | `lib/widgets/home_header.dart` | ✅ Hazır |
| 9 | `lib/screens/home_screen.dart` | ✅ Hazır |
| 10 | `lib/screens/root_shell.dart` | ✅ Hazır |
| 11 | `lib/widgets/vacuum_fab.dart` | ✅ Hazır |
| 12 | `lib/screens/studio_screen.dart` | ✅ Hazır |
| 13 | `lib/screens/discover_screen.dart` | ✅ Hazır |

---

ASK 14: Category Manager Screen📁 Dosya: lib/screens/category_manager_screen.dart📝 Trae'ye Komut:

"Bu dosyayı tamamen sil ve aşağıdaki kod ile değiştir. Kategorileri yönetme ve düzenleme ekranı - Soft UI tasarım."
dartimport 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/repositories/category_repository.dart';

class CategoryManagerScreen extends ConsumerStatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  ConsumerState<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends ConsumerState<CategoryManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final allItems = ref.watch(itemsProvider).valueOrNull ?? [];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(SoMineTokens.spacingL),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kategoriler',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    _AddCategoryButton(
                      onTap: () => _showAddCategorySheet(context),
                    ),
                  ],
                ),
              ),
            ),

            // Boş durum veya liste
            if (categories.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(context),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SoMineTokens.spacingL,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = categories[index];
                      final itemCount = allItems
                          .where((i) => i.categoryId == category.id)
                          .length;
                      final gradient = SoMineTokens.showcaseGradients[
                        index % SoMineTokens.showcaseGradients.length
                      ];

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: SoMineTokens.spacingM,
                        ),
                        child: _CategoryTile(
                          category: category,
                          itemCount: itemCount,
                          gradient: gradient,
                          onTap: () => _openCategoryDetail(category),
                          onEdit: () => _showEditCategorySheet(context, category),
                          onDelete: () => _confirmDelete(context, category),
                        ),
                      );
                    },
                    childCount: categories.length,
                  ),
                ),
              ),

            // Alt boşluk
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SoMineTokens.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: SoMineTokens.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: SoMineTokens.spacingXXL),
            Text(
              'Henüz kategori yok',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: SoMineTokens.spacingS),
            Text(
              'İçeriklerini düzenlemek için\nkategoriler oluştur',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SoMineTokens.spacingXXL),
            ElevatedButton.icon(
              onPressed: () => _showAddCategorySheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Kategori Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryFormSheet(
        onSave: (name, emoji) => _createCategory(name, emoji),
      ),
    );
  }

  void _showEditCategorySheet(BuildContext context, CategoryModel category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryFormSheet(
        initialName: category.name,
        initialEmoji: category.emoji,
        isEditing: true,
        onSave: (name, emoji) => _updateCategory(category, name, emoji),
      ),
    );
  }

  Future<void> _createCategory(String name, String? emoji) async {
    try {
      final categoryRepo = ref.read(categoryRepositoryProvider);
      await categoryRepo.createCategory(
        CategoryModel(
          id: '',
          name: name,
          emoji: emoji,
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackbar('Kategori oluşturuldu');
      }
    } catch (e) {
      _showErrorSnackbar('Kategori oluşturulamadı');
    }
  }

  Future<void> _updateCategory(
    CategoryModel category,
    String name,
    String? emoji,
  ) async {
    try {
      final categoryRepo = ref.read(categoryRepositoryProvider);
      await categoryRepo.updateCategory(
        category.copyWith(name: name, emoji: emoji),
      );
      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackbar('Kategori güncellendi');
      }
    } catch (e) {
      _showErrorSnackbar('Kategori güncellenemedi');
    }
  }

  void _confirmDelete(BuildContext context, CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
        ),
        title: const Text('Kategoriyi Sil'),
        content: Text(
          '"${category.name}" kategorisini silmek istediğine emin misin?\n\nBu kategorideki içerikler silinmeyecek, sadece kategorisiz kalacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(category);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    try {
      final categoryRepo = ref.read(categoryRepositoryProvider);
      await categoryRepo.deleteCategory(category.id);
      _showSuccessSnackbar('Kategori silindi');
    } catch (e) {
      _showErrorSnackbar('Kategori silinemedi');
    }
  }

  void _openCategoryDetail(CategoryModel category) {
    // Kategori detay sayfasına git (ileride eklenebilir)
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: SoMineTokens.accentEnd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
        ),
      ),
    );
  }
}

/// Kategori ekleme butonu
class _AddCategoryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCategoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SoMineTokens.spacingL,
          vertical: SoMineTokens.spacingS,
        ),
        decoration: BoxDecoration(
          gradient: SoMineTokens.primaryGradient,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusRound),
          boxShadow: [
            BoxShadow(
              color: SoMineTokens.accentEnd.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: SoMineTokens.spacingXS),
            Text(
              'Yeni',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kategori listesi öğesi
class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final int itemCount;
  final LinearGradient gradient;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CategoryTile({
    required this.category,
    required this.itemCount,
    required this.gradient,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SoMineTokens.spacingL),
        decoration: BoxDecoration(
          color: SoMineTokens.cardBackground,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
          boxShadow: SoMineTokens.cardShadow,
        ),
        child: Row(
          children: [
            // Gradient ikon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
              ),
              child: Center(
                child: Text(
                  category.emoji ?? '📁',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),

            const SizedBox(width: SoMineTokens.spacingL),

            // Bilgiler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$itemCount içerik',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Aksiyon butonları
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconButton(
                  icon: Icons.edit_outlined,
                  onTap: onEdit,
                ),
                const SizedBox(width: SoMineTokens.spacingS),
                _IconButton(
                  icon: Icons.delete_outline_rounded,
                  onTap: onDelete,
                  color: Colors.red.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _IconButton({
    required this.icon,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: SoMineTokens.background,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusSmall),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color ?? SoMineTokens.textSecondary,
        ),
      ),
    );
  }
}

/// Kategori ekleme/düzenleme formu
class _CategoryFormSheet extends StatefulWidget {
  final String? initialName;
  final String? initialEmoji;
  final bool isEditing;
  final Function(String name, String? emoji) onSave;

  const _CategoryFormSheet({
    this.initialName,
    this.initialEmoji,
    this.isEditing = false,
    required this.onSave,
  });

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final TextEditingController _nameController;
  String? _selectedEmoji;

  final List<String> _emojis = [
    '📁', '🎬', '🎵', '📚', '🍕', '✈️', '🛍️', '💡',
    '🎨', '🏠', '👗', '💪', '🎮', '📷', '🌿', '💼',
    '🎯', '⭐', '❤️', '🔥', '💎', '🌈', '🎁', '🏆',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedEmoji = widget.initialEmoji ?? _emojis.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    widget.onSave(name, _selectedEmoji);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(SoMineTokens.spacingL),
      decoration: BoxDecoration(
        color: SoMineTokens.cardBackground,
        borderRadius: BorderRadius.circular(SoMineTokens.radiusXLarge),
        boxShadow: SoMineTokens.cardShadowElevated,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: SoMineTokens.spacingXXL,
          right: SoMineTokens.spacingXXL,
          top: SoMineTokens.spacingXXL,
          bottom: SoMineTokens.spacingXXL + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SoMineTokens.textTertiary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: SoMineTokens.spacingXXL),

            // Başlık
            Text(
              widget.isEditing ? 'Kategoriyi Düzenle' : 'Yeni Kategori',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: SoMineTokens.spacingXXL),

            // Emoji seçici
            Text(
              'İkon Seç',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: SoMineTokens.spacingM),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _emojis.length,
                separatorBuilder: (_, __) => const SizedBox(
                  width: SoMineTokens.spacingS,
                ),
                itemBuilder: (context, index) {
                  final emoji = _emojis[index];
                  final isSelected = emoji == _selectedEmoji;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedEmoji = emoji);
                      HapticFeedback.selectionClick();
                    },
                    child: AnimatedContainer(
                      duration: SoMineTokens.animationFast,
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? SoMineTokens.primaryGradient
                            : null,
                        color: isSelected ? null : SoMineTokens.background,
                        borderRadius: BorderRadius.circular(
                          SoMineTokens.radiusMedium,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: SoMineTokens.spacingXXL),

            // İsim input
            Text(
              'Kategori Adı',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: SoMineTokens.spacingS),
            Container(
              decoration: BoxDecoration(
                color: SoMineTokens.background,
                borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
              ),
              child: TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Örn: Tatil Fikirleri',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: SoMineTokens.spacingL,
                    vertical: SoMineTokens.spacingM,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onSave(),
              ),
            ),

            const SizedBox(height: SoMineTokens.spacingXXL),

            // Kaydet butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSave,
                child: Text(widget.isEditing ? 'Güncelle' : 'Oluştur'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}🎯 TASK 15: Settings Screen (Profil)📁 Dosya: lib/screens/settings_screen.dart📝 Trae'ye Komut:

"Bu dosyayı tamamen sil ve aşağıdaki kod ile değiştir. Soft UI tasarımlı profil ve ayarlar ekranı."
dartimport 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/repositories/auth_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(SoMineTokens.spacingL),
                child: Text(
                  'Profil',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),

            // Profil kartı
            SliverToBoxAdapter(
              child: _ProfileCard(user: user),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: SoMineTokens.spacingSection),
            ),

            // Ayarlar listesi
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SoMineTokens.spacingL,
                ),
                child: Text(
                  'Ayarlar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: SoMineTokens.textSecondary,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: SoMineTokens.spacingM),
            ),

            SliverToBoxAdapter(
              child: _SettingsSection(
                items: [
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    title: 'Bildirimler',
                    subtitle: 'Bildirim tercihlerini yönet',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.palette_outlined,
                    title: 'Görünüm',
                    subtitle: 'Tema ve görünüm ayarları',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.cloud_outlined,
                    title: 'Yedekleme',
                    subtitle: 'Verilerini yedekle ve geri yükle',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: SoMineTokens.spacingXXL),
            ),

            // Destek
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SoMineTokens.spacingL,
                ),
                child: Text(
                  'Destek',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: SoMineTokens.textSecondary,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: SoMineTokens.spacingM),
            ),

            SliverToBoxAdapter(
              child: _SettingsSection(
                items: [
                  _SettingsItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Yardım Merkezi',
                    onTap: () => _launchUrl('https://somine.app/help'),
                  ),
                  _SettingsItem(
                    icon: Icons.mail_outline_rounded,
                    title: 'Geri Bildirim Gönder',
                    onTap: () => _launchUrl('mailto:hello@somine.app'),
                  ),
                  _SettingsItem(
                    icon: Icons.star_outline_rounded,
                    title: 'Uygulamayı Değerlendir',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: SoMineTokens.spacingXXL),
            ),

            // Çıkış
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SoMineTokens.spacingL,
                ),
                child: _LogoutButton(
                  onTap: () => _showLogoutDialog(context, ref),
                ),
              ),
            ),

            // Versiyon
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(SoMineTokens.spacingXXL),
                child: Center(
                  child: Text(
                    'So Mine v1.0.0',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),

            // Alt boşluk
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
        ),
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabından çıkış yapmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authRepositoryProvider).signOut();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}

/// Profil kartı
class _ProfileCard extends StatelessWidget {
  final dynamic user;

  const _ProfileCard({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: SoMineTokens.spacingL,
      ),
      padding: const EdgeInsets.all(SoMineTokens.spacingXL),
      decoration: BoxDecoration(
        gradient: SoMineTokens.primaryGradient,
        borderRadius: BorderRadius.circular(SoMineTokens.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: SoMineTokens.accentEnd.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: user?.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      user!.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultAvatar(),
                    ),
                  )
                : _defaultAvatar(),
          ),

          const SizedBox(width: SoMineTokens.spacingL),

          // Bilgiler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Kullanıcı',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? 'Misafir',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),

          // Düzenle butonu
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return const Icon(
      Icons.person_rounded,
      color: Colors.white,
      size: 36,
    );
  }
}

/// Ayarlar bölümü
class _SettingsSection extends StatelessWidget {
  final List<_SettingsItem> items;

  const _SettingsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: SoMineTokens.spacingL,
      ),
      decoration: BoxDecoration(
        color: SoMineTokens.cardBackground,
        borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
        boxShadow: SoMineTokens.cardShadow,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              item,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 56 + SoMineTokens.spacingL,
                  endIndent: SoMineTokens.spacingL,
                  color: SoMineTokens.background,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// Tek ayar öğesi
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.all(SoMineTokens.spacingL),
        child: Row(
          children: [
            // İkon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SoMineTokens.background,
                borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
              ),
              child: Icon(
                icon,
                color: SoMineTokens.textSecondary,
                size: 20,
              ),
            ),

            const SizedBox(width: SoMineTokens.spacingL),

            // Başlık ve alt başlık
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),

            // Trailing
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: SoMineTokens.textTertiary,
                ),
          ],
        ),
      ),
    );
  }
}

/// Çıkış butonu
class _LogoutButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _LogoutButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SoMineTokens.spacingL),
        decoration: BoxDecoration(
          color: SoMineTokens.cardBackground,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
          boxShadow: SoMineTokens.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: Colors.red.shade400,
              size: 20,
            ),
            const SizedBox(width: SoMineTokens.spacingS),
            Text(
              'Çıkış Yap',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.red.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}🎯 TASK 16: Splash Screen (Animasyonlu)📁 Dosya: lib/screens/splash_screen.dart📝 Trae'ye Komut:

"Bu dosyayı tamamen sil ve aşağıdaki kod ile değiştir. Logolu, animasyonlu splash ekranı."
dartimport 'package:flutter/material.dart';
import 'package:somine_app/core/design/design_tokens.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;

  const SplashScreen({
    super.key,
    this.onAnimationComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Logo animasyonu
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Fade out animasyonu
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    _logoController.forward();
    
    await Future.delayed(const Duration(milliseconds: 1800));
    
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoMineTokens.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: child,
                  ),
                );
              },
              child: _buildLogo(),
            ),

            const SizedBox(height: SoMineTokens.spacingXXL),

            // Slogan
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _textOpacity.value,
                  child: SlideTransition(
                    position: _textSlide,
                    child: child,
                  ),
                );
              },
              child: Text(
                'Dünyanı Tasarla',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: SoMineTokens.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: SoMineTokens.primaryGradient,
            borderRadius: BorderRadius.circular(SoMineTokens.radiusXLarge),
            boxShadow: [
              BoxShadow(
                color: SoMineTokens.accentEnd.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            // Eğer logo.png varsa onu kullan
            child: Image.asset(
              'assets/images/logo.png',
              width: 60,
              height: 60,
              color: Colors.white,
              errorBuilder: (_, __, ___) => const Text(
                'S',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: SoMineTokens.spacingXL),

        // App name
        ShaderMask(
          shaderCallback: (bounds) {
            return SoMineTokens.primaryGradient.createShader(bounds);
          },
          child: Text(
            'So Mine',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Logo widget'ı (başka yerlerde kullanmak için)
class SoMineLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const SoMineLogo({
    super.key,
    this.size = 48,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: SoMineTokens.primaryGradient,
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: SoMineTokens.accentEnd.withOpacity(0.3),
                blurRadius: size * 0.3,
                offset: Offset(0, size * 0.1),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: size * 0.6,
              height: size * 0.6,
              color: Colors.white,
              errorBuilder: (_, __, ___) => Text(
                'S',
                style: TextStyle(
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.25),
          Text(
            'So Mine',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}🎯 TASK 17: Model Güncellemeleri📁 Dosya: lib/core/models/category_model.dart📝 Trae'ye Komut:

"copyWith metodunu kontrol et, yoksa ekle. Aşağıdaki gibi olmalı:"
dartimport 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? emoji;
  final String? userId;
  final DateTime? createdAt;
  final int? order;

  const CategoryModel({
    required this.id,
    required this.name,
    this.emoji,
    this.userId,
    this.createdAt,
    this.order,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      emoji: data['emoji'],
      userId: data['userId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      order: data['order'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'emoji': emoji,
      'userId': userId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'order': order,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? emoji,
    String? userId,
    DateTime? createdAt,
    int? order,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      order: order ?? this.order,
    );
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, emoji: $emoji)';
  }
}📁 Dosya: lib/core/models/item_model.dart📝 Trae'ye Komut:

"copyWith metodunu kontrol et ve platform field'ını ekle. Aşağıdaki gibi olmalı:"
dartimport 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? domain;
  final String? platform;
  final String? categoryId;
  final String? userId;
  final DateTime? createdAt;
  final bool? isFavorite;

  const ItemModel({
    required this.id,
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.domain,
    this.platform,
    this.categoryId,
    this.userId,
    this.createdAt,
    this.isFavorite,
  });

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      id: doc.id,
      url: data['url'] ?? '',
      title: data['title'],
      description: data['description'],
      imageUrl: data['imageUrl'],
      domain: data['domain'],
      platform: data['platform'] ?? _detectPlatform(data['url'] ?? ''),
      categoryId: data['categoryId'],
      userId: data['userId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isFavorite: data['isFavorite'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'url': url,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'domain': domain,
      'platform': platform,
      'categoryId': categoryId,
      'userId': userId,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
      'isFavorite': isFavorite,
    };
  }

  ItemModel copyWith({
    String? id,
    String? url,
    String? title,
    String? description,
    String? imageUrl,
    String? domain,
    String? platform,
    String? categoryId,
    String? userId,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return ItemModel(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      domain: domain ?? this.domain,
      platform: platform ?? this.platform,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// URL'den platform tespit et
  static String? _detectPlatform(String url) {
    final lowered = url.toLowerCase();
    if (lowered.contains('pinterest')) return 'Pinterest';
    if (lowered.contains('instagram')) return 'Instagram';
    if (lowered.contains('youtube') || lowered.contains('youtu.be')) return 'YouTube';
    if (lowered.contains('twitter') || lowered.contains('x.com')) return 'Twitter';
    if (lowered.contains('spotify')) return 'Spotify';
    if (lowered.contains('tiktok')) return 'TikTok';
    if (lowered.contains('linkedin')) return 'LinkedIn';
    if (lowered.contains('reddit')) return 'Reddit';
    return null;
  }

  @override
  String toString() {
    return 'ItemModel(id: $id, title: $title, platform: $platform)';
  }
}

 TASK 18: Item Detail Screen
📁 Dosya: lib/screens/item_detail_screen.dart
📝 Trae'ye Komut:

"Bu dosyayı tamamen sil ve aşağıdaki kod ile değiştir. Soft UI tasarımlı içerik detay ekranı."

dartimport 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
import 'package:somine_app/widgets/item_card.dart';
import 'package:url_launcher/url_launcher.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final ItemModel item;

  const ItemDetailScreen({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  late ItemModel _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final currentCategory = categories.firstWhere(
      (c) => c.id == _item.categoryId,
      orElse: () => const CategoryModel(id: '', name: 'Kategorisiz'),
    );

    return Scaffold(
      backgroundColor: SoMineTokens.background,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Image
          _buildSliverAppBar(context),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(SoMineTokens.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform & Domain
                  _buildPlatformBadge(context),

                  const SizedBox(height: SoMineTokens.spacingL),

                  // Title
                  Text(
                    _item.title ?? 'Başlıksız',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),

                  if (_item.description != null &&
                      _item.description!.isNotEmpty) ...[
                    const SizedBox(height: SoMineTokens.spacingM),
                    Text(
                      _item.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],

                  const SizedBox(height: SoMineTokens.spacingXXL),

                  // Category Section
                  _buildCategorySection(context, currentCategory, categories),

                  const SizedBox(height: SoMineTokens.spacingXXL),

                  // URL Section
                  _buildUrlSection(context),

                  const SizedBox(height: SoMineTokens.spacingXXL),

                  // Actions
                  _buildActions(context),

                  const SizedBox(height: SoMineTokens.spacingSection),

                  // Meta Info
                  _buildMetaInfo(context),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Action Bar
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: SoMineTokens.background,
      leading: _buildBackButton(context),
      actions: [
        _buildMoreButton(context),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _item.imageUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          SoMineTokens.background.withOpacity(0.8),
                          SoMineTokens.background,
                        ],
                        stops: const [0.4, 0.8, 1.0],
                      ),
                    ),
                  ),
                ],
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: SoMineTokens.cardBackground,
            borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
            boxShadow: SoMineTokens.cardShadow,
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: SoMineTokens.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => _showOptionsSheet(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: SoMineTokens.cardBackground,
            borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
            boxShadow: SoMineTokens.cardShadow,
          ),
          child: const Icon(
            Icons.more_horiz_rounded,
            color: SoMineTokens.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: SoMineTokens.background,
      child: Center(
        child: Icon(
          getPlatformIcon(_item.platform),
          size: 64,
          color: SoMineTokens.textTertiary,
        ),
      ),
    );
  }

  Widget _buildPlatformBadge(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SoMineTokens.spacingM,
            vertical: SoMineTokens.spacingS,
          ),
          decoration: BoxDecoration(
            gradient: SoMineTokens.primaryGradient,
            borderRadius: BorderRadius.circular(SoMineTokens.radiusRound),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                getPlatformIcon(_item.platform),
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: SoMineTokens.spacingXS),
              Text(
                _item.platform ?? _item.domain ?? 'Link',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: SoMineTokens.spacingS),
        if (_item.isFavorite == true)
          Container(
            padding: const EdgeInsets.all(SoMineTokens.spacingS),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(SoMineTokens.radiusRound),
            ),
            child: Icon(
              Icons.favorite_rounded,
              size: 16,
              color: Colors.red.shade400,
            ),
          ),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    CategoryModel currentCategory,
    List<CategoryModel> categories,
  ) {
    return Container(
      padding: const EdgeInsets.all(SoMineTokens.spacingL),
      decoration: BoxDecoration(
        color: SoMineTokens.cardBackground,
        borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
        boxShadow: SoMineTokens.cardShadow,
      ),
      child: Row(
        children: [
          // Kategori ikonu
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: _item.categoryId != null
                  ? SoMineTokens.showcaseGradients[
                      categories.indexOf(currentCategory) %
                          SoMineTokens.showcaseGradients.length]
                  : null,
              color: _item.categoryId == null ? SoMineTokens.background : null,
              borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
            ),
            child: Center(
              child: Text(
                currentCategory.emoji ?? '📁',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),

          const SizedBox(width: SoMineTokens.spacingL),

          // Kategori bilgisi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kategori',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  currentCategory.name.isNotEmpty
                      ? currentCategory.name
                      : 'Kategorisiz',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),

          // Değiştir butonu
          GestureDetector(
            onTap: () => _showCategoryPicker(context, categories),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SoMineTokens.spacingM,
                vertical: SoMineTokens.spacingS,
              ),
              decoration: BoxDecoration(
                color: SoMineTokens.background,
                borderRadius: BorderRadius.circular(SoMineTokens.radiusSmall),
              ),
              child: Text(
                'Değiştir',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: SoMineTokens.accentEnd,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SoMineTokens.spacingL),
      decoration: BoxDecoration(
        color: SoMineTokens.cardBackground,
        borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
        boxShadow: SoMineTokens.cardShadow,
      ),
      child: Row(
        children: [
          // Link ikonu
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: SoMineTokens.background,
              borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
            ),
            child: const Icon(
              Icons.link_rounded,
              color: SoMineTokens.textSecondary,
            ),
          ),

          const SizedBox(width: SoMineTokens.spacingL),

          // URL
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kaynak URL',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  _item.url,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SoMineTokens.accentEnd,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Kopyala butonu
          GestureDetector(
            onTap: _copyUrl,
            child: Container(
              padding: const EdgeInsets.all(SoMineTokens.spacingS),
              decoration: BoxDecoration(
                color: SoMineTokens.background,
                borderRadius: BorderRadius.circular(SoMineTokens.radiusSmall),
              ),
              child: const Icon(
                Icons.copy_rounded,
                size: 18,
                color: SoMineTokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        // Favorilere ekle
        Expanded(
          child: _ActionButton(
            icon: _item.isFavorite == true
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded,
            label: _item.isFavorite == true ? 'Favorilerde' : 'Favorile',
            isActive: _item.isFavorite == true,
            onTap: _toggleFavorite,
          ),
        ),

        const SizedBox(width: SoMineTokens.spacingM),

        // Paylaş
        Expanded(
          child: _ActionButton(
            icon: Icons.share_outlined,
            label: 'Paylaş',
            onTap: _shareItem,
          ),
        ),
      ],
    );
  }

  Widget _buildMetaInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bilgiler',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: SoMineTokens.textSecondary,
              ),
        ),
        const SizedBox(height: SoMineTokens.spacingM),
        Container(
          padding: const EdgeInsets.all(SoMineTokens.spacingL),
          decoration: BoxDecoration(
            color: SoMineTokens.cardBackground,
            borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
            boxShadow: SoMineTokens.cardShadow,
          ),
          child: Column(
            children: [
              _MetaRow(
                label: 'Eklenme Tarihi',
                value: _formatDate(_item.createdAt),
              ),
              const Divider(height: SoMineTokens.spacingXL),
              _MetaRow(
                label: 'Platform',
                value: _item.platform ?? 'Bilinmiyor',
              ),
              const Divider(height: SoMineTokens.spacingXL),
              _MetaRow(
                label: 'Domain',
                value: _item.domain ?? 'Bilinmiyor',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: SoMineTokens.spacingL,
        right: SoMineTokens.spacingL,
        top: SoMineTokens.spacingL,
        bottom: SoMineTokens.spacingL + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: SoMineTokens.cardBackground,
        boxShadow: SoMineTokens.bottomNavShadow,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _openUrl,
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: const Text('Kaynağa Git'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: SoMineTokens.spacingL,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showCategoryPicker(
      BuildContext context, List<CategoryModel> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryPickerSheet(
        categories: categories,
        currentCategoryId: _item.categoryId,
        onSelect: (category) => _updateCategory(category),
      ),
    );
  }

  Future<void> _updateCategory(CategoryModel category) async {
    try {
      final itemRepo = ref.read(itemRepositoryProvider);
      final updatedItem = _item.copyWith(categoryId: category.id);
      await itemRepo.updateItem(updatedItem);

      setState(() => _item = updatedItem);
      if (mounted) Navigator.pop(context);

      _showSnackbar('${category.emoji} ${category.name} kategorisine taşındı');
    } catch (e) {
      _showSnackbar('Hata oluştu', isError: true);
    }
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.lightImpact();
    try {
      final itemRepo = ref.read(itemRepositoryProvider);
      final updatedItem = _item.copyWith(isFavorite: !(_item.isFavorite ?? false));
      await itemRepo.updateItem(updatedItem);

      setState(() => _item = updatedItem);
      _showSnackbar(
        updatedItem.isFavorite == true
            ? '❤️ Favorilere eklendi'
            : 'Favorilerden çıkarıldı',
      );
    } catch (e) {
      _showSnackbar('Hata oluştu', isError: true);
    }
  }

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: _item.url));
    HapticFeedback.lightImpact();
    _showSnackbar('📋 Link kopyalandı');
  }

  void _shareItem() {
    // Share functionality
    _showSnackbar('Paylaşım yakında...');
  }

  Future<void> _openUrl() async {
    final uri = Uri.parse(_item.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(SoMineTokens.spacingL),
        decoration: BoxDecoration(
          color: SoMineTokens.cardBackground,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusXLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: SoMineTokens.spacingM),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SoMineTokens.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _OptionTile(
              icon: Icons.edit_outlined,
              label: 'Düzenle',
              onTap: () {
                Navigator.pop(context);
                // Edit functionality
              },
            ),
            _OptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Sil',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _confirmDelete();
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
        ),
        title: const Text('İçeriği Sil'),
        content: const Text('Bu içeriği silmek istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem() async {
    try {
      final itemRepo = ref.read(itemRepositoryProvider);
      await itemRepo.deleteItem(_item.id);

      if (mounted) {
        Navigator.pop(context);
        _showSnackbar('İçerik silindi');
      }
    } catch (e) {
      _showSnackbar('Silme başarısız', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : SoMineTokens.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Bilinmiyor';
    return '${date.day}.${date.month}.${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: SoMineTokens.spacingM,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.red.shade50 : SoMineTokens.cardBackground,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
          boxShadow: SoMineTokens.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.red.shade400 : SoMineTokens.textSecondary,
            ),
            const SizedBox(width: SoMineTokens.spacingS),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isActive
                        ? Colors.red.shade400
                        : SoMineTokens.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: SoMineTokens.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : SoMineTokens.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SoMineTokens.spacingXXL,
          vertical: SoMineTokens.spacingL,
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: SoMineTokens.spacingL),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? currentCategoryId;
  final Function(CategoryModel) onSelect;

  const _CategoryPickerSheet({
    required this.categories,
    this.currentCategoryId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(SoMineTokens.spacingL),
      decoration: BoxDecoration(
        color: SoMineTokens.cardBackground,
        borderRadius: BorderRadius.circular(SoMineTokens.radiusXLarge),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: SoMineTokens.spacingM),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SoMineTokens.textTertiary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: SoMineTokens.spacingL),
          Text(
            'Kategori Seç',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: SoMineTokens.spacingL),
          SizedBox(
            height: 300,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: SoMineTokens.spacingL,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category.id == currentCategoryId;
                final gradient = SoMineTokens.showcaseGradients[
                    index % SoMineTokens.showcaseGradients.length];

                return GestureDetector(
                  onTap: () => onSelect(category),
                  child: Container(
                    margin: const EdgeInsets.only(
                      bottom: SoMineTokens.spacingS,
                    ),
                    padding: const EdgeInsets.all(SoMineTokens.spacingM),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? SoMineTokens.accentEnd.withOpacity(0.1)
                          : SoMineTokens.background,
                      borderRadius:
                          BorderRadius.circular(SoMineTokens.radiusMedium),
                      border: isSelected
                          ? Border.all(color: SoMineTokens.accentEnd, width: 2)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(
                              SoMineTokens.radiusSmall,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              category.emoji ?? '📁',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: SoMineTokens.spacingM),
                        Expanded(
                          child: Text(
                            category.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: SoMineTokens.accentEnd,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

🎯 TASK 19: Capture Screen (Vakum Efekti)
📁 Dosya: lib/screens/capture_screen.dart
📝 Trae'ye Komut:

"Bu dosyayı tamamen sil ve aşağıdaki kod ile değiştir. Link yakalama ve metadata çekme ekranı - Vakum animasyonu ile."

dartimport 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
import 'package:somine_app/core/services/link_preview_service.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  final String url;

  const CaptureScreen({
    super.key,
    required this.url,
  });

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
    with TickerProviderStateMixin {
  // State
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSuccess = false;
  String? _errorMessage;

  // Link preview data
  String? _title;
  String? _description;
  String? _imageUrl;
  String? _domain;
  String? _platform;

  // Selected category
  CategoryModel? _selectedCategory;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _successController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchLinkPreview();
  }

  void _setupAnimations() {
    // Pulse animation for loading
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Success animation
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _fetchLinkPreview() async {
    try {
      final previewService = LinkPreviewService();
      final preview = await previewService.fetchPreview(widget.url);

      if (mounted) {
        setState(() {
          _title = preview?.title;
          _description = preview?.description;
          _imageUrl = preview?.imageUrl;
          _domain = preview?.domain;
          _platform = _detectPlatform(widget.url);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _domain = Uri.tryParse(widget.url)?.host;
          _platform = _detectPlatform(widget.url);
          _isLoading = false;
        });
      }
    }
  }

  String? _detectPlatform(String url) {
    final lowered = url.toLowerCase();
    if (lowered.contains('pinterest')) return 'Pinterest';
    if (lowered.contains('instagram')) return 'Instagram';
    if (lowered.contains('youtube') || lowered.contains('youtu.be')) return 'YouTube';
    if (lowered.contains('twitter') || lowered.contains('x.com')) return 'Twitter';
    if (lowered.contains('spotify')) return 'Spotify';
    if (lowered.contains('tiktok')) return 'TikTok';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: SoMineTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('İçerik Ekle'),
      ),
      body: _isSuccess
          ? _buildSuccessView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(SoMineTokens.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview Card
                  _buildPreviewCard(context),

                  const SizedBox(height: SoMineTokens.spacingXXL),

                  // Category Selection
                  Text(
                    'Kategori Seç',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: SoMineTokens.spacingM),
                  _buildCategorySelector(context, categories),

                  const SizedBox(height: SoMineTokens.spacingXXL),

                  // Quick category add
                  if (_selectedCategory == null)
                    _buildSkipHint(context),

                  const SizedBox(height: SoMineTokens.spacingXXL),

                  // Save Button
                  _buildSaveButton(context),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: SoMineTokens.spacingL),
                    Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isLoading ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: SoMineTokens.cardBackground,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusXLarge),
          boxShadow: SoMineTokens.cardShadowElevated,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(SoMineTokens.radiusXLarge),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _isLoading
                    ? _buildLoadingImage()
                    : _imageUrl != null
                        ? Image.network(
                            _imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(SoMineTokens.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SoMineTokens.spacingM,
                          vertical: SoMineTokens.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          gradient: SoMineTokens.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            SoMineTokens.radiusRound,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPlatformIcon(),
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _platform ?? _domain ?? 'Link',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: SoMineTokens.spacingM),

                  // Title
                  if (_isLoading)
                    _buildShimmerLine(width: double.infinity, height: 24)
                  else
                    Text(
                      _title ?? 'Başlık alınamadı',
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: SoMineTokens.spacingS),

                  // Description
                  if (_isLoading)
                    _buildShimmerLine(width: 200, height: 16)
                  else if (_description != null)
                    Text(
                      _description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: SoMineTokens.spacingM),

                  // URL
                  Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 14,
                        color: SoMineTokens.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.url,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: SoMineTokens.textTertiary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      color: SoMineTokens.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: SoMineTokens.accentEnd,
              ),
            ),
            const SizedBox(height: SoMineTokens.spacingM),
            Text(
              'İçerik yükleniyor...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: SoMineTokens.background,
      child: Center(
        child: Icon(
          _getPlatformIcon(),
          size: 48,
          color: SoMineTokens.textTertiary,
        ),
      ),
    );
  }

  Widget _buildShimmerLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: SoMineTokens.background,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildCategorySelector(
      BuildContext context, List<CategoryModel> categories) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(
          width: SoMineTokens.spacingM,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory?.id == category.id;
          final gradient = SoMineTokens.showcaseGradients[
              index % SoMineTokens.showcaseGradients.length];

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategory = isSelected ? null : category;
              });
            },
            child: AnimatedContainer(
              duration: SoMineTokens.animationFast,
              width: 80,
              decoration: BoxDecoration(
                gradient: isSelected ? gradient : null,
                color: isSelected ? null : SoMineTokens.cardBackground,
                borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
                border: isSelected
                    ? null
                    : Border.all(
                        color: SoMineTokens.background,
                        width: 2,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: gradient.colors.first.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : SoMineTokens.cardShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.emoji ?? '📁',
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: SoMineTokens.spacingXS),
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              isSelected ? Colors.white : SoMineTokens.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkipHint(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SoMineTokens.spacingL),
      decoration: BoxDecoration(
        color: SoMineTokens.accentStart.withOpacity(0.1),
        borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: SoMineTokens.accentEnd,
          ),
          const SizedBox(width: SoMineTokens.spacingM),
          Expanded(
            child: Text(
              'Kategori seçmezsen içerik Studio\'ya eklenir, sonra düzenleyebilirsin.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SoMineTokens.accentEnd,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading || _isSaving ? null : _saveItem,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: SoMineTokens.spacingL,
          ),
          disabledBackgroundColor: SoMineTokens.textTertiary.withOpacity(0.3),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt_rounded, size: 20),
                  const SizedBox(width: SoMineTokens.spacingS),
                  Text(
                    _selectedCategory != null
                        ? '${_selectedCategory!.emoji} ${_selectedCategory!.name}\'a Kaydet'
                        : 'Studio\'ya Gönder',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _successScale,
            builder: (context, child) {
              return Transform.scale(
                scale: _successScale.value,
                child: child,
              );
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: SoMineTokens.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: SoMineTokens.accentEnd.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: SoMineTokens.spacingXXL),
          Text(
            'Vakumlandı! 🎉',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: SoMineTokens.spacingS),
          Text(
            _selectedCategory != null
                ? '${_selectedCategory!.emoji} ${_selectedCategory!.name} kategorisine eklendi'
                : 'Studio\'ya eklendi, istediğin zaman düzenle',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getPlatformIcon() {
    switch (_platform?.toLowerCase()) {
      case 'pinterest':
        return Icons.push_pin_rounded;
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'youtube':
        return Icons.play_circle_rounded;
      case 'twitter':
        return Icons.alternate_email_rounded;
      case 'spotify':
        return Icons.music_note_rounded;
      case 'tiktok':
        return Icons.music_video_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  Future<void> _saveItem() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      final itemRepo = ref.read(itemRepositoryProvider);

      final item = ItemModel(
        id: '',
        url: widget.url,
        title: _title,
        description: _description,
        imageUrl: _imageUrl,
        domain: _domain,
        platform: _platform,
        categoryId: _selectedCategory?.id,
        userId: user?.uid,
        createdAt: DateTime.now(),
      );

      await itemRepo.createItem(item);

      HapticFeedback.heavyImpact();
      
      setState(() {
        _isSaving = false;
        _isSuccess = true;
      });

      _successController.forward();

      // 2 saniye sonra kapat
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Kaydetme başarısız. Lütfen tekrar dene.';
      });
    }
  }
}

🎯 TASK 20: Loading Indicator Widget
📁 Dosya: lib/widgets/loading_indicator.dart
📝 Trae'ye Komut:

"Bu dosyayı tamamen sil ve aşağıdaki kod ile değiştir. Soft UI tasarımlı loading göstergesi."

dartimport 'package:flutter/material.dart';
import 'package:somine_app/core/design/design_tokens.dart';

/// Gradient loading indicator
class SoMineLoadingIndicator extends StatefulWidget {
  final double size;
  final String? message;

  const SoMineLoadingIndicator({
    super.key,
    this.size = 48,
    this.message,
  });

  @override
  State<SoMineLoadingIndicator> createState() => _SoMineLoadingIndicatorState();
}

class _SoMineLoadingIndicatorState extends State<SoMineLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * 3.14159,
              child: child,
            );
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  SoMineTokens.accentStart,
                  SoMineTokens.accentEnd,
                  SoMineTokens.accentStart.withOpacity(0.1),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: widget.size - 8,
                height: widget.size - 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: SoMineTokens.background,
                ),
              ),
            ),
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: SoMineTokens.spacingL),
          Text(
            widget.message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SoMineTokens.textSecondary,
                ),
          ),
        ],
      ],
    );
  }
}

/// Full screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;

  const LoadingOverlay({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SoMineTokens.background.withOpacity(0.9),
      child: Center(
        child: SoMineLoadingIndicator(
          message: message,
        ),
      ),
    );
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({
    super.key,
    required this.child,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [
                0.0,
                0.5 + _animation.value * 0.25,
                1.0,
              ],
              transform: _SlidingGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Skeleton card for loading state
class SkeletonCard extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonCard({
    super.key,
    this.width = double.infinity,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: SoMineTokens.cardBackground,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: height * 0.6,
              decoration: BoxDecoration(
                color: SoMineTokens.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(SoMineTokens.radiusLarge),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(SoMineTokens.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title placeholder
                  Container(
                    height: 16,
                    width: width * 0.7,
                    decoration: BoxDecoration(
                      color: SoMineTokens.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: SoMineTokens.spacingS),
                  // Subtitle placeholder
                  Container(
                    height: 12,
                    width: width * 0.5,
                    decoration: BoxDecoration(
                      color: SoMineTokens.background,
                      borderRadius: BorderRadius.circular(4),
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
}
```

---

## 📋 FİNAL ÖZET - TÜM TASKLAR

| # | Dosya | Tür | Durum |
|---|-------|-----|-------|
| 1 | `design_tokens.dart` | 🔄 | ✅ |
| 2 | `app_theme.dart` | 🔄 | ✅ |
| 3 | `soft_card.dart` | ✨ | ✅ |
| 4 | `item_card.dart` | 🔄 | ✅ |
| 5 | `content_swimlane.dart` | 🔄 | ✅ |
| 6 | `showcase_section.dart` | ✨ | ✅ |
| 7 | `inbox_card.dart` | ✨ | ✅ |
| 8 | `home_header.dart` | 🔄 | ✅ |
| 9 | `home_screen.dart` | 🔄 | ✅ |
| 10 | `root_shell.dart` | 🔄 | ✅ |
| 11 | `vacuum_fab.dart` | ✨ | ✅ |
| 12 | `studio_screen.dart` | 🔄 | ✅ |
| 13 | `discover_screen.dart` | 🔄 | ✅ |
| 14 | `category_manager_screen.dart` | 🔄 | ✅ |
| 15 | `settings_screen.dart` | 🔄 | ✅ |
| 16 | `splash_screen.dart` | 🔄 | ✅ |
| 17 | `category_model.dart` | 🔄 | ✅ |
| 17 | `item_model.dart` | 🔄 | ✅ |
| 18 | `item_detail_screen.dart` | 🔄 | ✅ |
| 19 | `capture_screen.dart` | 🔄 | ✅ |
| 20 | `loading_indicator.dart` | 🔄 | ✅ |


