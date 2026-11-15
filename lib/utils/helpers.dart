import 'package:flutter/material.dart';
import '../models/product_model.dart';

class AppHelpers {
  static String getProductEmoji(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('حليب') || lowerName.contains('milk') || lowerName.contains('لبن')) return '🥛';
    if (lowerName.contains('بيض') || lowerName.contains('egg')) return '🥚';
    if (lowerName.contains('جبن') || lowerName.contains('cheese')) return '🧀';
    if (lowerName.contains('خبز') || lowerName.contains('bread') || lowerName.contains('توست')) return '🍞';
    if (lowerName.contains('دجاج') || lowerName.contains('chicken') || lowerName.contains('لحم')) return '🍗';
    if (lowerName.contains('تفاح') || lowerName.contains('موز') || lowerName.contains('فواكه')) return '🍎';
    if (lowerName.contains('طماطم') || lowerName.contains('بندورة') || lowerName.contains('خيار')) return '🥗';
    if (lowerName.contains('قهوة') || lowerName.contains('نسكافيه')) return '☕';
    if (lowerName.contains('شوكولاتة') || lowerName.contains('كيك')) return '🍫';
    if (lowerName.contains('فراولة') || lowerName.contains('توت')) return '🍓';
    if (lowerName.contains('عصير') || lowerName.contains('ماء')) return '🧃';
    return '🍱';
  }

  static Color getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.expired:
        return const Color(0xFFFF6B8B);
      case ProductStatus.expiringSoon:
        return const Color(0xFFFFBE76);
      case ProductStatus.fresh:
        return const Color(0xFF7BED9F);
    }
  }

  static String getStatusText(ProductStatus status) {
    switch (status) {
      case ProductStatus.expired:
        return 'أنقذيني! منتهي الصلاحية 🥀';
      case ProductStatus.expiringSoon:
        return 'ينتهي قريباً، استهلكيه ⏳';
      case ProductStatus.fresh:
        return 'طازج وممتاز ✨';
    }
  }
}

class KawaiiFadeSlide extends StatelessWidget {
  final Widget child;
  final int index;

  const KawaiiFadeSlide({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + (index * 70).clamp(0, 500)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class KawaiiFloatingWidget extends StatefulWidget {
  final Widget child;
  const KawaiiFloatingWidget({super.key, required this.child});

  @override
  State<KawaiiFloatingWidget> createState() => _KawaiiFloatingWidgetState();
}

class _KawaiiFloatingWidgetState extends State<KawaiiFloatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}