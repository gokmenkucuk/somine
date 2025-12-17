import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:animate_do/animate_do.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Bilgilendirme Merkezi",
          style: GoogleFonts.poppins(
            color: const Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Mock Notification Item 1
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: _buildNotificationItem(
              icon: CupertinoIcons.info,
              iconColor: const Color(0xFF3B82F6), // Blue
              title: "Panonuzda bekleyen içerik var",
              subtitle: "Son eklediğiniz 3 içerik henüz kategorilenmedi. Düzenlemek için tıklayın.",
              time: "2 dk önce",
              isUnread: true,
            ),
          ),
          const SizedBox(height: 16),
          // Mock Notification Item 2
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: _buildNotificationItem(
              icon: CupertinoIcons.checkmark_alt,
              iconColor: const Color(0xFF10B981), // Green
              title: "İçe aktarım tamamlandı",
              subtitle: "Instagram'dan seçtiğiniz gönderiler başarıyla panonuza eklendi.",
              time: "1 saat önce",
              isUnread: false,
            ),
          ),
          const SizedBox(height: 16),
           // Mock Notification Item 3
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: _buildNotificationItem(
              icon: CupertinoIcons.sparkles,
              iconColor: const Color(0xFF8B5CF6), // Purple
              title: "Haftalık Özet",
              subtitle: "Geçen hafta en çok 'Tasarım' kategorisinde içerik kaydettiniz.",
              time: "Dün",
              isUnread: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFF3F4F6) : Colors.white, // Highlight unread
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          if (isUnread)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444), // Red dot
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
