import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../Memo.dart';
import '../services/memo_firestore_service.dart';
import '_template_picker_dialog.dart';

class WebMemoCreateDialog extends StatefulWidget {
  final void Function(Memo) onSave;
  final Memo? initialMemo;
  const WebMemoCreateDialog(
      {super.key, required this.onSave, this.initialMemo});

  @override
  State<WebMemoCreateDialog> createState() => _WebMemoCreateDialogState();
}

class _WebMemoCreateDialogState extends State<WebMemoCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final companyNameController = TextEditingController();
  final customerNameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final discountController = TextEditingController();
  final vatController = TextEditingController();

  List<Product> products = [];
  String? errorText;

  @override
  void initState() {
    super.initState();
    if (widget.initialMemo != null) {
      companyNameController.text = widget.initialMemo!.companyName;
      customerNameController.text = widget.initialMemo!.customerName;
      addressController.text = widget.initialMemo!.customerAddress;
      phoneController.text = widget.initialMemo!.customerPhoneNumber;
      discountController.text = widget.initialMemo!.discount.toString();
      vatController.text = widget.initialMemo!.vat.toString();
      products = List<Product>.from(widget.initialMemo!.products);
    } else {
      products =
          List.generate(4, (i) => Product(name: '', price: 0, quantity: 1));
    }
  }

  @override
  void dispose() {
    companyNameController.dispose();
    customerNameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    discountController.dispose();
    vatController.dispose();
    super.dispose();
  }

  void addProduct() {
    setState(() {
      products.add(Product(name: '', price: 0, quantity: 1));
    });
  }

  void saveMemo() {
    if (!_formKey.currentState!.validate() || products.isEmpty) {
      setState(() {
        errorText = 'Fill all fields and add at least one product';
      });
      return;
    }
    double total = products.fold(0.0, (t, p) => t + (p.price * p.quantity));
    final memo = Memo(
      companyAddress: '',
      companyLogo: '',
      companyName: companyNameController.text,
      customerName: customerNameController.text,
      customerAddress: addressController.text,
      customerPhoneNumber: phoneController.text,
      discount: double.tryParse(discountController.text) ?? 0.0,
      vat: double.tryParse(vatController.text) ?? 0.0,
      isPercentDiscount: true,
      date: DateTime.now().toIso8601String(),
      products: List<Product>.from(products),
      total: total,
      id: widget.initialMemo?.id,
    );
    // Persist to Firestore
    MemoFirestoreService.upsertMemo(memo).then((_) {
      widget.onSave(memo);
      // Removed: Navigator.pop(context);
      // Web: Log success to browser console
      // ignore: avoid_print
      print('[WEB] Memo save success for memo id: \${memo.id}');
      // Also show a snackbar for success
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memo saved successfully!')));
    }).catchError((e) {
      setState(() {
        errorText = 'Failed to save memo: \$e';
      });
      // Web: Log error to browser console
      // ignore: avoid_print
      print('[WEB][ERROR] Failed to save memo: \$e');
      // Also show Snackbar for error
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save memo: \$e')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        backgroundColor: const Color(0xFFf8fafc),
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1150,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.note_add_rounded,
                              color: Color(0xFF059669), size: 28),
                          const SizedBox(width: 8),
                          Text('Create Cash Memo',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context))
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),
                      TextFormField(
                        controller: companyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Company Name',
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Address',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 18),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFf1f5f9),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Color(0xFFe2e8f0), width: 1.4),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: discountController,
                                decoration: const InputDecoration(
                                    labelText: 'Total Discount'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: vatController,
                                decoration: const InputDecoration(
                                    labelText: 'Total VAT'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Products',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0f172a))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...products.asMap().entries.map((entry) {
                        final i = entry.key;
                        final p = entry.value;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          color: Colors.white,
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    initialValue: p.name,
                                    decoration: const InputDecoration(
                                      labelText: 'Product Name',
                                      prefixIcon: Icon(Icons.shopping_bag),
                                    ),
                                    onChanged: (v) => setState(() =>
                                        products[i] = Product(
                                            name: v,
                                            price: p.price,
                                            quantity: p.quantity,
                                            discount: p.discount,
                                            isExpanded: p.isExpanded)),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue:
                                        p.price == 0 ? '' : p.price.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Price',
                                      prefixIcon: Icon(Icons.attach_money),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => setState(() =>
                                        products[i] = Product(
                                            name: p.name,
                                            price: double.tryParse(v) ?? 0,
                                            quantity: p.quantity,
                                            discount: p.discount,
                                            isExpanded: p.isExpanded)),
                                    validator: (v) =>
                                        (double.tryParse(v ?? '') == null)
                                            ? 'Required'
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: p.quantity == 0
                                        ? ''
                                        : p.quantity.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Qty',
                                      prefixIcon: Icon(
                                          Icons.confirmation_number_outlined),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => setState(() =>
                                        products[i] = Product(
                                            name: p.name,
                                            price: p.price,
                                            quantity: int.parse(v),
                                            discount: p.discount,
                                            isExpanded: p.isExpanded)),
                                    validator: (v) =>
                                        (int.tryParse(v ?? '') == null)
                                            ? 'Required'
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          initialValue: p.discount == 0
                                              ? ''
                                              : p.discount.toString(),
                                          decoration: const InputDecoration(
                                            labelText: 'Discount',
                                            prefixIcon: Icon(Icons.sell),
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) => setState(() =>
                                              products[i] = Product(
                                                name: p.name,
                                                price: p.price,
                                                quantity: p.quantity,
                                                discount:
                                                    double.tryParse(v) ?? 0,
                                                discountType: p.discountType,
                                                isExpanded: p.isExpanded,
                                              )),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        flex: 2,
                                        child: DropdownButtonFormField<
                                            DiscountType>(
                                          initialValue: p.discountType,
                                          decoration: const InputDecoration(
                                            labelText: 'Discount Type',
                                            prefixIcon: Icon(Icons.merge_type),
                                          ),
                                          items: [
                                            DropdownMenuItem(
                                              value: DiscountType.perPiece,
                                              child: Text('Per Piece'),
                                            ),
                                            DropdownMenuItem(
                                              value: DiscountType.solid,
                                              child: Text('Solid Amount'),
                                            ),
                                          ],
                                          onChanged: (val) => setState(
                                              () => products[i] = Product(
                                                    name: p.name,
                                                    price: p.price,
                                                    quantity: p.quantity,
                                                    discount: p.discount,
                                                    discountType: val ??
                                                        DiscountType.perPiece,
                                                    isExpanded: p.isExpanded,
                                                  )),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.delete_outline,
                                      color: Color(0xFFef4444)),
                                  onPressed: () {
                                    setState(() => products.removeAt(i));
                                  },
                                  tooltip: 'Remove product',
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Product',
                                textAlign: TextAlign.center),
                            onPressed: addProduct,
                          ),
                        ),
                      ),
                      if (errorText != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(errorText!,
                                style: const TextStyle(color: Colors.red))),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0f172a),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(70, 46),
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w600),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('Save Cash Memo'),
                              onPressed: saveMemo,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(60, 46),
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_rounded),
                            label: const Text('Print PDF'),
                            onPressed: () async {
                              final String? template = await showDialog<String>(
                                context: context,
                                barrierDismissible: true,
                                builder: (ctx) => TemplatePickerDialog(),
                              );
                              if (template != null) {
                                final doc = pw.Document();
                                pw.Widget pdfContent;
                                switch (template) {
                                  case 'Standard (Default)':
                                    pdfContent = pw.DefaultTextStyle.merge(
                                      style: pw.TextStyle(
                                        lineSpacing: 2.2,
                                        font: pw.Font.courierBold(),
                                      ),
                                      child: pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.start,
                                        children: [
                                          // Header
                                          pw.Center(
                                            child: pw.Text(
                                              'CASH MEMO',
                                              style: pw.TextStyle(
                                                fontSize: 32,
                                                fontWeight: pw.FontWeight.bold,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                          ),
                                          pw.SizedBox(height: 16),

                                          // Company Information
                                          pw.Text(
                                            'COMPANY: ${companyNameController.text.toUpperCase()}',
                                            style: pw.TextStyle(
                                              fontSize: 16,
                                              fontWeight: pw.FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                          pw.SizedBox(height: 8),

                                          // Customer Details
                                          pw.Text(
                                            'Customer: ${customerNameController.text}',
                                            style: pw.TextStyle(
                                                fontSize: 14,
                                                fontWeight: pw.FontWeight.bold),
                                          ),
                                          pw.Text(
                                              'Phone: ${phoneController.text}',
                                              style:
                                                  pw.TextStyle(fontSize: 13)),
                                          pw.Text(
                                              'Address: ${addressController.text}',
                                              style:
                                                  pw.TextStyle(fontSize: 13)),
                                          pw.SizedBox(height: 12),

                                          // Items Section Header
                                          pw.Center(
                                            child: pw.Text(
                                              'ITEMS DETAILS',
                                              style: pw.TextStyle(
                                                fontSize: 15,
                                                fontWeight: pw.FontWeight.bold,
                                                decoration:
                                                    pw.TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                          pw.SizedBox(height: 8),

                                          // Products Table
                                          pw.Table(
                                            border:
                                                pw.TableBorder.all(width: 1.2),
                                            columnWidths: {
                                              0: pw.FlexColumnWidth(
                                                  3), // PRODUCT
                                              1: pw.FlexColumnWidth(1), // QTY
                                              2: pw.FlexColumnWidth(
                                                  1.5), // PRICE
                                              3: pw.FlexColumnWidth(
                                                  1.5), // DISCOUNT
                                              4: pw.FlexColumnWidth(
                                                  1.8), // AMOUNT
                                            },
                                            children: [
                                              // Table Header
                                              pw.TableRow(
                                                decoration: pw.BoxDecoration(
                                                    color: PdfColors.grey200),
                                                children: [
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            6),
                                                    child: pw.Text('PRODUCT',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight
                                                                .bold,
                                                            letterSpacing:
                                                                0.5)),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            6),
                                                    child: pw.Text('QTY',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight
                                                                .bold,
                                                            letterSpacing:
                                                                0.5)),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            6),
                                                    child: pw.Text('PRICE',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight
                                                                .bold,
                                                            letterSpacing:
                                                                0.5)),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            6),
                                                    child: pw.Text('DISCOUNT',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight
                                                                .bold,
                                                            letterSpacing:
                                                                0.5)),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            6),
                                                    child: pw.Text('AMOUNT',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight
                                                                .bold,
                                                            letterSpacing:
                                                                0.5)),
                                                  ),
                                                ],
                                              ),

                                              // Table Rows (Products)
                                              ...products.map((p) =>
                                                  pw.TableRow(children: [
                                                    pw.Padding(
                                                      padding: const pw
                                                          .EdgeInsets.all(6),
                                                      child: pw.Text(p.name,
                                                          style: pw.TextStyle(
                                                              fontSize: 11)),
                                                    ),
                                                    pw.Padding(
                                                      padding: const pw
                                                          .EdgeInsets.all(6),
                                                      child: pw.Text(
                                                          p.quantity.toString(),
                                                          style: pw.TextStyle(
                                                              fontSize: 11)),
                                                    ),
                                                    pw.Padding(
                                                      padding: const pw
                                                          .EdgeInsets.all(6),
                                                      child: pw.Text(
                                                          p.price
                                                              .toStringAsFixed(
                                                                  2),
                                                          style: pw.TextStyle(
                                                              fontSize: 11)),
                                                    ),
                                                    pw.Padding(
                                                      padding: const pw
                                                          .EdgeInsets.all(6),
                                                      child: pw.Text(
                                                        (p.discount ?? 0.0)
                                                            .toStringAsFixed(2),
                                                        style: pw.TextStyle(
                                                            fontSize: 11),
                                                      ),
                                                    ),
                                                    pw.Padding(
                                                      padding: const pw
                                                          .EdgeInsets.all(6),
                                                      child: pw.Text(
                                                        (() {
                                                          double discount =
                                                              p.discount ?? 0.0;
                                                          if (p.discountType ==
                                                              DiscountType
                                                                  .solid) {
                                                            // Solid discount once per product line
                                                            return ((p.price *
                                                                        p.quantity) -
                                                                    discount)
                                                                .toStringAsFixed(2);
                                                          } else {
                                                            // Per piece discount
                                                            return ((p.price -
                                                                        discount) *
                                                                    p.quantity)
                                                                .toStringAsFixed(
                                                                    2);
                                                          }
                                                        })(),
                                                        style: pw.TextStyle(
                                                            fontSize: 11),
                                                      ),
                                                    ),
                                                  ])),

                                              // Subtotal Row
                                              pw.TableRow(children: [
                                                pw.Padding(
                                                  padding:
                                                      const pw.EdgeInsets.all(
                                                          6),
                                                  child: pw.Text('Subtotal',
                                                      style: pw.TextStyle(
                                                          fontWeight: pw
                                                              .FontWeight.bold,
                                                          fontSize: 11)),
                                                ),
                                                pw.SizedBox(),
                                                pw.SizedBox(),
                                                pw.SizedBox(),
                                                pw.Padding(
                                                  padding:
                                                      const pw.EdgeInsets.all(
                                                          6),
                                                  child: pw.Text(
                                                    (() {
                                                      final subtotal = products
                                                          .fold(0.0, (t, p) {
                                                        final discount =
                                                            p.discount ?? 0.0;
                                                        if (p.discountType ==
                                                            DiscountType
                                                                .solid) {
                                                          return t +
                                                              ((p.price *
                                                                      p.quantity) -
                                                                  discount);
                                                        } else {
                                                          return t +
                                                              ((p.price -
                                                                      discount) *
                                                                  p.quantity);
                                                        }
                                                      });
                                                      return subtotal
                                                          .toStringAsFixed(2);
                                                    })(),
                                                    style: pw.TextStyle(
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                        fontSize: 11),
                                                  ),
                                                ),
                                              ]),
                                            ],
                                          ),

                                          pw.SizedBox(height: 16),

                                          // Summary Section
                                          pw.Container(
                                            padding:
                                                const pw.EdgeInsets.all(12),
                                            decoration: pw.BoxDecoration(
                                              border: pw.Border.all(width: 1),
                                              borderRadius:
                                                  pw.BorderRadius.circular(6),
                                            ),
                                            child: pw.Column(
                                              crossAxisAlignment:
                                                  pw.CrossAxisAlignment.start,
                                              children: [
                                                pw.Text(
                                                    'Total Discount: ${discountController.text}',
                                                    style: pw.TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: pw
                                                            .FontWeight.bold)),
                                                pw.SizedBox(height: 4),
                                                pw.Text(
                                                    'Total VAT: ${vatController.text}',
                                                    style: pw.TextStyle(
                                                        fontSize: 13)),
                                                pw.SizedBox(height: 8),
                                                pw.Divider(thickness: 1),
                                                pw.SizedBox(height: 8),
                                                pw.Text(
                                                  'TOTAL: \$' +
                                                      (() {
                                                        double subtotal =
                                                            products.fold(0.0,
                                                                (t, p) {
                                                          final discount =
                                                              p.discount ?? 0.0;
                                                          if (p.discountType ==
                                                              DiscountType
                                                                  .solid) {
                                                            return t +
                                                                ((p.price *
                                                                        p.quantity) -
                                                                    discount);
                                                          } else {
                                                            return t +
                                                                ((p.price -
                                                                        discount) *
                                                                    p.quantity);
                                                          }
                                                        });

                                                        double globalDiscount =
                                                            double.tryParse(
                                                                    discountController
                                                                        .text) ??
                                                                0.0;
                                                        bool isPercent =
                                                            true; // adjust if user can choose %
                                                        double afterDiscount = isPercent
                                                            ? subtotal *
                                                                (1 -
                                                                    globalDiscount /
                                                                        100.0)
                                                            : subtotal -
                                                                globalDiscount;

                                                        double vat =
                                                            double.tryParse(
                                                                    vatController
                                                                        .text) ??
                                                                0.0;
                                                        double total =
                                                            afterDiscount *
                                                                (1 +
                                                                    vat /
                                                                        100.0);
                                                        return total
                                                            .toStringAsFixed(2);
                                                      })(),
                                                  style: pw.TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    color: PdfColors.blue800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    break;
                                  case 'Compact':
                                    pdfContent = pw.DefaultTextStyle.merge(
                                        style: pw.TextStyle(
                                            lineSpacing: 1.8,
                                            font: pw.Font.courier()),
                                        child: pw.Column(
                                          crossAxisAlignment:
                                              pw.CrossAxisAlignment.start,
                                          children: [
                                            // Header
                                            pw.Text('CASH MEMO',
                                                style: pw.TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    letterSpacing: 0.8)),
                                            pw.SizedBox(height: 8),

                                            // Company Information
                                            pw.Text(
                                                'COMPANY: ${companyNameController.text.toUpperCase()}',
                                                style: pw.TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    letterSpacing: 0.3)),
                                            pw.SizedBox(height: 6),

                                            // Customer Details
                                            pw.Text(
                                                'Customer: ${customerNameController.text}',
                                                style: pw.TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        pw.FontWeight.bold)),
                                            pw.Text(
                                                'Phone: ${phoneController.text}',
                                                style:
                                                    pw.TextStyle(fontSize: 11)),
                                            pw.Text(
                                                'Address: ${addressController.text}',
                                                style:
                                                    pw.TextStyle(fontSize: 11)),
                                            pw.SizedBox(height: 8),

                                            // Products Table
                                            pw.Table(
                                              border: pw.TableBorder.all(
                                                  width: 0.8),
                                              defaultVerticalAlignment: pw
                                                  .TableCellVerticalAlignment
                                                  .middle,
                                              columnWidths: {
                                                0: pw.FlexColumnWidth(2.5),
                                                1: pw.FlexColumnWidth(0.8),
                                                2: pw.FlexColumnWidth(1.2),
                                                3: pw.FlexColumnWidth(1.2)
                                              },
                                              children: [
                                                // Table Header
                                                pw.TableRow(
                                                    decoration:
                                                        pw.BoxDecoration(
                                                            color: PdfColors
                                                                .grey100),
                                                    children: [
                                                      pw.Padding(
                                                          padding: const pw
                                                              .EdgeInsets.symmetric(
                                                              vertical: 3,
                                                              horizontal: 4),
                                                          child: pw.Text(
                                                              'PRODUCT',
                                                              style: pw.TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: pw
                                                                      .FontWeight
                                                                      .bold,
                                                                  letterSpacing:
                                                                      0.4))),
                                                      pw.Padding(
                                                          padding: const pw
                                                              .EdgeInsets.symmetric(
                                                              vertical: 3,
                                                              horizontal: 4),
                                                          child: pw.Text('QTY',
                                                              style: pw.TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: pw
                                                                      .FontWeight
                                                                      .bold,
                                                                  letterSpacing:
                                                                      0.4))),
                                                      pw.Padding(
                                                          padding: const pw
                                                              .EdgeInsets.symmetric(
                                                              vertical: 3,
                                                              horizontal: 4),
                                                          child: pw.Text(
                                                              'PRICE',
                                                              style: pw.TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: pw
                                                                      .FontWeight
                                                                      .bold,
                                                                  letterSpacing:
                                                                      0.4))),
                                                      pw.Padding(
                                                          padding: const pw
                                                              .EdgeInsets.symmetric(
                                                              vertical: 3,
                                                              horizontal: 4),
                                                          child: pw.Text('DISC',
                                                              style: pw.TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: pw
                                                                      .FontWeight
                                                                      .bold,
                                                                  letterSpacing:
                                                                      0.4))),
                                                    ]),
                                                // Table Rows
                                                ...products.map((p) =>
                                                    pw.TableRow(children: [
                                                      pw.Padding(
                                                          padding: const pw
                                                              .EdgeInsets.symmetric(
                                                              vertical: 2,
                                                              horizontal: 4),
                                                          child: pw.Text(p.name,
                                                              style:
                                                                  pw.TextStyle(
                                                                      fontSize:
                                                                          9))),
                                                      pw.Padding(
                                                          padding: const pw
                                                              .EdgeInsets.symmetric(
                                                              vertical: 2,
                                                              horizontal: 4),
                                                          child: pw.Text(
                                                              p.quantity
                                                                  .toString(),
                                                              style:
                                                                  pw.TextStyle(
                                                                      fontSize:
                                                                          9))),
                                                      pw.Padding(
                                                          padding: const pw
                                                              .EdgeInsets.symmetric(
                                                              vertical: 2,
                                                              horizontal: 4),
                                                          child: pw.Text(
                                                              p.price
                                                                  .toStringAsFixed(
                                                                      2),
                                                              style:
                                                                  pw.TextStyle(
                                                                      fontSize:
                                                                          9))),
                                                      pw.Padding(
                                                          padding: const pw
                                                              .EdgeInsets.symmetric(
                                                              vertical: 2,
                                                              horizontal: 4),
                                                          child: pw.Text(
                                                              p.discount
                                                                  .toStringAsFixed(
                                                                      2),
                                                              style:
                                                                  pw.TextStyle(
                                                                      fontSize:
                                                                          9))),
                                                      pw.Padding(
                                                          padding: const pw
                                                              .EdgeInsets.symmetric(
                                                              vertical: 2,
                                                              horizontal: 4),
                                                          child: pw.Text(
                                                              ((p.discountType ==
                                                                          DiscountType
                                                                              .perPiece
                                                                      ? ((p.price - (p.discount ?? 0.0)) *
                                                                          p
                                                                              .quantity)
                                                                      : ((p.price * p.quantity) -
                                                                          (p.discount ??
                                                                              0.0))))
                                                                  .toStringAsFixed(
                                                                      2),
                                                              style:
                                                                  pw.TextStyle(
                                                                      fontSize:
                                                                          9))),
                                                    ])),
                                              ],
                                            ),
                                            pw.SizedBox(height: 10),

                                            // Total Amount
                                            pw.Container(
                                              padding:
                                                  const pw.EdgeInsets.symmetric(
                                                      vertical: 6,
                                                      horizontal: 8),
                                              decoration: pw.BoxDecoration(
                                                  border:
                                                      pw.Border.all(width: 0.8),
                                                  borderRadius:
                                                      pw.BorderRadius.circular(
                                                          4)),
                                              child: pw.Text(
                                                  'TOTAL: \$${products.fold(0.0, (t, p) => t + (p.price * p.quantity)).toStringAsFixed(2)}',
                                                  style: pw.TextStyle(
                                                      fontWeight:
                                                          pw.FontWeight.bold,
                                                      fontSize: 14,
                                                      color:
                                                          PdfColors.blue700)),
                                            ),
                                          ],
                                        ));
                                    break;
                                  case 'Modern Accent':
                                    pdfContent = pw.DefaultTextStyle.merge(
                                      style: pw.TextStyle(
                                          lineSpacing: 2.0,
                                          font: pw.Font.helvetica()),
                                      child: pw.Container(
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border(
                                            left: pw.BorderSide(
                                                color: PdfColors.green700,
                                                width: 10),
                                          ),
                                          color: PdfColors.white,
                                        ),
                                        padding: const pw.EdgeInsets.all(20),
                                        child: pw.Column(
                                          crossAxisAlignment:
                                              pw.CrossAxisAlignment.start,
                                          children: [
                                            // Header with Total
                                            pw.Row(
                                              crossAxisAlignment:
                                                  pw.CrossAxisAlignment.end,
                                              children: [
                                                pw.Text('CASH MEMO',
                                                    style: pw.TextStyle(
                                                        fontSize: 28,
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                        color:
                                                            PdfColors.green700,
                                                        letterSpacing: 1.2)),
                                                pw.Spacer(),
                                                pw.Text(
                                                  '\$${products.fold(0.0, (t, p) {
                                                    final amount = (p
                                                                .discountType ==
                                                            DiscountType
                                                                .perPiece)
                                                        ? ((p.price -
                                                                (p.discount ??
                                                                    0.0)) *
                                                            p.quantity)
                                                        : ((p.price *
                                                                p.quantity) -
                                                            (p.discount ??
                                                                0.0));
                                                    return t + amount;
                                                  }).toStringAsFixed(2)}',
                                                  style: pw.TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          pw.FontWeight.bold,
                                                      color:
                                                          PdfColors.green700),
                                                ),
                                              ],
                                            ),
                                            pw.SizedBox(height: 16),

                                            // Company Information
                                            pw.Text(
                                              'COMPANY: ${companyNameController.text.toUpperCase()}',
                                              style: pw.TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  color: PdfColors.green800,
                                                  letterSpacing: 0.6),
                                            ),
                                            pw.SizedBox(height: 10),

                                            // Customer Details
                                            pw.Text(
                                                'Customer: ${customerNameController.text}',
                                                style: pw.TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        pw.FontWeight.bold)),
                                            pw.Text(
                                                'Phone: ${phoneController.text}',
                                                style:
                                                    pw.TextStyle(fontSize: 13)),
                                            pw.Text(
                                                'Address: ${addressController.text}',
                                                style:
                                                    pw.TextStyle(fontSize: 13)),
                                            pw.SizedBox(height: 12),

                                            // Products Table
                                            pw.Table(
                                              border: pw.TableBorder.symmetric(
                                                outside: pw.BorderSide(
                                                    color: PdfColors.green700,
                                                    width: 1.5),
                                              ),
                                              columnWidths: {
                                                0: pw.FlexColumnWidth(
                                                    3), // PRODUCT
                                                1: pw.FlexColumnWidth(1), // QTY
                                                2: pw.FlexColumnWidth(
                                                    1.5), // PRICE
                                                3: pw.FlexColumnWidth(
                                                    1.5), // DISC
                                                4: pw.FlexColumnWidth(
                                                    2), // AMOUNT
                                              },
                                              children: [
                                                // Table Header
                                                pw.TableRow(
                                                  decoration: pw.BoxDecoration(
                                                      color: PdfColors.green50),
                                                  children: [
                                                    pw.Padding(
                                                        padding: const pw
                                                            .EdgeInsets.all(6),
                                                        child: pw.Text(
                                                            'PRODUCT',
                                                            style: pw.TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: pw
                                                                    .FontWeight
                                                                    .bold,
                                                                color: PdfColors
                                                                    .green900))),
                                                    pw.Padding(
                                                        padding: const pw
                                                            .EdgeInsets.all(6),
                                                        child: pw.Text('QTY',
                                                            style: pw.TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: pw
                                                                    .FontWeight
                                                                    .bold,
                                                                color: PdfColors
                                                                    .green900))),
                                                    pw.Padding(
                                                        padding: const pw
                                                            .EdgeInsets.all(6),
                                                        child: pw.Text('PRICE',
                                                            style: pw.TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: pw
                                                                    .FontWeight
                                                                    .bold,
                                                                color: PdfColors
                                                                    .green900))),
                                                    pw.Padding(
                                                        padding: const pw
                                                            .EdgeInsets.all(6),
                                                        child: pw.Text('DISC',
                                                            style: pw.TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: pw
                                                                    .FontWeight
                                                                    .bold,
                                                                color: PdfColors
                                                                    .green900))),
                                                    pw.Padding(
                                                        padding: const pw
                                                            .EdgeInsets.all(6),
                                                        child: pw.Text('AMOUNT',
                                                            style: pw.TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: pw
                                                                    .FontWeight
                                                                    .bold,
                                                                color: PdfColors
                                                                    .green900))),
                                                  ],
                                                ),

                                                // Table Rows
                                                ...products
                                                    .map(
                                                        (p) => pw.TableRow(
                                                                children: [
                                                                  pw.Padding(
                                                                      padding: const pw
                                                                          .EdgeInsets.all(
                                                                          6),
                                                                      child: pw.Text(
                                                                          p.name,
                                                                          style: pw.TextStyle(fontSize: 11))),
                                                                  pw.Padding(
                                                                      padding: const pw
                                                                          .EdgeInsets.all(
                                                                          6),
                                                                      child: pw.Text(
                                                                          p.quantity
                                                                              .toString(),
                                                                          style:
                                                                              pw.TextStyle(fontSize: 11))),
                                                                  pw.Padding(
                                                                      padding: const pw
                                                                          .EdgeInsets.all(
                                                                          6),
                                                                      child: pw.Text(
                                                                          p.price.toStringAsFixed(
                                                                              2),
                                                                          style:
                                                                              pw.TextStyle(fontSize: 11))),
                                                                  pw.Padding(
                                                                      padding: const pw
                                                                          .EdgeInsets.all(
                                                                          6),
                                                                      child: pw.Text(
                                                                          p.discount.toStringAsFixed(
                                                                              2),
                                                                          style:
                                                                              pw.TextStyle(fontSize: 11))),
                                                                  pw.Padding(
                                                                      padding: const pw
                                                                          .EdgeInsets.all(
                                                                          6),
                                                                      child: pw.Text(
                                                                          ((p.discountType == DiscountType.perPiece) ? ((p.price - (p.discount ?? 0.0)) * p.quantity) : ((p.price * p.quantity) - (p.discount ?? 0.0))).toStringAsFixed(
                                                                              2),
                                                                          style:
                                                                              pw.TextStyle(fontSize: 11))),
                                                                ])),
                                              ],
                                            ),
                                            pw.SizedBox(height: 12),

                                            // Summary Information
                                            pw.Row(
                                              mainAxisAlignment: pw
                                                  .MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                pw.Text(
                                                    'Discount: ${discountController.text}',
                                                    style: pw.TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                        color:
                                                            PdfColors.grey700)),
                                                pw.Text(
                                                    'VAT: ${vatController.text}',
                                                    style: pw.TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            PdfColors.grey700)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                    break;

                                  case 'Classic':
                                    pdfContent = pw.DefaultTextStyle.merge(
                                      style: pw.TextStyle(
                                        lineSpacing: 1.8,
                                        font: pw.Font.courier(),
                                      ),
                                      child: pw.Container(
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(
                                              color: PdfColors.brown800,
                                              width: 2.5),
                                        ),
                                        padding: const pw.EdgeInsets.all(20),
                                        child: pw.Column(
                                          crossAxisAlignment:
                                              pw.CrossAxisAlignment.start,
                                          children: [
                                            // Header
                                            pw.Center(
                                              child: pw.Text(
                                                'CASH MEMO',
                                                style: pw.TextStyle(
                                                  fontSize: 26,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  letterSpacing: 1.5,
                                                  color: PdfColors.brown900,
                                                ),
                                              ),
                                            ),
                                            pw.SizedBox(height: 16),

                                            // Company Info
                                            pw.Text(
                                              'COMPANY: ${companyNameController.text.toUpperCase()}',
                                              style: pw.TextStyle(
                                                fontSize: 16,
                                                fontWeight: pw.FontWeight.bold,
                                                color: PdfColors.brown800,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                            pw.SizedBox(height: 12),

                                            // Customer Info
                                            pw.Text(
                                              'Customer: ${customerNameController.text}',
                                              style: pw.TextStyle(
                                                fontSize: 14,
                                                fontWeight: pw.FontWeight.bold,
                                              ),
                                            ),
                                            pw.Text(
                                                'Phone: ${phoneController.text}',
                                                style:
                                                    pw.TextStyle(fontSize: 13)),
                                            pw.Text(
                                                'Address: ${addressController.text}',
                                                style:
                                                    pw.TextStyle(fontSize: 13)),
                                            pw.SizedBox(height: 14),

                                            pw.Divider(
                                                thickness: 1.8,
                                                color: PdfColors.brown700),
                                            pw.SizedBox(height: 10),

                                            // Products Table
                                            pw.Table(
                                              border: pw.TableBorder.all(
                                                  color: PdfColors.brown700,
                                                  width: 1.2),
                                              columnWidths: {
                                                0: pw.FlexColumnWidth(3),
                                                1: pw.FlexColumnWidth(1),
                                                2: pw.FlexColumnWidth(1.5),
                                                3: pw.FlexColumnWidth(1.5),
                                                4: pw.FlexColumnWidth(2),
                                              },
                                              children: [
                                                // Table Header
                                                pw.TableRow(
                                                  decoration: pw.BoxDecoration(
                                                      color: PdfColors.brown50),
                                                  children: [
                                                    pw.Padding(
                                                      padding: const pw
                                                          .EdgeInsets.all(6),
                                                      child: pw.Text('PRODUCT',
                                                          style: pw.TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: pw
                                                                  .FontWeight
                                                                  .bold,
                                                              color: PdfColors
                                                                  .brown900)),
                                                    ),
                                                    pw.Padding(
                                                      padding: const pw
                                                          .EdgeInsets.all(6),
                                                      child: pw.Text('QTY',
                                                          style: pw.TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: pw
                                                                  .FontWeight
                                                                  .bold,
                                                              color: PdfColors
                                                                  .brown900)),
                                                    ),
                                                    pw.Padding(
                                                      padding: const pw
                                                          .EdgeInsets.all(6),
                                                      child: pw.Text('PRICE',
                                                          style: pw.TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: pw
                                                                  .FontWeight
                                                                  .bold,
                                                              color: PdfColors
                                                                  .brown900)),
                                                    ),
                                                    pw.Padding(
                                                      padding: const pw
                                                          .EdgeInsets.all(6),
                                                      child: pw.Text('DISC',
                                                          style: pw.TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: pw
                                                                  .FontWeight
                                                                  .bold,
                                                              color: PdfColors
                                                                  .brown900)),
                                                    ),
                                                    pw.Padding(
                                                      padding: const pw
                                                          .EdgeInsets.all(6),
                                                      child: pw.Text('TOTAL',
                                                          style: pw.TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: pw
                                                                  .FontWeight
                                                                  .bold,
                                                              color: PdfColors
                                                                  .brown900)),
                                                    ),
                                                  ],
                                                ),

                                                // Table Rows (with corrected AMOUNT logic)
                                                ...products.map(
                                                  (p) => pw.TableRow(
                                                    children: [
                                                      pw.Padding(
                                                        padding: const pw
                                                            .EdgeInsets.all(6),
                                                        child: pw.Text(p.name,
                                                            style: pw.TextStyle(
                                                                fontSize: 11)),
                                                      ),
                                                      pw.Padding(
                                                        padding: const pw
                                                            .EdgeInsets.all(6),
                                                        child: pw.Text(
                                                            p.quantity
                                                                .toString(),
                                                            style: pw.TextStyle(
                                                                fontSize: 11)),
                                                      ),
                                                      pw.Padding(
                                                        padding: const pw
                                                            .EdgeInsets.all(6),
                                                        child: pw.Text(
                                                            p.price
                                                                .toStringAsFixed(
                                                                    2),
                                                            style: pw.TextStyle(
                                                                fontSize: 11)),
                                                      ),
                                                      pw.Padding(
                                                        padding: const pw
                                                            .EdgeInsets.all(6),
                                                        child: pw.Text(
                                                            (p.discount ?? 0.0)
                                                                .toStringAsFixed(
                                                                    2),
                                                            style: pw.TextStyle(
                                                                fontSize: 11)),
                                                      ),
                                                      pw.Padding(
                                                        padding: const pw
                                                            .EdgeInsets.all(6),
                                                        child: pw.Text(
                                                          // Correct calculation:
                                                          // If perPiece: (price - discount) * qty
                                                          // If solidAmount: (price * qty) - discount
                                                          (() {
                                                            final discount =
                                                                p.discount ??
                                                                    0.0;
                                                            double rowTotal;
                                                            if (p.discountType ==
                                                                DiscountType
                                                                    .perPiece) {
                                                              rowTotal = (p
                                                                          .price -
                                                                      discount) *
                                                                  p.quantity;
                                                            } else {
                                                              // solid amount (fixed amount deducted once per line)
                                                              rowTotal = (p
                                                                          .price *
                                                                      p.quantity) -
                                                                  discount;
                                                            }
                                                            return rowTotal
                                                                .toStringAsFixed(
                                                                    2);
                                                          })(),
                                                          style: pw.TextStyle(
                                                              fontSize: 11),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),

                                            pw.SizedBox(height: 14),

                                            // Summary
                                            pw.Row(
                                              mainAxisAlignment: pw
                                                  .MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                pw.Text(
                                                    'Discount: ${discountController.text}',
                                                    style: pw.TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                        color: PdfColors
                                                            .brown700)),
                                                pw.Text(
                                                    'VAT: ${vatController.text}',
                                                    style: pw.TextStyle(
                                                        fontSize: 12,
                                                        color: PdfColors
                                                            .brown700)),
                                              ],
                                            ),

                                            pw.SizedBox(height: 8),

                                            // Total Calculation (consistent with row logic)
                                            pw.Center(
                                              child: pw.Text(
                                                (() {
                                                  double subtotal = products
                                                      .fold(0.0, (t, p) {
                                                    final discount =
                                                        p.discount ?? 0.0;
                                                    if (p.discountType ==
                                                        DiscountType.perPiece) {
                                                      return t +
                                                          ((p.price -
                                                                  discount) *
                                                              p.quantity);
                                                    } else {
                                                      // solid amount
                                                      return t +
                                                          ((p.price *
                                                                  p.quantity) -
                                                              discount);
                                                    }
                                                  });

                                                  double globalDiscount =
                                                      double.tryParse(
                                                              discountController
                                                                  .text) ??
                                                          0.0;
                                                  bool isPercent =
                                                      true; // keep your existing behaviour; change if necessary
                                                  double afterDiscount = isPercent
                                                      ? (subtotal *
                                                          (1 -
                                                              globalDiscount /
                                                                  100.0))
                                                      : (subtotal -
                                                          globalDiscount);

                                                  double vat = double.tryParse(
                                                          vatController.text) ??
                                                      0.0;
                                                  double total = afterDiscount *
                                                      (1 + vat / 100.0);
                                                  return 'Total: \$${total.toStringAsFixed(2)}';
                                                })(),
                                                style: pw.TextStyle(
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  fontSize: 18,
                                                  color: PdfColors.brown900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                    break;
                                  case 'Bordered':
                                    pdfContent = pw.DefaultTextStyle.merge(
                                      style: pw.TextStyle(
                                          lineSpacing: 2.0,
                                          font: pw.Font.helvetica()),
                                      child: pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.start,
                                        children: [
                                          // Header Banner
                                          pw.Container(
                                            color: PdfColors.blueGrey800,
                                            padding:
                                                const pw.EdgeInsets.symmetric(
                                                    vertical: 10),
                                            child: pw.Center(
                                              child: pw.Text(
                                                'BORDERED CASH MEMO',
                                                style: pw.TextStyle(
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  fontSize: 18,
                                                  color: PdfColors.white,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          pw.SizedBox(height: 16),

                                          // Company Information
                                          pw.Text(
                                            'COMPANY: ${companyNameController.text.toUpperCase()}',
                                            style: pw.TextStyle(
                                              fontSize: 16,
                                              fontWeight: pw.FontWeight.bold,
                                              color: PdfColors.blueGrey900,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                          pw.SizedBox(height: 12),

                                          // Customer Details
                                          pw.Text(
                                              'Customer: ${customerNameController.text}',
                                              style: pw.TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      pw.FontWeight.bold)),
                                          pw.Text(
                                              'Phone: ${phoneController.text}',
                                              style:
                                                  pw.TextStyle(fontSize: 13)),
                                          pw.Text(
                                              'Address: ${addressController.text}',
                                              style:
                                                  pw.TextStyle(fontSize: 13)),
                                          pw.SizedBox(height: 14),

                                          // Products Table (with AMOUNT column)
                                          pw.Table(
                                            border: pw.TableBorder.all(
                                                width: 2.5,
                                                color: PdfColors.blueGrey800),
                                            columnWidths: {
                                              0: pw.FlexColumnWidth(
                                                  3), // PRODUCT
                                              1: pw.FlexColumnWidth(1), // QTY
                                              2: pw.FlexColumnWidth(
                                                  1.5), // PRICE
                                              3: pw.FlexColumnWidth(
                                                  1.5), // DISC
                                              4: pw.FlexColumnWidth(
                                                  1.8), // AMOUNT
                                            },
                                            children: [
                                              // Table Header
                                              pw.TableRow(
                                                decoration: pw.BoxDecoration(
                                                    color:
                                                        PdfColors.blueGrey100),
                                                children: [
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            8),
                                                    child: pw.Text('PRODUCT',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight
                                                                .bold,
                                                            color: PdfColors
                                                                .blueGrey900)),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            8),
                                                    child: pw.Text('QTY',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight
                                                                .bold,
                                                            color: PdfColors
                                                                .blueGrey900)),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            8),
                                                    child: pw.Text('PRICE',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight
                                                                .bold,
                                                            color: PdfColors
                                                                .blueGrey900)),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            8),
                                                    child: pw.Text('DISC',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight
                                                                .bold,
                                                            color: PdfColors
                                                                .blueGrey900)),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            8),
                                                    child: pw.Text('AMOUNT',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight
                                                                .bold,
                                                            color: PdfColors
                                                                .blueGrey900)),
                                                  ),
                                                ],
                                              ),

                                              // Table Rows
                                              ...products.map((p) =>
                                                  pw.TableRow(children: [
                                                    pw.Padding(
                                                        padding: const pw
                                                            .EdgeInsets.all(8),
                                                        child: pw.Text(p.name,
                                                            style: pw.TextStyle(
                                                                fontSize: 11))),
                                                    pw.Padding(
                                                        padding: const pw
                                                            .EdgeInsets.all(8),
                                                        child: pw.Text(
                                                            p.quantity
                                                                .toString(),
                                                            style: pw.TextStyle(
                                                                fontSize: 11))),
                                                    pw.Padding(
                                                        padding: const pw
                                                            .EdgeInsets.all(8),
                                                        child: pw.Text(
                                                            p.price
                                                                .toStringAsFixed(
                                                                    2),
                                                            style: pw.TextStyle(
                                                                fontSize: 11))),
                                                    pw.Padding(
                                                        padding: const pw
                                                            .EdgeInsets.all(8),
                                                        child: pw.Text(
                                                            (p.discount ?? 0.0)
                                                                .toStringAsFixed(
                                                                    2),
                                                            style: pw.TextStyle(
                                                                fontSize: 11))),
                                                    pw.Padding(
                                                        padding: const pw
                                                            .EdgeInsets.all(8),
                                                        child: pw.Text(
                                                          // AMOUNT calculation: perPiece or solid amount
                                                          (() {
                                                            final discount =
                                                                p.discount ??
                                                                    0.0;
                                                            double rowAmount;
                                                            if (p.discountType ==
                                                                DiscountType
                                                                    .perPiece) {
                                                              rowAmount = (p
                                                                          .price -
                                                                      discount) *
                                                                  p.quantity;
                                                            } else {
                                                              // solid amount: subtract discount once per line
                                                              rowAmount = (p
                                                                          .price *
                                                                      p.quantity) -
                                                                  discount;
                                                            }
                                                            return rowAmount
                                                                .toStringAsFixed(
                                                                    2);
                                                          })(),
                                                          style: pw.TextStyle(
                                                              fontSize: 11),
                                                        )),
                                                  ])),
                                            ],
                                          ),
                                          pw.SizedBox(height: 16),

                                          // Summary Information
                                          pw.Row(
                                            mainAxisAlignment: pw
                                                .MainAxisAlignment.spaceBetween,
                                            children: [
                                              pw.Text(
                                                  'Discount: ${discountController.text}',
                                                  style: pw.TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          pw.FontWeight.bold,
                                                      color: PdfColors
                                                          .blueGrey700)),
                                              pw.Text(
                                                  'VAT: ${vatController.text}',
                                                  style: pw.TextStyle(
                                                      fontSize: 12,
                                                      color: PdfColors
                                                          .blueGrey700)),
                                            ],
                                          ),
                                          pw.SizedBox(height: 10),

                                          // Total Amount (uses AMOUNT per line)
                                          pw.Container(
                                            decoration: pw.BoxDecoration(
                                              border: pw.Border.all(
                                                  color: PdfColors.blueGrey800,
                                                  width: 2),
                                              borderRadius:
                                                  pw.BorderRadius.circular(4),
                                            ),
                                            padding:
                                                const pw.EdgeInsets.all(12),
                                            child: pw.Center(
                                              child: pw.Text(
                                                // calculate sum of row amounts, then apply global discount/VAT as before
                                                (() {
                                                  // sum per-line amounts using the same rules
                                                  double subtotal = products
                                                      .fold(0.0, (t, p) {
                                                    final discount =
                                                        p.discount ?? 0.0;
                                                    if (p.discountType ==
                                                        DiscountType.perPiece) {
                                                      return t +
                                                          ((p.price -
                                                                  discount) *
                                                              p.quantity);
                                                    } else {
                                                      return t +
                                                          ((p.price *
                                                                  p.quantity) -
                                                              discount);
                                                    }
                                                  });

                                                  double globalDiscount =
                                                      double.tryParse(
                                                              discountController
                                                                  .text) ??
                                                          0.0;
                                                  bool isPercent =
                                                      true; // keep existing behaviour; change if you allow selecting percent/amount
                                                  double afterDiscount = isPercent
                                                      ? (subtotal *
                                                          (1 -
                                                              globalDiscount /
                                                                  100.0))
                                                      : (subtotal -
                                                          globalDiscount);

                                                  double vat = double.tryParse(
                                                          vatController.text) ??
                                                      0.0;
                                                  double total = afterDiscount *
                                                      (1 + vat / 100.0);

                                                  return 'Total: \$' +
                                                      total.toStringAsFixed(2);
                                                })(),
                                                style: pw.TextStyle(
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    fontSize: 18,
                                                    color:
                                                        PdfColors.blueGrey900),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    break;

                                  case 'Bold Headings':
                                    pdfContent = pw.DefaultTextStyle.merge(
                                      style: pw.TextStyle(
                                        lineSpacing: 2.2,
                                        font: pw.Font.helveticaBold(),
                                      ),
                                      child: pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.start,
                                        children: [
                                          // Bold Header
                                          pw.Container(
                                            padding: const pw.EdgeInsets.all(16),
                                            decoration: pw.BoxDecoration(
                                              gradient: pw.LinearGradient(
                                                colors: [
                                                  PdfColors.red700,
                                                  PdfColors.red900
                                                ],
                                              ),
                                              borderRadius:
                                                  pw.BorderRadius.circular(8),
                                            ),
                                            child: pw.Center(
                                              child: pw.Text(
                                                'CASH MEMO',
                                                style: pw.TextStyle(
                                                  fontSize: 32,
                                                  fontWeight: pw.FontWeight.bold,
                                                  color: PdfColors.white,
                                                  letterSpacing: 2.0,
                                                ),
                                              ),
                                            ),
                                          ),
                                          pw.SizedBox(height: 20),

                                          // Company Section with Bold Header
                                          pw.Container(
                                            padding: const pw.EdgeInsets.all(10),
                                            decoration: pw.BoxDecoration(
                                              color: PdfColors.red50,
                                              borderRadius:
                                                  pw.BorderRadius.circular(6),
                                            ),
                                            child: pw.Column(
                                              crossAxisAlignment:
                                                  pw.CrossAxisAlignment.start,
                                              children: [
                                                pw.Text(
                                                  'COMPANY INFORMATION',
                                                  style: pw.TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    color: PdfColors.red900,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                                pw.SizedBox(height: 6),
                                                pw.Text(
                                                  companyNameController.text
                                                      .toUpperCase(),
                                                  style: pw.TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    color: PdfColors.red800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          pw.SizedBox(height: 16),

                                          // Customer Section with Bold Header
                                          pw.Container(
                                            padding: const pw.EdgeInsets.all(10),
                                            decoration: pw.BoxDecoration(
                                              color: PdfColors.grey100,
                                              borderRadius:
                                                  pw.BorderRadius.circular(6),
                                            ),
                                            child: pw.Column(
                                              crossAxisAlignment:
                                                  pw.CrossAxisAlignment.start,
                                              children: [
                                                pw.Text(
                                                  'CUSTOMER DETAILS',
                                                  style: pw.TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    color: PdfColors.grey900,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                                pw.SizedBox(height: 6),
                                                pw.Text(
                                                  'Customer: ${customerNameController.text}',
                                                  style: pw.TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          pw.FontWeight.bold),
                                                ),
                                                pw.Text(
                                                    'Phone: ${phoneController.text}',
                                                    style: pw.TextStyle(
                                                        fontSize: 12)),
                                                pw.Text(
                                                    'Address: ${addressController.text}',
                                                    style: pw.TextStyle(
                                                        fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          pw.SizedBox(height: 16),

                                          // Products Section Header
                                          pw.Text(
                                            'ITEMS',
                                            style: pw.TextStyle(
                                              fontSize: 16,
                                              fontWeight: pw.FontWeight.bold,
                                              color: PdfColors.red900,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          pw.SizedBox(height: 8),

                                          // Products Table
                                          pw.Table(
                                            border: pw.TableBorder.all(
                                                width: 2, color: PdfColors.red700),
                                            columnWidths: {
                                              0: pw.FlexColumnWidth(3),
                                              1: pw.FlexColumnWidth(1),
                                              2: pw.FlexColumnWidth(1.5),
                                              3: pw.FlexColumnWidth(1.5),
                                              4: pw.FlexColumnWidth(2),
                                            },
                                            children: [
                                              // Table Header
                                              pw.TableRow(
                                                decoration: pw.BoxDecoration(
                                                    color: PdfColors.red700),
                                                children: [
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(8),
                                                    child: pw.Text('PRODUCT',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight.bold,
                                                            color:
                                                                PdfColors.white)),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(8),
                                                    child: pw.Text('QTY',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight.bold,
                                                            color:
                                                                PdfColors.white)),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(8),
                                                    child: pw.Text('PRICE',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight.bold,
                                                            color:
                                                                PdfColors.white)),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(8),
                                                    child: pw.Text('DISC',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight.bold,
                                                            color:
                                                                PdfColors.white)),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(8),
                                                    child: pw.Text('AMOUNT',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight.bold,
                                                            color:
                                                                PdfColors.white)),
                                                  ),
                                                ],
                                              ),
                                              // Table Rows
                                              ...products.map((p) => pw.TableRow(
                                                      decoration: pw.BoxDecoration(
                                                          color:
                                                              PdfColors.red50),
                                                      children: [
                                                        pw.Padding(
                                                          padding: const pw
                                                              .EdgeInsets.all(8),
                                                          child: pw.Text(p.name,
                                                              style: pw.TextStyle(
                                                                  fontSize: 11,
                                                                  fontWeight: pw
                                                                      .FontWeight
                                                                      .bold)),
                                                        ),
                                                        pw.Padding(
                                                          padding: const pw
                                                              .EdgeInsets.all(8),
                                                          child: pw.Text(
                                                              p.quantity
                                                                  .toString(),
                                                              style: pw.TextStyle(
                                                                  fontSize: 11)),
                                                        ),
                                                        pw.Padding(
                                                          padding: const pw
                                                              .EdgeInsets.all(8),
                                                          child: pw.Text(
                                                              p.price
                                                                  .toStringAsFixed(
                                                                      2),
                                                              style: pw.TextStyle(
                                                                  fontSize: 11)),
                                                        ),
                                                        pw.Padding(
                                                          padding: const pw
                                                              .EdgeInsets.all(8),
                                                          child: pw.Text(
                                                              (p.discount ?? 0.0)
                                                                  .toStringAsFixed(
                                                                      2),
                                                              style: pw.TextStyle(
                                                                  fontSize: 11)),
                                                        ),
                                                        pw.Padding(
                                                          padding: const pw
                                                              .EdgeInsets.all(8),
                                                          child: pw.Text(
                                                            (() {
                                                              final discount =
                                                                  p.discount ??
                                                                      0.0;
                                                              if (p.discountType ==
                                                                  DiscountType
                                                                      .perPiece) {
                                                                return ((p.price -
                                                                            discount) *
                                                                        p.quantity)
                                                                    .toStringAsFixed(
                                                                        2);
                                                              } else {
                                                                return ((p.price *
                                                                            p.quantity) -
                                                                        discount)
                                                                    .toStringAsFixed(
                                                                        2);
                                                              }
                                                            })(),
                                                            style: pw.TextStyle(
                                                                fontSize: 11,
                                                                fontWeight: pw
                                                                    .FontWeight
                                                                    .bold),
                                                          ),
                                                        ),
                                                      ])),
                                            ],
                                          ),
                                          pw.SizedBox(height: 16),

                                          // Summary Section
                                          pw.Container(
                                            padding:
                                                const pw.EdgeInsets.all(12),
                                            decoration: pw.BoxDecoration(
                                              color: PdfColors.grey100,
                                              borderRadius:
                                                  pw.BorderRadius.circular(6),
                                            ),
                                            child: pw.Column(
                                              crossAxisAlignment:
                                                  pw.CrossAxisAlignment.start,
                                              children: [
                                                pw.Text(
                                                  'SUMMARY',
                                                  style: pw.TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                                pw.SizedBox(height: 8),
                                                pw.Row(
                                                  mainAxisAlignment: pw
                                                      .MainAxisAlignment
                                                      .spaceBetween,
                                                  children: [
                                                    pw.Text(
                                                        'Discount: ${discountController.text}',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight
                                                                .bold)),
                                                    pw.Text(
                                                        'VAT: ${vatController.text}',
                                                        style: pw.TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: pw
                                                                .FontWeight
                                                                .bold)),
                                                  ],
                                                ),
                                                pw.Divider(thickness: 2),
                                                pw.Center(
                                                  child: pw.Text(
                                                    'TOTAL: \$' +
                                                        (() {
                                                          double subtotal =
                                                              products.fold(0.0,
                                                                  (t, p) {
                                                            final discount =
                                                                p.discount ?? 0.0;
                                                            if (p.discountType ==
                                                                DiscountType
                                                                    .perPiece) {
                                                              return t +
                                                                  ((p.price -
                                                                          discount) *
                                                                      p.quantity);
                                                            } else {
                                                              return t +
                                                                  ((p.price *
                                                                          p.quantity) -
                                                                      discount);
                                                            }
                                                          });
                                                          double globalDiscount =
                                                              double.tryParse(
                                                                      discountController
                                                                          .text) ??
                                                                  0.0;
                                                          double afterDiscount =
                                                              subtotal *
                                                                  (1 -
                                                                      globalDiscount /
                                                                          100.0);
                                                          double vat =
                                                              double.tryParse(
                                                                      vatController
                                                                          .text) ??
                                                                  0.0;
                                                          double total =
                                                              afterDiscount *
                                                                  (1 +
                                                                      vat /
                                                                          100.0);
                                                          return total
                                                              .toStringAsFixed(2);
                                                        })(),
                                                    style: pw.TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          pw.FontWeight.bold,
                                                      color: PdfColors.red900,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    break;

                                  case 'Minimalist Elegance':
                                    pdfContent = pw.DefaultTextStyle.merge(
                                      style: pw.TextStyle(
                                        lineSpacing: 2.5,
                                        font: pw.Font.helvetica(),
                                      ),
                                      child: pw.Container(
                                        padding: const pw.EdgeInsets.all(24),
                                        child: pw.Column(
                                          crossAxisAlignment:
                                              pw.CrossAxisAlignment.start,
                                          children: [
                                            // Minimalist Header
                                            pw.Text(
                                              'Cash Memo',
                                              style: pw.TextStyle(
                                                fontSize: 36,
                                                fontWeight: pw.FontWeight.normal,
                                                color: PdfColors.grey800,
                                                letterSpacing: 3.0,
                                              ),
                                            ),
                                            pw.Container(
                                              width: 100,
                                              height: 2,
                                              color: PdfColors.grey800,
                                              margin: const pw.EdgeInsets.only(
                                                  top: 8, bottom: 24),
                                            ),

                                            // Company Info - Minimalist
                                            pw.Text(
                                              companyNameController.text,
                                              style: pw.TextStyle(
                                                fontSize: 18,
                                                fontWeight: pw.FontWeight.bold,
                                                color: PdfColors.grey900,
                                              ),
                                            ),
                                            pw.SizedBox(height: 32),

                                            // Customer Info - Clean Layout
                                            pw.Row(
                                              crossAxisAlignment:
                                                  pw.CrossAxisAlignment.start,
                                              children: [
                                                pw.Expanded(
                                                  child: pw.Column(
                                                    crossAxisAlignment: pw
                                                        .CrossAxisAlignment.start,
                                                    children: [
                                                      pw.Text('To',
                                                          style: pw.TextStyle(
                                                            fontSize: 10,
                                                            color:
                                                                PdfColors.grey600,
                                                            letterSpacing: 1.5,
                                                          )),
                                                      pw.SizedBox(height: 4),
                                                      pw.Text(
                                                          customerNameController
                                                              .text,
                                                          style: pw.TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: pw
                                                                  .FontWeight
                                                                  .bold)),
                                                      pw.Text(
                                                          phoneController.text,
                                                          style: pw.TextStyle(
                                                              fontSize: 12,
                                                              color: PdfColors
                                                                  .grey700)),
                                                      pw.Text(
                                                          addressController.text,
                                                          style: pw.TextStyle(
                                                              fontSize: 12,
                                                              color: PdfColors
                                                                  .grey700)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            pw.SizedBox(height: 32),

                                            // Products - Minimalist Table
                                            ...products.map((p) => pw.Container(
                                                  padding: const pw.EdgeInsets
                                                      .symmetric(vertical: 8),
                                                  decoration: pw.BoxDecoration(
                                                    border: pw.Border(
                                                      bottom: pw.BorderSide(
                                                          color:
                                                              PdfColors.grey300,
                                                          width: 1),
                                                    ),
                                                  ),
                                                  child: pw.Row(
                                                    mainAxisAlignment: pw
                                                        .MainAxisAlignment
                                                        .spaceBetween,
                                                    children: [
                                                      pw.Expanded(
                                                        flex: 3,
                                                        child: pw.Text(p.name,
                                                            style: pw.TextStyle(
                                                                fontSize: 13)),
                                                      ),
                                                      pw.Expanded(
                                                        flex: 1,
                                                        child: pw.Text(
                                                            '×${p.quantity}',
                                                            style: pw.TextStyle(
                                                              fontSize: 12,
                                                              color: PdfColors
                                                                  .grey600,
                                                            ),
                                                            textAlign: pw
                                                                .TextAlign
                                                                .center),
                                                      ),
                                                      pw.Expanded(
                                                        flex: 1,
                                                        child: pw.Text(
                                                            '\$${p.price.toStringAsFixed(2)}',
                                                            style: pw.TextStyle(
                                                                fontSize: 12),
                                                            textAlign: pw
                                                                .TextAlign
                                                                .right),
                                                      ),
                                                      pw.SizedBox(width: 16),
                                                      pw.Expanded(
                                                        flex: 1,
                                                        child: pw.Text(
                                                          '\$' +
                                                              (() {
                                                                final discount =
                                                                    p.discount ??
                                                                        0.0;
                                                                if (p.discountType ==
                                                                    DiscountType
                                                                        .perPiece) {
                                                                  return ((p.price -
                                                                              discount) *
                                                                          p.quantity)
                                                                      .toStringAsFixed(
                                                                          2);
                                                                } else {
                                                                  return ((p.price *
                                                                              p.quantity) -
                                                                          discount)
                                                                      .toStringAsFixed(
                                                                          2);
                                                                }
                                                              })(),
                                                          style: pw.TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: pw
                                                                  .FontWeight
                                                                  .bold),
                                                          textAlign:
                                                              pw.TextAlign.right,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )),

                                            pw.SizedBox(height: 24),

                                            // Total Section
                                            pw.Row(
                                              mainAxisAlignment:
                                                  pw.MainAxisAlignment.end,
                                              children: [
                                                pw.Column(
                                                  crossAxisAlignment: pw
                                                      .CrossAxisAlignment.end,
                                                  children: [
                                                    pw.Text('Total',
                                                        style: pw.TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              PdfColors.grey600,
                                                          letterSpacing: 1.5,
                                                        )),
                                                    pw.SizedBox(height: 4),
                                                    pw.Text(
                                                      '\$' +
                                                          (() {
                                                            double subtotal =
                                                                products.fold(0.0,
                                                                    (t, p) {
                                                              final discount =
                                                                  p.discount ??
                                                                      0.0;
                                                              if (p.discountType ==
                                                                  DiscountType
                                                                      .perPiece) {
                                                                return t +
                                                                    ((p.price -
                                                                            discount) *
                                                                        p.quantity);
                                                              } else {
                                                                return t +
                                                                    ((p.price *
                                                                            p.quantity) -
                                                                        discount);
                                                              }
                                                            });
                                                            double
                                                                globalDiscount =
                                                                double.tryParse(
                                                                        discountController
                                                                            .text) ??
                                                                    0.0;
                                                            double
                                                                afterDiscount =
                                                                subtotal *
                                                                    (1 -
                                                                        globalDiscount /
                                                                            100.0);
                                                            double vat = double
                                                                    .tryParse(
                                                                        vatController
                                                                            .text) ??
                                                                0.0;
                                                            double total =
                                                                afterDiscount *
                                                                    (1 +
                                                                        vat /
                                                                            100.0);
                                                            return total
                                                                .toStringAsFixed(
                                                                    2);
                                                          })(),
                                                      style: pw.TextStyle(
                                                        fontSize: 32,
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                        color: PdfColors.grey900,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                    break;

                                  case 'Professional Invoice':
                                    pdfContent = pw.DefaultTextStyle.merge(
                                      style: pw.TextStyle(
                                        lineSpacing: 2.0,
                                        font: pw.Font.helvetica(),
                                      ),
                                      child: pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.start,
                                        children: [
                                          // Professional Header with Two Columns
                                          pw.Row(
                                            mainAxisAlignment: pw
                                                .MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                pw.CrossAxisAlignment.start,
                                            children: [
                                              // Left: Company Info
                                              pw.Column(
                                                crossAxisAlignment: pw
                                                    .CrossAxisAlignment.start,
                                                children: [
                                                  pw.Text(
                                                    companyNameController.text,
                                                    style: pw.TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          pw.FontWeight.bold,
                                                      color: PdfColors.blue900,
                                                    ),
                                                  ),
                                                  pw.SizedBox(height: 4),
                                                  pw.Container(
                                                    width: 60,
                                                    height: 3,
                                                    color: PdfColors.blue700,
                                                  ),
                                                ],
                                              ),
                                              // Right: Invoice Label
                                              pw.Column(
                                                crossAxisAlignment: pw
                                                    .CrossAxisAlignment.end,
                                                children: [
                                                  pw.Text(
                                                    'INVOICE',
                                                    style: pw.TextStyle(
                                                      fontSize: 32,
                                                      fontWeight:
                                                          pw.FontWeight.bold,
                                                      color: PdfColors.blue900,
                                                      letterSpacing: 2.0,
                                                    ),
                                                  ),
                                                  pw.Text(
                                                    'Date: ${DateTime.now().toString().split(' ')[0]}',
                                                    style: pw.TextStyle(
                                                      fontSize: 11,
                                                      color: PdfColors.grey700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          pw.SizedBox(height: 24),

                                          // Customer Info Section
                                          pw.Container(
                                            padding:
                                                const pw.EdgeInsets.all(12),
                                            decoration: pw.BoxDecoration(
                                              color: PdfColors.blue50,
                                              borderRadius:
                                                  pw.BorderRadius.circular(6),
                                              border: pw.Border(
                                                left: pw.BorderSide(
                                                    color: PdfColors.blue700,
                                                    width: 4),
                                              ),
                                            ),
                                            child: pw.Column(
                                              crossAxisAlignment: pw
                                                  .CrossAxisAlignment.start,
                                              children: [
                                                pw.Text(
                                                  'BILL TO:',
                                                  style: pw.TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    color: PdfColors.blue900,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                                pw.SizedBox(height: 6),
                                                pw.Text(
                                                  customerNameController.text,
                                                  style: pw.TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                  ),
                                                ),
                                                pw.Text(
                                                  phoneController.text,
                                                  style: pw.TextStyle(
                                                      fontSize: 12,
                                                      color: PdfColors.grey700),
                                                ),
                                                pw.Text(
                                                  addressController.text,
                                                  style: pw.TextStyle(
                                                      fontSize: 12,
                                                      color: PdfColors.grey700),
                                                ),
                                              ],
                                            ),
                                          ),
                                          pw.SizedBox(height: 20),

                                          // Products Table
                                          pw.Table(
                                            border: pw.TableBorder.symmetric(
                                              inside: pw.BorderSide(
                                                  color: PdfColors.grey300,
                                                  width: 1),
                                              outside: pw.BorderSide(
                                                  color: PdfColors.blue700,
                                                  width: 2),
                                            ),
                                            columnWidths: {
                                              0: pw.FlexColumnWidth(3),
                                              1: pw.FlexColumnWidth(1),
                                              2: pw.FlexColumnWidth(1.5),
                                              3: pw.FlexColumnWidth(1.5),
                                              4: pw.FlexColumnWidth(2),
                                            },
                                            children: [
                                              // Header
                                              pw.TableRow(
                                                decoration: pw.BoxDecoration(
                                                    color: PdfColors.blue700),
                                                children: [
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            10),
                                                    child: pw.Text('DESCRIPTION',
                                                        style: pw.TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              pw.FontWeight.bold,
                                                          color: PdfColors.white,
                                                          letterSpacing: 0.8,
                                                        )),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            10),
                                                    child: pw.Text('QTY',
                                                        style: pw.TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              pw.FontWeight.bold,
                                                          color: PdfColors.white,
                                                          letterSpacing: 0.8,
                                                        )),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            10),
                                                    child: pw.Text('RATE',
                                                        style: pw.TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              pw.FontWeight.bold,
                                                          color: PdfColors.white,
                                                          letterSpacing: 0.8,
                                                        )),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            10),
                                                    child: pw.Text('DISC',
                                                        style: pw.TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              pw.FontWeight.bold,
                                                          color: PdfColors.white,
                                                          letterSpacing: 0.8,
                                                        )),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            10),
                                                    child: pw.Text('AMOUNT',
                                                        style: pw.TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              pw.FontWeight.bold,
                                                          color: PdfColors.white,
                                                          letterSpacing: 0.8,
                                                        ),
                                                        textAlign:
                                                            pw.TextAlign.right),
                                                  ),
                                                ],
                                              ),
                                              // Products
                                              ...products.asMap().entries.map(
                                                  (entry) => pw.TableRow(
                                                        decoration:
                                                            pw.BoxDecoration(
                                                          color: entry.key % 2 ==
                                                                  0
                                                              ? PdfColors.white
                                                              : PdfColors.blue50,
                                                        ),
                                                        children: [
                                                          pw.Padding(
                                                            padding: const pw
                                                                .EdgeInsets.all(
                                                                10),
                                                            child: pw.Text(
                                                                entry.value.name,
                                                                style: pw.TextStyle(
                                                                    fontSize:
                                                                        11)),
                                                          ),
                                                          pw.Padding(
                                                            padding: const pw
                                                                .EdgeInsets.all(
                                                                10),
                                                            child: pw.Text(
                                                                entry.value
                                                                    .quantity
                                                                    .toString(),
                                                                style: pw.TextStyle(
                                                                    fontSize:
                                                                        11)),
                                                          ),
                                                          pw.Padding(
                                                            padding: const pw
                                                                .EdgeInsets.all(
                                                                10),
                                                            child: pw.Text(
                                                                '\$${entry.value.price.toStringAsFixed(2)}',
                                                                style: pw.TextStyle(
                                                                    fontSize:
                                                                        11)),
                                                          ),
                                                          pw.Padding(
                                                            padding: const pw
                                                                .EdgeInsets.all(
                                                                10),
                                                            child: pw.Text(
                                                                '\$${(entry.value.discount ?? 0.0).toStringAsFixed(2)}',
                                                                style: pw.TextStyle(
                                                                    fontSize:
                                                                        11)),
                                                          ),
                                                          pw.Padding(
                                                            padding: const pw
                                                                .EdgeInsets.all(
                                                                10),
                                                            child: pw.Text(
                                                              '\$' +
                                                                  (() {
                                                                    final p =
                                                                        entry
                                                                            .value;
                                                                    final discount =
                                                                        p.discount ??
                                                                            0.0;
                                                                    if (p.discountType ==
                                                                        DiscountType
                                                                            .perPiece) {
                                                                      return ((p.price -
                                                                                  discount) *
                                                                              p.quantity)
                                                                          .toStringAsFixed(
                                                                              2);
                                                                    } else {
                                                                      return ((p.price *
                                                                                  p.quantity) -
                                                                              discount)
                                                                          .toStringAsFixed(
                                                                              2);
                                                                    }
                                                                  })(),
                                                              style: pw.TextStyle(
                                                                  fontSize: 11,
                                                                  fontWeight: pw
                                                                      .FontWeight
                                                                      .bold),
                                                              textAlign: pw
                                                                  .TextAlign
                                                                  .right,
                                                            ),
                                                          ),
                                                        ],
                                                      )),
                                            ],
                                          ),
                                          pw.SizedBox(height: 16),

                                          // Summary
                                          pw.Row(
                                            mainAxisAlignment: pw
                                                .MainAxisAlignment.end,
                                            children: [
                                              pw.Container(
                                                width: 250,
                                                padding:
                                                    const pw.EdgeInsets.all(12),
                                                decoration: pw.BoxDecoration(
                                                  color: PdfColors.blue50,
                                                  borderRadius:
                                                      pw.BorderRadius.circular(
                                                          6),
                                                ),
                                                child: pw.Column(
                                                  children: [
                                                    pw.Row(
                                                      mainAxisAlignment: pw
                                                          .MainAxisAlignment
                                                          .spaceBetween,
                                                      children: [
                                                        pw.Text('Subtotal:',
                                                            style: pw.TextStyle(
                                                                fontSize: 11)),
                                                        pw.Text(
                                                            '\$' +
                                                                products
                                                                    .fold(0.0,
                                                                        (t, p) {
                                                                      final discount =
                                                                          p.discount ??
                                                                              0.0;
                                                                      if (p.discountType ==
                                                                          DiscountType
                                                                              .perPiece) {
                                                                        return t +
                                                                            ((p.price - discount) *
                                                                                p.quantity);
                                                                      } else {
                                                                        return t +
                                                                            ((p.price * p.quantity) -
                                                                                discount);
                                                                      }
                                                                    }).toStringAsFixed(2),
                                                            style: pw.TextStyle(
                                                                fontSize: 11)),
                                                      ],
                                                    ),
                                                    pw.Row(
                                                      mainAxisAlignment: pw
                                                          .MainAxisAlignment
                                                          .spaceBetween,
                                                      children: [
                                                        pw.Text(
                                                            'Discount (${discountController.text}%):',
                                                            style: pw.TextStyle(
                                                                fontSize: 11)),
                                                        pw.Text(
                                                            '\$' +
                                                                (() {
                                                                  double subtotal =
                                                                      products.fold(
                                                                          0.0,
                                                                          (t, p) {
                                                                    final discount =
                                                                        p.discount ??
                                                                            0.0;
                                                                    if (p.discountType ==
                                                                        DiscountType
                                                                            .perPiece) {
                                                                      return t +
                                                                          ((p.price - discount) *
                                                                              p.quantity);
                                                                    } else {
                                                                      return t +
                                                                          ((p.price * p.quantity) -
                                                                              discount);
                                                                    }
                                                                  });
                                                                  double discount = double.tryParse(
                                                                          discountController
                                                                              .text) ??
                                                                      0.0;
                                                                  return (subtotal *
                                                                          discount /
                                                                          100.0)
                                                                      .toStringAsFixed(
                                                                          2);
                                                                })(),
                                                            style: pw.TextStyle(
                                                                fontSize: 11)),
                                                      ],
                                                    ),
                                                    pw.Row(
                                                      mainAxisAlignment: pw
                                                          .MainAxisAlignment
                                                          .spaceBetween,
                                                      children: [
                                                        pw.Text(
                                                            'VAT (${vatController.text}%):',
                                                            style: pw.TextStyle(
                                                                fontSize: 11)),
                                                        pw.Text(
                                                            '\$' +
                                                                (() {
                                                                  double subtotal =
                                                                      products.fold(
                                                                          0.0,
                                                                          (t, p) {
                                                                    final discount =
                                                                        p.discount ??
                                                                            0.0;
                                                                    if (p.discountType ==
                                                                        DiscountType
                                                                            .perPiece) {
                                                                      return t +
                                                                          ((p.price - discount) *
                                                                              p.quantity);
                                                                    } else {
                                                                      return t +
                                                                          ((p.price * p.quantity) -
                                                                              discount);
                                                                    }
                                                                  });
                                                                  double discount = double.tryParse(
                                                                          discountController
                                                                              .text) ??
                                                                      0.0;
                                                                  double
                                                                      afterDiscount =
                                                                      subtotal *
                                                                          (1 -
                                                                              discount /
                                                                                  100.0);
                                                                  double vat = double.tryParse(
                                                                          vatController
                                                                              .text) ??
                                                                      0.0;
                                                                  return (afterDiscount *
                                                                          vat /
                                                                          100.0)
                                                                      .toStringAsFixed(
                                                                          2);
                                                                })(),
                                                            style: pw.TextStyle(
                                                                fontSize: 11)),
                                                      ],
                                                    ),
                                                    pw.Divider(thickness: 2),
                                                    pw.Row(
                                                      mainAxisAlignment: pw
                                                          .MainAxisAlignment
                                                          .spaceBetween,
                                                      children: [
                                                        pw.Text('TOTAL:',
                                                            style: pw.TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: pw
                                                                  .FontWeight
                                                                  .bold,
                                                            )),
                                                        pw.Text(
                                                          '\$' +
                                                              (() {
                                                                double subtotal =
                                                                    products.fold(
                                                                        0.0,
                                                                        (t, p) {
                                                                  final discount =
                                                                      p.discount ??
                                                                          0.0;
                                                                  if (p.discountType ==
                                                                      DiscountType
                                                                          .perPiece) {
                                                                    return t +
                                                                        ((p.price -
                                                                                discount) *
                                                                            p.quantity);
                                                                  } else {
                                                                    return t +
                                                                        ((p.price *
                                                                                p.quantity) -
                                                                            discount);
                                                                  }
                                                                });
                                                                double
                                                                    globalDiscount =
                                                                    double.tryParse(
                                                                            discountController
                                                                                .text) ??
                                                                        0.0;
                                                                double
                                                                    afterDiscount =
                                                                    subtotal *
                                                                        (1 -
                                                                            globalDiscount /
                                                                                100.0);
                                                                double vat = double
                                                                        .tryParse(
                                                                            vatController
                                                                                .text) ??
                                                                    0.0;
                                                                double total =
                                                                    afterDiscount *
                                                                        (1 +
                                                                            vat /
                                                                                100.0);
                                                                return total
                                                                    .toStringAsFixed(
                                                                        2);
                                                              })(),
                                                          style: pw.TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: pw
                                                                .FontWeight
                                                                .bold,
                                                            color:
                                                                PdfColors.blue900,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                    break;

                                  case 'Creative Gradient':
                                    pdfContent = pw.DefaultTextStyle.merge(
                                      style: pw.TextStyle(
                                        lineSpacing: 2.0,
                                        font: pw.Font.helvetica(),
                                      ),
                                      child: pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.start,
                                        children: [
                                          // Gradient-style Header
                                          pw.Container(
                                            decoration: pw.BoxDecoration(
                                              gradient: pw.LinearGradient(
                                                colors: [
                                                  PdfColors.purple700,
                                                  PdfColors.pink600
                                                ],
                                              ),
                                              borderRadius:
                                                  pw.BorderRadius.circular(10),
                                            ),
                                            padding:
                                                const pw.EdgeInsets.all(20),
                                            child: pw.Column(
                                              crossAxisAlignment: pw
                                                  .CrossAxisAlignment.start,
                                              children: [
                                                pw.Text(
                                                  'CASH MEMO',
                                                  style: pw.TextStyle(
                                                    fontSize: 28,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    color: PdfColors.white,
                                                    letterSpacing: 2.0,
                                                  ),
                                                ),
                                                pw.SizedBox(height: 8),
                                                pw.Text(
                                                  companyNameController.text
                                                      .toUpperCase(),
                                                  style: pw.TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    color: PdfColors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          pw.SizedBox(height: 20),

                                          // Customer Info Card
                                          pw.Container(
                                            padding:
                                                const pw.EdgeInsets.all(12),
                                            decoration: pw.BoxDecoration(
                                              border: pw.Border.all(
                                                  color: PdfColors.purple300,
                                                  width: 2),
                                              borderRadius:
                                                  pw.BorderRadius.circular(8),
                                            ),
                                            child: pw.Column(
                                              crossAxisAlignment: pw
                                                  .CrossAxisAlignment.start,
                                              children: [
                                                pw.Text(
                                                  'CUSTOMER DETAILS',
                                                  style: pw.TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    color: PdfColors.purple700,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                                pw.Divider(
                                                    color: PdfColors.purple300),
                                                pw.Text(
                                                  customerNameController.text,
                                                  style: pw.TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                  ),
                                                ),
                                                pw.Text(
                                                    'Phone: ${phoneController.text}',
                                                    style: pw.TextStyle(
                                                        fontSize: 12)),
                                                pw.Text(
                                                    'Address: ${addressController.text}',
                                                    style: pw.TextStyle(
                                                        fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          pw.SizedBox(height: 20),

                                          // Products with Modern Style
                                          pw.Table(
                                            border: pw.TableBorder(
                                              horizontalInside: pw.BorderSide(
                                                  color: PdfColors.purple100,
                                                  width: 1),
                                              verticalInside: pw.BorderSide(
                                                  color: PdfColors.purple100,
                                                  width: 1),
                                            ),
                                            columnWidths: {
                                              0: pw.FlexColumnWidth(3),
                                              1: pw.FlexColumnWidth(1),
                                              2: pw.FlexColumnWidth(1.5),
                                              3: pw.FlexColumnWidth(1.5),
                                              4: pw.FlexColumnWidth(2),
                                            },
                                            children: [
                                              // Header
                                              pw.TableRow(
                                                decoration: pw.BoxDecoration(
                                                  gradient: pw.LinearGradient(
                                                    colors: [
                                                      PdfColors.purple100,
                                                      PdfColors.pink100
                                                    ],
                                                  ),
                                                ),
                                                children: [
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            10),
                                                    child: pw.Text('ITEM',
                                                        style: pw.TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              pw.FontWeight.bold,
                                                          color:
                                                              PdfColors.purple900,
                                                        )),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            10),
                                                    child: pw.Text('QTY',
                                                        style: pw.TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              pw.FontWeight.bold,
                                                          color:
                                                              PdfColors.purple900,
                                                        )),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            10),
                                                    child: pw.Text('PRICE',
                                                        style: pw.TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              pw.FontWeight.bold,
                                                          color:
                                                              PdfColors.purple900,
                                                        )),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            10),
                                                    child: pw.Text('DISC',
                                                        style: pw.TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              pw.FontWeight.bold,
                                                          color:
                                                              PdfColors.purple900,
                                                        )),
                                                  ),
                                                  pw.Padding(
                                                    padding:
                                                        const pw.EdgeInsets.all(
                                                            10),
                                                    child: pw.Text('TOTAL',
                                                        style: pw.TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              pw.FontWeight.bold,
                                                          color:
                                                              PdfColors.purple900,
                                                        ),
                                                        textAlign:
                                                            pw.TextAlign.right),
                                                  ),
                                                ],
                                              ),
                                              // Products
                                              ...products.map(
                                                (p) => pw.TableRow(
                                                  children: [
                                                    pw.Padding(
                                                      padding: const pw
                                                          .EdgeInsets.all(10),
                                                      child: pw.Text(p.name,
                                                          style: pw.TextStyle(
                                                              fontSize: 11)),
                                                    ),
                                                    pw.Padding(
                                                      padding: const pw
                                                          .EdgeInsets.all(10),
                                                      child: pw.Text(
                                                          p.quantity.toString(),
                                                          style: pw.TextStyle(
                                                              fontSize: 11)),
                                                    ),
                                                    pw.Padding(
                                                      padding: const pw
                                                          .EdgeInsets.all(10),
                                                      child: pw.Text(
                                                          '\$${p.price.toStringAsFixed(2)}',
                                                          style: pw.TextStyle(
                                                              fontSize: 11)),
                                                    ),
                                                    pw.Padding(
                                                      padding: const pw
                                                          .EdgeInsets.all(10),
                                                      child: pw.Text(
                                                          '\$${(p.discount ?? 0.0).toStringAsFixed(2)}',
                                                          style: pw.TextStyle(
                                                              fontSize: 11)),
                                                    ),
                                                    pw.Padding(
                                                      padding: const pw
                                                          .EdgeInsets.all(10),
                                                      child: pw.Text(
                                                        '\$' +
                                                            (() {
                                                              final discount =
                                                                  p.discount ??
                                                                      0.0;
                                                              if (p.discountType ==
                                                                  DiscountType
                                                                      .perPiece) {
                                                                return ((p.price -
                                                                            discount) *
                                                                        p.quantity)
                                                                    .toStringAsFixed(
                                                                        2);
                                                              } else {
                                                                return ((p.price *
                                                                            p.quantity) -
                                                                        discount)
                                                                    .toStringAsFixed(
                                                                        2);
                                                              }
                                                            })(),
                                                        style: pw.TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: pw
                                                                .FontWeight
                                                                .bold),
                                                        textAlign:
                                                            pw.TextAlign.right,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          pw.SizedBox(height: 20),

                                          // Grand Total with Gradient
                                          pw.Container(
                                            decoration: pw.BoxDecoration(
                                              gradient: pw.LinearGradient(
                                                colors: [
                                                  PdfColors.purple700,
                                                  PdfColors.pink600
                                                ],
                                              ),
                                              borderRadius:
                                                  pw.BorderRadius.circular(8),
                                            ),
                                            padding:
                                                const pw.EdgeInsets.all(16),
                                            child: pw.Row(
                                              mainAxisAlignment: pw
                                                  .MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                pw.Column(
                                                  crossAxisAlignment: pw
                                                      .CrossAxisAlignment.start,
                                                  children: [
                                                    pw.Text(
                                                        'Discount: ${discountController.text}%',
                                                        style: pw.TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              PdfColors.white,
                                                        )),
                                                    pw.Text(
                                                        'VAT: ${vatController.text}%',
                                                        style: pw.TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              PdfColors.white,
                                                        )),
                                                  ],
                                                ),
                                                pw.Column(
                                                  crossAxisAlignment: pw
                                                      .CrossAxisAlignment.end,
                                                  children: [
                                                    pw.Text('TOTAL',
                                                        style: pw.TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              PdfColors.white,
                                                          letterSpacing: 1.0,
                                                        )),
                                                    pw.Text(
                                                      '\$' +
                                                          (() {
                                                            double subtotal =
                                                                products.fold(0.0,
                                                                    (t, p) {
                                                              final discount =
                                                                  p.discount ??
                                                                      0.0;
                                                              if (p.discountType ==
                                                                  DiscountType
                                                                      .perPiece) {
                                                                return t +
                                                                    ((p.price -
                                                                            discount) *
                                                                        p.quantity);
                                                              } else {
                                                                return t +
                                                                    ((p.price *
                                                                            p.quantity) -
                                                                        discount);
                                                              }
                                                            });
                                                            double
                                                                globalDiscount =
                                                                double.tryParse(
                                                                        discountController
                                                                            .text) ??
                                                                    0.0;
                                                            double
                                                                afterDiscount =
                                                                subtotal *
                                                                    (1 -
                                                                        globalDiscount /
                                                                            100.0);
                                                            double vat = double
                                                                    .tryParse(
                                                                        vatController
                                                                            .text) ??
                                                                0.0;
                                                            double total =
                                                                afterDiscount *
                                                                    (1 +
                                                                        vat /
                                                                            100.0);
                                                            return total
                                                                .toStringAsFixed(
                                                                    2);
                                                          })(),
                                                      style: pw.TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                        color: PdfColors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    break;

                                  default:
                                    pdfContent = pw.Text('Template: $template');
                                }
                                doc.addPage(
                                  pw.MultiPage(
                                    build: (pw.Context context) => [pdfContent],
                                  ),
                                );
                                await Printing.layoutPdf(
                                    onLayout: (format) async => doc.save());
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
