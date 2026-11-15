enum ProductStatus { fresh, expiringSoon, expired }

class Product {
  final String name;
  final String date;
  final int quantity;
  final ProductStatus status;

  Product({
    required this.name,
    required this.date,
    required this.quantity,
    required this.status,
  });

  static ProductStatus calculateStatus(String dateStr) {
    try {
      final expiryDate = DateTime.parse(dateStr);
      final today = DateTime.now();
      final difference = expiryDate.difference(DateTime(today.year, today.month, today.day)).inDays;

      if (difference < 0) {
        return ProductStatus.expired;
      } else if (difference <= 3) {
        return ProductStatus.expiringSoon;
      } else {
        return ProductStatus.fresh;
      }
    } catch (_) {
      return ProductStatus.fresh;
    }
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    final dateStr = map['date'] ?? '';
    return Product(
      name: map['name'] ?? '',
      date: dateStr,
      quantity: map['quantity'] ?? 1,
      status: calculateStatus(dateStr),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': date,
      'quantity': quantity,
      'status': status.name,
    };
  }
}