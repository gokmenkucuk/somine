import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AddContentScreen extends StatefulWidget {
  final String? initialText;

  const AddContentScreen({super.key, this.initialText});

  @override
  State<AddContentScreen> createState() => _AddContentScreenState();
}

class _AddContentScreenState extends State<AddContentScreen> {
  final TextEditingController _textController = TextEditingController();
  
  // Link Preview State
  bool _hasLink = false;
  bool _isLoadingMetadata = false; 
  String _detectedLink = "";
  String _previewTitle = ""; 
  String _previewDomain = "";
  String? _previewImage;

  // --- KATEGORİ SİSTEMİ (YENİ) ---
  // Mock Data: Gerçek uygulamada burası veritabanından gelecek
  final List<Map<String, dynamic>> _groups = [
    {'name': 'Gelen Kutusu', 'icon': CupertinoIcons.tray, 'color': Colors.blueAccent},
    {'name': 'İlham Panosu', 'icon': CupertinoIcons.sparkles, 'color': Colors.purpleAccent},
    {'name': 'Okuma Listesi', 'icon': CupertinoIcons.book, 'color': Colors.orangeAccent},
    {'name': 'Yazılım Projeleri', 'icon': CupertinoIcons.layers_alt, 'color': Colors.green},
    {'name': 'Spor & Sağlık', 'icon': CupertinoIcons.heart, 'color': Colors.redAccent},
  ];

  int _selectedGroupIndex = 0; // Varsayılan: Gelen Kutusu

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    // 1. Paylaşım Kontrolü
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _setTextAndProcess(widget.initialText!);
    } else {
      _tryAutoPaste();
    }

    _textController.addListener(() {
      _checkContent(_textController.text);
    });
  }

  Future<void> _tryAutoPaste() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _setTextAndProcess(data.text!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Panodan yapıştırıldı", style: GoogleFonts.dmSans()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1a1a1a),
            duration: const Duration(milliseconds: 1500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _setTextAndProcess(String text) {
    setState(() {
      _textController.text = text;
      _textController.selection = TextSelection.fromPosition(TextPosition(offset: _textController.text.length));
    });
    _checkContent(text);
  }

  void _checkContent(String text) {
    final urlRegExp = RegExp(r'(https?:\/\/[^\s]+)');
    final match = urlRegExp.firstMatch(text);

    if (match != null) {
      String url = match.group(0)!;
      if (_detectedLink == url) return;

      _detectedLink = url;
      final uri = Uri.tryParse(url);
      String domain = uri?.host.replaceFirst("www.", "") ?? "link";
      
      setState(() {
        _hasLink = true;
        _previewDomain = domain;
        _previewTitle = url; 
        _previewImage = null; 
        _isLoadingMetadata = true;
      });

      _fetchRealMetadata(url);
    } else {
      if (_hasLink) setState(() => _hasLink = false);
    }
  }

  Future<void> _fetchRealMetadata(String url) async {
    await Future.delayed(const Duration(seconds: 2)); 
    if (mounted && _detectedLink == url) {
      setState(() {
        _isLoadingMetadata = false;
        if (url.contains("youtube") || url.contains("youtu.be")) {
            _previewTitle = "Flutter ile Modern UI Tasarımı: Masterclass";
            _previewImage = "https://images.unsplash.com/photo-1626785774573-4b799314348d?q=80"; 
        } 
      });
    }
  }

  // --- KATEGORİ SEÇİM MODALI ---
  void _showGroupPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Text("Hedef Grup Seç", style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: _groups.length,
                separatorBuilder: (c, i) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  final isSelected = _selectedGroupIndex == index;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedGroupIndex = index);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF2F4F7) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected ? Border.all(color: Colors.black12) : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (group['color'] as Color).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(group['icon'], color: group['color'], size: 20),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            group['name'],
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.black : Colors.grey[700],
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Colors.black, size: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Seçili grubun verileri
    final currentGroup = _groups[_selectedGroupIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7), // Modern Cool Grey
      
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Yeni İçerik",
          style: GoogleFonts.dmSans(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(CupertinoIcons.xmark, size: 20, color: Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
           Padding(
             padding: const EdgeInsets.only(right: 16.0),
             child: Center(
               child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _textController.text.isNotEmpty ? 1.0 : 0.5,
                  child: ElevatedButton(
                    onPressed: _textController.text.isNotEmpty ? () {
                        // SAVE ACTION
                        print("Kaydedildi: ${_textController.text}");
                        print("Hedef Grup: ${currentGroup['name']}");
                        Navigator.pop(context);
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text("Ekle", style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                  ),
               ),
             ),
           )
        ],
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            
            // --- 1. YAZI KARTI (INPUT) ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: TextField(
                controller: _textController,
                maxLines: null,
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  height: 1.5,
                  color: const Color(0xFF1a1a1a),
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "Ne kaydetmek istersin?",
                  hintStyle: GoogleFonts.dmSans(
                    color: Colors.grey.shade400,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                cursorColor: Colors.blueAccent,
              ),
            ),

            const SizedBox(height: 16),

            // --- 2. HEDEF/GRUP SEÇİCİ KARTI (BEHANCE STYLE) ---
            // Bu kısım "Nereye gidecek?" sorusunu çözer.
            GestureDetector(
              onTap: _showGroupPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                   boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // İkon Alanı
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (currentGroup['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(currentGroup['icon'], color: currentGroup['color'], size: 22),
                    ),
                    const SizedBox(width: 16),
                    
                    // Metin Alanı
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Şuraya Kaydedilecek:",
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentGroup['name'],
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Değiştir Butonu Görünümü
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Değiştir",
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                          ),
                          const SizedBox(width: 4),
                          const Icon(CupertinoIcons.chevron_down, size: 12, color: Colors.black54),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- 3. LINK PREVIEW KARTI ---
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              child: _hasLink ? _buildLinkPreviewCard() : const SizedBox.shrink(),
            ),
            
            // Klavye açılınca altta boşluk kalsın
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkPreviewCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              height: 180,
              width: double.infinity,
              color: const Color(0xFFF2F4F7),
              child: _previewImage != null
                  ? CachedNetworkImage(
                      imageUrl: _previewImage!,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => _buildPlaceholder(),
                      errorWidget: (c, u, e) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _previewDomain.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                    if (_isLoadingMetadata) ...[
                      const Spacer(),
                      const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                    ]
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _previewTitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        CupertinoIcons.link,
        size: 40, 
        color: Colors.grey.shade300
      ),
    );
  }
}