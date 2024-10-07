import 'dart:io';
import 'package:cash_memo_creator/admob_ads/AdHelper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'PdfSaver.dart';
import 'PdfViewerScreen.dart';
import 'PreviewPage.dart';
import 'Memo.dart';
import 'dart:typed_data' as typed_data;
import 'admob_ads/BannerAdWidget.dart';
import 'admob_ads/InterstitialAdManager.dart';
import 'l10n/gen_l10n/app_localizations.dart';
import 'CashMemoPdfPrintService.dart';

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

class _CashMemoEditState extends State<CashMemoEdit>
    with WidgetsBindingObserver {
  late List<Product> products;
  late TextEditingController discountController;
  late TextEditingController vatController;
  late TextEditingController customerNameController;
  late TextEditingController customerAddressController;
  late TextEditingController customerPhoneNumberController;
  late ScrollController _scrollController;

  late InterstitialAd? _interstitialAd;
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
    WidgetsBinding.instance.removeObserver(this); // Remove the observer

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
    WidgetsBinding.instance.removeObserver(this); // Remove the observer

    super.dispose();
  }

  // This is where you handle lifecycle changes like onResume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Load the ad when the app is resumed
      loadInterstitialAD();
      print("app state: app is resumed");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add the observer here

    _scrollController = ScrollController();
    loadInterstitialAD();
    print("widget.autoGenerate value : ${widget.autoGenerate}");
    print("widget.memo value : ${widget.memo}");
    // Check if we need to automatically generate the memo

    print("Water mark option :$selectedWatermarkOption");

    //  savePdf();
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

  Future<void> loadCompanyInfo(localizations) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      companyName =
          prefs.getString('companyName') ?? localizations.pdf_company_name;
      companyAddress = prefs.getString('companyAddress') ?? '';
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

  Future<void> requestPermissions() async {
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }

    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
  }

  void loadInterstitialAD() {
    InterstitialAd.load(
        adUnitId: AdHelper.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            // Keep a reference to the ad so you can show it later.
            _interstitialAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            _interstitialAd = null;
            print('InterstitialAd failed to load: $error');
          },
        ));
  }

  void generateCashMemoAndShowAd(Uint8List pdfData, String fileName) {
    if (_interstitialAd == null) {
      print("add error: interstitial null");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfData: pdfData,
            fileName: fileName,
          ),
        ),
      );
    } else {
      _interstitialAd?.show();

      _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
          // Called when the ad showed the full screen content.
          onAdShowedFullScreenContent: (ad) {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

          },
          // Called when an impression occurs on the ad.
          onAdImpression: (ad) {},
          // Called when the ad failed to show full screen content.
          onAdFailedToShowFullScreenContent: (ad, err) {
            print('Ad failed to show. Navigating to PdfPreviewScreen.');
            // Navigate to PdfPreviewScreen after ad is closed
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfPreviewScreen(
                  pdfData: pdfData,
                  fileName: fileName,
                ),
              ),
            );
          },
          // Called when the ad dismissed full screen content.
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _interstitialAd = null;
            loadInterstitialAD(); // Load a new ad for the next time
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

            print('Ad closed. Navigating to PdfPreviewScreen.');
            // Navigate to PdfPreviewScreen after ad is closed
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfPreviewScreen(
                  pdfData: pdfData,
                  fileName: fileName,
                ),
              ),
            );
          },
          // Called when a click is recorded for an ad.
          onAdClicked: (ad) {
            print('Ad clicked. Navigating to PdfPreviewScreen.');
            // Navigate to PdfPreviewScreen after ad is closed
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfPreviewScreen(
                  pdfData: pdfData,
                  fileName: fileName,
                ),
              ),
            );
          });
    }
  }

// Call this function when you want to generate the PDF and show the ad
  void generateCashMemo(
      localizations,
      int selectedTemplate,
      int selectedWatermarkOption,
      String? watermarkText,
      String? watermarkImagePath) async {
    final pdf = pw.Document();

    // Load the logo from the saved path
    Uint8List? logoBytes = await loadLogo(companyLogoPath);

    // Get the current date
    String currentDate =
        DateTime.now().toLocal().toString().split(' ')[0]; // Format: YYYY-MM-DD

    // Add pages to the PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          pw.Widget templateWidget;

          switch (selectedTemplate) {
            case 1:
              templateWidget = buildTemplate1(logoBytes, currentDate);
              break;
            case 2:
              templateWidget = buildTemplate2(logoBytes, currentDate);
              break;
            case 3:
              templateWidget = buildTemplate3(logoBytes, currentDate);
              break;
            case 4:
              templateWidget = buildTemplate4(logoBytes, currentDate);
              break;
            default:
              templateWidget = buildTemplate1(logoBytes, currentDate);
          }

          return pw.Stack(
            children: [
              waterMarkWidget(
                  selectedWatermarkOption, watermarkText, watermarkImagePath),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  templateWidget,
                  pw.Expanded(child: pw.Container()),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.Text('Signature: ', style: pw.TextStyle(fontSize: 18)),
                      pw.Container(
                        width: 200,
                        height: 50,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom:
                                pw.BorderSide(width: 1, color: PdfColors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (nbMessage != null && nbMessage!.isNotEmpty) ...[
                    pw.SizedBox(height: 20),
                    buildNBMessage(),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );

    final pdfData = await pdf.save(); // Save PDF as byte array
    String fileName = generateFileName(customerNameController.text);

    // Show the ad and navigate to PdfPreviewScreen based on callbacks
    generateCashMemoAndShowAd(pdfData, fileName);
  }

  String generateFileName(String customerName) {
    String formattedDate =
        DateFormat('_yyyyMMdd_HHmmss').format(DateTime.now());
    return '${customerName}_$formattedDate.pdf'; // e.g., document_20231001_120101.pdf
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
  pw.Widget buildTemplate4(Uint8List? logoBytes, String currentDate) {
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
            buildCustomerDetails(),
            pw.SizedBox(height: 20),
            buildBorderlessProductTable(),
            pw.SizedBox(height: 30),
            buildPricingDetails(),
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
  pw.Widget buildTemplate1(Uint8List? logoBytes, String currentDate) {
    return pw.Stack(
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Cash Memo',
                style: const pw.TextStyle(fontSize: 24),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 20),
            buildCompanyDetails(logoBytes),
            pw.SizedBox(height: 10),
            pw.Text('Date: $currentDate',
                style: pw.TextStyle(fontSize: 12),
                textAlign: pw.TextAlign.right),
            pw.SizedBox(height: 10),
            buildCustomerDetails(),
            pw.SizedBox(height: 10),
            buildProductTable(),
            buildPricingDetails(),
          ],
        ),
      ],
    );
  }

// Template 2: Modern Template
  pw.Widget buildTemplate2(Uint8List? logoBytes, String currentDate) {
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
                    buildCustomerDetails(),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            buildProductTable(),
            pw.Divider(),
            buildPricingDetails(),
          ],
        ),
      ],
    );
  }

// Template 3: Minimal Template
  pw.Widget buildTemplate3(Uint8List? logoBytes, String currentDate) {
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
            buildCustomerDetails(),
            pw.SizedBox(height: 20),
            buildProductTable(),
            pw.SizedBox(height: 10),
            buildPricingDetails(),
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
  pw.Widget buildCustomerDetails() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Customer name: ${customerNameController.text}'),
        pw.Text('Customer address: ${customerAddressController.text}'),
        pw.Text('Phone number: ${customerPhoneNumberController.text}'),
      ],
    );
  }

// Helper to build product table (used across templates)
  pw.Widget buildProductTable() {
    return pw.Table.fromTextArray(
      headers: ['Product name', 'Price', 'Quantity', 'Total'],
      data: products.map((product) {
        return [
          product.name,
          product.price.toString(),
          product.quantity.toString(),
          (product.price * product.quantity).toString()
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey),
      cellStyle: pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

// Helper to build pricing details (used across templates)
  pw.Widget buildPricingDetails() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        buildPricingRow('Subtotal', calculateSubtotal().toStringAsFixed(2)),
        buildPricingRow('Discount', '${discountController.text}%'),
        buildPricingRow('Vat/Tax', '${vatController.text}%'),
        pw.Divider(),
        buildPricingRow('Total', calculateTotal().toStringAsFixed(2)),
        // Total with bold styling
      ],
    );
  }

  pw.Widget buildPricingRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    var localizations = AppLocalizations.of(context)!; // Get localization

    return WillPopScope(
      onWillPop: () async {
        Memo memo = saveMemo();
        Navigator.pop(context, memo);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 10,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text(
            widget.memo != null ? 'Edit Cash Memo' : 'Create Cash Memo',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              Memo memo = saveMemo();
              Navigator.pop(context, memo);
            },
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade100, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      isLoadingCompanyInfo
                          ? const Center(child: CircularProgressIndicator())
                          : Text(
                              companyName ?? 'Company Name',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                      const SizedBox(height: 20),
                      _buildCustomerDetails(localizations),
                      const SizedBox(height: 20),
                      _buildProductList(localizations),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            addProduct();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(localizations.product_added)),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: Text(localizations.add_product_button_label),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDiscountAndVatFields(localizations),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Memo memo = saveMemo();
                          _showTemplateSelectionDialog(context, localizations);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(localizations.create_cash_memo_label),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10), // Add some space before the banner
              MyBannerAdWidget(), // Banner ad widget at the bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerDetails(localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: customerNameController,
          decoration: InputDecoration(
            labelText: localizations.customer_name,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: customerAddressController,
          decoration: InputDecoration(
            labelText: localizations.customer_address,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: customerPhoneNumberController,
          decoration: InputDecoration(
            labelText: localizations.customer_phone_number,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildProductList(AppLocalizations localizations) {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(products.length, (index) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Rounded edges
            ),
            color: Colors.teal,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            // Margin between cards
            elevation: 2,
            // Elevation for shadow effect
            child: ExpansionPanelList(
              elevation: 0, // No elevation for the list inside the card
              expandedHeaderPadding: EdgeInsets.zero,
              children: [
                ExpansionPanel(
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return ListTile(
                      title: Text(
                        products[index].name.isNotEmpty
                            ? products[index].name
                            : '${localizations.product_name} ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    );
                  },
                  body: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Product Name (Full Width)
                        TextField(
                          controller: _nameControllers[index],
                          onChanged: (value) {
                            setState(() {
                              products[index].name = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: localizations.product_name,
                            labelStyle: const TextStyle(color: Colors.teal),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.teal.shade300,
                                  width: 1.5), // Lighter border
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.teal.shade700,
                                  width: 2), // Darker border on focus
                            ),
                            prefixIcon:
                                const Icon(Icons.article, color: Colors.teal),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 15), // Better vertical alignment
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Row with Product Price and Quantity
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _priceControllers[index],
                                onChanged: (value) {
                                  setState(() {
                                    products[index].price =
                                        double.tryParse(value) ?? 0;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: localizations.product_price,
                                  labelStyle:
                                      const TextStyle(color: Colors.teal),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: Colors.teal.shade300,
                                        width: 1.5), // Lighter border
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: Colors.teal.shade700,
                                        width: 2), // Darker border on focus
                                  ),
                                  prefixIcon: const Icon(Icons.attach_money,
                                      color: Colors.teal),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical:
                                          15), // Better vertical alignment
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _quantityControllers[index],
                                onChanged: (value) {
                                  setState(() {
                                    products[index].quantity =
                                        int.tryParse(value) ?? 1;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: localizations.product_quantity,
                                  labelStyle:
                                      const TextStyle(color: Colors.teal),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: Colors.teal.shade300,
                                        width: 1.5), // Lighter border
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: Colors.teal.shade700,
                                        width: 2), // Darker border on focus
                                  ),
                                  prefixIcon: const Icon(
                                      Icons.format_list_numbered,
                                      color: Colors.teal),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical:
                                          15), // Better vertical alignment
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Remove Product Button with Teal color scheme
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              products.removeAt(index);
                              _nameControllers.removeAt(index);
                              _priceControllers.removeAt(index);
                              _quantityControllers.removeAt(index);
                            });
                          },
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label:
                              Text(localizations.remove_product_button_label),
                          // Updated to localized text
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            // Matches the teal theme
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  isExpanded: products[index].isExpanded ? false : true,
                ),
              ],
              // Expansion callback to toggle the state of the panel
              expansionCallback: (int index, bool isExpanded) {
                setState(() {
                  products[index].isExpanded =
                      !isExpanded; // Toggle the expanded state
                });
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDiscountAndVatFields(localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.money_off),
                ),
                keyboardType: TextInputType.number,
                onTap: () {
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
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.percent),
                ),
                keyboardType: TextInputType.number,
                onTap: () {
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
