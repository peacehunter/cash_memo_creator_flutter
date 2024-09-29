import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'PreviewPage.dart';
import 'Memo.dart';
import 'dart:typed_data' as typed_data;
import 'l10n/gen_l10n/app_localizations.dart';

class CashMemoEdit extends StatefulWidget {
  final Memo? memo;
  final int? memoIndex;
  final VoidCallback? onMemoSaved;
  final bool autoGenerate; // Add this parameter to trigger auto-generation

  CashMemoEdit(
      {this.memo,
        this.memoIndex,
        this.onMemoSaved,
        required this.autoGenerate});

  @override
  _CashMemoEditState createState() => _CashMemoEditState();
}

class _CashMemoEditState extends State<CashMemoEdit> {
  late List<Product> products;
  late TextEditingController discountController;
  late TextEditingController vatController;
  late TextEditingController customerNameController;
  late TextEditingController customerAddressController;
  late TextEditingController customerPhoneNumberController;
  late ScrollController _scrollController;

  FocusNode discountFocusNode = FocusNode();
  FocusNode vatFocusNode = FocusNode();

  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _priceControllers = [];
  final List<TextEditingController> _quantityControllers = [];

  int selectedWatermarkOption = 2; // Example default value
  String? watermarkImagePath; // Path to the watermark image

  late bool isPercentDiscount;
  String? companyName;
  String? companyAddress;
  String? companyLogoPath;
  String? watermarkText;
  String? nbMessage;
  bool isLoadingCompanyInfo = true;

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose of the scroll controller

    // Dispose of the controllers when the widget is removed from the widget tree
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    for (var controller in _priceControllers) {
      controller.dispose();
    }
    for (var controller in _quantityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> printPdfInner() async {
    const platform = MethodChannel('com.tuhin.cash_memo/pdf_print');

    String batteryLevel;
    try {
      final result = await platform.invokeMethod<String>('pdf_print');
      print(result);
      print("method called flutter");
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }


  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    printPdfInner();
    print("widget.autoGenerate value : ${widget.autoGenerate}");
    print("widget.memo value : ${widget.memo}");
    // Check if we need to automatically generate the memo

    print("Water mark option :$selectedWatermarkOption");

    // Initialize products with existing memo data or create a new one
    products = widget.memo?.products.isNotEmpty == true
        ? List.from(widget.memo!.products)
        : [Product(name: '', price: 0, quantity: 1)];

    // Initialize controllers with existing memo data
    discountController =
        TextEditingController(text: widget.memo?.discount.toString() ?? '0');
    vatController =
        TextEditingController(text: widget.memo?.vat.toString() ?? '0');
    customerNameController =
        TextEditingController(text: widget.memo?.customerName ?? '');
    customerAddressController =
        TextEditingController(text: widget.memo?.customerAddress ?? '');
    customerPhoneNumberController =
        TextEditingController(text: widget.memo?.customerPhoneNumber ?? '');

    isPercentDiscount = widget.memo?.isPercentDiscount ?? true;

    for (var product in products) {
      _nameControllers.add(TextEditingController(text: product.name));
      _priceControllers
          .add(TextEditingController(text: product.price.toString()));
      _quantityControllers
          .add(TextEditingController(text: product.quantity.toString()));
    }
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    var localizations = AppLocalizations.of(context)!; // Get localization

    if (widget.autoGenerate && widget.memo != null) {
      Future.delayed(Duration.zero, () async {
        // Delay execution to ensure the page has loaded
        if (mounted) {
          // Ensure the widget is still mounted
          _showTemplateSelectionDialog(context, localizations);
          print("widget.memo value inside if block: ${widget.memo}");
        }
      });
    }
    // Load company info
    loadCompanyInfo(localizations);
  }

  // Function to load the custom Bangla font
  Future<pw.Font> loadBengaliFont() async {
    final fontData = await rootBundle.load('assets/fonts/Nikosh.ttf');
    return pw.Font.ttf(fontData);
  }

  Future<pw.Font> loadFont(String languageCode) async {

    if (languageCode == 'bn') {
      // Load Bengali font
      final fontData = await rootBundle.load('assets/fonts/NotoSansBengali.ttf');
      return pw.Font.ttf(fontData);
    } else {
      // Use built-in font for English (e.g., Helvetica)
      return pw.Font.helvetica();

    }
  }

  Future<void> loadCompanyInfo(localizations) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      companyName =
          prefs.getString('companyName') ?? localizations.pdf_company_name;
      companyAddress = prefs.getString('companyAddress') ?? 'Company Address';
      companyLogoPath = prefs.getString('companyLogo') ?? '';
      watermarkText = prefs.getString('watermarkText') ?? '';
      watermarkImagePath = prefs.getString('watermarkImage') ?? '';
      nbMessage = prefs.getString('nbMessage') ?? '';
      selectedWatermarkOption = prefs.getInt('watermarkOption') ?? 0;
      isLoadingCompanyInfo = false;
    });
  }

  Memo saveMemo() {
    double total = products.fold(
        0.0, (sum, product) => sum + (product.price * product.quantity));
    double discount = double.tryParse(discountController.text) ?? 0;
    double vat = double.tryParse(vatController.text) ?? 0;

    double discountedTotal = isPercentDiscount
        ? total - (total * (discount / 100))
        : total - discount;

    double finalTotal = discountedTotal + (discountedTotal * (vat / 100));
    String currentDate = DateTime.now().toLocal().toString().split(' ')[0];

    return Memo(
      companyName: companyName ?? '',
      products: products,
      total: finalTotal,
      date: widget.memo?.date ?? currentDate,
      customerName: customerNameController.text,
      customerAddress: customerAddressController.text,
      customerPhoneNumber: customerPhoneNumberController.text,
      companyAddress: '',
      companyLogo: '',
    );
  }

  Future<Uint8List?> loadLogo(String? logoPath) async {
    if (logoPath != null && File(logoPath).existsSync()) {
      return await File(logoPath).readAsBytes();
    }
    return null;
  }

// Update the generateCashMemo method to handle the new template
  Future<void> generateCashMemo(localizations,int selectedTemplate,int selectedWatermarkOption,String? watermarkText,String? watermarkImagePath) async {
    final pdf = pw.Document();

    String languageCode = Localizations.localeOf(context).languageCode;
    // Use loadFont function to load the appropriate font for the language
    final font = await loadFont(languageCode);

    // Load the logo from the saved path
    Uint8List? logoBytes = await loadLogo(companyLogoPath);

    // Get the current date
    String currentDate =
    DateTime.now().toLocal().toString().split(' ')[0]; // Format: YYYY-MM-DD

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          // Declare a variable to hold the template widget
          pw.Widget templateWidget;

          // Use a switch case to determine the template widget
          switch (selectedTemplate) {
            case 1:
              templateWidget = buildTemplate1(
                  logoBytes, currentDate, localizations,font); // Classic template
              break;
            case 2:
              templateWidget = buildTemplate2(
                  logoBytes, currentDate, localizations,font); // Modern template
              break;
            case 3:
              templateWidget = buildTemplate3(
                  logoBytes, currentDate, localizations,font); // Minimal template
              break;
            case 4:
              templateWidget = buildTemplate4(logoBytes, currentDate,
                  localizations,font); // Borderless product template
              break;
            default:
              templateWidget = buildTemplate1(logoBytes, currentDate,
                  localizations,font); // Default to template 1
          }

          // Use a Stack to overlay the watermark and content
          return pw.Stack(
            children: [
              // Watermark widget based on user selection
              waterMarkWidget(
                  selectedWatermarkOption, watermarkText, watermarkImagePath),

              // Main page content on top of the watermark
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  templateWidget,
                  pw.Expanded(child: pw.Container()), // Take up available space

                  // Signature section
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.Text('Signature: ', style: pw.TextStyle(fontSize: 18)),
                      pw.Container(
                        width: 200,
                        height: 50,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  width: 1, color: PdfColors.black)),
                        ),
                      ),
                    ],
                  ),

                  // Add N.B. message if available
                  if (nbMessage != null && nbMessage!.isNotEmpty) ...[
                    pw.SizedBox(height: 20), // Space before N.B. message
                    buildNBMessage(),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );

    // Call the callback function to notify the list screen
    if (widget.onMemoSaved != null) {
      widget.onMemoSaved!();
    }

    Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

// N.B. message widget
  pw.Widget buildNBMessage() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'N.B. (Note Well)',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          nbMessage!, // Use the variable that holds the N.B. message
          style: pw.TextStyle(color: PdfColors.grey),
        ),
      ],
    );
  }

  pw.Widget waterMarkWidget(int selectedWatermarkOption, String? watermarkText,
      String? watermarkImagePath) {
    // Watermark in the middle of the page
    return pw.Positioned.fill(
      child: pw.Opacity(
        opacity: 0.1, // Adjust opacity as needed
        child: pw.Stack(
          children: [
            // If both text and image are selected
            if (selectedWatermarkOption == 2 && watermarkImagePath != null) ...[
              // Display the watermark image
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(File(watermarkImagePath).readAsBytesSync()),
                  fit: pw.BoxFit.contain, // Adjust as necessary
                ),
              ),
              // Display the watermark text
              pw.Center(
                child: pw.Text(
                  (watermarkText ?? ''),
                  style: pw.TextStyle(
                    fontSize: 72,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
            // If only the watermark text is selected
            if (selectedWatermarkOption == 0) ...[
              pw.Center(
                child: pw.Text(
                  (watermarkText ?? ''),
                  style: pw.TextStyle(
                    fontSize: 72,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
            // If only the watermark image is selected
            if (selectedWatermarkOption == 1 && watermarkImagePath != null) ...[
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(File(watermarkImagePath).readAsBytesSync()),
                  fit: pw.BoxFit.contain, // Adjust as necessary
                ),
              ),
            ],
            // If no watermark is selected
            if (selectedWatermarkOption == 3) ...[
              // Do not display any watermark
            ],
          ],
        ),
      ),
    );
  }

// Template 4: Borderless Product Template
  pw.Widget buildTemplate4(
      Uint8List? logoBytes, String currentDate, localizations,font) {
    return pw.Stack(
      children: [
        // Content over the watermark
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: buildCompanyDetails(logoBytes),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Date: $currentDate', style: pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 10),
            buildCustomerDetails(localizations,font),
            pw.SizedBox(height: 20),
            buildBorderlessProductTable(),
            pw.SizedBox(height: 10),
            buildPricingDetails(localizations,font),
          ],
        ),
      ],
    );
  }

// Helper to build a borderless product table
  pw.Widget buildBorderlessProductTable() {
    return pw.Table(
      border: null, // Remove borders
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color:
            PdfColors.grey300, // Optional: Add background color to header
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0), // Add padding
              child: pw.Text('Product',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0), // Add padding
              child: pw.Text('Price',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0), // Add padding
              child: pw.Text('Quantity',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0), // Add padding
              child: pw.Text('Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        // Data Rows
        ...products.map((product) {
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8.0), // Add padding
                child: pw.Text(product.name),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8.0), // Add padding
                child: pw.Text(product.price.toString()),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8.0), // Add padding
                child: pw.Text(product.quantity.toString()),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8.0), // Add padding
                child: pw.Text((product.price * product.quantity).toString()),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

// Template 1: Classic Template
  pw.Widget buildTemplate1(
      Uint8List? logoBytes, String currentDate, localizations , font) {
    return pw.Stack(
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Cash Memo',
                style: pw.TextStyle(fontSize: 24,font: font),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 20),
            buildCompanyDetails(logoBytes),
            pw.SizedBox(height: 10),
            pw.Text('Date: $currentDate',
                style: pw.TextStyle(fontSize: 12,font: font),
                textAlign: pw.TextAlign.right),
            pw.SizedBox(height: 10),
            buildCustomerDetails(localizations,font),
            pw.SizedBox(height: 10),
            buildProductTable(localizations,font),
            buildPricingDetails(localizations,font),
          ],
        ),
      ],
    );
  }

// Template 2: Modern Template
  pw.Widget buildTemplate2(
      Uint8List? logoBytes, String currentDate, localizations,font) {
    return pw.Stack(
      children: [
        // Content over the watermark
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Different arrangement for company details and customer info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Company details on the left
                buildCompanyDetails(logoBytes),

                // Customer and date details on the right
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  // Aligns everything to the left (or start)
                  children: [
                    pw.Text('Date: $currentDate',
                        style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 5),
                    buildCustomerDetails(localizations,font),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            buildProductTable(localizations,font),
            pw.Divider(),
            buildPricingDetails(localizations,font),
          ],
        ),
      ],
    );
  }

// Template 3: Minimal Template
  pw.Widget buildTemplate3(
      Uint8List? logoBytes, String currentDate, localizations,font) {
    return pw.Stack(
      children: [
        // Watermark in the middle of the page
        pw.Positioned.fill(
          child: pw.Opacity(
            opacity: 0.1,
            child: pw.Center(
              child: pw.Text(
                (watermarkText ?? ''),
                style: pw.TextStyle(
                  fontSize: 72,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
        ),

        // Content over the watermark
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Company name centered with customer details on the side
            pw.Center(
              child: buildCompanyDetails(logoBytes),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Date: $currentDate', style: pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 10),
            buildCustomerDetails(localizations,font),
            pw.SizedBox(height: 20),
            buildProductTable(localizations,font),
            pw.SizedBox(height: 10),
            buildPricingDetails(localizations,font),
          ],
        ),
      ],
    );
  }

// Helper to build company details (used across templates)
  pw.Widget buildCompanyDetails(Uint8List? logoBytes) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        if (logoBytes != null)
          pw.Image(pw.MemoryImage(logoBytes), width: 50, height: 50),
        pw.SizedBox(width: 10),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(companyName ?? '', style: pw.TextStyle(fontSize: 20)),
            pw.Text(companyAddress ?? ''),
          ],
        ),
      ],
    );
  }

// Helper to build customer details (used across templates)
  pw.Widget buildCustomerDetails(localizations,font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
            '${localizations.customer_name}: ${customerNameController.text}',style: pw.TextStyle(font:font)),
        pw.Text(
            '${localizations.customer_address}: ${customerAddressController.text}',style: pw.TextStyle(font:font)),
        pw.Text(
            '${localizations.customer_phone_number}: ${customerPhoneNumberController.text}',style: pw.TextStyle(font:font)),
      ],
    );
  }

// Helper to build product table (used across templates)
  pw.Widget buildProductTable(localizations,font) {
    return pw.Table.fromTextArray(
      headers: [
        '${localizations.product_name}',
        '${localizations.product_price}',
        '${localizations.product_quantity}',
        '${localizations.total}'
      ],
      data: products.map((product) {
        return [
          product.name,
          product.price.toString(),
          product.quantity.toString(),
          (product.price * product.quantity).toString()
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold,font: font),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey),
      cellStyle: pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

// Helper to build pricing details (used across templates)
  pw.Widget buildPricingDetails(localizations,font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        buildPricingRow('${localizations.product_subtotal}',
            calculateSubtotal().toStringAsFixed(2),font),
        buildPricingRow(
            '${localizations.discount_label}', '${discountController.text}%',font),
        buildPricingRow('${localizations.tax_label}', '${vatController.text}%',font),
        pw.Divider(),
        buildPricingRow('${localizations.product_total}',
            calculateTotal().toStringAsFixed(2),font,
            isBold: true),
        // Total with bold styling
      ],
    );
  }

  pw.Widget buildPricingRow(String label, String value,font, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,font:font),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,font:font),
        ),
      ],
    );
  }

  double calculateSubtotal() {
    return products.fold(
        0.0, (total, product) => total + (product.price * product.quantity));
  }

  double calculateTotal() {
    double subtotal = calculateSubtotal();
    double discount = double.tryParse(discountController.text) ?? 0.0;
    double vat = double.tryParse(vatController.text) ?? 0.0;

    double discountedTotal = isPercentDiscount
        ? subtotal - (subtotal * (discount / 100))
        : subtotal - discount;

    double finalTotal = discountedTotal + (discountedTotal * (vat / 100));
    return finalTotal;
  }

  Future<bool> _onWillPop() async {
    Memo memo = saveMemo();
    Navigator.pop(context, memo);
    return true;
  }

  void addProduct() {
    setState(() {
      products.add(Product(name: '', price: 0, quantity: 1));

      _nameControllers.add(TextEditingController());
      _priceControllers.add(TextEditingController());
      _quantityControllers.add(TextEditingController());
    });
  }

  void removeProduct(int index) {
    setState(() {
      products.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    var localizations = AppLocalizations.of(context)!; // Get localization

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title:
          Text(widget.memo != null ? 'Edit Cash Memo' : 'Create Cash Memo'),
          backgroundColor: Colors.teal,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Memo memo = saveMemo();
              Navigator.pop(context, memo);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                isLoadingCompanyInfo
                    ? CircularProgressIndicator()
                    : Text(companyName ?? 'Company Name',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                _buildCustomerDetails(localizations),
                SizedBox(height: 20),
                _buildProductList(localizations),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      addProduct();
                      // Scroll to the bottom after adding a product
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      });
                    },
                    icon: Icon(Icons.add),
                    label: Text(localizations.add_product_button_label),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                _buildDiscountAndVatFields(localizations),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Memo memo = saveMemo();
                    _showTemplateSelectionDialog(context, localizations);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(localizations.create_cash_memo_label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Helper method to build section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  void _showTemplateSelectionDialog(BuildContext context, localizations) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.select_template_label),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(localizations.template_name_1),
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  generateCashMemo(
                      localizations,
                      1,
                      selectedWatermarkOption,
                      watermarkText,
                      watermarkImagePath); // Pass all required arguments
                },
              ),
              ListTile(
                title: Text(localizations.template_name_2),
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  generateCashMemo(
                      localizations,
                      2,
                      selectedWatermarkOption,
                      watermarkText,
                      watermarkImagePath); // Pass all required arguments
                },
              ),
              ListTile(
                title: Text(localizations.template_name_3),
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  generateCashMemo(
                      localizations,
                      3,
                      selectedWatermarkOption,
                      watermarkText,
                      watermarkImagePath); // Pass all required arguments
                },
              ),
              ListTile(
                title: Text(localizations.template_name_4),
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  generateCashMemo(
                      localizations,
                      4,
                      selectedWatermarkOption,
                      watermarkText,
                      watermarkImagePath); // Pass all required arguments
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without action
              },
              child: Text(localizations.dialog_cancel_label),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomerDetails(localizations) {
    return Column(
      children: [
        TextField(
          controller: customerNameController,
          decoration: InputDecoration(
              labelText: localizations.customer_name,
              border: OutlineInputBorder()),
        ),
        SizedBox(height: 10),
        TextField(
          controller: customerAddressController,
          decoration: InputDecoration(
              labelText: localizations.customer_address,
              border: OutlineInputBorder()),
        ),
        SizedBox(height: 10),
        TextField(
          controller: customerPhoneNumberController,
          decoration: InputDecoration(
              labelText: localizations.customer_phone_number,
              border: OutlineInputBorder()),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildProductList(localizations) {
    return Column(
      children: List.generate(products.length, (index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() {
                      products[index].name = value;
                    }),
                    controller: _nameControllers[index],
                    decoration: InputDecoration(
                        labelText: localizations.product_name,
                        border: const OutlineInputBorder()),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() {
                      products[index].price = double.tryParse(value) ?? 0;
                    }),
                    controller: _priceControllers[index],
                    decoration: InputDecoration(
                        labelText: localizations.product_price,
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() {
                      products[index].quantity = int.tryParse(value) ?? 1;
                    }),
                    controller: _quantityControllers[index],
                    decoration: InputDecoration(
                        labelText: localizations.product_quantity,
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => removeProduct(index),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDiscountAndVatFields(localizations) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextField(
                controller: discountController,
                focusNode: discountFocusNode,
                decoration: InputDecoration(
                    labelText: localizations.discount_label,
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onTap: () {
                  // Clear the discount field on tap if the current value is 0.0
                  if (discountController.text == '0.0') {
                    discountController.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: vatController,
                focusNode: vatFocusNode,
                decoration: InputDecoration(
                    labelText: localizations.tax_label,
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onTap: () {
                  // Clear the VAT field on tap if the current value is 0.0
                  if (vatController.text == '0.0') {
                    vatController.clear();
                  }
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: isPercentDiscount,
              onChanged: (value) {
                setState(() {
                  isPercentDiscount = value ?? true;
                });
              },
            ),
            Text(localizations.percent_discount_label),
          ],
        ),
      ],
    );
  }
}
