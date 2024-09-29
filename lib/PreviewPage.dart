import 'dart:typed_data'; // Import Uint8List
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'Memo.dart'; // Import your Memo class

class PreviewPage extends StatelessWidget {
  final Memo memo;

  const PreviewPage({Key? key, required this.memo}) : super(key: key);

  Future<Uint8List> generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Cash Memo',
                  style: pw.TextStyle(fontSize: 24),
                  textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 20),
              pw.Text(memo.companyName,
                  style: pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 10),

              pw.Table.fromTextArray(
                headers: ['Product', 'Price', 'Quantity', 'Total'],
                data: memo.products.map((product) {
                  return [
                    product.name,
                    product.price.toString(),
                    product.quantity.toString(),
                    (product.price * product.quantity).toString()
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey,
                ),
                cellStyle: pw.TextStyle(fontSize: 10),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(),
                  ),
                  pw.Text('Total: ${memo.total.toStringAsFixed(2)}',
                      textAlign: pw.TextAlign.end),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Convert to Uint8List before returning
    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview Cash Memo'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final pdfData = await generatePdf(); // Update call to expect Uint8List
            await Printing.layoutPdf(
              onLayout: (PdfPageFormat format) async => pdfData,
            );
          },
          child: Text('Print Cash Memo'),
        ),
      ),
    );
  }
}
