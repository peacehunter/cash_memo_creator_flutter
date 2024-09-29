import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding/decoding

class CashMemo extends StatefulWidget {
  final Map<String, dynamic>? memo;

  CashMemo({this.memo});

  @override
  _CashMemoState createState() => _CashMemoState();
}

class _CashMemoState extends State<CashMemo> {
  List<Map<String, dynamic>> products = [
    {'name': '', 'price': '', 'quantity': ''}
  ];
  String companyName = 'ABC Company';
  bool showMemo = false;

  @override
  void initState() {
    super.initState();
    if (widget.memo != null) {
      loadMemoData();
    }
  }

  void loadMemoData() {
    setState(() {
      products = List<Map<String, dynamic>>.from(widget.memo!['products']);
      companyName = widget.memo!['companyName'];
      showMemo = true;
    });
  }

  void addProductRow() {
    setState(() {
      products.add({'name': '', 'price': '', 'quantity': ''});
    });
  }

  double calculateTotal() {
    return products.fold(0, (total, product) {
      double price = double.tryParse(product['price']) ?? 0;
      int quantity = int.tryParse(product['quantity']) ?? 0;
      return total + (price * quantity);
    });
  }

  Future<void> saveMemo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> memos = [];

    String? savedMemos = prefs.getString('memos');
    if (savedMemos != null) {
      memos = List<Map<String, dynamic>>.from(json.decode(savedMemos));
    }

    memos.add({
      'companyName': companyName,
      'products': products,
      'total': calculateTotal(),
    });

    await prefs.setString('memos', json.encode(memos));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cash Memo Generator'),
      ),
      body: !showMemo
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Company Name',
              ),
              onChanged: (value) {
                setState(() {
                  companyName = value;
                });
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Product Name',
                          ),
                          onChanged: (value) {
                            products[index]['name'] = value;
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Price',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            products[index]['price'] = value;
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            products[index]['quantity'] = value;
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: addProductRow,
                  child: Text('Add More Product'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showMemo = true;
                    });
                    saveMemo(); // Save memo when generating
                  },
                  child: Text('Generate Memo'),
                ),
              ],
            )
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(companyName, style: TextStyle(fontSize: 24)),
            Text('Cash Memo', style: TextStyle(fontSize: 18)),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  double total = (double.tryParse(products[index]['price']) ?? 0) *
                      (int.tryParse(products[index]['quantity']) ?? 0);
                  return ListTile(
                    title: Text(products[index]['name']),
                    subtitle: Text('Total: \$${total.toStringAsFixed(2)}'),
                  );
                },
              ),
            ),
            Text('Total Amount: \$${calculateTotal().toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
