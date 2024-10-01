import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'Memo.dart';
import 'memo_edit.dart';
import 'package:cash_memo_creator/l10n/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';

class MemoListScreen extends StatefulWidget {
  const MemoListScreen({super.key});

  @override
  MemoListScreenState createState() => MemoListScreenState();
}

class MemoListScreenState extends State<MemoListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Memo> _memos = []; // Define the _memos variable here

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<List<Memo>> loadMemos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? memosJson = prefs.getString('memos');
    if (memosJson != null) {
      try {
        List<dynamic> memosData = jsonDecode(memosJson);
        return memosData
            .map<Memo?>((item) {
              try {
                return Memo.fromJson(item);
              } catch (e) {
                print('Error parsing memo: $item\nError: $e');
                return null;
              }
            })
            .where((memo) => memo != null)
            .cast<Memo>()
            .toList();
      } catch (e) {
        print('Error loading memos: $e');
      }
    }
    return [];
  }

  Future<List<File>> loadSavedPdfFiles() async {
    final String pdfDirectory = '/sdcard/Documents/Invoice Generator/';
    Directory dir = Directory(pdfDirectory);
    if (await dir.exists()) {
      return dir
          .listSync()
          .where((file) => file.path.endsWith(".pdf"))
          .map((file) => File(file.path))
          .toList();
    } else {
      print("Directory does not exist: $pdfDirectory");
      return [];
    }
  }

  void saveMemos(List<Memo> memos) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String memosJson = jsonEncode(memos.map((memo) => memo.toJson()).toList());
    await prefs.setString('memos', memosJson);
  }

  Future<void> removeMemo(List<Memo> memos, int index) async {
    memos.removeAt(index);
    saveMemos(memos);
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
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: localizations.memosTab),
            Tab(text: localizations.pdfTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FutureBuilder<List<Memo>>(
            future: loadMemos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    localizations.noMemosAvailable,
                    style: const TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                );
              }
              return _buildMemoListView(snapshot.data!, localizations);
            },
          ),
          FutureBuilder<List<File>>(
            future: loadSavedPdfFiles(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    localizations.noPdfsAvailable,
                    style: const TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                );
              }
              return _buildPdfListView(snapshot.data!, localizations);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
            saveMemos(_memos);
          }
        },
        tooltip: localizations.generateCashMemo,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  Widget _buildMemoListView(List<Memo> memos, AppLocalizations localizations) {
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
          Expanded(
            child: ListView.builder(
              itemCount: memos.length,
              itemBuilder: (context, index) {
                final memo = memos[index];
                return Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                            backgroundColor: Colors.teal,
                            child:
                            Icon(Icons.business, color: Colors.white, size: 32),
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
                                icon: const Icon(Icons.edit, color: Colors.teal),
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
                                      memos[index] = updatedMemo;
                                    });
                                    saveMemos(memos);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(localizations.deleteMemo),
                                        content: Text(localizations.deletePdf),
                                        actions: [
                                          TextButton(
                                            child: Text(localizations.cancel),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          TextButton(
                                            child: Text(localizations.delete),
                                            onPressed: () {
                                              removeMemo(memos, index);
                                              setState(() {});
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal, // Button color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10), // Rounded corners
                                ),
                              ),
                              onPressed: () async {
                                // Redirect the user to MemoEdit and trigger auto-generation
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CashMemoEdit(
                                      memo: memo,
                                      memoIndex: index,
                                      autoGenerate: true, // Trigger auto-generation
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                localizations.generateCashMemo, // Use localized text
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
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildPdfListView( List<File> pdfFiles, AppLocalizations localizations) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade100, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListView.builder(
        itemCount: pdfFiles.length,
        itemBuilder: (context, index) {
          final file = pdfFiles[index];
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.white,
              child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.picture_as_pdf,
                        color: Colors.white, size: 32),
                  ),
                  title: Text(
                    file.path.split('/').last,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.teal,
                    ),
                  ),
                  trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(localizations.deletePdf),
                              content: Text(localizations.deletePdf),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(localizations.cancel),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      pdfFiles[index].deleteSync();
                                    //  _pdfFiles.removeAt(index);
                                    });
                                  },
                                  child: Text(localizations.delete),
                                ),
                              ],
                            );
                          },
                        );
                      })),
            ),
          );
        },
      ),
    );
  }
}
