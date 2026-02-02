import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/repositories/user_repository.dart';
import 'package:somine_app/widgets/success_notification_sheet.dart';
import 'dart:convert';
import 'package:somine_app/widgets/user_avatar.dart';
import 'package:intl/intl.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  String? _currentUsername;
  String? _currentDisplayName;
  String? _currentPhotoUrl; // Keeps legacy/auth URL support mainly for internal logic
  String? _currentPhotoBase64; // New: To check if we have a custom photo
  bool _isLoading = true;
  bool _isUploadingColor = false; // Is uploading photo

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _currentUsername = doc.data()?['username'] as String?;
          _currentDisplayName = user.displayName;
          _currentPhotoUrl = user.photoURL;
          _currentPhotoBase64 = doc.data()?['photoBase64'] as String?;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }



  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    // Smaller size for Firestore storage
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      maxWidth: 300, 
      maxHeight: 300, 
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() => _isUploadingColor = true);
      
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        
        // Save to Firestore (Base64)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'photoBase64': base64String,
          'photoUrl': FieldValue.delete(), // Clear legacy URL if any
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update Auth (Clear it so we don't use Google's)
        await user.updatePhotoURL(null);
        await user.reload();

        if (mounted) {
          setState(() {
            _currentPhotoUrl = null; 
            // Local state doesn't really matter as UserAvatar watches FirestoreProvider
          });
          SuccessNotificationSheet.show(
            context,
            title: 'Fotoğraf Güncellendi',
            message: 'Profil fotoğrafınız başarıyla değiştirildi.',
          );
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      } finally {
        if (mounted) setState(() => _isUploadingColor = false);
      }
    }
  }

  Future<void> _removeProfilePhoto() async {
    setState(() => _isUploadingColor = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Update Auth
      await user.updatePhotoURL(null);
      
      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoUrl': FieldValue.delete(),
        'photoBase64': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reload
      await user.reload();

      if (mounted) {
        setState(() {
          _currentPhotoUrl = null; 
        });
        SuccessNotificationSheet.show(
          context,
          title: 'Fotoğraf Kaldırıldı',
          message: 'Profil fotoğrafınız varsayılan haline döndürüldü.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingColor = false);
    }
  }

  void _showProfilePhotoOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickAndUploadImage();
            },
            child: const Text('Fotoğraf Seç'),
          ),
          // Check if we have a custom photo (Base64 from Firestore)
          // We ignore FirebaseAuth.currentUser.photoURL because we disabled auto-import
          if (_currentPhotoBase64 != null) 
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _removeProfilePhoto();
              },
              child: const Text('Fotoğrafı Kaldır'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final creationTime = user?.metadata.creationTime;
    
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
          'Hesap Bilgileri',
          style: GoogleFonts.poppins(
            color: context.colors.headline,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Avatar - Direct tap to pick photo
          Center(
            child: GestureDetector(
              onTap: () => _showProfilePhotoOptions(context),
              child: Stack(
                children: [
                  const UserAvatar(radius: 50, showBorder: true),
                  
                  if (_isUploadingColor)
                    const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                  
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colors.headline,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(PhosphorIconsRegular.camera, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Display Name (Editable)
          _buildEditableInfoCard(
            context,
            icon: PhosphorIconsRegular.user,
            label: 'Ad Soyad',
            value: _currentDisplayName ?? 'Ayarlanmamış',
            onEdit: () => _showDisplayNameEditDialog(context),
          ),

          const SizedBox(height: 12),

          // Username Card (Editable)
          _buildEditableInfoCard(
            context,
            icon: PhosphorIconsRegular.at,
            label: 'Kullanıcı Adı',
            value: _isLoading ? '...' : (_currentUsername != null ? '@$_currentUsername' : 'Ayarlanmamış'),
            onEdit: () => _showUsernameEditDialog(context),
          ),
          
          const SizedBox(height: 12),
          
          // Info Cards
          _buildInfoCard(
            context,
            icon: CupertinoIcons.mail,
            label: 'E-posta',
            value: user?.email ?? 'Bilinmiyor',
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoCard(
            context,
            icon: CupertinoIcons.calendar,
            label: 'Hesap Oluşturma',
            value: creationTime != null 
                ? DateFormat('d MMMM yyyy', 'tr').format(creationTime)
                : 'Bilinmiyor',
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoCard(
            context,
            icon: CupertinoIcons.checkmark_shield,
            label: 'E-posta Doğrulama',
            value: user?.emailVerified == true ? 'Doğrulandı' : 'Doğrulanmadı',
            valueColor: user?.emailVerified == true ? Colors.green : Colors.orange,
          ),
          
          const SizedBox(height: 32),
          
          _buildActionButton(
            context,
            icon: PhosphorIconsRegular.trash,
            label: 'Hesabı Sil',
            isDestructive: true,
            onTap: () => _showDeleteAccountDialog(context),
          ),
          
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // ... (Keep existing helpers _buildEditableInfoCard, _buildInfoCard, _buildActionButton, etc. exactly the same)
  Widget _buildEditableInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
      ),
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
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.colors.body,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.colors.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(
              PhosphorIconsRegular.pencilSimple,
              color: context.colors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
      ),
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
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.colors.body,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? context.colors.headline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : context.colors.headline;
    
    return Material(
      color: context.colors.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              Icon(CupertinoIcons.chevron_right, color: color.withOpacity(0.5), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisplayNameEditDialog(BuildContext context) {
    final controller = TextEditingController(text: _currentDisplayName ?? '');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.colors.surfaceWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Adı Güncelle',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.headline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bu isim profilinizde görünecektir.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: context.colors.body,
                ),
              ),
              
              const SizedBox(height: 24),
              
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.colors.backgroundTop,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Ad Soyad',
                ),
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                     if (controller.text.trim().isEmpty) return;

                     try {
                       final user = FirebaseAuth.instance.currentUser;
                       if (user != null) {
                         await user.updateDisplayName(controller.text.trim());
                         
                         // Update Firestore optionally if you keep display name there
                         // await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'displayName': controller.text.trim()});

                         if (mounted) {
                           setState(() {
                             _currentDisplayName = controller.text.trim();
                           });
                           Navigator.pop(ctx);
                           SuccessNotificationSheet.show(
                             this.context,
                             title: 'Ad Güncellendi',
                             message: 'Görünen adınız başarıyla değiştirildi.',
                           );
                         }
                       }
                     } catch (e) {
                       Navigator.pop(ctx);
                       ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                     }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Kaydet',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showUsernameEditDialog(BuildContext context) {
    final controller = TextEditingController(text: _currentUsername ?? '');
    bool isChecking = false;
    bool? isAvailable;
    String? errorMessage;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.surfaceWhite,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Kullanıcı Adını Değiştir',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.colors.headline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kullanıcı adın paylaşımlarda seni bulmak için kullanılır.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: context.colors.body,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    prefixText: '@',
                    prefixStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.colors.primary,
                    ),
                    filled: true,
                    fillColor: context.colors.backgroundTop,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isAvailable == true 
                            ? Colors.green 
                            : isAvailable == false 
                                ? Colors.red 
                                : Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isAvailable == true 
                            ? Colors.green 
                            : isAvailable == false 
                                ? Colors.red 
                                : Colors.grey[300]!,
                        width: isAvailable != null ? 2 : 1,
                      ),
                    ),
                    suffixIcon: isChecking
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : isAvailable == true
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : isAvailable == false
                                ? const Icon(Icons.error, color: Colors.red)
                                : null,
                  ),
                  onChanged: (value) async {
                    setState(() {
                      isAvailable = null;
                      errorMessage = null;
                    });
                    
                    if (value.trim().isEmpty) return;
                    
                    setState(() => isChecking = true);
                    
                    final normalized = value.toLowerCase().trim();
                    final regex = RegExp(r'^[a-z0-9_]{3,20}$');
                    
                    if (!regex.hasMatch(normalized)) {
                      setState(() {
                        isChecking = false;
                        isAvailable = false;
                        errorMessage = '3-20 karakter, sadece harf, rakam ve alt çizgi';
                      });
                      return;
                    }
                    
                    // Skip check if same as current
                    if (normalized == _currentUsername) {
                      setState(() {
                        isChecking = false;
                        isAvailable = true;
                      });
                      return;
                    }
                    
                    final available = await UserRepository().isUsernameAvailable(normalized);
                    setState(() {
                      isChecking = false;
                      isAvailable = available;
                      errorMessage = available ? null : 'Bu kullanıcı adı alınmış';
                    });
                  },
                ),
                
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorMessage!,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isAvailable == true
                        ? () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;
                            
                            try {
                              await UserRepository().updateUsername(
                                user.uid,
                                controller.text.toLowerCase().trim(),
                              );
                              
                              Navigator.pop(ctx);
                              
                              _loadUserData(); // Reload
                              
                              if (mounted) {
                                SuccessNotificationSheet.show(
                                  this.context,
                                  title: 'Kullanıcı Adı Güncellendi',
                                  message: 'Yeni kullanıcı adın: @${controller.text.toLowerCase().trim()}',
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(content: Text('Hata: $e')),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Kaydet',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPasswordChangeDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Şifre Değiştir'),
        content: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('E-posta adresinize şifre sıfırlama bağlantısı gönderilecek.'),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('İptal'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.pop(context);
              final user = FirebaseAuth.instance.currentUser;
              if (user?.email != null) {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Şifre sıfırlama e-postası gönderildi')),
                  );
                }
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('Bu işlem geri alınamaz. Tüm verileriniz silinecektir.'),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('İptal'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Güvenlik nedeniyle yeniden giriş yapmanız gerekiyor')),
              );
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
