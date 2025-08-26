class Memo {
  String companyName;
  List<Product> products;
  double total;
  String? date; // Date is optional
  String customerName; // New field
  String customerAddress; // New field
  String customerPhoneNumber; // New field
  double discount; // New field for discount
  double vat; // New field for VAT
  bool isPercentDiscount;

  String companyAddress; // Add this line
  String companyLogo; // Add this line (assuming it's a URL or file path)

  Memo({
    required this.companyAddress, // Add this line
    required this.companyLogo, // Add this line

    required this.companyName,
    required this.products,
    required this.total,
    this.date,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhoneNumber,
    this.discount = 0.0, // Default value for discount
    this.vat = 0.0, // Default value for VAT
    this.isPercentDiscount = true, // Default value for percentage discount
  });

  // Convert Memo to JSON format for saving
  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'products': products.map((product) => product.toJson()).toList(),
      'total': total,
      'date': date ?? '',
      'customerName': customerName,
      'customerAddress': customerAddress,
      'customerPhoneNumber': customerPhoneNumber,
      'discount': discount, // Save discount
      'vat': vat, // Save VAT
      'isPercentDiscount': isPercentDiscount, // Save discount type
      'companyAddress': companyAddress, // Save company address
      'companyLogo': companyLogo, // Save company logo
    };
  }

  // Create a Memo from JSON data
  static Memo fromJson(Map<String, dynamic> json) {
    return Memo(
        companyName: json['companyName'] ?? '',
        products: (json['products'] as List<dynamic>?)
                ?.map((item) => Product.fromJson(item))
                .toList() ??
            [],
        total: json['total'] ?? 0.0,
        date: json['date'] as String? ?? '',
        customerName: json['customerName'] ?? '',
        customerAddress: json['customerAddress'] ?? '',
        customerPhoneNumber: json['customerPhoneNumber'] ?? '',
        discount: json['discount']?.toDouble() ?? 0.0, // Handle null discount
        vat: json['vat']?.toDouble() ?? 0.0, // Handle null VAT
        isPercentDiscount: json['isPercentDiscount'] ?? true,
        companyAddress:
            json['companyAddress'] ?? '', // Handle null discount type
        companyLogo: json['companyLogo'] ?? '');
  }
}

class Product {
  String name;
  double price;
  int quantity;
  double discount; // New field for discount
  bool isExpanded; // Added isExpanded property

  Product({
    required this.name,
    required this.price,
    required this.quantity,
    this.discount = 0.0, // Initialize discount to 0.0 by default
    this.isExpanded = false, // Initialize to false by default
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'discount': discount, // Include discount in toJson
      'isExpanded': isExpanded, // Include isExpanded in toJson
    };
  }

  static Product fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'],
      price: (json['price'] is String)
          ? double.tryParse(json['price']) ?? 0.0
          : json['price'].toDouble(),
      quantity: (json['quantity'] is String)
          ? int.tryParse(json['quantity']) ?? 0
          : json['quantity'],
      discount: (json['discount'] is String)
          ? double.tryParse(json['discount']) ?? 0.0
          : (json['discount'] ?? 0.0).toDouble(),
      isExpanded: json['isExpanded'] ??
          false, // Parse isExpanded from JSON, default to false
    );
  }
}
