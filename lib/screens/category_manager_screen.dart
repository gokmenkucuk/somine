import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';

class CategoryManagerScreen extends ConsumerStatefulWidget {
  final CategoryModel? categoryToEdit;

  const CategoryManagerScreen({super.key, this.categoryToEdit});

  @override
  ConsumerState<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends ConsumerState<CategoryManagerScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TabController _tabController;
  
  // State
  int _selectedColorIndex = 0;
  int _selectedPatternIndex = 0; // -1 if color selected, >=0 if pattern
  bool _isPatternSelected = true;

  final List<Color> _colors = [
    const Color(0xFFEF4444), // Red
    const Color(0xFFF97316), // Orange
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Emerald
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFEC4899), // Pink
    const Color(0xFF6B7280), // Gray
  ];

  final List<LinearGradient> _patterns = [
    const LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF2DD4BF)]), // Default
    const LinearGradient(colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)]),
    const LinearGradient(colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)]),
    const LinearGradient(colors: [Color(0xFF84fab0), Color(0xFF8fd3f4)]),
    const LinearGradient(colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)]),
    const LinearGradient(colors: [Color(0xFFf093fb), Color(0xFFf5576c)]),
    const LinearGradient(colors: [Color(0xFF43e97b), Color(0xFF38f9d7)]),
    const LinearGradient(colors: [Color(0xFFfa709a), Color(0xFFfee140)]),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.categoryToEdit?.name ?? '');
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  void _saveCategory() {
    if (_nameController.text.trim().isEmpty) return;
    
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // TODO: Determine how to store "Pattern" vs "Color" in model. 
    // Assuming model has color/icon fields. For now mapping logic simplistically.
    
    final category = CategoryModel(
      id: widget.categoryToEdit?.id ?? '',
      userId: user.uid,
      name: _nameController.text.trim(),
      // Store color value or gradient index as String
      color: _isPatternSelected 
          ? 'pattern:$_selectedPatternIndex' 
          : '#${_colors[_selectedColorIndex].value.toRadixString(16).padLeft(8, '0')}', 
      icon: 'folder', // Default icon
      order: widget.categoryToEdit?.order ?? 99,
      createdAt: widget.categoryToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    if (widget.categoryToEdit != null) {
      ref.read(categoryRepositoryProvider).updateCategory(category);
    } else {
      ref.read(categoryRepositoryProvider).createCategory(category);
    }
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.categoryToEdit != null ? 'Kategoriyi Düzenle' : 'Yeni Kategori',
          style: GoogleFonts.poppins(color: DesignTokens.textPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: DesignTokens.textPrimary),
        actions: [
          TextButton(
            onPressed: _saveCategory,
            child: Text(
              'Kaydet',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: DesignTokens.primary),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Live Preview
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
                gradient: _isPatternSelected ? _patterns[_selectedPatternIndex] : null,
                color: !_isPatternSelected ? _colors[_selectedColorIndex] : null,
                boxShadow: DesignTokens.shadowMD,
              ),
              alignment: Alignment.center,
              child: Text(
                _nameController.text.isEmpty ? 'Başlık' : _nameController.text,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          // 2. Name Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Kategori Adı',
                hintStyle: GoogleFonts.poppins(color: DesignTokens.textTertiary),
                border: const UnderlineInputBorder(borderSide: BorderSide(color: DesignTokens.border)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: DesignTokens.primary)),
              ),
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 3. The Cover Picker
          TabBar(
            controller: _tabController,
            labelColor: DesignTokens.textPrimary,
            unselectedLabelColor: DesignTokens.textTertiary,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            indicatorColor: DesignTokens.primary,
            onTap: (index) {
              setState(() {
                _isPatternSelected = index == 0;
              });
            },
            tabs: const [
              Tab(text: 'Designer Series'),
              Tab(text: 'Renkler'),
            ],
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Designer Series Grid
                GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _patterns.length,
                  itemBuilder: (context, index) {
                    final isSelected = _isPatternSelected && _selectedPatternIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _isPatternSelected = true;
                        _selectedPatternIndex = index;
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _patterns[index],
                          borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
                          border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                        ),
                        child: isSelected 
                           ? const Icon(Icons.check, color: Colors.white) 
                           : null,
                      ),
                    );
                  },
                ),
                
                // Colors Grid
                GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _colors.length,
                  itemBuilder: (context, index) {
                    final isSelected = !_isPatternSelected && _selectedColorIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _isPatternSelected = false;
                        _selectedColorIndex = index;
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _colors[index],
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                        ),
                         child: isSelected 
                           ? const Icon(Icons.check, color: Colors.white, size: 20) 
                           : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
