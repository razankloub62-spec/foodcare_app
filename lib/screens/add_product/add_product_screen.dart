import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../theme/theme_manager.dart';
import '../../utils/helpers.dart';

class AddProductScreen extends StatefulWidget {
  final Product? existingProduct;
  const AddProductScreen({super.key, this.existingProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  int _quantity = 1;
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.existingProduct!.name;
      _dateController.text = widget.existingProduct!.date;
      _quantity = widget.existingProduct!.quantity;
    }
  }

  Future<void> _selectDate(BuildContext context, Color primaryColor) async {
    DateTime initialDate = DateTime.now().add(const Duration(days: 3));
    if (_dateController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_dateController.text);
      } catch (_) {}
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryColor,
              onPrimary: const Color(0xFF16121E),
              surface: const Color(0xFF1F1A2B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
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
            title: Text(
              _isEditing ? 'تعديل بيانات المنتج ✏️✨' : 'إضافة غرض جديد لـ FoodCare 🌸',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [primaryColor.withValues(alpha: 0.18), primaryColor.withValues(alpha: 0.0)]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      KawaiiFloatingWidget(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 2),
                            ),
                            child: Text(_isEditing ? '✏️' : '🍱', style: const TextStyle(fontSize: 40)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      KawaiiFadeSlide(
                        index: 1,
                        child: TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'اسم المنتج (مثال: حليب، بيض، فراولة)',
                            labelStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: Icon(Icons.fastfood_rounded, color: primaryColor),
                            filled: true,
                            fillColor: const Color(0xFF1F1A2B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال اسم المنتج' : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      KawaiiFadeSlide(
                        index: 2,
                        child: TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          onTap: () => _selectDate(context, primaryColor),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'تاريخ انتهاء الصلاحية',
                            hintText: 'اضغطي لاختيار التاريخ من التقويم',
                            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            labelStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: Icon(Icons.calendar_month_rounded, color: primaryColor),
                            filled: true,
                            fillColor: const Color(0xFF1F1A2B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'يرجى اختيار تاريخ الصلاحية' : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      KawaiiFadeSlide(
                        index: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1A2B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('الكمية المطلوبة:', style: TextStyle(color: Colors.white, fontSize: 16)),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (_quantity > 1) setState(() => _quantity--);
                                    },
                                    icon: Icon(Icons.remove_circle_rounded, color: primaryColor),
                                  ),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Text(
                                      '$_quantity',
                                      key: ValueKey<int>(_quantity),
                                      style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(() => _quantity++),
                                    icon: Icon(Icons.add_circle_rounded, color: primaryColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      KawaiiFadeSlide(
                        index: 4,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: const Color(0xFF16121E),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            elevation: 6,
                            shadowColor: primaryColor.withValues(alpha: 0.4),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final dateStr = _dateController.text.trim();
                              final updatedProduct = Product(
                                name: _nameController.text.trim(),
                                date: dateStr,
                                quantity: _quantity,
                                status: Product.calculateStatus(dateStr),
                              );
                              Navigator.pop(context, updatedProduct);
                            }
                          },
                          child: Text(
                            _isEditing ? 'حفظ التعديلات ✨' : 'حفظ في FoodCare 💖',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}