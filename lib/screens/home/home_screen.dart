import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../../screens/add_product/add_product_screen.dart';
import '../../models/product_model.dart';
import '../../screens/alerts/alerts_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/shopping/shopping_list_screen.dart';
import '../../screens/barcode_scanner_screen.dart';
import '../../theme/theme_manager.dart';
import '../../utils/helpers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final Set<String> _selectedDocIds = {};
  late AnimationController _fridgeGlowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _fridgeGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _fridgeGlowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fridgeGlowController.dispose();
    super.dispose();
  }

  CollectionReference get _productsCollection {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'guest';
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('products');
  }

  Future<void> _openChefChat(List<QueryDocumentSnapshot> docs, Color primaryColor) async {
    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ثلاجتك فاضية حالياً، أضيفي شوية أغراض لنقترح عليكِ أكلة! 🛒')),
      );
      return;
    }

    final targetDocs = _selectedDocIds.isNotEmpty
        ? docs.where((d) => _selectedDocIds.contains(d.id)).toList()
        : docs;

    final targetProducts = targetDocs
        .map((d) => Product.fromMap(d.data() as Map<String, dynamic>))
        .toList();

    final validProducts = targetProducts
        .where((p) => p.status != ProductStatus.expired)
        .toList();

    if (validProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2A223D),
          content: Text(
            'كل العناصر المحددة منتهية الصلاحية 🥀! اختاري منتجات طازجة لحماية صحتكِ 💖',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChefChatSheet(
        products: validProducts,
        primaryColor: primaryColor,
      ),
    );
  }

  Future<void> _restockProduct(String docId, String productName, Color primaryColor) async {
    final newDate = DateTime.now().add(const Duration(days: 7));
    final formattedDate =
        '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}';
    await _productsCollection.doc(docId).update({'date': formattedDate, 'status': 'fresh'});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1F1A2B),
          content: Text('تم تجديد $productName لمدة أسبوع إضافي بنجاح! 🔄✨', style: TextStyle(color: primaryColor)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: ThemeManager.themeColor,
      builder: (context, primaryColor, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF110E17),
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('FoodCare 🧊', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Icon(Icons.auto_awesome, color: primaryColor, size: 20),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            actions: [
              if (_selectedDocIds.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.deselect, color: primaryColor),
                  tooltip: 'إلغاء التحديد',
                  onPressed: () => setState(() => _selectedDocIds.clear()),
                ),
              IconButton(
                icon: Icon(Icons.qr_code_scanner_rounded, color: primaryColor),
                tooltip: 'مسح الباركود',
                onPressed: () async {
                  final scannedCode = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
                  );
                  if (scannedCode != null && context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1F1A2B),
                        title: const Text('نتيجة الباركود', style: TextStyle(color: Colors.white)),
                        content: Text('الكود الممسوح: $scannedCode', style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('حسناً', style: TextStyle(color: primaryColor)),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined, color: primaryColor),
                tooltip: 'قائمة التسوق',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen())),
              ),
              IconButton(
                icon: Icon(Icons.notifications_active_outlined, color: primaryColor),
                tooltip: 'التنبيهات',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                tooltip: 'الإعدادات',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
          body: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.3,
                    colors: [
                      primaryColor.withValues(alpha: _glowAnimation.value * 0.3),
                      const Color(0xFF16121E),
                      const Color(0xFF0D0A12),
                    ],
                  ),
                ),
                child: child,
              );
            },
            child: StreamBuilder<QuerySnapshot>(
              stream: _productsCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryColor));
                }
                final docs = snapshot.data?.docs ?? [];
                final productsList = docs.map((d) => Product.fromMap(d.data() as Map<String, dynamic>)).toList();

                return Column(
                  children: [
                    // لوحة التحكم العلوية الثلاجة الذكية بتصميم فائق الجمال
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF221A30),
                            const Color(0xFF161122),
                            primaryColor.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.6), width: 1.8),
                        boxShadow: [
                          BoxShadow(color: primaryColor.withValues(alpha: 0.28), blurRadius: 24, spreadRadius: 2),
                        ],
                      ),
                      child: Row(
                        children: [
                          KawaiiFloatingWidget(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryColor, width: 1.5),
                              ),
                              child: const Text('✨', style: TextStyle(fontSize: 24)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productsList.isEmpty ? 'الثلاجة فارغة تماماً 🥺' : 'إضاءة ثلاجة FoodCare نشطة 💡',
                                  style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _selectedDocIds.isEmpty ? 'اختاري أغراض لتحضير وجبتكِ 👩‍🍳' : 'تم اختيار ${_selectedDocIds.length} مكونات للطبخ 💖',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: const Color(0xFF110E17),
                              elevation: 8,
                              shadowColor: primaryColor.withValues(alpha: 0.5),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            onPressed: () => _openChefChat(docs, primaryColor),
                            icon: const Icon(Icons.restaurant_menu_rounded, size: 16),
                            label: const Text('اسألي الشيف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),

                    // محتوى الثلاجة المضيء
                    Expanded(
                      child: docs.isEmpty
                          ? Center(
                              child: KawaiiFloatingWidget(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.kitchen_rounded, size: 90, color: primaryColor.withValues(alpha: 0.4)),
                                    const SizedBox(height: 16),
                                    const Text('لا توجد أغراض داخل الثلاجة!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text('اضغطي على الزر بالأسفل لإضافة منتجاتكِ 🛒', style: TextStyle(color: primaryColor, fontSize: 12)),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final product = Product.fromMap(data);
                                final docId = doc.id;
                                final statusColor = AppHelpers.getStatusColor(product.status);
                                final needsRestock = product.status != ProductStatus.fresh;
                                final isSelected = _selectedDocIds.contains(docId);

                                return KawaiiFadeSlide(
                                  index: index,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (product.status == ProductStatus.expired) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('هذا المنتج منتهي الصلاحية ولا يمكن اختياره للطبخ 🥀')),
                                        );
                                        return;
                                      }
                                      setState(() {
                                        if (isSelected) {
                                          _selectedDocIds.remove(docId);
                                        } else {
                                          _selectedDocIds.add(docId);
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.only(bottom: 14),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? primaryColor.withValues(alpha: 0.22)
                                            : const Color(0xFF1B1626).withValues(alpha: 0.92),
                                        borderRadius: BorderRadius.circular(26),
                                        border: Border.all(
                                          color: isSelected ? primaryColor : statusColor.withValues(alpha: 0.5),
                                          width: isSelected ? 2.5 : 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSelected ? primaryColor.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.25),
                                            blurRadius: 18,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                            color: isSelected ? primaryColor : Colors.grey.shade600,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(18),
                                            ),
                                            child: Text(AppHelpers.getProductEmoji(product.name), style: const TextStyle(fontSize: 26)),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(product.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Text('الانتهاء: ${product.date}', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(AppHelpers.getStatusText(product.status), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (needsRestock)
                                            IconButton(
                                              icon: Icon(Icons.refresh_rounded, color: primaryColor, size: 22),
                                              tooltip: 'تجديد المنتج',
                                              onPressed: () => _restockProduct(docId, product.name, primaryColor),
                                            ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(color: const Color(0xFF110E17), borderRadius: BorderRadius.circular(12)),
                                            child: Text('×${product.quantity}', style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.edit_outlined, color: primaryColor, size: 20),
                                            onPressed: () async {
                                              final updatedProduct = await Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => AddProductScreen(existingProduct: product)),
                                              );
                                              if (updatedProduct != null && updatedProduct is Product) {
                                                await _productsCollection.doc(docId).update(updatedProduct.toMap());
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                            onPressed: () async {
                                              _selectedDocIds.remove(docId);
                                              await _productsCollection.doc(docId).delete();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: primaryColor,
            elevation: 12,
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
              if (result != null && result is Product) {
                await _productsCollection.add(result.toMap());
              }
            },
            icon: const Icon(Icons.add_rounded, color: Color(0xFF110E17), size: 28),
            label: const Text('إضافة للثلاجة', style: TextStyle(color: Color(0xFF110E17), fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        );
      },
    );
  }
}

// نافذة الشيف الذكي التفاعلية
class _ChefChatSheet extends StatefulWidget {
  final List<Product> products;
  final Color primaryColor;

  const _ChefChatSheet({required this.products, required this.primaryColor});

  @override
  State<_ChefChatSheet> createState() => _ChefChatSheetState();
}

class _ChefChatSheetState extends State<_ChefChatSheet> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<dynamic> _messages = [];
  late ChatSession _chatSession;
  bool _isTyping = true;

  @override
  void initState() {
    super.initState();
    _initChefChat();
  }

  Future<void> _initChefChat() async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3-flash-preview',
      );
      _chatSession = model.startChat();

      final ingredientsList = widget.products.map((p) {
        final urgency = p.status != ProductStatus.fresh ? '(ينتهي قريباً، يفضل استخدامه أولاً)' : '';
        return '- ${p.name} (الكمية: ${p.quantity}) $urgency';
      }).join('\n');

      final initialPrompt = '''
أنت شيف ذكي ومساعد مطبخ محترف لطيف وكيوت لتطبيق FoodCare (العناية الذكية بالطعام).
هذه هي القائمة التي أرسلتها المستخدمة:
$ingredientsList

قواعد صارمة جداً يجب الالتزام بها:
1. تجاهل تماماً ولا تستخدم أي مادة غير قابلة للاستهلاك البشري أو غير غذائية (مثل: الرمل، التراب، العطور، المكياج، المنظفات، الصابون، البلاستيك، الأدوية).
2. استخدم فقط المكونات الغذائية الطازجة والصالحة للأكل، وأعطِ الأولوية لما ينتهي تاريخه قريباً تحت رعاية FoodCare.
3. اكتب الوصفة باللغة العربية بأسلوب لطيف ومختصر (اسم الوصفة، المكونات المستخدمة، وخطوات التحضير السريعة في نقاط) بدون استخدام كلمة أنمي نهائياً.
4. في نهاية ردك، اسألها بلطف إذا كانت تريد تعديل أي مكون أو لديها سؤال حول الوصفة.
''';

      final response = await _chatSession.sendMessage(Content.text(initialPrompt));
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'chef',
          'text': response.text ?? 'عذراً، لم أتمكن من تحضير الوصفة الآن (｡•́︿•̀｡)',
        });
        _isTyping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'chef',
          'text': 'حدث خطأ في الاتصال بالمطبخ الذكي: ${e.toString()}',
        });
        _isTyping = false;
      });
    }
  }

  Future<void> _sendFollowUpMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isTyping) return;

    _msgController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final safeQuery = '$text\n(تذكير للشيف: التزم باللغة العربية وبأسلوب لطيف ومحترف، ولا تقترح أبداً تناول مواد غير غذائية أو تستخدم كلمة أنمي).';
      final response = await _chatSession.sendMessage(Content.text(safeQuery));
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'chef',
          'text': response.text ?? 'هممم، لم أفهم ذلك تماماً، هل يمكنكِ التوضيح؟ 🌸',
        });
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'chef', 'text': 'تعذر إرسال الرسالة، حاولي مجدداً 📡'});
        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1525),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(color: widget.primaryColor.withValues(alpha: 0.3), blurRadius: 25),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 45,
            height: 5,
            decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(10)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                KawaiiFloatingWidget(
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: widget.primaryColor.withValues(alpha: 0.2),
                    child: const Text('👩‍🍳', style: TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الشيف الذكي في FoodCare ✨',
                        style: TextStyle(color: widget.primaryColor, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'اسأليني عن أي تعديل أو بديل للوصفة 💖',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(color: widget.primaryColor.withValues(alpha: 0.2), height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF261F36),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: widget.primaryColor, strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          const Text('الشيف يكتب الوصفة... 🍳✨', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                final isChef = msg['role'] == 'chef';

                return KawaiiFadeSlide(
                  index: 0,
                  child: Align(
                    alignment: isChef ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                      decoration: BoxDecoration(
                        color: isChef ? const Color(0xFF261F36) : widget.primaryColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(22),
                          topRight: const Radius.circular(22),
                          bottomLeft: isChef ? const Radius.circular(22) : const Radius.circular(4),
                          bottomRight: isChef ? const Radius.circular(4) : const Radius.circular(22),
                        ),
                        border: isChef ? Border.all(color: widget.primaryColor.withValues(alpha: 0.45)) : null,
                      ),
                      child: Text(
                        msg['text'] ?? '',
                        style: TextStyle(
                          color: isChef ? Colors.white : const Color(0xFF110E17),
                          fontSize: 14,
                          height: 1.55,
                          fontWeight: isChef ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1A2B),
              border: Border(top: BorderSide(color: widget.primaryColor.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onSubmitted: (_) => _sendFollowUpMessage(),
                    decoration: InputDecoration(
                      hintText: 'اكتبي سؤالك للشيف (مثلاً: بديل الحليب؟)...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF110E17),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: widget.primaryColor,
                  radius: 23,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF110E17), size: 20),
                    onPressed: _sendFollowUpMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
