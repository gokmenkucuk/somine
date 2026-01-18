import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/design/design_tokens.dart';

import 'package:somine_app/core/design/app_colors.dart';
import 'package:somine_app/screens/onboarding_prep_screen.dart';

/// Onboarding screen to get user's name
class OnboardingNameScreen extends StatefulWidget {
  final String userId;
  
  const OnboardingNameScreen({super.key, required this.userId});

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _continue() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen adınızı girin')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OnboardingPrepScreen(
          userId: widget.userId,
          displayName: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Text
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
                    fontSize: 28, // Reduced from 32 based on feedback
                    fontWeight: FontWeight.bold,
                    height: 1.2, 
                    color: Colors.white, // Required for ShaderMask
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
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: DesignTokens.textPrimary,
                ),
                cursorColor: Colors.grey[600],
                decoration: InputDecoration(
                  hintText: 'Adın',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: DesignTokens.textSecondary.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100], // Visible gray
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
                    borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onSubmitted: (_) {
                  // User requested: Don't navigate on keyboard interaction.
                  // Just dismiss keyboard.
                  FocusScope.of(context).unfocus();
                },
              ),
              
              const SizedBox(height: 24),
              
              // Continue Button
              // Continue Button
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.secondary, // Su Yeşili / Mint
                      AppColors.primary, // Derin Adaçayı
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
            ],
          ),
        ),
      ),
    );
  }
}
