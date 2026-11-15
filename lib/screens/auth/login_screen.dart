import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/theme_manager.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isPreview; // معامل خاص بوضع المعاينة من الإعدادات
  const LoginScreen({super.key, this.isPreview = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool isFridgeOpen = false;
  bool isSignInSelected = true;
  bool isForgotPassword = false;
  bool isLoading = false;
  bool obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _doorAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _doorAnimation = Tween<double>(begin: 0.0, end: -0.55).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutBack),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleFridge() {
    setState(() {
      isFridgeOpen = !isFridgeOpen;
      if (isFridgeOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        isForgotPassword = false;
      }
    });
  }

  void _showMessage(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Future<void> _handleAuth() async {
    // إذا كنا في وضع المعاينة، عند الضغط يتم نقلك مباشرة للشاشة الرئيسية فوراً دون تحقق
    if (widget.isPreview) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showMessage('يرجى إدخال بريد إلكتروني صحيح');
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isForgotPassword) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        _showMessage('تم إرسال رابط استعادة كلمة المرور إلى بريدكِ ✨', isError: false);
        setState(() => isForgotPassword = false);
      } else if (isSignInSelected) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        if (password.length < 6) {
          _showMessage('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
          setState(() => isLoading = false);
          return;
        }
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        if (_nameController.text.trim().isNotEmpty) {
          await cred.user?.updateDisplayName(_nameController.text.trim());
        }
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ، يرجى التحقق من البيانات.';
      if (e.code == 'user-not-found') {
        message = 'لا يوجد حساب بهذا البريد الإلكتروني.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'البريد أو كلمة المرور غير صحيحة.';
      } else if (e.code == 'email-already-in-use') {
        message = 'هذا البريد مستخدم مسبقاً.';
      } else if (e.code == 'network-request-failed') {
        message = 'يرجى التحقق من اتصالكِ بالإنترنت والمحاولة مجدداً 📡';
      } else if (e.code == 'too-many-requests') {
        message = 'تم تجاوز عدد المحاولات المسموح به، يرجى المحاولة لاحقاً.';
      }
      _showMessage(message);
    } catch (e) {
      _showMessage('خطأ غير متوقع: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: ThemeManager.themeColor,
      builder: (context, selectedColor, _) {
        return Scaffold(
          body: Stack(
            children: [
              Positioned(top: -50, left: -50, child: _buildGlowOrb(const Color(0xFFFF8FAB), 150, 0.15)),
              Positioned(top: 100, right: -60, child: _buildGlowOrb(const Color(0xFFC77DFF), 180, 0.12)),
              Positioned(bottom: -40, left: -30, child: _buildGlowOrb(const Color(0xFF80ED99), 160, 0.10)),
              Positioned(bottom: 50, right: -40, child: _buildGlowOrb(const Color(0xFFFFB5A7), 170, 0.12)),

              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    if (widget.isPreview)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selectedColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selectedColor),
                        ),
                        child: Text(
                          'وضع المعاينة الفورية ✨',
                          style: TextStyle(color: selectedColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF231D30).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...ThemeManager.availableColors.map((color) => _buildColorOption(color, selectedColor)),
                            const SizedBox(width: 12),
                            Icon(Icons.auto_awesome, color: selectedColor, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        height: 250,
                        width: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _glowAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _glowAnimation.value,
                                  child: CustomPaint(
                                    size: const Size(280, 240),
                                    painter: WideFridgeGlowPainter(color: selectedColor),
                                  ),
                                );
                              },
                            ),
                            GestureDetector(
                              onTap: _toggleFridge,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildCuteFridge(selectedColor),
                                  const SizedBox(height: 12),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF231D30).withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isFridgeOpen ? selectedColor.withValues(alpha: 0.6) : Colors.white12,
                                      ),
                                    ),
                                    child: Text(
                                      isFridgeOpen ? 'اضغطي للإغلاق 🔒' : 'اضغطي لفتح الثلاجة ✨',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isFridgeOpen ? selectedColor : Colors.grey.shade400,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOutBack,
                left: 0,
                right: 0,
                bottom: isFridgeOpen ? 0 : -470,
                child: Container(
                  height: 430,
                  padding: const EdgeInsets.fromLTRB(26, 20, 26, 26),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1A2B).withValues(alpha: 0.97),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                    border: Border.all(color: selectedColor.withValues(alpha: 0.6), width: 2),
                    boxShadow: [
                      BoxShadow(color: selectedColor.withValues(alpha: 0.35), blurRadius: 35, spreadRadius: 8),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: _toggleFridge,
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (widget.isPreview) ...[
                          Row(
                            children: [
                              const Text('وضع المعاينة الفورية ✨', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(width: 8),
                              Icon(Icons.visibility_rounded, color: selectedColor, size: 20),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('يمكنكِ الانتقال مباشرة إلى الشاشة الرئيسية للاستمتاع برؤية الثلاجة من الداخل 🧊💖', style: TextStyle(fontSize: 13, color: Colors.grey.shade300, height: 1.5)),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedColor,
                                foregroundColor: const Color(0xFF16121E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              child: const Text('دخول مباشر للثلاجة (الرئيسية) 🚀', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ] else if (isForgotPassword) ...[
                          Row(
                            children: [
                              const Text('استعادة كلمة المرور ✨', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(width: 8),
                              Icon(Icons.lock_reset, color: selectedColor, size: 20),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('أدخلي بريدكِ الإلكتروني لإرسال رابط التعيين', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined, color: selectedColor, size: 18),
                              hintText: 'البريد الإلكتروني',
                              filled: true,
                              fillColor: const Color(0xFF272136),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedColor,
                                foregroundColor: const Color(0xFF16121E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Color(0xFF16121E))
                                  : const Text('إرسال الرابط 🌸', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: GestureDetector(
                              onTap: () => setState(() => isForgotPassword = false),
                              child: Text('العودة لتسجيل الدخول', style: TextStyle(fontSize: 13, color: selectedColor, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Text(
                                isSignInSelected ? 'أهلاً بعودتكِ ✨' : 'إنشاء حساب جديد 🌸',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.favorite, color: selectedColor, size: 20),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            height: 40,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(color: const Color(0xFF16121E), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => isSignInSelected = true),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSignInSelected ? const Color(0xFF2E263E) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(17),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSignInSelected ? selectedColor : Colors.grey.shade400)),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => isSignInSelected = false),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: !isSignInSelected ? const Color(0xFF2E263E) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(17),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text('حساب جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: !isSignInSelected ? selectedColor : Colors.grey.shade400)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!isSignInSelected) ...[
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.badge_outlined, color: selectedColor, size: 18),
                                hintText: 'الاسم الكامل',
                                filled: true,
                                fillColor: const Color(0xFF272136),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined, color: selectedColor, size: 18),
                              hintText: 'البريد الإلكتروني',
                              filled: true,
                              fillColor: const Color(0xFF272136),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _passwordController,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock_outline, color: selectedColor, size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 18),
                                onPressed: () => setState(() => obscurePassword = !obscurePassword),
                              ),
                              hintText: 'كلمة المرور',
                              filled: true,
                              fillColor: const Color(0xFF272136),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                          if (isSignInSelected) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: () => setState(() => isForgotPassword = true),
                                child: Text('نسيتِ كلمة المرور؟', style: TextStyle(fontSize: 11, color: selectedColor, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedColor,
                                foregroundColor: const Color(0xFF16121E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              child: isLoading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Color(0xFF16121E), strokeWidth: 2))
                                  : Text(isSignInSelected ? 'دخول ✨' : 'إنشاء الحساب 🌸', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlowOrb(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0.0)]),
      ),
    );
  }

  Widget _buildCuteFridge(Color selectedColor) {
    return SizedBox(
      width: 150,
      height: 175,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 100,
            height: 165,
            decoration: BoxDecoration(
              color: isFridgeOpen ? selectedColor.withValues(alpha: 0.25) : const Color(0xFF2A233A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isFridgeOpen ? selectedColor : Colors.white24, width: 2.5),
              boxShadow: isFridgeOpen ? [BoxShadow(color: selectedColor.withValues(alpha: 0.6), blurRadius: 30, spreadRadius: 5)] : [],
            ),
            child: isFridgeOpen ? _buildFridgeInterior(selectedColor) : _buildClosedFridgeFront(selectedColor),
          ),
          Positioned(
            right: 18,
            child: AnimatedBuilder(
              animation: _doorAnimation,
              builder: (context, child) {
                return Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()..setEntry(3, 2, 0.002)..rotateY(_doorAnimation.value),
                  child: Container(
                    width: 32,
                    height: 158,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E263E),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                      border: Border.all(color: selectedColor.withValues(alpha: 0.7), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(width: 16, height: 4, decoration: BoxDecoration(color: selectedColor, borderRadius: BorderRadius.circular(4))),
                        Container(width: 16, height: 4, decoration: BoxDecoration(color: selectedColor, borderRadius: BorderRadius.circular(4))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFridgeInterior(Color selectedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 28,
            height: 5,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: selectedColor, blurRadius: 10, spreadRadius: 2)]),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Icon(Icons.icecream_outlined, color: selectedColor, size: 18), const Icon(Icons.local_cafe_outlined, color: Colors.white70, size: 16)]),
          Divider(color: selectedColor.withValues(alpha: 0.5), thickness: 1.5, height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [const Icon(Icons.cake_outlined, color: Colors.white70, size: 18), Icon(Icons.favorite, color: selectedColor, size: 15)]),
          Divider(color: selectedColor.withValues(alpha: 0.5), thickness: 1.5, height: 4),
          Container(height: 22, width: double.infinity, decoration: BoxDecoration(color: selectedColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: selectedColor.withValues(alpha: 0.4)))),
        ],
      ),
    );
  }

  Widget _buildClosedFridgeFront(Color selectedColor) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              Positioned(left: 10, bottom: 8, child: Container(width: 4, height: 18, decoration: BoxDecoration(color: selectedColor.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)))),
              Positioned(right: 12, top: 12, child: Icon(Icons.favorite, color: selectedColor.withValues(alpha: 0.6), size: 13)),
            ],
          ),
        ),
        Container(height: 2, color: Colors.white12),
        Expanded(
          flex: 6,
          child: Stack(
            children: [
              Positioned(left: 10, top: 12, child: Container(width: 4, height: 32, decoration: BoxDecoration(color: selectedColor.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorOption(Color color, Color selectedColor) {
    bool isSelected = selectedColor == color;
    return GestureDetector(
      onTap: () => ThemeManager.updateTheme(color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2)),
        child: Container(width: 18, height: 18, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ),
    );
  }
}

class WideFridgeGlowPainter extends CustomPainter {
  final Color color;
  WideFridgeGlowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.75,
        colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawOval(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant WideFridgeGlowPainter oldDelegate) => true;
}