import 'dart:async';
import 'package:flutter/foundation.dart';
// dart:io is used only on non-web platforms
import 'dart:io' if (dart.library.html) 'src/stub_io.dart';
import 'package:cash_memo_creator/admob_ads/AdHelper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'PdfViewerScreen.dart';
import 'Memo.dart';
import 'l10n/gen_l10n/app_localizations.dart';
import 'design_system.dart';
import 'widgets/professional_widgets.dart';

class CashMemoEdit extends StatefulWidget {
  final Memo? memo;
  final int? memoIndex;
  final VoidCallback? onMemoSaved;
  final bool autoGenerate; // Add this parameter to trigger auto-generation

  const CashMemoEdit(
      {super.key,
      this.memo,
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
  late TextEditingController notesController;
  late ScrollController _scrollController;

  InterstitialAd? _interstitialAd;
  FocusNode discountFocusNode = FocusNode();
  FocusNode vatFocusNode = FocusNode();

  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _priceControllers = [];
  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _discountController = [];
  final List<bool> _isProductDiscountPercent = [];

  // Debounce timers for performance optimization
  Timer? _debounceTimer;
  final Map<int, Timer?> _productDebounceTimers = {};

  // Cached calculations to avoid recalculating on every build
  final Map<int, double> _cachedItemTotals = {};

  // Memoization for expensive calculations
  double? _cachedSubtotal;
  double? _cachedTotal;
  String? _lastSubtotalHash;
  String? _lastTotalHash;

  // Flag to prevent multiple template dialog shows
  bool _hasShownTemplateDialog = false;

  int selectedWatermarkOption = 2; // Example default value
  String? watermarkImagePath; // Path to the watermark image

  late bool isPercentDiscount;
  double discount = 0.0;
  double vat = 0.0;
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
    for (var controller in _discountController) {
      controller.dispose();
    }

    // Dispose of debounce timers
    _debounceTimer?.cancel();
    for (var timer in _productDebounceTimers.values) {
      timer?.cancel();
    }

    super.dispose();
  }

  // Debounced update methods for better performance
  void _debouncedUpdateProduct(int index, VoidCallback updateFunction) {
    _productDebounceTimers[index]?.cancel();
    _productDebounceTimers[index] =
        Timer(const Duration(milliseconds: 300), () {
      updateFunction();
      _updateCachedItemTotal(index);
      _clearMemoizationCache();
      setState(() {});
    });
  }

  void _updateCachedItemTotal(int index) {
    if (index < products.length) {
      double itemTotal = products[index].price * products[index].quantity;
      double discountAmount = _isProductDiscountPercent[index]
          ? itemTotal * (products[index].discount / 100)
          : products[index].discount;
      _cachedItemTotals[index] = itemTotal - discountAmount;
    }
  }

  double _getCachedItemTotal(int index) {
    if (!_cachedItemTotals.containsKey(index)) {
      _updateCachedItemTotal(index);
    }
    return _cachedItemTotals[index] ?? 0.0;
  }

  // Generate hash for subtotal calculation dependencies
  String _getSubtotalHash() {
    return products.asMap().entries.map((entry) {
      int index = entry.key;
      Product product = entry.value;
      return '${product.price}_${product.quantity}_${product.discount}_${_isProductDiscountPercent[index]}';
    }).join('|');
  }

  // Generate hash for total calculation dependencies
  String _getTotalHash() {
    String subtotalHash = _getSubtotalHash();
    String discountText = discountController.text;
    String vatText = vatController.text;
    return '${subtotalHash}_${discountText}_${vatText}_${isPercentDiscount}';
  }

  // Memoized subtotal calculation
  double getMemoizedSubtotal() {
    String currentHash = _getSubtotalHash();
    if (_lastSubtotalHash == currentHash && _cachedSubtotal != null) {
      return _cachedSubtotal!;
    }

    _cachedSubtotal = calculateSubtotal();
    _lastSubtotalHash = currentHash;
    return _cachedSubtotal!;
  }

  // Memoized total calculation
  double getMemoizedTotal() {
    String currentHash = _getTotalHash();
    if (_lastTotalHash == currentHash && _cachedTotal != null) {
      return _cachedTotal!;
    }

    _cachedTotal = calculateTotal();
    _lastTotalHash = currentHash;
    return _cachedTotal!;
  }

  // Clear memoization cache when data changes
  void _clearMemoizationCache() {
    _cachedSubtotal = null;
    _cachedTotal = null;
    _lastSubtotalHash = null;
    _lastTotalHash = null;
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
        : [Product(name: '', price: 0, quantity: 0, discount: 0)];

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
    notesController =
        TextEditingController(text: widget.memo?.notes ?? '');

    isPercentDiscount = widget.memo?.isPercentDiscount ?? true;

    for (var product in products) {
      _nameControllers.add(TextEditingController(text: product.name));
      // Initialize price, quantity, and discount fields as empty by default for new products
      if (widget.memo?.products.isNotEmpty == true) {
        // For existing memos, use the stored values
        _priceControllers
            .add(TextEditingController(text: product.price.toString()));
        _quantityControllers
            .add(TextEditingController(text: product.quantity.toString()));
        _discountController
            .add(TextEditingController(text: product.discount.toString()));
      } else {
        // For new memos, use empty strings
        _priceControllers.add(TextEditingController(text: ''));
        _quantityControllers.add(TextEditingController(text: ''));
        _discountController.add(TextEditingController(text: ''));
      }
      // Initialize discount type as percentage by default
      _isProductDiscountPercent.add(true);
    }
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    var localizations = AppLocalizations.of(context)!; // Get localization

    if (widget.autoGenerate &&
        widget.memo != null &&
        !_hasShownTemplateDialog) {
      _hasShownTemplateDialog = true; // Set flag to prevent multiple shows
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
      // Use new keys from settings_screen.dart
      companyName =
          prefs.getString('company_name') ?? localizations.pdf_company_name;
      companyAddress = prefs.getString('company_address') ?? '';
      companyLogoPath = prefs.getString('companyLogo') ?? '';
      watermarkText = prefs.getString('watermarkText') ?? '';
      watermarkImagePath = prefs.getString('watermarkImage') ?? '';
      nbMessage = prefs.getString('nbMessage') ?? '';
      selectedWatermarkOption = prefs.getInt('watermarkOption') ?? 0;
      isLoadingCompanyInfo = false;
    });
  }

  Memo saveMemo() {
    double subtotal =
        getMemoizedSubtotal(); // This now includes individual product discounts
    double discount = double.tryParse(discountController.text) ?? 0;
    double vat = double.tryParse(vatController.text) ?? 0;

    double discountedTotal = isPercentDiscount
        ? subtotal - (subtotal * (discount / 100))
        : subtotal - discount;

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
      notes: notesController.text.isNotEmpty ? notesController.text : null,
      companyAddress: '',
      companyLogo: '',
    );
  }

  Future<Uint8List?> loadLogo(String? logoPath) async {
    if (kIsWeb) {
      // On web, no file system access; logo loading disabled
      return null;
    }
    if (logoPath != null && File(logoPath).existsSync()) {
      return await File(logoPath).readAsBytes();
    }
    return null;
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) {
      // Permissions not required on web.
      return;
    }
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
    if (kIsWeb) {
      // On web, directly navigate to PDF preview without showing ads
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfData: pdfData,
            fileName: fileName,
          ),
        ),
      );
      return;
    }
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
          });
      // Removed onAdClicked handler to comply with AdMob policy
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
            case 5:
              templateWidget = buildTemplate5(logoBytes, currentDate);
              break;
            case 6:
              templateWidget = buildTemplate6(logoBytes, currentDate);
              break;
            case 7:
              templateWidget = buildTemplate7(logoBytes, currentDate);
              break;
            case 8:
              templateWidget = buildTemplate8(logoBytes, currentDate);
              break;
            default:
              templateWidget = buildTemplate1(logoBytes, currentDate);
          }

          return pw.DefaultTextStyle.merge(
              style: const pw.TextStyle(lineSpacing: 2),
              child: pw.Stack(
                children: [
                  waterMarkWidget(selectedWatermarkOption, watermarkText,
                      watermarkImagePath),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      templateWidget,
                      pw.Expanded(child: pw.Container()),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.Text('Signature: ',
                              style: const pw.TextStyle(fontSize: 18)),
                          pw.Container(
                            width: 200,
                            height: 50,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(
                                    width: 1, color: PdfColors.black),
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
              ));
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
          style: const pw.TextStyle(color: PdfColors.grey),
        ),
      ],
    );
  }

  pw.Widget waterMarkWidget(int selectedWatermarkOption, String? watermarkText,
      String? watermarkImagePath) {
    // On web, watermark image is not supported due to lack of File API.
    if (kIsWeb) {
      // On web, only text watermark is supported. No File can be referenced here.
      if (selectedWatermarkOption == 0 || selectedWatermarkOption == 2) {
        return pw.Positioned.fill(
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
        );
      } else {
        return pw.Container();
      }
    } else {
      // Native platforms: allow file/image watermarks as before (safe to use File here)
      return pw.Positioned.fill(
        child: pw.Opacity(
          opacity: 0.1,
          child: pw.Stack(
            children: [
              // Both text and image
              if (selectedWatermarkOption == 2 &&
                  watermarkImagePath != null &&
                  File(watermarkImagePath).existsSync()) ...[
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(Uint8List.fromList(
                        File(watermarkImagePath).readAsBytesSync())),
                    fit: pw.BoxFit.contain,
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    (watermarkText ?? ''),
                    style: pw.TextStyle(
                        fontSize: 72,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
              // Only text
              if (selectedWatermarkOption == 0) ...[
                pw.Center(
                  child: pw.Text(
                    (watermarkText ?? ''),
                    style: pw.TextStyle(
                        fontSize: 72,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
              // Only image
              if (selectedWatermarkOption == 1 &&
                  watermarkImagePath != null &&
                  File(watermarkImagePath).existsSync()) ...[
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(Uint8List.fromList(
                        File(watermarkImagePath).readAsBytesSync())),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ],
              // Option 3: none
            ],
          ),
        ),
      );
    }
  }

// Modern Helper Functions for Templates
  pw.Widget buildModernProductTable() {
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        verticalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
      ),
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey800),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Text(
                'PRODUCT',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Text(
                'PRICE',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                  letterSpacing: 0.8,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Text(
                'QTY',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                  letterSpacing: 0.8,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Text(
                'DISCOUNT',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                  letterSpacing: 0.8,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Text(
                'TOTAL',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                  letterSpacing: 0.8,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        // Data Rows
        ...products.asMap().entries.map((entry) {
          int index = entry.key;
          Product product = entry.value;
          double productTotal = product.price * product.quantity;
          double discountAmount = _isProductDiscountPercent[index]
              ? productTotal * (product.discount / 100)
              : product.discount;
          double discountedTotal = productTotal - discountAmount;

          String discountDisplay = _isProductDiscountPercent[index]
              ? '${product.discount}%'
              : '৳${product.discount.toStringAsFixed(2)}';

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index.isEven ? PdfColors.white : PdfColors.grey50,
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Text(
                  product.name,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Text(
                  '৳${product.price.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Text(
                  product.quantity.toString(),
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Text(
                  discountDisplay,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Text(
                  '৳${discountedTotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget buildCleanProductTable() {
    return pw.Column(
      children: [
        // Header with bottom border only
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey800, width: 2)),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  'ITEM',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'PRICE',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                    letterSpacing: 1,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Text(
                  'QTY',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                    letterSpacing: 1,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'AMOUNT',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                    letterSpacing: 1,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),

        // Product rows with minimal styling
        ...products.asMap().entries.map((entry) {
          int index = entry.key;
          Product product = entry.value;
          double productTotal = product.price * product.quantity;
          double discountAmount = _isProductDiscountPercent[index]
              ? productTotal * (product.discount / 100)
              : product.discount;
          double discountedTotal = productTotal - discountAmount;

          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    product.name,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    '৳${product.price.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Text(
                    '${product.quantity}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    '৳${discountedTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget buildModernPricingDetails() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildModernPricingRow('Subtotal', '৳${getMemoizedSubtotal().toStringAsFixed(2)}', false),
          pw.SizedBox(height: 6),
          _buildModernPricingRow('Discount', '${discountController.text}%', false),
          pw.SizedBox(height: 6),
          _buildModernPricingRow('VAT/Tax', '${vatController.text}%', false),
          pw.SizedBox(height: 10),
          pw.Container(
            height: 1,
            color: PdfColors.grey400,
          ),
          pw.SizedBox(height: 10),
          _buildModernPricingRow('TOTAL', '৳${getMemoizedTotal().toStringAsFixed(2)}', true),
        ],
      ),
    );
  }

  pw.Widget _buildModernPricingRow(String label, String value, bool isTotal) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: isTotal ? 13 : 11,
            color: isTotal ? PdfColors.grey900 : PdfColors.grey700,
            letterSpacing: isTotal ? 0.5 : 0,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: isTotal ? 15 : 11,
            color: isTotal ? PdfColors.blue700 : PdfColors.grey800,
          ),
        ),
      ],
    );
  }

  // Helper to build notes section if notes exist
  pw.Widget? buildNotesSection() {
    if (notesController.text.isEmpty) {
      return null;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.amber200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Icon(
                const pw.IconData(0xe873), // note icon
                color: PdfColors.amber700,
                size: 16,
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'NOTES',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.amber900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            notesController.text,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey900,
              lineSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }

// Template 4: Modern Accent (Modernized - formerly Borderless)
  pw.Widget buildTemplate4(Uint8List? logoBytes, String currentDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Side accent bar
          pw.Row(
            children: [
              pw.Container(
                width: 6,
                height: 80,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.purple600,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CASH MEMO',
                      style: pw.TextStyle(
                        fontSize: 30,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.purple700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Invoice Date: $currentDate',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              if (logoBytes != null)
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.purple200, width: 2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Image(pw.MemoryImage(logoBytes), width: 50, height: 50),
                ),
            ],
          ),
          pw.SizedBox(height: 28),

          // Company and Customer in cards
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company Card
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.purple50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    border: pw.Border.all(color: PdfColors.purple100, width: 1.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 4,
                            height: 4,
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.purple600,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Text(
                            'FROM',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.purple700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        companyName ?? '',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        companyAddress ?? '',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 14),

              // Customer Card
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    border: pw.Border.all(color: PdfColors.grey200, width: 1.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 4,
                            height: 4,
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.grey700,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Text(
                            'BILL TO',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        customerNameController.text,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        customerAddressController.text,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Tel: ${customerPhoneNumberController.text}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Borderless product table with alternating row colors
          buildBorderlessProductTable(),
          pw.SizedBox(height: 24),

          // Summary section
          buildModernPricingDetails(),

          // Notes section (if exists)
          if (buildNotesSection() != null) ...[
            pw.SizedBox(height: 16),
            buildNotesSection()!,
          ],
        ],
      ),
    );
  }

  // Helper to build a modern borderless product table
  pw.Widget buildBorderlessProductTable() {
    return pw.Column(
      children: [
        // Header with purple accent
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: const pw.BoxDecoration(
            color: PdfColors.purple600,
            borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(8)),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  'PRODUCT',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'PRICE',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 0.8,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Text(
                  'QTY',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 0.8,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 0.8,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),

        // Product rows with alternating background
        ...products.asMap().entries.map((entry) {
          int index = entry.key;
          Product product = entry.value;
          double productTotal = product.price * product.quantity;
          double discountAmount = _isProductDiscountPercent[index]
              ? productTotal * (product.discount / 100)
              : product.discount;
          double discountedTotal = productTotal - discountAmount;

          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: index.isEven ? PdfColors.white : PdfColors.grey50,
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    product.name,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    '৳${product.price.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Text(
                    '${product.quantity}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    '৳${discountedTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),

        // Bottom border
        pw.Container(
          height: 2,
          decoration: const pw.BoxDecoration(
            color: PdfColors.purple200,
            borderRadius: pw.BorderRadius.vertical(bottom: pw.Radius.circular(8)),
          ),
        ),
      ],
    );
  }

// Template 1: Professional Classic (Modernized)
  pw.Widget buildTemplate1(Uint8List? logoBytes, String currentDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header with gradient effect simulation using colored box
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue700,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'CASH MEMO',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                pw.Text(
                  currentDate,
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Company and Customer Info Row
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Company Details
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FROM',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      if (logoBytes != null) ...[
                        pw.Image(pw.MemoryImage(logoBytes), width: 40, height: 40),
                        pw.SizedBox(height: 8),
                      ],
                      pw.Text(
                        companyName ?? '',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        companyAddress ?? '',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 16),

              // Customer Details
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILL TO',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        customerNameController.text,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        customerAddressController.text,
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Phone: ${customerPhoneNumberController.text}',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Products Table
          buildModernProductTable(),
          pw.SizedBox(height: 20),

          // Pricing Summary
          buildModernPricingDetails(),
        ],
      ),
    );
  }

// Template 2: Modern Elegance (Modernized)
  pw.Widget buildTemplate2(Uint8List? logoBytes, String currentDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Top Bar with accent color
          pw.Container(
            height: 8,
            decoration: const pw.BoxDecoration(
              color: PdfColors.green600,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
          ),
          pw.SizedBox(height: 20),

          // Header Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left Side - Company Info
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoBytes != null) ...[
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.green600, width: 2),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Image(pw.MemoryImage(logoBytes), width: 50, height: 50),
                    ),
                    pw.SizedBox(height: 12),
                  ],
                  pw.Text(
                    companyName ?? '',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    companyAddress ?? '',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                  ),
                ],
              ),

              // Right Side - Invoice Details
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'CASH MEMO',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green700,
                      letterSpacing: 1,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: PdfColors.green200),
                    ),
                    child: pw.Text(
                      'Date: $currentDate',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 28),

          // Customer Details Section
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.green200, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CUSTOMER INFORMATION',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow('Name:', customerNameController.text),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: _buildInfoRow('Phone:', customerPhoneNumberController.text),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                _buildInfoRow('Address:', customerAddressController.text),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Products Table
          buildModernProductTable(),
          pw.SizedBox(height: 20),

          // Footer with pricing
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: buildModernPricingDetails(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for info rows
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 60,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
          ),
        ),
      ],
    );
  }

// Template 3: Minimalist Clean (Modernized)
  pw.Widget buildTemplate3(Uint8List? logoBytes, String currentDate) {
    return pw.Stack(
      children: [
        // Subtle watermark
        if (watermarkText != null && watermarkText!.isNotEmpty)
          pw.Positioned.fill(
            child: pw.Opacity(
              opacity: 0.05,
              child: pw.Center(
                child: pw.Text(
                  watermarkText!,
                  style: pw.TextStyle(
                    fontSize: 80,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          ),

        // Clean content
        pw.Container(
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header - Centered and minimal
              pw.Center(
                child: pw.Column(
                  children: [
                    if (logoBytes != null) ...[
                      pw.Image(pw.MemoryImage(logoBytes), width: 60, height: 60),
                      pw.SizedBox(height: 12),
                    ],
                    pw.Text(
                      companyName ?? '',
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      companyAddress ?? '',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      width: 200,
                      height: 1,
                      color: PdfColors.grey300,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Date and Customer in a clean grid
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INVOICE DATE',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey600,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        currentDate,
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 40),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILL TO',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          customerNameController.text,
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey900,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          customerAddressController.text,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          customerPhoneNumberController.text,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 28),

              // Clean product table with minimal borders
              buildCleanProductTable(),
              pw.SizedBox(height: 24),

              // Pricing aligned to right
              pw.Row(
                children: [
                  pw.Spacer(),
                  pw.Container(
                    width: 240,
                    child: buildModernPricingDetails(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

// Template 5: Bold Gradient Header
  pw.Widget buildTemplate5(Uint8List? logoBytes, String currentDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Bold gradient header (simulated with red background)
          pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: const pw.BoxDecoration(
              color: PdfColors.red700,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CASH MEMO',
                  style: pw.TextStyle(
                    fontSize: 36,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      companyName ?? '',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red900,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                      ),
                      child: pw.Text(
                        currentDate,
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Content area
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company info
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'FROM',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    if (logoBytes != null) ...[
                      pw.Image(pw.MemoryImage(logoBytes), width: 45, height: 45),
                      pw.SizedBox(height: 8),
                    ],
                    pw.Text(
                      companyAddress ?? '',
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),

              // Customer info
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BILL TO',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      customerNameController.text,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      customerAddressController.text,
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Phone: ${customerPhoneNumberController.text}',
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Products table
          buildModernProductTable(),
          pw.SizedBox(height: 20),

          // Pricing
          pw.Row(
            children: [
              pw.Spacer(),
              pw.Container(
                width: 280,
                child: buildModernPricingDetails(),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Template 6: Executive Professional
  pw.Widget buildTemplate6(Uint8List? logoBytes, String currentDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(28),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Executive header with logo and details side by side
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo section
              if (logoBytes != null)
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue900, width: 3),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Image(pw.MemoryImage(logoBytes), width: 60, height: 60),
                ),
              pw.SizedBox(width: 20),

              // Company details
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      companyName ?? '',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      companyAddress ?? '',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),

              // Invoice badge
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue900,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      currentDate,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 28),

          // Divider
          pw.Container(
            height: 2,
            color: PdfColors.blue900,
          ),
          pw.SizedBox(height: 20),

          // Customer section
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              border: pw.Border.all(color: PdfColors.blue200, width: 1.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BILLED TO',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  customerNameController.text,
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  customerAddressController.text,
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Tel: ${customerPhoneNumberController.text}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Products
          buildModernProductTable(),
          pw.SizedBox(height: 24),

          // Summary
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NOTES',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Thank you for your business. Payment is due within 30 days.',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Container(
                width: 260,
                child: buildModernPricingDetails(),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Template 7: Creative Modern
  pw.Widget buildTemplate7(Uint8List? logoBytes, String currentDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Creative top section with diagonal accent
          pw.Stack(
            children: [
              // Background accent
              pw.Container(
                height: 120,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.orange500,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(16)),
                ),
              ),

              // Content
              pw.Container(
                height: 120,
                padding: const pw.EdgeInsets.all(20),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        if (logoBytes != null) ...[
                          pw.Container(
                            padding: const pw.EdgeInsets.all(8),
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
                            ),
                            child: pw.Image(pw.MemoryImage(logoBytes), width: 40, height: 40),
                          ),
                          pw.SizedBox(height: 10),
                        ],
                        pw.Text(
                          companyName ?? '',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'CASH MEMO',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.orange700,
                              letterSpacing: 1,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            currentDate,
                            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 28),

          // Customer and company details
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.orange200, width: 2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 6,
                            height: 6,
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.orange500,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            'FROM',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.orange700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        companyAddress ?? '',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    border: pw.Border.all(color: PdfColors.orange100, width: 1.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 6,
                            height: 6,
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.orange600,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            'BILL TO',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.orange700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        customerNameController.text,
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        customerAddressController.text,
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        customerPhoneNumberController.text,
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Products
          buildModernProductTable(),
          pw.SizedBox(height: 20),

          // Total
          buildModernPricingDetails(),
        ],
      ),
    );
  }

// Template 8: Elegant Minimalist
  pw.Widget buildTemplate8(Uint8List? logoBytes, String currentDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Elegant header with thin accent line
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 60,
                height: 4,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.teal600,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (logoBytes != null) ...[
                    pw.Image(pw.MemoryImage(logoBytes), width: 55, height: 55),
                    pw.SizedBox(width: 16),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          companyName ?? '',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          companyAddress ?? '',
                          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 32),

          // Invoice details in elegant grid
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Invoice Date',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    currentDate,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal700,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.teal600, width: 2),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  'CASH MEMO',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Customer section with elegant border
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: PdfColors.teal600, width: 4),
                top: pw.BorderSide(color: PdfColors.grey200, width: 1),
                right: pw.BorderSide(color: PdfColors.grey200, width: 1),
                bottom: pw.BorderSide(color: PdfColors.grey200, width: 1),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BILLING DETAILS',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600, letterSpacing: 1.2),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  customerNameController.text,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  customerAddressController.text,
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Phone: ${customerPhoneNumberController.text}',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 28),

          // Elegant product table
          buildCleanProductTable(),
          pw.SizedBox(height: 24),

          // Summary
          pw.Row(
            children: [
              pw.Spacer(),
              pw.Container(
                width: 280,
                child: buildModernPricingDetails(),
              ),
            ],
          ),

          // Footer accent line
          pw.SizedBox(height: 24),
          pw.Container(
            width: 100,
            height: 3,
            decoration: const pw.BoxDecoration(
              color: PdfColors.teal600,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
          ),
        ],
      ),
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
            pw.Text(companyName ?? '', style: const pw.TextStyle(fontSize: 20)),
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
      headers: ['Product name', 'Price', 'Quantity', 'Discount', 'Total'],
      data: products.asMap().entries.map((entry) {
        int index = entry.key;
        Product product = entry.value;
        double productTotal = product.price * product.quantity;
        double discountAmount = _isProductDiscountPercent[index]
            ? productTotal * (product.discount / 100)
            : product.discount;
        double discountedTotal = productTotal - discountAmount;

        String discountDisplay = _isProductDiscountPercent[index]
            ? '${product.discount}%'
            : '\$${product.discount.toStringAsFixed(2)}';

        return [
          product.name,
          product.price.toString(),
          product.quantity.toString(),
          discountDisplay,
          discountedTotal.toStringAsFixed(2)
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

// Helper to build pricing details (used across templates)
  pw.Widget buildPricingDetails() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        buildPricingRow('Subtotal', getMemoizedSubtotal().toStringAsFixed(2)),
        buildPricingRow('Discount', '${discountController.text}%'),
        buildPricingRow('Vat/Tax', '${vatController.text}%'),
        pw.Divider(),
        buildPricingRow('Total', getMemoizedTotal().toStringAsFixed(2)),
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
    return products.asMap().entries.fold(0.0, (total, entry) {
      int index = entry.key;
      Product product = entry.value;

      // Handle empty or invalid price and quantity fields
      double price = product.price;
      int quantity = product.quantity;
      double discount = product.discount;

      // Calculate product total after applying individual discount
      double productTotal = price * quantity;
      double discountAmount = _isProductDiscountPercent[index]
          ? productTotal * (discount / 100)
          : discount;
      double discountedProductTotal = productTotal - discountAmount;
      return total + discountedProductTotal;
    });
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

  void addProduct() {
    setState(() {
      // Initialize new product with empty fields
      products.add(Product(name: '', price: 0, quantity: 0, discount: 0));

      // Initialize controllers with empty text
      _nameControllers.add(TextEditingController());
      _priceControllers.add(TextEditingController(text: ''));
      _quantityControllers.add(TextEditingController(text: ''));
      _discountController.add(TextEditingController(text: ''));
      // Initialize discount type as percentage by default
      _isProductDiscountPercent.add(true);

      // Initialize cache for new product
      int newIndex = products.length - 1;
      _updateCachedItemTotal(newIndex);
      _clearMemoizationCache();
    });
  }

  void removeProduct(int index) {
    setState(() {
      products.removeAt(index);
    });
  }

  void _showTemplateSelectionDialog(BuildContext context, localizations) {
    final templates = [
      {
        'id': 1,
        'name': 'Professional Classic',
        'description': 'Modern blue header with organized sections',
        'icon': Icons.business_center_rounded,
        'color': Colors.blue.shade700,
      },
      {
        'id': 2,
        'name': 'Modern Elegance',
        'description': 'Green accent with clean professional layout',
        'icon': Icons.auto_awesome_rounded,
        'color': Colors.green.shade600,
      },
      {
        'id': 3,
        'name': 'Minimalist Clean',
        'description': 'Subtle watermark with centered design',
        'icon': Icons.fiber_manual_record_outlined,
        'color': Colors.grey.shade700,
      },
      {
        'id': 4,
        'name': 'Modern Accent',
        'description': 'Purple themed with borderless table',
        'icon': Icons.palette_rounded,
        'color': Colors.purple.shade600,
      },
      {
        'id': 5,
        'name': 'Bold Gradient',
        'description': 'Eye-catching red header with bold typography',
        'icon': Icons.gradient_rounded,
        'color': Colors.red.shade700,
      },
      {
        'id': 6,
        'name': 'Executive Professional',
        'description': 'Corporate style with detailed sections',
        'icon': Icons.workspace_premium_rounded,
        'color': Colors.indigo.shade900,
      },
      {
        'id': 7,
        'name': 'Creative Modern',
        'description': 'Orange creative design with unique layout',
        'icon': Icons.brush_rounded,
        'color': Colors.orange.shade600,
      },
      {
        'id': 8,
        'name': 'Elegant Minimalist',
        'description': 'Teal accents with sophisticated borders',
        'icon': Icons.diamond_outlined,
        'color': Colors.teal.shade600,
      },
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.article_outlined, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              const Text('Select Template'),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: templates.map((template) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          generateCashMemo(
                            localizations,
                            template['id'] as int,
                            selectedWatermarkOption,
                            watermarkText,
                            watermarkImagePath,
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: (template['color'] as Color).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: (template['color'] as Color).withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  template['icon'] as IconData,
                                  color: template['color'] as Color,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      template['name'] as String,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      template['description'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Arrow
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                localizations.dialog_cancel_label,
                style: TextStyle(color: Colors.grey.shade700),
              ),
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
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          title: Text(
            widget.memo != null ? 'Edit Cash Memo' : 'Create Cash Memo',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                Memo memo = saveMemo();
                Navigator.pop(context, memo);
              },
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                  child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        MediaQuery.of(context).size.width > 600 ? 32.0 : 16.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Company Header Card
                      Container(
                        margin: EdgeInsets.only(
                          bottom:
                              MediaQuery.of(context).size.width > 600 ? 32 : 24,
                        ),
                        padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width > 600 ? 32 : 24,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade100,
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.blue.shade100,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.business,
                              size: 40,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(height: 12),
                            isLoadingCompanyInfo
                                ? const CircularProgressIndicator()
                                : Text(
                                    companyName ?? 'Company Name',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blue.shade800,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                            const SizedBox(height: 8),
                            Text(
                              'Professional Cash Memo',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      _buildCustomerDetails(localizations),
                      const SizedBox(height: 20),
                      _buildProductList(localizations),
                      const SizedBox(height: 20),
                      // Modern Add Product Button
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal:
                              MediaQuery.of(context).size.width > 600 ? 24 : 16,
                        ),
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
                                content: Text(localizations.product_added),
                                backgroundColor: Colors.green.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text("Add New Item"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: Colors.green.shade200,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            minimumSize: const Size(double.infinity, 56),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildDiscountAndVatFields(localizations),
                      const SizedBox(height: 24),
                      // Modern Create Cash Memo Button
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal:
                              MediaQuery.of(context).size.width > 600 ? 24 : 16,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Memo memo = saveMemo();
                            _showTemplateSelectionDialog(
                                context, localizations);
                          },
                          icon: const Icon(Icons.receipt_long),
                          label: Text(localizations.create_cash_memo_label),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: Colors.blue.shade200,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            minimumSize: const Size(double.infinity, 60),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 10), // Add some space before the banner
              // Banner ad widget at the bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerDetails(localizations) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.width > 600 ? 32 : 24,
      ),
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width > 600 ? 32 : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Customer Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: customerNameController,
            decoration: InputDecoration(
              labelText: localizations.customer_name,
              labelStyle: TextStyle(color: Colors.blue.shade600),
              filled: true,
              fillColor: Colors.blue.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade100),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
              prefixIcon: Icon(Icons.person, color: Colors.blue.shade600),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: customerAddressController,
            decoration: InputDecoration(
              labelText: localizations.customer_address,
              labelStyle: TextStyle(color: Colors.blue.shade600),
              filled: true,
              fillColor: Colors.blue.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade100),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
              prefixIcon: Icon(Icons.location_on, color: Colors.blue.shade600),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: customerPhoneNumberController,
            decoration: InputDecoration(
              labelText: localizations.customer_phone_number,
              labelStyle: TextStyle(color: Colors.blue.shade600),
              filled: true,
              fillColor: Colors.blue.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade100),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
              prefixIcon: Icon(Icons.phone, color: Colors.blue.shade600),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: notesController,
            decoration: InputDecoration(
              labelText: 'Notes / Remarks (Optional)',
              labelStyle: TextStyle(color: Colors.blue.shade600),
              filled: true,
              fillColor: Colors.blue.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade100),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
              prefixIcon: Icon(Icons.note_alt_outlined, color: Colors.blue.shade600),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              hintText: 'Add any additional notes or remarks here...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(AppLocalizations localizations) {
    return Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Item Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '${products.length} items',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: List.generate(products.length, (index) {
                return ProductItemWidget(
                  index: index,
                  product: products[index],
                  nameController: _nameControllers[index],
                  priceController: _priceControllers[index],
                  quantityController: _quantityControllers[index],
                  discountController: _discountController[index],
                  isProductDiscountPercent: _isProductDiscountPercent[index],
                  totalProducts: products.length,
                  onDebouncedUpdate: _debouncedUpdateProduct,
                  onRemove: (int removeIndex) {
                    setState(() {
                      // Cancel any pending timer for this product
                      _productDebounceTimers[removeIndex]?.cancel();
                      _productDebounceTimers.remove(removeIndex);

                      // Remove from cache
                      _cachedItemTotals.remove(removeIndex);

                      // Remove product and controllers
                      products.removeAt(removeIndex);
                      _nameControllers.removeAt(removeIndex);
                      _priceControllers.removeAt(removeIndex);
                      _quantityControllers.removeAt(removeIndex);
                      _discountController.removeAt(removeIndex);
                      _isProductDiscountPercent.removeAt(removeIndex);

                      // Update cache indices for remaining products
                      Map<int, double> newCache = {};
                      Map<int, Timer?> newTimers = {};
                      for (int i = 0; i < products.length; i++) {
                        if (_cachedItemTotals
                            .containsKey(i >= removeIndex ? i + 1 : i)) {
                          newCache[i] =
                              _cachedItemTotals[i >= removeIndex ? i + 1 : i]!;
                        }
                        if (_productDebounceTimers
                            .containsKey(i >= removeIndex ? i + 1 : i)) {
                          newTimers[i] = _productDebounceTimers[
                              i >= removeIndex ? i + 1 : i];
                        }
                      }
                      _cachedItemTotals.clear();
                      _cachedItemTotals.addAll(newCache);
                      _productDebounceTimers.clear();
                      _productDebounceTimers.addAll(newTimers);

                      // Clear memoization cache after removing product
                      _clearMemoizationCache();
                    });
                  },
                  getCachedItemTotal: _getCachedItemTotal,
                  onDiscountTypeToggle: () {
                    setState(() {
                      _isProductDiscountPercent[index] =
                          !_isProductDiscountPercent[index];
                      _clearMemoizationCache();
                    });
                  },
                  localizations: localizations,
                );
              }),
            ),
          ],
        ));
  }

  Widget _buildDiscountAndVatFields(localizations) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                color: Colors.blue.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Discount & Tax',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextField(
                  controller: discountController,
                  focusNode: discountFocusNode,
                  onChanged: (value) {
                    setState(() {
                      discount = double.tryParse(value) ?? 0;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: localizations.discount_label,
                    hintText: '0.00',
                    prefixIcon: Icon(
                      Icons.percent,
                      color: Colors.blue.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue.shade600,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: vatController,
                  focusNode: vatFocusNode,
                  onChanged: (value) {
                    setState(() {
                      vat = double.tryParse(value) ?? 0;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: localizations.tax_label,
                    hintText: '0.00',
                    prefixIcon: Icon(
                      Icons.calculate,
                      color: Colors.blue.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue.shade600,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(localizations) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Colors.green.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Total Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '৳${getMemoizedSubtotal().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Discount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discount:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                isPercentDiscount
                    ? '${discountController.text}%'
                    : '৳${discountController.text}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // VAT
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VAT/Tax:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '${vatController.text}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                '৳${getMemoizedTotal().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildDiscountAndVatSection(localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                color: Colors.blue.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Discount & Tax',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextField(
                  controller: discountController,
                  focusNode: discountFocusNode,
                  decoration: InputDecoration(
                    labelText: localizations.discount_label,
                    labelStyle: TextStyle(color: Colors.blue.shade600),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue.shade400,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.money_off,
                      color: Colors.blue.shade600,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onTap: () {
                    if (discountController.text == '0.0') {
                      discountController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: vatController,
                  focusNode: vatFocusNode,
                  decoration: InputDecoration(
                    labelText: localizations.tax_label,
                    labelStyle: TextStyle(color: Colors.blue.shade600),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue.shade400,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.percent,
                      color: Colors.blue.shade600,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: isPercentDiscount,
                  onChanged: (value) {
                    setState(() {
                      isPercentDiscount = value ?? true;
                    });
                  },
                  activeColor: Colors.blue.shade600,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                localizations.percent_discount_label,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Extracted Product Item Widget for better performance
class ProductItemWidget extends StatefulWidget {
  final int index;
  final Product product;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController quantityController;
  final TextEditingController discountController;
  final bool isProductDiscountPercent;
  final Function(int, VoidCallback) onDebouncedUpdate;
  final Function(int) onRemove;
  final Function(int) getCachedItemTotal;
  final VoidCallback onDiscountTypeToggle;
  final AppLocalizations localizations;
  final int totalProducts;

  const ProductItemWidget({
    Key? key,
    required this.index,
    required this.product,
    required this.nameController,
    required this.priceController,
    required this.quantityController,
    required this.discountController,
    required this.isProductDiscountPercent,
    required this.onDebouncedUpdate,
    required this.onRemove,
    required this.getCachedItemTotal,
    required this.onDiscountTypeToggle,
    required this.localizations,
    required this.totalProducts,
  }) : super(key: key);

  @override
  State<ProductItemWidget> createState() => _ProductItemWidgetState();
}

class _ProductItemWidgetState extends State<ProductItemWidget> {
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    // Expand if:
    // - First product (index 0)
    // - Product has data (name, price, or quantity)
    // - Last product AND empty (newly added)
    bool isLastItem = widget.index == widget.totalProducts - 1;
    bool hasData = widget.product.name.isNotEmpty || widget.product.price > 0 || widget.product.quantity > 0;

    isExpanded = widget.index == 0 || hasData || (isLastItem && !hasData);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header that can be tapped to expand/collapse
          InkWell(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
              bottom: isExpanded ? Radius.zero : Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isExpanded
                      ? [Colors.green.shade50, Colors.green.shade100]
                      : [Colors.grey.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                  bottom: isExpanded ? Radius.zero : Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name.isNotEmpty
                              ? widget.product.name
                              : '${widget.localizations.product_name} ${widget.index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            fontSize: 16,
                          ),
                        ),
                        if (widget.product.price > 0 ||
                            widget.product.quantity > 0)
                          Text(
                            'Price: \$${widget.product.price.toStringAsFixed(2)} × ${widget.product.quantity}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '\$${widget.getCachedItemTotal(widget.index).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          if (isExpanded) _buildProductForm(),
        ],
      ),
    );
  }

  Widget _buildProductForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name Field
          _buildTextField(
            controller: widget.nameController,
            label: widget.localizations.product_name,
            icon: Icons.inventory_2_outlined,
            onChanged: (value) {
              widget.onDebouncedUpdate(widget.index, () {
                widget.product.name = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Price and Quantity Row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: widget.priceController,
                  label: widget.localizations.product_price,
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    widget.onDebouncedUpdate(widget.index, () {
                      widget.product.price = double.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: widget.quantityController,
                  label: widget.localizations.product_quantity,
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    widget.onDebouncedUpdate(widget.index, () {
                      widget.product.quantity = int.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Discount Section
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: widget.discountController,
                  label: widget.localizations.discount_label,
                  icon: Icons.local_offer_outlined,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    widget.onDebouncedUpdate(widget.index, () {
                      widget.product.discount = double.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: widget.isProductDiscountPercent,
                      onChanged: (value) => widget.onDiscountTypeToggle(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(
                      '%',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Remove Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => widget.onRemove(widget.index),
              icon: const Icon(Icons.remove_circle_outline),
              label: const Text("Remove Item"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade700,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onTap: () {
        if (controller.text == '0.0' || controller.text == '0') {
          controller.clear();
        }
      },
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade500, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
