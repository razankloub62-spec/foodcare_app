import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/theme_manager.dart';
import '../../utils/helpers.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: ThemeManager.themeColor,
      builder: (context, primaryColor, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF110E17),
          appBar: AppBar(
            title: const Text('الإعدادات ⚙️🌸', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KawaiiFadeSlide(
                  index: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1626),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: KawaiiFloatingWidget(
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: primaryColor.withValues(alpha: 0.2),
                          child: const Text('🧸', style: TextStyle(fontSize: 24)),
                        ),
                      ),
                      title: Text(
                        FirebaseAuth.instance.currentUser?.email ?? 'مستخدم FoodCare',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('حساب متصل بالسحابة ✨', style: TextStyle(color: primaryColor, fontSize: 12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                KawaiiFadeSlide(
                  index: 1,
                  child: Text('لون ثيم الثلاجة المفضل 🎨💖', style: TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                KawaiiFadeSlide(
                  index: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1626),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ThemeManager.availableColors.map((color) {
                        final isSelected = primaryColor == color;
                        return GestureDetector(
                          onTap: () => ThemeManager.updateTheme(color),
                          child: AnimatedScale(
                            scale: isSelected ? 1.2 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2.5),
                              ),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Spacer(),
                
                // زر معاينة شاشة تسجيل الدخول مع تمرير isPreview: true
                KawaiiFadeSlide(
                  index: 3,
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor.withValues(alpha: 0.15),
                        foregroundColor: primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen(isPreview: true)),
                        );
                      },
                      icon: const Icon(Icons.remove_red_eye_rounded, size: 20),
                      label: const Text('معاينة شاشة تسجيل الدخول 🚪✨', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // زر تسجيل الخروج الفعلي
                KawaiiFadeSlide(
                  index: 4,
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text('تسجيل الخروج الفعلي 👋', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}