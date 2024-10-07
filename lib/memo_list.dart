import 'dart:io';

import 'package:cash_memo_creator/AndroidAPILevel.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'Memo.dart';
import 'admob_ads/BannerAdWidget.dart';
import 'memo_edit.dart'; // Import your CashMemoEdit page
import 'package:cash_memo_creator/l10n/gen_l10n/app_localizations.dart'; // Import localization

class MemoListScreen extends StatefulWidget {
  const MemoListScreen({super.key});

  @override
  MemoListScreenState createState() => MemoListScreenState();
}

class MemoListScreenState extends State<MemoListScreen>
    with SingleTickerProviderStateMixin,WidgetsBindingObserver {
  List<Memo> _memos = [];
  late TabController _tabController;
  List<FileSystemEntity> _pdfFiles = [];

  @override
  void initState() {
    super.initState();
    loadMemos();
    _requestStoragePermission(); // Request permission before loading PDFs
    WidgetsBinding.instance.addObserver(this);  // Add the observer here

    _tabController = TabController(
        length: 2, vsync: this); // Use 'this' as the TickerProvider
  //  print("Saved PDF length: ${_tabController.indexIsChanging}");

    // Add a listener to the TabController
    _tabController.addListener(() {
      print("Saved PDF : listener started");

        print("Saved PDF : ${_tabController.index}");

        // This is called when the user swipes to a new tab
        if (_tabController.index == 1) {
          // "Saved PDF Cash Memo" tab is in focus
          print("Saved PDF Cash Memo tab is in focus");
          print("Saved PDF : ${_tabController.index}");
          // You can add any logic here, like refreshing data or showing an alert
          // load saved pdf from storage when the respective tab is in focus
          _loadSavedPdfs(); // Load PDFs from storage when the screen initializes

        }

    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);  // Remove the observer

    _tabController.dispose();
    print("Saved PDF test: disposed");

    super.dispose();
  }

  // This is where you handle lifecycle changes like onResume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("page status : $state");
    if (state == AppLifecycleState.resumed) {
      // Load the ad when the app is resumed
      print("page status : page resumed");
      _loadSavedPdfs();
    }
  }


  void loadMemos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? memosJson = prefs.getString('memos');
    if (memosJson != null) {
      try {
        List<dynamic> memosData = jsonDecode(memosJson);
        setState(() {
          _memos = memosData
              .map((item) {
            try {
              return Memo.fromJson(item);
            } catch (e) {
              print('Error parsing memo: $item\nError: $e');
              return null; // Return null if there's an error
            }
          })
              .where((memo) => memo != null)
              .cast<Memo>()
              .toList(); // Filter out nulls
        });
      } catch (e) {
        print('Error loading memos: $e');
      }
    }
  }

  void saveMemos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String memosJson = jsonEncode(_memos.map((memo) => memo.toJson()).toList());
    await prefs.setString('memos', memosJson);
  }

  // Method to remove a memo
  void removeMemo(int index) {
    setState(() {
      _memos.removeAt(index);
    });
    saveMemos(); // Save the updated list
  }

  String formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

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
          localizations.savedMemos,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 28,
            ),
            tooltip: 'settings',
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: localizations.memosTab),
            Tab(text: localizations.pdfTab),
          ],
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
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSavedMemosTab(),
                  _buildShowPdfTab(),
                ],
              ),
            ),
            const SizedBox(height: 10), // Add some space before the banner
            MyBannerAdWidget(), // Display the banner ad at the bottom
          ],
        ),
      ),
    );
  }
  /// Loads a banner ad.
  // Request storage permissions
  void _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        _loadSavedPdfs();
      }
    } else {
      _loadSavedPdfs();
    }
  }

  // Load saved PDFs
  void _loadSavedPdfs() async {
    Directory? pdfDirectory;
    if (Platform.isAndroid) {
      if(await AndroidAPILevel.getApiLevel() <= 29) {
        if (await Permission.storage.isGranted) {
          const String pdfDirectoryPath = "/storage/emulated/0/Documents/Invoice Generator";
          pdfDirectory = Directory(pdfDirectoryPath);
        }
      }else{
        const String pdfDirectoryPath = "/storage/emulated/0/Documents/Invoice Generator";
         pdfDirectory = Directory(pdfDirectoryPath);

        if (await pdfDirectory.exists()) {
          setState(() {
            _pdfFiles = pdfDirectory!.listSync().where((file) => file.path.endsWith(".pdf")).toList();
          });
        }
      }
    } else {
      pdfDirectory = await getApplicationDocumentsDirectory(); // For non-Android
    }

    if (pdfDirectory != null && await pdfDirectory.exists()) {
      setState(() {
        _pdfFiles = pdfDirectory!.listSync().where((file) => file.path.endsWith(".pdf")).toList();
      });
    }
  }

  // Method to format the last modified date
  String _getLastModifiedDate(FileSystemEntity file) {
    final lastModified = File(file.path).lastModifiedSync();
    return DateFormat('yyyy-MM-dd HH:mm').format(lastModified);
  }

  Widget _buildShowPdfTab() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: _pdfFiles.isNotEmpty
          ? ListView.builder(
        itemCount: _pdfFiles.length,
        itemBuilder: (context, index) {
          final pdfFile = _pdfFiles[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: const Icon(
                Icons.picture_as_pdf,
                color: Colors.redAccent,
                size: 36.0, // PDF icon on the left
              ),
              title: Text(
                pdfFile.path.split('/').last, // Display the file name
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pdfFile.path, // Display the file path
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4), // Add space between file path and date
                  Text(
                    'Last modified: ${_getLastModifiedDate(pdfFile)}', // Display the last modified date
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.blue),
                    onPressed: () {
                      _sharePdf(pdfFile.path); // Share the PDF file
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _showDeleteConfirmationDialog(pdfFile); // Show confirmation dialog before deleting
                    },
                  ),
                ],
              ),
              onTap: () {
                _openPdf(pdfFile.path); // Open PDF on tap
              },
            ),
          );
        },
      )
          : const Center(
        child: Text("No PDF files found in the specified directory."),
      ),
    );
  }

  // Method to open the PDF using the 'open_file' package
  void _openPdf(String filePath) async {
    final result = await OpenFile.open(filePath,type:"application/pdf");

    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening PDF: ${result.message}'),
        ),
      );
    }
  }

  // Method to show a confirmation dialog for deleting the PDF
  void _showDeleteConfirmationDialog(FileSystemEntity file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete PDF"),
          content: const Text("Are you sure you want to delete this PDF file?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text("Delete"),
              onPressed: () {
                _deletePdfFile(file);
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Method to delete the PDF file
  void _deletePdfFile(FileSystemEntity file) async {
    try {
      await file.delete(); // Delete the file
      setState(() {
        _pdfFiles.remove(file); // Remove the file from the list
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF file deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting file: $e')),
      );
    }
  }

  // Method to share the PDF file
  void _sharePdf(String filePath) {
    Share.shareXFiles([XFile(filePath)], text: 'Check out this PDF file!');
  }


  Widget _buildSavedMemosTab() {
    final localizations = AppLocalizations.of(context)!; // Get localization

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade100, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Add "Create Cash Memo" button at the top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.white, size: 24),
                label:  Text(localizations.generateCashMemo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  Memo? newMemo = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CashMemoEdit(autoGenerate: true),
                    ),
                  );
                  if (newMemo != null) {
                    setState(() {
                      _memos.add(newMemo);
                    });
                    saveMemos(); // Save the new memo
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: _memos.isNotEmpty
                ? ListView.builder(
              itemCount: _memos.length,
              itemBuilder: (context, index) {
                final memo = _memos[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.white,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.business,
                                color: Colors.white, size: 32),
                          ),
                          title: Text(
                            memo.customerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.teal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${localizations.total}: ${memo.total}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                memo.date != null && memo.date!.isNotEmpty
                                    ? '${localizations.date}: ${formatDate(memo.date!)}'
                                    : localizations.dateNotAvailable,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.teal),
                                onPressed: () async {
                                  Memo? updatedMemo = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CashMemoEdit(
                                        memo: memo,
                                        memoIndex: index,
                                        autoGenerate: false,
                                      ),
                                    ),
                                  );
                                  if (updatedMemo != null) {
                                    setState(() {
                                      _memos[index] = updatedMemo;
                                    });
                                    saveMemos();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(localizations.deleteMemo),
                                        content: Text(localizations.confirmDelete),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(localizations.cancel),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              removeMemo(index);
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(localizations.delete),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CashMemoEdit(
                                      memo: memo,
                                      memoIndex: index,
                                      autoGenerate: true,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                localizations.printCashMemo,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
                : Center(
              child: Text(localizations.noSavedMemos),
            ),
          ),
        ],
      ),
    );
  }
}
