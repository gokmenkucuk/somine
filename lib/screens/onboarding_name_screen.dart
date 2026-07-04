import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/design/app_colors.dart';
import 'package:somine_app/core/repositories/user_repository.dart';
import 'package:somine_app/screens/onboarding_prep_screen.dart';
import 'dart:async';

/// Onboarding screen to get user's name and username
class OnboardingNameScreen extends StatefulWidget {
  final String userId;
  
  const OnboardingNameScreen({super.key, required this.userId});

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _userRepository = UserRepository();
  
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameError;
  Timer? _debounceTimer;
  String? _suggestedUsername;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _onNameChanged(String name) async {
    if (name.trim().isEmpty) {
      setState(() {
        _suggestedUsername = null;
      });
      return;
    }

    // Kullanıcı adı önerisi oluştur ama inputa yazma
    final suggested = await _userRepository.generateUniqueUsername(name);
    
    if (mounted) {
      setState(() {
        _suggestedUsername = suggested;
      });
    }
  }

  void _onUsernameChanged(String username) {
    // Debounce
    _debounceTimer?.cancel();
    
    setState(() {
      _isUsernameAvailable = null;
      _usernameError = null;
    });

    if (username.trim().isEmpty) return;

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await _checkUsernameAvailability(username);
    });
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (!mounted) return;
    
    setState(() => _isCheckingUsername = true);

    final normalized = username.toLowerCase().trim();
    
    // Format kontrolü
    final regex = RegExp(r'^[a-z0-9_]{3,20}$');
    if (!regex.hasMatch(normalized)) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = false;
        _usernameError = '3-20 karakter, sadece harf, rakam ve alt çizgi';
      });
      return;
    }

    final isAvailable = await _userRepository.isUsernameAvailable(normalized);
    
    if (mounted) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = isAvailable;
        _usernameError = isAvailable ? null : 'Bu kullanıcı adı alınmış';
      });
    }
  }

  void _continue() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen adınızı girin')),
      );
      return;
    }

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kullanıcı adı girin')),
      );
      return;
    }

    if (_isUsernameAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir kullanıcı adı seçin')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Kullanıcı adını kaydet
    try {
      await _userRepository.updateUsername(widget.userId, username);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
        setState(() => _isLoading = false);
      }
      return;
    }
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OnboardingPrepScreen(
            userId: widget.userId,
            displayName: name,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                
                // Welcome Text with Gradient
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'Hazırsan\nBaşlayalım',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2, 
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Subtitle
                Text(
                  'Sana nasıl hitap etmemizi istersin?',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: DesignTokens.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Name Input
                // Name Input
                Text(
                  'Adınız', // UPDATED
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: DesignTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: DesignTokens.textPrimary,
                  ),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: 'Adı ve Soyadı', // UPDATED
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: DesignTokens.textSecondary.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  onChanged: _onNameChanged,
                ),
                
                const SizedBox(height: 24),
                
                // Username Input
                Text(
                  'Kullanıcı Adınız', // UPDATED
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: DesignTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (bounds) {
                    if (_isUsernameAvailable == true) {
                      return const LinearGradient(
                        colors: [AppColors.secondary, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    }
                    return const LinearGradient(colors: [Colors.transparent, Colors.transparent]).createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn,
                  child: Container(
                     // Bu container sadece border rengini gradient yapmak için (karmaşık olacağı için şimdilik düz renk kullanacağım ama clean olsun)
                  ),
                ),
                TextField(
                  controller: _usernameController,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: DesignTokens.textPrimary,
                  ),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    prefixText: '@',
                    prefixStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                    hintText: 'kullanici_adi',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: DesignTokens.textSecondary.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isUsernameAvailable == true 
                            ? AppColors.secondary // Müsaitse yeşil
                            : _isUsernameAvailable == false 
                                ? Colors.red // Müsait değilse kırmızı
                                : Colors.grey[300]!, // Normalde gri
                        width: _isUsernameAvailable != null ? 1.5 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isUsernameAvailable == true 
                            ? AppColors.primary // Focus olunca primary (koyu yeşil)
                            : _isUsernameAvailable == false 
                                ? Colors.red 
                                : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: _isCheckingUsername
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _isUsernameAvailable == true
                            ? const Icon(Icons.check_circle, color: AppColors.secondary)
                            : _isUsernameAvailable == false
                                ? const Icon(Icons.error, color: Colors.red)
                                : null,
                  ),
                  onChanged: _onUsernameChanged,
                ),
                
                // Username Status OR Suggestion (Combined logic)
                if (_suggestedUsername != null && _usernameController.text != _suggestedUsername && _usernameController.text.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft, // Left aligned looks better under input
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _usernameController.text = _suggestedUsername!;
                            _usernameController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _usernameController.text.length),
                            );
                          });
                          _onUsernameChanged(_suggestedUsername!);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Öneri: ',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: DesignTokens.textSecondary,
                                ),
                              ),
                              Text(
                                '@$_suggestedUsername',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else if (_usernameError != null || _isUsernameAvailable == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      _usernameError ?? 'Kullanıcı adı müsait ✓',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _isUsernameAvailable == true ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // Continue Button
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.secondary,
                        AppColors.primary,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Devam Et',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
