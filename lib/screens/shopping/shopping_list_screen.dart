import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/shopping_item_model.dart';
import '../../theme/theme_manager.dart';
import '../../utils/helpers.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _itemController = TextEditingController();

  CollectionReference get _shoppingCollection {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'guest';
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('shopping_list');
  }

  Future<void> _addItem([String? customName]) async {
    final name = customName ?? _itemController.text.trim();
    if (name.isEmpty) return;

    await _shoppingCollection.add({
      'name': name,
      'quantity': 1,
      'isChecked': false,
    });

    if (customName == null) {
      _itemController.clear();
    }
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: ThemeManager.themeColor,
      builder: (context, primaryColor, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF16121E),
          appBar: AppBar(
            title: const Text('قائمة التسوق الذكية 🛒✨', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1A2B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _itemController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'إضافة غرض جديد للتسوق (مثال: حليب، تفاح)...',
                            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _addItem(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_rounded, color: primaryColor, size: 28),
                        onPressed: () => _addItem(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _shoppingCollection.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: primaryColor));
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final items = docs.map((d) => ShoppingItem.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();

                      if (items.isEmpty) {
                        return Center(
                          child: KawaiiFloatingWidget(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🛒✨', style: TextStyle(fontSize: 45)),
                                const SizedBox(height: 12),
                                const Text('قائمة التسوق فارغة في FoodCare!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('أضيفي الأغراض الناقصة لتجهيز جدولكِ القادم 💖', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return KawaiiFadeSlide(
                            index: index,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F1A2B),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: item.isChecked ? Colors.greenAccent.withValues(alpha: 0.3) : primaryColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: item.isChecked,
                                    activeColor: primaryColor,
                                    checkColor: const Color(0xFF16121E),
                                    onChanged: (val) {
                                      _shoppingCollection.doc(item.id).update({'isChecked': val ?? false});
                                    },
                                  ),
                                  Text(AppHelpers.getProductEmoji(item.name), style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: TextStyle(
                                        color: item.isChecked ? Colors.grey.shade500 : Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () => _shoppingCollection.doc(item.id).delete(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}