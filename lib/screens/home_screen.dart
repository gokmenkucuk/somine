import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:somine_app/screens/profile_screen.dart';
import 'dart:ui' as ui;
import 'package:somine_app/screens/notifications_screen.dart';
import 'package:somine_app/screens/add_content_screen.dart';

import 'package:somine_app/screens/category_manager_screen.dart';

import 'package:somine_app/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State for Grid/List Toggle & Category Selection
  bool _isGridMode = true;
  String _selectedCategory = 'Tümü';

  // Sharing Intent Subscriptions
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _setupSharingIntent();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  // Setup Share Intent Listener
  void _setupSharingIntent() {
    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> value) {
            if (value.isNotEmpty && value.first.path.isNotEmpty) {
              if (mounted) {
                _openAddContentScreen(initialText: value.first.path);
              }
            }
          },
          onError: (err) {
            debugPrint("getMediaStream error: $err");
          },
        );

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> value,
    ) {
      if (value.isNotEmpty && value.first.path.isNotEmpty) {
        if (mounted) {
          _openAddContentScreen(initialText: value.first.path);
        }
      }
    });
  }

  void _openAddContentScreen({String? initialText}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddContentScreen(initialText: initialText),
      ),
    );
  }

  // Platform Color Helper
  Color _getPlatformColor(String source) {
    switch (source.toLowerCase()) {
      case 'instagram':
        return const Color(0xFFC13584); // Instagram Purple/Pink
      case 'youtube':
        return const Color(0xFFFF0000); // YouTube Red
      case 'twitter':
      case 'x':
        return Colors.black; // X Black
      case 'linkedin':
        return const Color(0xFF0077B5); // LinkedIn Blue
      default:
        return const Color(0xFF1A1E38); // So.Mine Dark Blue
    }
  }

  // Provided Content Data with Categories (Updated with Dynamic Ratios)
  final List<Map<String, String>> _allContentList = [
    {
      'type': 'video',
      'url':
          'https://www.instagram.com/reel/DQ7I1OrDMMS/?igsh=NTNsYjJ5NWM2bTlw',
      'thumbnail': 'https://picsum.photos/seed/insta1/400/600', // 2:3
      'title': 'Instagram Reel',
      'subtitle': 'Videoyu izlemek için tıklayın',
      'source': 'Instagram',
      'badge': 'Seyahat',
      'category': 'Seyahat',
    },
    {
      'type': 'video',
      'url': 'https://youtu.be/dummy1',
      'thumbnail': 'https://picsum.photos/seed/yt1/400/300', // 4:3
      'title': 'YouTube Eğitim Videosu',
      'subtitle': 'Flutter ile harikalar yaratın',
      'source': 'YouTube',
      'badge': 'Eğitim',
      'category': 'Eğitim',
    },
    {
      'type': 'link',
      'url': 'https://twitter.com/dummy',
      'thumbnail': 'https://picsum.photos/seed/tw1/400/400', // 1:1
      'title': 'Twitter Thread',
      'subtitle': 'Yazılım dünyasından haberler',
      'source': 'Twitter',
      'badge': 'Teknoloji',
      'category': 'Teknoloji',
    },
    {
      'type': 'video',
      'url': 'https://instagram.com/dummy2',
      'thumbnail': 'https://picsum.photos/seed/insta2/400/500', // 4:5
      'title': 'Moda Haftası',
      'subtitle': 'En son trendler',
      'source': 'Instagram',
      'badge': 'Moda',
      'category': 'Moda',
    },
    {
      'type': 'video',
      'url':
          'https://www.instagram.com/reel/DQ7I1OrDMMS/?igsh=NTNsYjJ5NWM2bTlw',
      'thumbnail': 'https://picsum.photos/seed/insta3/400/700', // Tall
      'title': 'Doğa Yürüyüşü',
      'subtitle': 'Huzur dolu anlar',
      'source': 'Instagram',
      'badge': 'Spor',
      'category': 'Spor',
    },
     {
      'type': 'video',
      'url': 'https://youtu.be/dummy2',
      'thumbnail': 'https://picsum.photos/seed/yt2/400/250', // Wide
      'title': 'Yemek Tarifi',
      'subtitle': 'Lezzetli makarnalar',
      'source': 'YouTube',
      'badge': 'Yemek',
      'category': 'Yemek',
    },
    {
      'type': 'link',
      'url': 'https://example.com',
      'thumbnail': '', // NO IMAGE -> Triggers Fallback Gradient
      'title': 'Görselsiz Fikir Notu',
      'subtitle': 'Sadece metin içeren örnek',
      'source': 'Linkedin',
      'badge': 'Fikir',
      'category': 'Fikir',
    },
  ];
  // Category List
  final List<String> _categories = [
    "Tümü",
    "Seyahat",
    "Spor",
    "Müzik",
    "Komik",
    "Tasarım",
    "Fikir",
  ];

  @override
  Widget build(BuildContext context) {
    // Filter content based on selection
    final filteredContent =
        _selectedCategory == 'Tümü'
            ? _allContentList
            : _allContentList
                .where((item) => item['category'] == _selectedCategory)
                .toList();

    return Scaffold(
      backgroundColor: Colors.transparent, 
      extendBody: true,
      
      // Floating Action Button (Center Docked)
      floatingActionButton: Container(
        width: 64, 
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE8E6C9), // Soft Yellow/Cream
              Color(0xFFC0D6D8), // Soft Blue/Grey
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC0D6D8).withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openAddContentScreen(),
            customBorder: const CircleBorder(),
            splashColor: Colors.white.withOpacity(0.3),
            child: const Icon(
              PhosphorIconsLight.plus,
              color: Color(0xFF1A1E38),
              size: 28,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0, // Compact notch gap
        color: const Color(0xFF1C1C1C), // Anthracite
        elevation: 0,
        height: 50, // Reduced height for less bottom space
        padding: const EdgeInsets.only(top: 8), // Push icons down slightly
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // Equal distribution
          children: [
            // Left Items
            IconButton(
              onPressed: () {}, // Active Home
              icon: const Icon(
                PhosphorIconsLight.house,
                color: Colors.white,
                size: 26,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              icon: Icon(
                PhosphorIconsLight.magnifyingGlass,
                color: Colors.white.withOpacity(0.6),
                size: 26,
              ),
            ),

            // Spacer for FAB (Standard gap)
            const SizedBox(width: 48),

            // Right Items
            IconButton(
              onPressed: () {},
              icon: Icon(
                PhosphorIconsLight.squaresFour,
                color: Colors.white.withOpacity(0.6),
                size: 26,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              icon: Icon(
                PhosphorIconsLight.user,
                color: Colors.white.withOpacity(0.6),
                size: 26,
              ),
            ),
          ],
        ),
      ),

      body: Container(
        color: Colors.white, // Pure White Background
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  // Header & Categories Section (Box Adapter)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Content with Padding
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 12.0,
                          ),
                          child: FadeInDown(
                            duration: const Duration(milliseconds: 600),
                            child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min, // Wrap content height
                                      children: [
                                        Text(
                                          "Merhaba,",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF6B7280), // Gray 
                                            height: 1.2,
                                          ),
                                        ),
                                        Text(
                                          "Gökmen",
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF111827), // Darker black
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        const SearchScreen(),
                                              ),
                                            );
                                          },
                                          child: Hero(
                                            tag: 'searchField',
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.6), // Frosted
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5,
                                                ), 
                                              ),
                                              child: Icon(
                                                PhosphorIconsLight.magnifyingGlass,
                                                color: Colors.black,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        const NotificationsScreen(),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.6), // Frosted
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Icon(
                                              PhosphorIconsLight.bell, 
                                              color: Colors.black,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),

                        // Slogan (Full Width)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: FadeInLeft(
                            delay: const Duration(milliseconds: 400),
                            child: Text(
                              "Dijital dünyanı\ntasarla.",
                              style: GoogleFonts.poppins(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                letterSpacing: -0.5,
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                    colors: [
                                      Color(0xFF438E96), // Vibrant Teal (Cool but Colorful)
                                      Color(0xFFE0CD60), // Vibrant Warm Cream/Gold (Warmth)
                                    ],
                                    begin: Alignment.bottomRight, // Reversed Direction
                                    end: Alignment.topLeft,
                                  ).createShader(
                                    const Rect.fromLTWH(0.0, 0.0, 300.0, 100.0),
                                  ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),



                        // Category Header
                        FadeInUp(
                          delay: const Duration(milliseconds: 800),
                          child: Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 24.0),
                             child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Koleksiyonlar",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1F2937), // Darker Grey
                                    ),
                                  ),
                                  const SizedBox(height: 2), // Minimal spacing
                                  Text(
                                    "Kaydettiklerinin arasında özgürce gez.",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13, // Increased size
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const CategoryManagerScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 48, // Same size as top icons
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.3), // Visible Border
                                      width: 1.5,
                                    ), 
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(
                                          0.05,
                                        ),
                                        blurRadius: 10, // Softer shadow
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    PhosphorIconsLight.slidersHorizontal,
                                    size: 24,
                                    color: Colors.black,
                                  ), // Better icon
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),
                        const SizedBox(height: 16), 

                        // Categories (Horizontal List) ...
                        FadeInUp(
                          delay: const Duration(milliseconds: 1000),
                          child: SizedBox(
                            height: 48, // Reduced height
                            child: ListView.builder(
                              clipBehavior: Clip.none,
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                return Center(
                                  child: _buildCategoryChip(_categories[index]),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 2), // Almost zero spacing
                        // Toggle Row
                        FadeInUp(
                          delay: const Duration(milliseconds: 1200),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${filteredContent.length} İçerik",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1E38),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        CupertinoIcons.square_grid_2x2_fill,
                                        color:
                                            _isGridMode
                                                ? const Color(0xFF1A1E38)
                                                : const Color(0xFF9CA3AF),
                                        size: 20,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () => _isGridMode = true,
                                          ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        CupertinoIcons.list_bullet,
                                        color:
                                            !_isGridMode
                                                ? const Color(0xFF1A1E38)
                                                : const Color(0xFF9CA3AF),
                                        size: 22,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () => _isGridMode = false,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 4), 
                      ],
                    ),
                  ),

                  // Content Feed (Masonry Grid or List)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver:
                        _isGridMode
                            ? SliverMasonryGrid.count(
                              key: ValueKey(
                                _selectedCategory,
                              ), // Forces rebuild for animation
                              crossAxisCount: 2,
                              mainAxisSpacing: 12, // Reduced to 12px
                              crossAxisSpacing: 12, // Reduced to 12px
                              childCount: filteredContent.length,
                              itemBuilder:
                                  (context, index) => _buildContentCard(
                                    filteredContent[index],
                                    index,
                                    isGrid: true,
                                  ),
                            )
                            : SliverList(
                              key: ValueKey(
                                _selectedCategory,
                              ), // Forces rebuild
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildContentCard(
                                    filteredContent[index],
                                    index,
                                    isGrid: false,
                                  ),
                                ),
                                childCount: filteredContent.length,
                              ),
                            ),
                  ),

                  // Bottom Spacer
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Redesigned Category Chip
  Widget _buildCategoryChip(String label) {
    final bool isSelected = _selectedCategory == label;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = label;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 8, // Reduced vertical padding (was 12)
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // Gradient for Selected (Aurora Effect)
            gradient:
                isSelected
                    ? const LinearGradient(
                      colors: [
                        Color(0xFFE8E6C9), // Soft Yellow/Cream
                        Color(0xFFC0D6D8), // Soft Blue/Grey
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(30), // Pill Shape
            border:
                isSelected
                    ? Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1,
                    ) // Subtle border for active
                    : Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1.5,
                    ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: const Color(
                          0xFF6B8C96,
                        ).withOpacity(0.2), // Soft colored shadow
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color:
                  isSelected
                      ? const Color(0xFF1A1E38)
                      : const Color(0xFF4B5563), // Dark text on light gradient
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 15, // Slightly larger font
            ),
          ),
        ),
      ),
    );
  }

  // Platform Icon Helper
  IconData _getPlatformIcon(String source) {
    if (source.toLowerCase() == 'somine' || source.isEmpty) {
        return PhosphorIconsLight.spiral; // Placeholder, used for logic later
    }
    switch (source.toLowerCase()) {
      case 'instagram':
        return PhosphorIconsLight.instagramLogo;
      case 'youtube':
        return PhosphorIconsLight.youtubeLogo;
      case 'twitter':
      case 'x':
        return PhosphorIconsLight.xLogo;
      case 'linkedin':
        return PhosphorIconsLight.linkedinLogo;
      default:
        return PhosphorIconsLight.globe; // Generic Web
    }
  }

  // Helper to check if it is a major social platform
  bool _isSocialPlatform(String source) {
      final s = source.toLowerCase();
      return ['instagram', 'youtube', 'twitter', 'x', 'linkedin'].contains(s);
  }


  // Aspect Ratio Helper from Picsum URL
  double _getAspectRatio(String url) {
    try {
      if (url.contains('picsum.photos')) {
        final parts = url.split('/');
        final height = double.parse(parts.last);
        final width = double.parse(parts[parts.length - 2]);
        return width / height;
      }
      return 1.0; // Default square
    } catch (e) {
      return 1.0;
    }
  }

  // Platform Gradient Helper
  LinearGradient? _getPlatformGradient(String source) {
    switch (source.toLowerCase()) {
      case 'instagram':
        return LinearGradient(
          colors: [
            const Color(0xFF833AB4).withOpacity(0.8),
            const Color(0xFFFD1D1D).withOpacity(0.8),
            const Color(0xFFFCAF45).withOpacity(0.8),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        );
      case 'youtube':
        return LinearGradient(
          colors: [
            const Color(0xFFFF0000).withOpacity(0.8),
            const Color(0xFFCC0000).withOpacity(0.8),
          ],
        );
      default:
        // Use single color as gradient for others
        final color = _getPlatformColor(source).withOpacity(0.8);
        return LinearGradient(colors: [color, color]);
    }
  }

  // Center Icon Helper
  Widget? _buildCenterIcon(String type) {
    IconData icon;
    switch (type.toLowerCase()) {
      case 'video':
        icon = PhosphorIconsLight.playCircle;
        break;
      case 'link':
        icon = PhosphorIconsLight.arrowUpRight; // Changed to UpRight Arrow
        break;
      case 'image':
        icon = PhosphorIconsLight.image;
        break;
      default:
        return null; // No icon for others
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: 32,
        ),
      ),
    );
  }

  // Content Card (Refined Style with Fade Animation - Stack Design)
  Widget _buildContentCard(
    Map<String, String> item,
    int index, {
    required bool isGrid,
  }) {
    final aspectRatio = _getAspectRatio(item['thumbnail']!);
    final source = item['source'] ?? '';
    final hasImage =
        item['thumbnail'] != null && item['thumbnail']!.isNotEmpty;

    // Fade-in animation on build
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, double value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: Colors.transparent, // Important for InkWell
                child: InkWell(
                  onTap: () async {
                      final url = item['url'];
                      if (url != null) {
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      }
                  },
                  highlightColor: Colors.black.withOpacity(0.1),
                  splashColor: Colors.black.withOpacity(0.1),
                  child: Stack(
                fit: StackFit.expand, // Fill the aspect ratio box
                children: [
                  // Layer 1: Background (Image or Fallback Gradient)
                  if (hasImage)
                    CachedNetworkImage(
                      imageUrl: item['thumbnail']!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error),
                      ),
                    )
                  else
                    // NO IMAGE STATE - Redesigned
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          stops: const [0.0, 0.3, 1.0], // Colors finish lower, more white space
                          colors: [
                            const Color(0xFF438E96), // Vibrant Teal
                            const Color(0xFFF3EAC2), // Pale Cream/Gold (Softer)
                            Colors.white,            // Clean White
                          ],
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                            // Visual Center Icon (Nested Border Style)
                            Container(
                              padding: const EdgeInsets.all(12), // Gap between Dark Bg and White Border
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2), // Standard Dark Glass (Outer)
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(6), // Gap between Border and Icon
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.9), // White Border (Inner)
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  PhosphorIconsLight.arrowRight,
                                  color: Colors.white,
                                  size: 16, // Smaller Icon
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Layer 1.5: Overlay Gradient (Only if Image exists)
                  if (hasImage)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: const Alignment(0.0, -0.6), // Higher gradient overlay for better visibility
                          colors: [
                            const Color(
                              0xFFC8DCE5,
                            ).withOpacity(0.95), // Soft Blue/Grey
                            const Color(
                              0xFFD6E4CA,
                            ).withOpacity(0.0), // Sage Green Transparent
                          ],
                        ),
                      ),
                    ),

                  // Layer 2: Center Icon (Only if has image, otherwise watermark handles it)
                  if (hasImage && _buildCenterIcon(item['type'] ?? '') != null)
                    _buildCenterIcon(item['type'] ?? '')!,

                  // Layer 3: Header Row (Badge Left, Platform/Badge Right)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Badge (User Category) - Left Top with Blur
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(
                              sigmaX: 10.0,
                              sigmaY: 10.0,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                  0.6, // More opaque
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                item['badge'] ?? item['category']!,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1E38), // Dark Text
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Platform Indicator - Right Top (Complex Logic)
                        Builder(
                            builder: (context) {
                                bool isInternal = source.toLowerCase() == 'somine' || source.isEmpty;
                                
                                if (isInternal) {
                                    // "SO" Badge for Internal Content
                                    return ClipRRect(
                                        borderRadius: BorderRadius.circular(12), // Oval/Pill shape
                                        child: BackdropFilter(
                                            filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                                            child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.3),
                                                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 0.5),
                                                ),
                                                child: Text(
                                                    "SO",
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w900, // Extra Bold
                                                        color: Colors.black, // Black Text
                                                    ),
                                                ),
                                            ),
                                        ),
                                    );
                                } else {
                                    // Social or Web Icon
                                    return Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                            gradient: _getPlatformGradient(source), // Gradient Background
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                            BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                            ),
                                            ],
                                        ),
                                        child: Icon(
                                            _getPlatformIcon(source),
                                            color: Colors.white, // White Icon
                                            size: 16,
                                        ),
                                    );
                                }
                            },
                        ),
                      ],
                    ),
                  ),

                  // Layer 4: Content Info (Bottom Left) - Title Only
                  Positioned(
                    bottom: 16, // Moved up slightly
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          item['title']!,
                          maxLines: 1, // Single line
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600, // Medium weight
                            color: const Color(0xFF1A1E38), // Dark Text
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
                ),
              ),
            ),
          ),
      ),
    );
  }
}
