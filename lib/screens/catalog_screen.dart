import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          "Katalog Yakında...",
          style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
