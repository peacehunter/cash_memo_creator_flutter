import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design_system.dart';
import 'widgets/professional_widgets.dart';

class CustomerDirectoryScreen extends StatefulWidget {
  const CustomerDirectoryScreen({Key? key}) : super(key: key);

  @override
  _CustomerDirectoryScreenState createState() => _CustomerDirectoryScreenState();
}

class _CustomerDirectoryScreenState extends State<CustomerDirectoryScreen> {
  List<Map<String, dynamic>> _directory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? directoryJson = prefs.getString('customer_directory');
      if (directoryJson != null) {
        final List<dynamic> decoded = jsonDecode(directoryJson);
        setState(() {
          _directory = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      }
    } catch (e) {
      debugPrint('Failed to load customer directory: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDirectory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customer_directory', jsonEncode(_directory));
    } catch (e) {
      debugPrint('Failed to save customer directory: $e');
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? item, int? index}) {
    final nameController = TextEditingController(text: item?['name'] ?? '');
    final addressController = TextEditingController(text: item?['address'] ?? '');
    final phoneController = TextEditingController(text: item?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Text(item == null ? 'Add Customer' : 'Edit Customer', style: AppTypography.h3),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                    prefixIcon: const Icon(Icons.person_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    prefixIcon: const Icon(Icons.location_on_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
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
                final phone = phoneController.text.trim();
                final address = addressController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a customer name')),
                  );
                  return;
                }

                final newItem = {
                  'name': name,
                  'phone': phone,
                  'address': address,
                };

                setState(() {
                  if (index == null) {
                    _directory.add(newItem);
                  } else {
                    _directory[index] = newItem;
                  }
                });
                _saveDirectory();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCustomer(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer from your directory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              setState(() {
                _directory.removeAt(index);
              });
              _saveDirectory();
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
        title: const Text('Customer Directory', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: ProfessionalLoading())
          : _directory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_alt_outlined, size: 64, color: AppColors.neutral400),
                      const SizedBox(height: AppSpacing.md),
                      const Text('Directory is Empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: AppSpacing.xs),
                      const Text('Save client details here to auto-fill them later.', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Customer'),
                        onPressed: () => _showAddEditDialog(),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _directory.length,
                  itemBuilder: (context, index) {
                    final item = _directory[index];
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
                          child: const Icon(Icons.person_rounded, color: AppColors.primary),
                        ),
                        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item['phone'].isNotEmpty) Text('Phone: ${item['phone']}'),
                            if (item['address'].isNotEmpty) Text('Address: ${item['address']}'),
                          ],
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
                              onPressed: () => _deleteCustomer(index),
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
