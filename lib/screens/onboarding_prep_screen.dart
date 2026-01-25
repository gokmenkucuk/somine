import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/design/app_colors.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/repositories/user_repository.dart';
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:somine_app/core/services/metadata_service.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/screens/home_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Onboarding screen that prepares demo content with a visual progress bar
class OnboardingPrepScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? displayName;
  
  const OnboardingPrepScreen({
    super.key, 
    required this.userId,
    this.displayName,
  });

  @override
  ConsumerState<OnboardingPrepScreen> createState() => _OnboardingPrepScreenState();
}

class _OnboardingPrepScreenState extends ConsumerState<OnboardingPrepScreen> with TickerProviderStateMixin {
  // Progress State (0.0 to 1.0)
  double _progress = 0.0;
  bool _isComplete = false;
  
  // Animation Controller for smooth progress bar
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  // Animation Controller for Text Shimmer
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // Initialize Animation Controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_progressController);
    
    // Initialize Shimmer Controller
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    // Start Content Preparation
    _prepareContent();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _updateProgress(double value) {
    if (mounted) {
      setState(() {
        _progress = value.clamp(0.0, 1.0);
      });
      _progressController.animateTo(_progress, curve: Curves.easeInOut);
    }
  }

  Future<void> _prepareContent() async {
    try {
      final userRepository = UserRepository();
      final categoryRepository = CategoryRepository();
      final itemRepository = ItemRepository();
      
      int totalSteps = 2 + 9; // Profile + Categories + 9 Items
      int currentStep = 0;

      void incrementStep() {
        currentStep++;
        _updateProgress(currentStep / totalSteps);
      }
      
      // 1. Update user name (Step 1)
      if (widget.displayName != null && widget.displayName!.isNotEmpty) {
        await userRepository.updateUserProfile(
          uid: widget.userId,
          displayName: widget.displayName,
        );
      }
      incrementStep();
      
      // 2. Create default categories (Step 2)
      final categories = await categoryRepository.createDefaultCategories(widget.userId);
      incrementStep();
      
      // 3. Find categories for demo content
      final placesCategory = categories.firstWhere(
        (c) => c.name == 'Gitmek İstediğim Yerler',
        orElse: () => categories.first,
      );
      
      final musicCategory = categories.firstWhere(
        (c) => c.name == 'Dinlemek İstediğim',
        orElse: () => categories.first,
      );
      
      // 4. Create demo content (Steps 3-11)
      final demoUrls = [
        {'url': 'https://www.instagram.com/reel/C4BRE6vIFIX/', 'categoryId': placesCategory.id},
        {'url': 'https://www.youtube.com/watch?v=Sf9CaRfv-BM', 'categoryId': placesCategory.id},
        {'url': 'https://www.youtube.com/shorts/Ah_2uDsoXQ8', 'categoryId': placesCategory.id},
        {'url': 'https://www.youtube.com/watch?v=i9UDD6zyCGs', 'categoryId': musicCategory.id},
        {'url': 'https://www.youtube.com/watch?v=Pclv31cDTTc', 'categoryId': musicCategory.id},
        {'url': 'https://www.youtube.com/watch?v=FkFB8f8bzbY', 'categoryId': musicCategory.id},
        {'url': 'https://www.youtube.com/watch?v=oD6fL4yyhDk', 'categoryId': musicCategory.id},
        {'url': 'https://www.youtube.com/watch?v=fR2JHaCDrMw', 'categoryId': musicCategory.id},
        {'url': 'https://www.youtube.com/watch?v=RP8REaM3WQ4', 'categoryId': musicCategory.id},
      ];
      
      final now = DateTime.now();
      int hourOffset = 0;
      
      for (final demo in demoUrls) {
        try {
          final url = demo['url'] as String;
          final categoryId = demo['categoryId'] as String;
          
          // Fetch metadata
          final metadata = await MetadataService.fetchMetadata(url);
          
          final item = ItemModel(
            id: '',
            userId: widget.userId,
            categoryId: categoryId,
            type: ItemType.link,
            url: url,
            ogMetadata: metadata,
            createdAt: now.subtract(Duration(hours: hourOffset)),
            updatedAt: now.subtract(Duration(hours: hourOffset)),
          );
          
          await itemRepository.createItem(item);
          hourOffset++;
        } catch (e) {
          debugPrint('⚠️ [Onboarding] Error creating demo item: $e');
        } finally {
          incrementStep();
        }
      }
      
      // Complete!
      if (mounted) {
        _updateProgress(1.0);
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => _isComplete = true);
        
        // Reset onboarding state so AuthWrapper is happy, but DON'T navigate yet
        ref.read(onboardingStateProvider.notifier).state = false;
      }
    } catch (e) {
      debugPrint('❌ [Onboarding] Error preparing content: $e');
      // If error, force complete state to allow user to proceed anyway
      if (mounted) {
        _updateProgress(1.0);
        setState(() => _isComplete = true);
        ref.read(onboardingStateProvider.notifier).state = false;
      }
    }
  }

  void _continueToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              
              // Title with Gradient
              // Title with Shimmer Effect
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: const [
                          AppColors.secondary,
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                        stops: const [
                          0.0,
                          0.5,
                          1.0,
                        ],
                        // Soldan sağa hareket için:
                        transform: _SlidingGradientTransform(slidePercent: _shimmerController.value),
                        tileMode: TileMode.repeated, // Sürekli akış için repeated
                      ).createShader(bounds);
                    },
                    child: Text(
                      'Koleksiyonlar Hazırlanıyor',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, 
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                'Sizin için seveceğinizi düşündüğümüz örnek içerikler hazırlıyoruz.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                  color: DesignTokens.textSecondary,
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Progress Bar
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                   return Container(
                     height: 8,
                     width: double.infinity,
                     decoration: BoxDecoration(
                       color: DesignTokens.background,
                       borderRadius: BorderRadius.circular(4),
                     ),
                     child: FractionallySizedBox(
                       alignment: Alignment.centerLeft,
                       widthFactor: _progressController.value,
                       child: Container(
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(4),
                           gradient: const LinearGradient(
                             colors: [AppColors.secondary, AppColors.primary], // Oil Green Gradient
                           ),
                         ),
                       ),
                     ),
                   );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Percentage Text (Optional, or just status)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _isComplete ? 'Tamamlandı' : 'Hazırlanıyor...',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _isComplete ? AppColors.primary : DesignTokens.textTertiary,
                  ),
                ),
              ),
              
              const Spacer(flex: 3),
              
              // Continue Button (Only Visible when Complete)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _isComplete ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_isComplete,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.secondary, AppColors.primary],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _continueToHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Keşfetmeye Başla',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    // Soldan sağa hareket (slidePercent 0 -> 1)
    // 0 iken translasyon 0
    // 1 iken translasyon bounds.width kadar (veya biraz daha fazla)
    // Tam bir döngü için 2 katı kadar kaydırıp TileMode ile tekrar etmesini sağlayabiliriz
    // Ama TileMode.mirror kullandık, o yüzden sürekli kayması lazım
    
    // Basit bir x ekseni translasyonu
    return Matrix4.translationValues(bounds.width * slidePercent * 2.0 - bounds.width, 0.0, 0.0);
  }
}
