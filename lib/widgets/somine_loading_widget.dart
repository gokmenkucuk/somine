import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/widgets/loading_indicator.dart';

class SoMineLoadingWidget extends StatelessWidget {
  final String? message;
  
  const SoMineLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    // Logo size calculation: LoadingIndicator multiplies size by 8
    // Default size is now 22.0 (5% bump)
    const double logoHeight = 22.0 * 8.0; 
    const double halfLogoHeight = logoHeight / 2.0;
    
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent logo jump when keyboard dismisses
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          // 1. Logo - Always Dead Center (Uses default size 18.0)
          const LoadingIndicator(),
          
          // 2. Message - Positioned relative to center
          if (message != null)
            LayoutBuilder(
              builder: (context, constraints) {
                return Positioned(
                  // Center Y + Half Logo + Spacing
                  top: (constraints.maxHeight / 2) + halfLogoHeight + 24,
                  left: 40,
                  right: 40,
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
