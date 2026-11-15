class ShoppingItem {
  final String id;
  final String name;
  final int quantity;
  final bool isChecked;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.isChecked = false,
  });

  factory ShoppingItem.fromMap(String id, Map<String, dynamic> map) {
    return ShoppingItem(
      id: id,
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 1,
      isChecked: map['isChecked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'isChecked': isChecked,
    };
  }
}