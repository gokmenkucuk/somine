import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:animate_do/animate_do.dart';

import 'package:somine_app/screens/profile_screen.dart';

// Required for ImageFilter

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

  // Provided Content Data with Categories
  final List<Map<String, String>> _allContentList = [
    {
      'type': 'video',
      'url':
          'https://www.instagram.com/reel/DQ7I1OrDMMS/?igsh=NTNsYjJ5NWM2bTlw',
      'thumbnail': 'https://picsum.photos/seed/insta1/400/600',
      'title': 'Instagram Reel',
      'subtitle': 'Videoyu izlemek için tıklayın',
      'source': 'Instagram',
      'badge': 'Reel',
      'category': 'Komik',
    },
    {
      'type': 'image',
      'url': 'https://www.instagram.com/p/DQpLnkGgnm4/?igsh=eWlwcXhobWxqbmwz',
      'thumbnail': 'https://picsum.photos/seed/insta2/400/500',
      'title': 'Instagram Post',
      'subtitle': 'Gönderiyi incele',
      'source': 'Instagram',
      'badge': 'Post',
      'category': 'Tasarım',
    },
    {
      'type': 'image',
      'url': 'https://www.instagram.com/p/DSCoEkaAmAX/?igsh=MjhqZ2EzY2poNTZx',
      'thumbnail': 'https://picsum.photos/seed/insta3/400/450',
      'title': 'Doğa Yürüyüşü',
      'subtitle': 'Manzaranın tadını çıkar',
      'source': 'Instagram',
      'badge': 'New',
      'category': 'Seyahat',
    },
    {
      'type': 'video',
      'url':
          'https://www.instagram.com/reel/C4BRE6vIFIX/?igsh=enN6cWwzdmpyMHVu',
      'thumbnail': 'https://picsum.photos/seed/insta4/400/700',
      'title': 'Eğlenceli Anlar',
      'subtitle': 'Günün videosu',
      'source': 'Instagram',
      'badge': 'Viral',
      'category': 'Komik',
    },
    {
      'type': 'image',
      'url':
          'https://www.instagram.com/p/DQOWXTvgN97/?igsh=MXJuZnM1c3U1ZDA5eQ==',
      'thumbnail': 'https://picsum.photos/seed/insta5/400/400',
      'title': 'Sanat Eseri',
      'subtitle': 'Detaylara göz at',
      'source': 'Instagram',
      'badge': 'Art',
      'category': 'Tasarım',
    },
    {
      'type': 'video',
      'url': 'https://www.youtube.com/watch?v=D1f2dSi7kG4',
      'thumbnail': 'https://img.youtube.com/vi/D1f2dSi7kG4/hqdefault.jpg',
      'title': 'YouTube Video',
      'subtitle': 'Hemen izle',
      'source': 'YouTube',
      'badge': 'HD',
      'category': 'Müzik',
    },
    {
      'type': 'video',
      'url': 'https://www.youtube.com/watch?v=hhw90xpY7MI',
      'thumbnail': 'https://img.youtube.com/vi/hhw90xpY7MI/hqdefault.jpg',
      'title': 'Müzik Klibi',
      'subtitle': 'Yeni çıkanlar',
      'source': 'YouTube',
      'badge': 'Music',
      'category': 'Müzik',
    },
    {
      'type': 'video',
      'url': 'https://www.youtube.com/watch?v=vPg67r76hAA&t=1s',
      'thumbnail': 'https://img.youtube.com/vi/vPg67r76hAA/hqdefault.jpg',
      'title': 'Eğitici İçerik',
      'subtitle': 'Öğrenmeye başla',
      'source': 'YouTube',
      'badge': 'Edu',
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
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white, // FORCE PURE WHITE
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row (Menu & Search/Profile)
                              FadeInDown(
                                duration: const Duration(milliseconds: 600),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFE5E7EB),
                                          width: 1.5,
                                        ), // Added Grey Border
                                      ),
                                      child: const Icon(
                                        Icons.sort,
                                        color: Colors.black,
                                        size: 28,
                                      ),
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
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFE5E7EB,
                                                  ),
                                                  width: 1.5,
                                                ), // Added Grey Border
                                              ),
                                              child: const Icon(
                                                CupertinoIcons.search,
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
                                                        const ProfileScreen(),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(
                                                  0xFFE5E7EB,
                                                ), // Added Grey Border (Existing was white)
                                                width: 1.5,
                                              ),
                                            ),
                                            child: const Icon(
                                              CupertinoIcons.person,
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
                              const SizedBox(height: 32),

                              // Greeting
                              FadeInLeft(
                                delay: const Duration(milliseconds: 200),
                                child: Text(
                                  "Merhaba, Gökmen!",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Slogan (Full Width)
                              FadeInLeft(
                                delay: const Duration(milliseconds: 400),
                                child: ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback:
                                      (bounds) => const LinearGradient(
                                        colors: [
                                          Color(0xFF2563EB), // Blue 600
                                          Color(0xFF06B6D4), // Cyan 500
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                  child: Text(
                                    "Dijital dünyanı\ntasarla.",
                                    style: GoogleFonts.poppins(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Action Button Row (Single Slider Button)
                              FadeInUp(
                                delay: const Duration(milliseconds: 600),
                                child: Container(
                                  height: 80, // Biraz daha yüksek ve gösterişli
                                  decoration: BoxDecoration(
                                    // O referans görseldeki tatlı yeşil gradyan
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFE1EDE3),
                                        Color(0xFFD1E3D6),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      30,
                                    ), // Daha yuvarlak
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFD1E3D6,
                                        ).withValues(alpha: 0.5),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        // Add content action
                                      },
                                      borderRadius: BorderRadius.circular(30),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(
                                              left: 20.0,
                                            ),
                                            child: CircleAvatar(
                                              backgroundColor:
                                                  Colors
                                                      .black, // Siyah ikon butonu patlatır
                                              child: Icon(
                                                Icons.arrow_forward,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            "Yeni İçerik Ekle",
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const Padding(
                                            // Sağdaki oklar
                                            padding: EdgeInsets.only(
                                              right: 20.0,
                                            ),
                                            child: Icon(
                                              Icons.keyboard_double_arrow_right,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Category Header
                              FadeInUp(
                                delay: const Duration(milliseconds: 800),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Kategori seç",
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF9CA3AF),
                                      ),
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
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFE5E7EB),
                                            width: 1.5,
                                          ), // Added Grey Border
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              blurRadius: 10, // Softer shadow
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.slider_horizontal_3,
                                          size: 24,
                                          color: Colors.black,
                                        ), // Better icon
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),

                        // Categories (Horizontal List - Redesigned)
                        FadeInUp(
                          delay: const Duration(milliseconds: 1000),
                          child: SizedBox(
                            height: 60,
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

                        const SizedBox(height: 24),
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

                        const SizedBox(height: 16),
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
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
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

            // Floating Bottom Navigation Bar
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827), // Deep Black/Navy
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      CupertinoIcons.home,
                      color: Colors.white,
                      size: 26,
                    ),
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.search,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchScreen(),
                          ),
                        );
                      },
                    ),
                    // Center ADD Button
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.add,
                        color: Colors.black,
                        size: 28,
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.square_grid_2x2,
                      color: Colors.white,
                      size: 26,
                    ),
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.person,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
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
            // Gradient for Selected
            gradient:
                isSelected
                    ? const LinearGradient(
                      colors: [
                        Color(0xFF3B82F6), // Blue
                        Color(0xFF2563EB), // Darker Blue for 3D depth
                        Color(0xFF3B82F6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 0.5, 1.0], // Wave/3D effect in middle
                    )
                    : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(30), // Pill Shape
            border:
                isSelected
                    ? null
                    : Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : const Color(0xFF4B5563),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 15, // Slightly larger font
            ),
          ),
        ),
      ),
    );
  }

  // Content Card (Refined Style with Fade Animation)
  Widget _buildContentCard(
    Map<String, String> item,
    int index, {
    required bool isGrid,
  }) {
    // Fade-in animation on build
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, double value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: GestureDetector(
        onTap: () async {
          final url = Uri.parse(item['url']!);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFE5E7EB), // Lighter gray for outer border
              width: 1.5,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image/Thumbnail
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                        bottom: Radius.circular(0),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: item['thumbnail']!,
                        fit: BoxFit.cover,
                        height: isGrid ? (index % 2 == 0 ? 180 : 140) : 220,
                        width: double.infinity,
                        placeholder:
                            (context, url) =>
                                Container(color: Colors.grey[100]),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.error),
                            ),
                      ),
                    ),
                    // Badge Overlay
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item['badge'] ?? 'New',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    // Play Icon if Video
                    if (item['type'] == 'video')
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Content Details
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']!,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['subtitle']!,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w400,
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Action Button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827), // Black Button
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "İncele",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }
}
