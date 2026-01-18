import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String _appVersion = '';
  final Set<int> _expandedItems = {};

  final List<Map<String, String>> _faqItems = [
    {
      'question': 'So Mine nasıl çalışır?',
      'answer': 'So Mine, Instagram, YouTube, Twitter ve diğer platformlardan kaydettiğiniz linkleri tek bir yerde toplamanızı sağlar. Paylaş düğmesine basarak veya manuel olarak içerik ekleyebilirsiniz.',
    },
    {
      'question': 'Koleksiyonlar nasıl oluşturulur?',
      'answer': 'Koleksiyonlar sekmesinde sağ üstteki + butonuna basarak yeni koleksiyon oluşturabilirsiniz. Koleksiyonlarınıza isim ve emoji atayabilirsiniz.',
    },
    {
      'question': 'Premium özellikleri nelerdir?',
      'answer': 'Premium ile sınırsız koleksiyon, özel app ikonları, widget desteği ve daha fazla özelliğe erişebilirsiniz.',
    },
    {
      'question': 'Verilerim güvende mi?',
      'answer': 'Evet! Tüm verileriniz Firebase güvenlik altyapısıyla şifrelenerek saklanır. Gizli Kasa özelliği ile hassas içeriklerinizi Face ID/Touch ID ile koruyabilirsiniz.',
    },
    {
      'question': 'İçeriklerimi nasıl silebilirim?',
      'answer': 'İçerik kartına uzun basarak silme seçeneğine ulaşabilirsiniz. Silinen içerikler 30 gün boyunca "Son Silinenler" bölümünde saklanır.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${info.version} (${info.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.backgroundBottom,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundTop,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: context.colors.headline),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yardım ve Destek',
          style: GoogleFonts.poppins(
            color: context.colors.headline,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.colors.primary,
                  context.colors.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  PhosphorIconsFill.lifebuoy,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nasıl yardımcı olabiliriz?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aşağıdaki SSS bölümünü inceleyin veya bize ulaşın',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // FAQ Section
          Text(
            'Sık Sorulan Sorular',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.colors.headline,
            ),
          ),
          const SizedBox(height: 12),

          ...List.generate(_faqItems.length, (index) {
            final item = _faqItems[index];
            final isExpanded = _expandedItems.contains(index);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: context.colors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: isExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      if (expanded) {
                        _expandedItems.add(index);
                      } else {
                        _expandedItems.remove(index);
                      }
                    });
                  },
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Text(
                    item['question']!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.colors.headline,
                    ),
                  ),
                  children: [
                    Text(
                      item['answer']!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: context.colors.body,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Contact Section
          Text(
            'Bize Ulaşın',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.colors.headline,
            ),
          ),
          const SizedBox(height: 12),

          _buildContactItem(
            context,
            icon: PhosphorIconsRegular.envelope,
            title: 'E-posta Desteği',
            subtitle: 'support@somine.app',
            onTap: () async {
              final uri = Uri.parse('mailto:support@somine.app?subject=So Mine Destek');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),

          const SizedBox(height: 8),

          _buildContactItem(
            context,
            icon: PhosphorIconsRegular.globe,
            title: 'Web Sitesi',
            subtitle: 'www.somine.app',
            onTap: () async {
              final uri = Uri.parse('https://www.somine.app');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),

          const SizedBox(height: 24),

          // App Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Uygulama Versiyonu',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: context.colors.body,
                      ),
                    ),
                    Text(
                      _appVersion,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.colors.headline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildLinkButton(
                        context,
                        'Gizlilik Politikası',
                        () async {
                          final uri = Uri.parse('https://www.somine.app/privacy');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLinkButton(
                        context,
                        'Kullanım Koşulları',
                        () async {
                          final uri = Uri.parse('https://www.somine.app/terms');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: context.colors.surfaceWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: context.colors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.colors.headline,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: context.colors.body.withOpacity(0.5),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkButton(BuildContext context, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: context.colors.primary,
          decoration: TextDecoration.underline,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
