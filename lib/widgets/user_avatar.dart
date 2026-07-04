import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';

class UserAvatar extends ConsumerWidget {
  final double radius;
  final bool showBorder;

  const UserAvatar({
    super.key,
    this.radius = 50,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Get Auth User (for display name / email if needed immediately)
    final authUser = ref.watch(authStateProvider).valueOrNull;
    
    // 2. Get Firestore User (for Base64 image)
    final userModelAsync = ref.watch(currentUserModelProvider);
    final userModel = userModelAsync.valueOrNull;

    // Determine Image Source
    ImageProvider? imageProvider;
    
    // Priority 1: Base64 from Firestore
    if (userModel?.photoBase64 != null && userModel!.photoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(userModel.photoBase64!);
        imageProvider = MemoryImage(bytes);
      } catch (e) {
        debugPrint('Error decoding base64 avatar: $e');
      }
    }
    
    // Priority 2: PhotoURL from Auth (Google) - ONLY IF NO Base64
    // Note: We deliberately prioritize Base64 to allow overriding Google photo
    // DISABLED Fallback: We don't want to show Google photo if user hasn't explicitly set one in Firestore
    /* 
    if (imageProvider == null && authUser?.photoURL != null && authUser!.photoURL!.isNotEmpty) {
      imageProvider = NetworkImage(authUser.photoURL!);
    }
    */

    // Initials Logic
    final String initials = _getInitials(userModel?.displayName ?? authUser?.displayName ?? userModel?.email ?? authUser?.email ?? 'U');

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF5F5F7), // Neutral Soft Grey
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: showBorder ? Border.all(color: Colors.white, width: 4) : null,
      ),
      child: Center(
        child: imageProvider != null
            ? CircleAvatar(
                radius: radius,
                backgroundImage: imageProvider,
                backgroundColor: Colors.transparent,
              )
            : ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [context.colors.primary, context.colors.secondary], // "Oil Green" Gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  initials,
                  style: GoogleFonts.outfit(
                    fontSize: radius * 0.8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Required for ShaderMask
                  ),
                ),
              ),
      ),
    );
  }

  String _getInitials(String input) {
    if (input.isEmpty) return 'U';
    // If email (contains @), take first char
    if (input.contains('@')) {
      return input[0].toUpperCase();
    }
    // If name, take first char of first name
    return input[0].toUpperCase();
  }
}
