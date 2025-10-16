import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'PdfSaver.dart';
import 'admob_ads/BannerAdWidget.dart';

class PdfPreviewScreen extends StatefulWidget {
  final Uint8List pdfData;
  final String fileName;

  const PdfPreviewScreen(
      {super.key, required this.pdfData, required this.fileName});

  @override
  PdfPreviewScreenState createState() => PdfPreviewScreenState();
}

class PdfPreviewScreenState extends State<PdfPreviewScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: const Color(0xFF1e40af),
        title: const Text(
          'PDF Preview',
          style: TextStyle(
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
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.background,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        constraints: BoxConstraints.expand(), // Ensures full-screen coverage
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        'Preview of ${widget.fileName}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 500, // Adjust this height according to your needs
                      child: PDFView(
                        pdfData: widget.pdfData,
                        autoSpacing: false,
                        enableSwipe: true,
                        pageSnap: true,
                        onError: (error) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error loading PDF: $error'),
                          ));
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: 200,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            PdfService().savePdf(widget.pdfData,
                                "Invoice Generator", widget.fileName);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text('PDF saved successfully!'),
                                ],
                              ),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ));
                          },
                          icon: const Icon(
                            Icons.save_alt,
                            color: Colors.white,
                            size: 24,
                          ),
                          label: const Text(
                            'Save PDF',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Add the Banner Ad widget here, stuck at the bottom
            if(kIsWeb==false)
              MyBannerAdWidget(), // Replace with your actual banner ad widget
          ],
        ),
      ),
    );
  }
}
