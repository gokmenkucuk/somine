import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/screens/capture_screen.dart';
import 'package:somine_app/screens/item_detail_screen.dart';
import 'package:somine_app/screens/settings_screen.dart';
import 'package:somine_app/widgets/brand_logo_text.dart';
import 'package:somine_app/widgets/item_card.dart'; // Will refactor this later
import 'package:somine_app/widgets/loading_indicator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _crossAxisCount = 2; // Default to 2 columns
  // Scale for pinch gesture
  double _baseScaleFactor = 1.0;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final itemsAsync = ref.watch(itemsProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // A. Sticky Header with Greeting
            SliverAppBar(
              backgroundColor: DesignTokens.background,
              surfaceTintColor: Colors.transparent,
              floating: true,
              pinned: true,
              expandedHeight: 140, 
              toolbarHeight: 80, // Taller toolbar for greeting
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Greeting & Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded( // Allow text to take space
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Selam,',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: DesignTokens.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    user?.displayName?.split(' ').first ?? 'Misafir',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      color: DesignTokens.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Profile / Scanner Button (Grouped like reference)
                            Row(
                               children: [
                                   // Scanner Placeholder (Reference has one)
                                   Container(
                                     padding: const EdgeInsets.all(10),
                                     decoration: BoxDecoration(
                                       color: Colors.white,
                                       shape: BoxShape.circle,
                                       boxShadow: DesignTokens.shadowSM,
                                     ),
                                     child: const Icon(Icons.qr_code_scanner, color: DesignTokens.primary, size: 20),
                                   ),
                                   const SizedBox(width: 12),
                                   // Profile Pic
                                   GestureDetector(
                                     onTap: () {
                                       Navigator.push(
                                         context,
                                         MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                       );
                                     },
                                     child: Container(
                                       width: 44,
                                       height: 44,
                                       decoration: BoxDecoration(
                                         shape: BoxShape.circle,
                                         color: DesignTokens.border,
                                         image: user?.photoURL != null 
                                           ? DecorationImage(image: NetworkImage(user!.photoURL!))
                                           : null,
                                       ),
                                       child: user?.photoURL == null 
                                         ? const Icon(Icons.person, color: DesignTokens.textSecondary, size: 24)
                                         : null,
                                     ),
                                   ),
                               ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Search Bar (White container)
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
                            boxShadow: DesignTokens.shadowSM, // Soft shadow like reference
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: DesignTokens.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Koleksiyonunda ara...',
                                  style: GoogleFonts.poppins(color: DesignTokens.textTertiary, fontSize: 14),
                                ),
                              ),
                              // Filter icon maybe?
                              const Icon(Icons.tune, color: DesignTokens.textTertiary, size: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // B. Category Strip (Horizontal Scroll)
            SliverToBoxAdapter(
              child: _buildCategoryStrip(categoriesAsync, selectedCategoryId),
            ),
          ];
        },
        // C. Dynamic Masonry Grid
        body: GestureDetector(
          onScaleStart: (details) => _baseScaleFactor = _baseScaleFactor, 
          onScaleUpdate: (details) {
            if (details.scale > 1.5 && _crossAxisCount > 1) {
              setState(() => _crossAxisCount = 1);
            } else if (details.scale < 0.7 && _crossAxisCount < 3) {
              setState(() => _crossAxisCount = 3);
            }
          },
          child: itemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'Koleksiyonun boş.',
                    style: GoogleFonts.poppins(color: DesignTokens.textTertiary),
                  ),
                );
              }
              return MasonryGridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: _crossAxisCount, 
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ItemCard(
                    item: item,
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
              );
            },
            loading: () => const Center(child: LoadingIndicator()),
            error: (e, _) => Center(child: Text('Hata: $e')),
          ),
        ),
      ),
      // D. Floating Action Button (Magic Button)
      floatingActionButton: Container(
        decoration: BoxDecoration(
           gradient: DesignTokens.floatingButtonGradient,
           shape: BoxShape.circle,
           boxShadow: DesignTokens.shadowGlow,
        ),
        child: FloatingActionButton(
          onPressed: () {
             Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder:(_) => const CaptureScreen(url: 'https://example.com'),
                 ),
             );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  Widget _buildCategoryStrip(AsyncValue<List<CategoryModel>> categoriesAsync, String? selectedCategoryId) {
    return SizedBox(
      height: 140, 
      child: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) return const SizedBox.shrink();
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1, // +1 for "Inbox"
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              // 0 is Inbox
              if (index == 0) {
                return _buildVisualCategoryBox(
                  title: 'Tümü',
                  subtitle: '${itemsAsync.valueOrNull?.length ?? 0} öğe', // Actual count
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  icon: Icons.all_inclusive,
                  isSelected: selectedCategoryId == null,
                  onTap: () {
                    ref.read(selectedCategoryIdProvider.notifier).state = null;
                  },
                );
              }
              
              final category = categories[index - 1]; // Offset index
              return _buildVisualCategoryBox(
                title: category.name,
                subtitle: 'Gözat', // Generic subtitle for now
                gradient: _getGradientForCategory(index), 
                icon: Icons.folder_open,
                isSelected: selectedCategoryId == category.id,
                onTap: () {
                  ref.read(selectedCategoryIdProvider.notifier).state = category.id;
                },
              );
            },
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
      ),
    );
  }

  Widget _buildVisualCategoryBox({
    required String title,
    required String subtitle,
    required Gradient gradient,
    required IconData icon,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200, 
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          border: isSelected ? Border.all(color: DesignTokens.primary, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: const Color(0xff333333).withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [ // ... (rest of stack)
          // 1. Artistic Background Decoration (Big Icon)
          Positioned(
            right: -20,
            bottom: -20,
            child: Transform.rotate(
              angle: -0.2, // Slight tilt
              child: Icon(
                icon,
                size: 100, // Huge icon
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          
          // 2. Artistic Circle Decoration
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),

          // 3. Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 // Small Icon Badge
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     color: Colors.white.withValues(alpha: 0.25), // Glassy
                     shape: BoxShape.circle,
                   ),
                   child: Icon(icon, color: Colors.white, size: 18),
                 ),
                 
                 const Spacer(), // Pushes text to bottom
                 
                 // Title with Auto-sizing logic (using Flexible)
                 Text(
                   title,
                   style: GoogleFonts.poppins(
                     fontSize: 16, // Slightly smaller base to fit
                     fontWeight: FontWeight.bold,
                     color: Colors.white,
                     height: 1.2,
                   ),
                   maxLines: 2, 
                   overflow: TextOverflow.ellipsis,
                 ),
                 
                 const SizedBox(height: 4),
                 
                 Text(
                   subtitle,
                   style: GoogleFonts.poppins(
                     fontSize: 11,
                     fontWeight: FontWeight.w500,
                     color: Colors.white.withValues(alpha: 0.8),
                   ),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Gradient _getGradientForCategory(int index) {
     // More vivid, creative gradients
     final gradients = [
       const LinearGradient(
         colors: [Color(0xFF4facfe), Color(0xFF00f2fe)], // Vivid Blue/Cyan
         begin: Alignment.topLeft, end: Alignment.bottomRight,
       ),
       const LinearGradient(
         colors: [Color(0xFFf093fb), Color(0xFFf5576c)], // Pink/Red
         begin: Alignment.topLeft, end: Alignment.bottomRight,
       ),
       const LinearGradient(
         colors: [Color(0xFF84fab0), Color(0xFF8fd3f4)], // Minty
         begin: Alignment.topLeft, end: Alignment.bottomRight,
       ),
       const LinearGradient(
         colors: [Color(0xFFfa709a), Color(0xFFfee140)], // Sunset
         begin: Alignment.topLeft, end: Alignment.bottomRight,
       ),
       const LinearGradient(
         colors: [Color(0xFF667eea), Color(0xFF764ba2)], // Deep Purple
         begin: Alignment.topLeft, end: Alignment.bottomRight,
       ),
     ];
     return gradients[index % gradients.length];
  }
}
