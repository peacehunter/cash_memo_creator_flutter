import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'Memo.dart';
import 'memo_edit.dart'; // Import your CashMemoEdit page
import 'package:cash_memo_creator/l10n/gen_l10n/app_localizations.dart'; // Import localization

class MemoListScreen extends StatefulWidget {
  const MemoListScreen({super.key});

  @override
  MemoListScreenState createState() => MemoListScreenState();
}

class MemoListScreenState extends State<MemoListScreen> {
  List<Memo> _memos = [];

  @override
  void initState() {
    super.initState();
    loadMemos();
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
    final localizations = AppLocalizations.of(context)!; // Get localization

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.savedMemos), // Use localized text
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings'); // Navigate to SettingsPage
            },
          ),
        ],
      ),
      body: _memos.isNotEmpty
          ? ListView.builder(
        itemCount: _memos.length,
        itemBuilder: (context, index) {
          final memo = _memos[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Card(
              elevation: 4,
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
                      child: Icon(Icons.business, color: Colors.white),
                    ),
                    title: Text(
                      memo.companyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.teal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${localizations.total}: ${memo.total}', // Use localized text
                          style: const TextStyle(color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          memo.date != null && memo.date!.isNotEmpty
                              ? '${localizations.date}: ${formatDate(memo.date!)}' // Use localized text
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
                                _memos[index] = updatedMemo;
                              });
                              saveMemos();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            // Confirm before deleting
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(localizations.deleteMemo), // Use localized text
                                  content: Text(localizations.confirmDelete), // Use localized text
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(localizations.cancel), // Use localized text
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        removeMemo(index); // Remove the memo
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(localizations.delete), // Use localized text
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
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
      )
          : Center(
        child: Text(localizations.noSavedMemos), // Use localized text
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
            saveMemos(); // Save the new memo
          }
        },
        tooltip: localizations.generateCashMemo, // Use localized text
        child: const Icon(Icons.add),
      ),
    );
  }
}
