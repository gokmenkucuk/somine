import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:animate_do/animate_do.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  // Son Aramalar (Mock Data)
  final List<String> _recentSearches = [
    "Minimalist Tasarım",
    "Flutter UI Kit",
    "Seyahat Planı",
    "Yemek Tarifleri",
    "Teknoloji Haberleri",
    "Logo İlhamları",
    "Renk Paletleri",
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _removeSearchItem(int index) {
    setState(() {
      _recentSearches.removeAt(index);
    });
  }

  void _clearAllSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // === 1. BACKGROUND: "The Freedom Wave" ===
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(
                0xFFFFFEF9,
              ), // Sunlight Cream (üst sol) - çok açık sıcak beyaz
              Color(0xFFF7F9F4), // Soft warm white
              Color(0xFFEEF6F5), // Geçiş - çok açık mint
              Color(0xFFE4F2F1), // Mist Teal
              Color(0xFFDBEEF0), // Soft Ocean Mist (alt sağ)
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // === HEADER: Back Button + Title ===
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: FadeInDown(
                  duration: const Duration(milliseconds: 400),
                  child: Row(
                    children: [
                      // Geri/Kapat Butonu
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0EA5E9,
                                ).withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Başlık
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Ara ",
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w300,
                                  color: const Color(0xFF1F2937),
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                "ve Keşfet",
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F2937),
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Koleksiyonlarında arama yap...",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // === 2. THE HERO: "Aurora Search Bar" ===
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: FadeInDown(
                  delay: const Duration(milliseconds: 150),
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white, // Pure White Background
                      borderRadius: BorderRadius.circular(30), // Tam oval
                      // White Contour (Visible but soft)
                      border: Border.all(
                        color: const Color(
                          0xFFB0BEC5,
                        ), // Slightly more distinct Grey
                        width: 1.5,
                      ),
                      // Shadow Removed
                      boxShadow: [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Stack(
                        children: [
                          // TextField
                          Center(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              style: GoogleFonts.poppins(
                                color: Colors.black, // Black Text
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              cursorColor: Colors.black, // Black Cursor
                              cursorWidth: 2,
                              decoration: InputDecoration(
                                hintText: "Aramak için bir şeyler yaz...",
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.black54, // Distinct Grey Hint
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 20, right: 14),
                                  child: Icon(
                                    CupertinoIcons.search,
                                    color: Colors.black, // Black Icon
                                    size: 22,
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 56,
                                ),
                                suffixIcon:
                                    _searchController.text.isNotEmpty
                                        ? Padding(
                                          padding: const EdgeInsets.only(
                                            right: 10,
                                          ),
                                          child: GestureDetector(
                                            onTap:
                                                () => setState(
                                                  () =>
                                                      _searchController.clear(),
                                                ),
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.1,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                size: 18,
                                                color: Colors.white60,
                                              ),
                                            ),
                                          ),
                                        )
                                        : null,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // === 3. SON ARAMALAR HEADER ===
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeInDown(
                  delay: const Duration(milliseconds: 250),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.clock,
                            size: 18,
                            color: const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Son Aramalar",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                      if (_recentSearches.isNotEmpty)
                        GestureDetector(
                          onTap: _clearAllSearches,
                          child: Text(
                            "Temizle",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(
                                0xFF2563EB,
                              ), // Home Screen Blue
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // === 3. SON ARAMALAR LİSTESİ ===
              Expanded(
                child:
                    _recentSearches.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _recentSearches.length,
                          itemBuilder: (context, index) {
                            return FadeInUp(
                              delay: Duration(milliseconds: 300 + (index * 60)),
                              child: _buildSearchHistoryItem(
                                _recentSearches[index],
                                index,
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Son Arama Kartı
  Widget _buildSearchHistoryItem(String query, int index) {
    return GestureDetector(
      onTap: () {
        // Aramayı yap
        _searchController.text = query;
        debugPrint('Aranıyor: $query');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Saat ikonu
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CupertinoIcons.time,
                size: 18,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 14),
            // Arama metni
            Expanded(
              child: Text(
                query,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151),
                ),
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF60A5FA), // Faint Blue Border
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Color(0xFF60A5FA),
                ), // Faint Blue Icon
              ),
              color: const Color(0xFF60A5FA), // Faint Blue Splash
              onPressed: () => _removeSearchItem(index),
            ),
          ],
        ),
      ),
    );
  }

  // Boş State
  Widget _buildEmptyState() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                CupertinoIcons.search,
                size: 32,
                color: const Color(0xFFD1D5DB),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Henüz arama yapmadınız",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937), // Dark Black-Grey
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Aramalarınız burada görünecek",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280), // Medium Dark Grey
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
