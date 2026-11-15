import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product_model.dart';
import '../../theme/theme_manager.dart';
import '../../utils/helpers.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  CollectionReference get _productsCollection {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'guest';
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('products');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: ThemeManager.themeColor,
      builder: (context, primaryColor, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF16121E),
          appBar: AppBar(
            title: const Text('التنبيهات الذكية 🔔✨', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'منتجات تحتاج انتباهكِ الآن 💖',
                  style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _productsCollection.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: primaryColor));
                      }
                      final docs = snapshot.data?.docs ?? [];
                      final allProducts = docs.map((d) => Product.fromMap(d.data() as Map<String, dynamic>)).toList();
                      final urgentProducts = allProducts
                          .where((p) => p.status == ProductStatus.expired || p.status == ProductStatus.expiringSoon)
                          .toList();

                      if (urgentProducts.isEmpty) {
                        return Center(
                          child: KawaiiFloatingWidget(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🌸🎉🌸', style: TextStyle(fontSize: 44)),
                                const SizedBox(height: 12),
                                Text('(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧', style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                const Text('لا توجد تنبيهات عاجلة!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('جميع أغراض ثلاجتك تحت العناية وبحالة ممتازة في FoodCare ✨', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: urgentProducts.length,
                        itemBuilder: (context, index) {
                          final product = urgentProducts[index];
                          final isExpired = product.status == ProductStatus.expired;
                          final alertColor = isExpired ? const Color(0xFFFF6B8B) : const Color(0xFFFFBE76);

                          return KawaiiFadeSlide(
                            index: index,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F1A2B),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: alertColor.withValues(alpha: 0.5), width: 1.5),
                                boxShadow: [
                                  BoxShadow(color: alertColor.withValues(alpha: 0.12), blurRadius: 12),
                                ],
                              ),
                              child: Row(
                                children: [
                                  KawaiiFloatingWidget(
                                    child: Text(isExpired ? '🥀' : '⏳', style: const TextStyle(fontSize: 28)),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(product.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(
                                          isExpired ? 'انتهت صلاحيته بتاريخ ${product.date}!' : 'ينتهي قريباً بتاريخ ${product.date}، استهلكيه اليوم.',
                                          style: TextStyle(color: alertColor, fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: const Color(0xFF16121E), borderRadius: BorderRadius.circular(12)),
                                    child: Text('×${product.quantity}', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
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