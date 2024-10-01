import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'PdfSaver.dart';

class PdfPreviewScreen extends StatefulWidget {
  final Uint8List pdfData;
  final String fileName;

  const PdfPreviewScreen({super.key, required this.pdfData, required this.fileName});

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
          'PDF Preview',
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
            Navigator.pop(context);
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
        constraints: BoxConstraints.expand(), // Ensures full-screen coverage
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  'Preview of ${widget.fileName}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
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
                child: ElevatedButton.icon(
                  onPressed: () async {
                    PdfService().savePdf(widget.pdfData,"Invoice Generator",widget.fileName);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('PDF saved '),
                    ));
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
