import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design_system.dart';
import 'widgets/professional_widgets.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({Key? key}) : super(key: key);

  @override
  _ProductCatalogScreenState createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  List<Map<String, dynamic>> _catalog = [];
  bool _isLoading = true;
  String _currencySymbol = '৳';

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _currencySymbol = prefs.getString('currency_symbol') ?? '৳';
      final String? catalogJson = prefs.getString('product_catalog');
      if (catalogJson != null) {
        final List<dynamic> decoded = jsonDecode(catalogJson);
        setState(() {
          _catalog = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      }
    } catch (e) {
      debugPrint('Failed to load catalog: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCatalog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('product_catalog', jsonEncode(_catalog));
    } catch (e) {
      debugPrint('Failed to save catalog: $e');
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? item, int? index}) {
    final nameController = TextEditingController(text: item?['name'] ?? '');
    final priceController = TextEditingController(text: item != null ? item['price'].toString() : '');
    final discountController = TextEditingController(text: item != null ? item['discount'].toString() : '0.0');
    String discountType = item?['discountType'] ?? 'Percent';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              title: Text(item == null ? 'Add Product' : 'Edit Product', style: AppTypography.h3),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        prefixIcon: const Icon(Icons.shopping_bag_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Price ($_currencySymbol)',
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: discountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Default Discount',
                        prefixIcon: const Icon(Icons.local_offer_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Text('Discount Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        ChoiceChip(
                          label: const Text('Percent (%)'),
                          selected: discountType == 'Percent',
                          onSelected: (selected) {
                            if (selected) setDialogState(() => discountType = 'Percent');
                          },
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ChoiceChip(
                          label: Text('Flat ($_currencySymbol)'),
                          selected: discountType == 'Flat',
                          onSelected: (selected) {
                            if (selected) setDialogState(() => discountType = 'Flat');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final price = double.tryParse(priceController.text) ?? 0.0;
                    final discount = double.tryParse(discountController.text) ?? 0.0;

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a product name')),
                      );
                      return;
                    }

                    final newItem = {
                      'name': name,
                      'price': price,
                      'discount': discount,
                      'discountType': discountType,
                    };

                    setState(() {
                      if (index == null) {
                        _catalog.add(newItem);
                      } else {
                        _catalog[index] = newItem;
                      }
                    });
                    _saveCatalog();
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteProduct(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product from your catalog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              setState(() {
                _catalog.removeAt(index);
              });
              _saveCatalog();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Product Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: ProfessionalLoading())
          : _catalog.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.neutral400),
                      const SizedBox(height: AppSpacing.md),
                      const Text('Catalog is Empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: AppSpacing.xs),
                      const Text('Add products you sell frequently to save time.', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Product'),
                        onPressed: () => _showAddEditDialog(),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _catalog.length,
                  itemBuilder: (context, index) {
                    final item = _catalog[index];
                    final String discountSuffix = item['discountType'] == 'Percent' ? '%' : ' $_currencySymbol';
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_bag_rounded, color: AppColors.primary),
                        ),
                        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Price: $_currencySymbol${item['price'].toStringAsFixed(2)} | Discount: ${item['discount']}${discountSuffix}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                              onPressed: () => _showAddEditDialog(item: item, index: index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, color: Colors.red),
                              onPressed: () => _deleteProduct(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
