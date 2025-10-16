import 'package:flutter/material.dart';
import '../Memo.dart';

class WebMemoDetailPanel extends StatelessWidget {
  final Memo memo;
  final VoidCallback onBack;
  const WebMemoDetailPanel({Key? key, required this.memo, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
            const SizedBox(width: 8),
            Text(
              memo.companyName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Divider(height: 32),
        Text('Customer: ${memo.customerName}', style: const TextStyle(fontSize: 18)),
        Text('Address: ${memo.customerAddress}'),
        Text('Phone: ${memo.customerPhoneNumber}'),
        Text('Total: ${memo.total.toStringAsFixed(2)}'),
        Text('Discount: ${memo.discount}'),
        Text('VAT: ${memo.vat}'),
        const SizedBox(height: 16),
        const Text('Products:', style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: ListView.separated(
            itemCount: memo.products.length,
            itemBuilder: (ctx, idx) {
              final p = memo.products[idx];
              return ListTile(
                title: Text(p.name),
                subtitle: Text('Qtty: ${p.quantity}, Price: ${p.price}'),
                trailing: Text('Disc: ${p.discount}'),
              );
            },
            separatorBuilder: (ctx, idx) => const Divider(),
          ),
        ),
      ],
    );
  }
}
