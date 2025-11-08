import 'package:cash_memo_creator/src/stub_io.dart';
import 'package:cash_memo_creator/widgets/professional_memo_card.dart';
import 'package:cash_memo_creator/widgets/statistics_dashboard.dart';
import 'package:flutter/foundation.dart';
import 'web/web_memo_list_screen.dart';
// dart:io is used only on non-web platforms
import 'dart:io' if (dart.library.html) 'src/stub_io.dart';
import 'dart:isolate';
import 'package:cash_memo_creator/AndroidAPILevel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart'; // Used only on mobile, web unsupported.
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Not used on web.
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'Memo.dart';
// import 'NativeAdContainer.dart'; // Removed
import 'admob_ads/BannerAdWidget.dart'; // still imported, not used
import 'memo_edit.dart';
import 'package:cash_memo_creator/l10n/gen_l10n/app_localizations.dart';
import 'design_system.dart';
import 'widgets/professional_widgets.dart';

class MemoListScreen extends StatefulWidget {
  const MemoListScreen({super.key});

  @override
  MemoListScreenState createState() => MemoListScreenState();
}

class MemoListScreenState extends State<MemoListScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  List<Memo> _memos = [];
  late TabController _tabController;
  // Use correct file entity for web
  // Use platform-specific file entity list
  dynamic _pdfFiles = kIsWeb ? <WebFileEntity>[] : <FileSystemEntity>[];
  // Cache for formatted last-modified timestamps to avoid expensive I/O in every build
  Map<String, String> _pdfModifiedDates = {};

  // Performance optimization: Cache expensive computations
  late final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

  // Memoized theme and localization to avoid repeated lookups
  ThemeData? _cachedTheme;
  AppLocalizations? _cachedLocalizations;

  // PDF file caching
  List<FileSystemEntity>? _cachedPdfFiles;
  DateTime? _lastPdfCacheTime;

  Future<void> _requestStoragePermission() async {
    if (kIsWeb) return;
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  void _openPdfOnPlatform(String filePath) async {
    if (kIsWeb) {
      // Opening native files not supported on web.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening PDFs is not supported on the web.')),
      );
      return;
    }
    await OpenFile.open(filePath);
  }

  void _sharePdfOnPlatform(String filePath) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sharing PDFs is not supported on the web.')),
      );
      return;
    }
    await Share.shareXFiles([XFile(filePath)], text: 'PDF');
  }

  @override
  void initState() {
    super.initState();
    // Clear memoization caches on initialization
    _MemoizationCache.clearCache();
    loadMemos();
    _requestStoragePermission();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _loadSavedPdfs();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    // Clear memoization caches on disposal
    _MemoizationCache.clearCache();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSavedPdfs();
    }
  }

  Future<List<Memo>> _parseMemos(String jsonStr) async {
    return (jsonDecode(jsonStr) as List<dynamic>)
        .map((item) {
          try {
            return Memo.fromJson(item);
          } catch (_) {
            return null;
          }
        })
        .whereType<Memo>()
        .toList();
  }

  void loadMemos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final memosJson = prefs.getString('memos');

    if (memosJson != null) {
      final List<dynamic> memosList = jsonDecode(memosJson);
      setState(() {
        _memos = memosList.map((json) => Memo.fromJson(json)).toList();
      });
    }
  }

  void saveMemos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String memosJson = jsonEncode(_memos.map((memo) => memo.toJson()).toList());
    await prefs.setString('memos', memosJson);
  }

  void removeMemo(int index) {
    setState(() {
      _memos.removeAt(index);
    });
    saveMemos();
  }

  String formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return WebMemoListScreen(memos: _memos);
    }
    // Cache theme and localizations to avoid repeated lookups
    _cachedTheme ??= Theme.of(context);
    _cachedLocalizations ??= AppLocalizations.of(context)!;
    final localizations = _cachedLocalizations!;
    final theme = _cachedTheme!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF), // Colors.white.withOpacity(0.2)
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              localizations.savedMemos,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF), // Colors.white.withOpacity(0.2)
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x26FFFFFF), // Colors.white.withOpacity(0.15)
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0x4DFFFFFF), // Colors.white.withOpacity(0.3)
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor:
                  const Color(0xB3FFFFFF), // Colors.white.withOpacity(0.7)
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          localizations.memosTab,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          localizations.pdfTab,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  try {
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSavedMemosTab(),
                        kIsWeb ? _buildPdfWebWarningTab() : _buildShowPdfTab(),
                      ],
                    );
                  } catch (e) {
                    // Fallback UI in case of layout errors
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Layout Error',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
            // Only show ads on mobile (not web)
            if (!kIsWeb)
              SafeArea(
                child: MyBannerAdWidget(),
              ),
          ],
        ),
      ),
    );
  }

  // Add this widget for the web PDF tab
  Widget _buildPdfWebWarningTab() {
    return const EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'PDF Features Not Available',
      description: 'PDF preview and file management features are only available in the mobile version of the app.',
    );
  }

  Future<List<FileSystemEntity>> _getCachedPdfFiles() async {
    final now = DateTime.now();

    // Return cached files if they're less than 30 seconds old
    if (_cachedPdfFiles != null &&
        _lastPdfCacheTime != null &&
        now.difference(_lastPdfCacheTime!).inSeconds < 30) {
      return _cachedPdfFiles!;
    }

    // Refresh cache
    await _loadSavedPdfs();
    _cachedPdfFiles = List.from(_pdfFiles); // Create a copy
    _lastPdfCacheTime = now;

    return _cachedPdfFiles!;
  }

  void _refreshPdfCache() {
    _cachedPdfFiles = null;
    _lastPdfCacheTime = null;
  }

  static Future<Map<String, dynamic>> _loadPdfsInIsolate(
      String directoryPath) async {
    final pdfDirectory = Directory(directoryPath);
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

    if (await pdfDirectory.exists()) {
      final files = await pdfDirectory
          .list()
          .where((file) => file.path.endsWith('.pdf'))
          .toList();

      final modDates = <String, String>{};
      for (final file in files) {
        final last = File(file.path).lastModifiedSync();
        modDates[file.path] = dateFormatter.format(last);
      }

      return {
        'files': files.map((f) => f.path).toList(),
        'modDates': modDates,
      };
    }

    return {'files': <String>[], 'modDates': <String, String>{}};
  }

  Future<void> _loadSavedPdfs() async {
    Directory? pdfDirectory;
    if (Platform.isAndroid) {
      if (await AndroidAPILevel.getApiLevel() <= 29) {
        if (await Permission.storage.isGranted) {
          pdfDirectory =
              Directory("/storage/emulated/0/Documents/Invoice Generator");
        }
      } else {
        pdfDirectory =
            Directory("/storage/emulated/0/Documents/Invoice Generator");
      }
    } else {
      pdfDirectory = kIsWeb
          ? Directory("")
          : (await getApplicationDocumentsDirectory()) as Directory;
    }

    if (pdfDirectory != null && await pdfDirectory.exists()) {
      try {
        final result =
            await Isolate.run(() => _loadPdfsInIsolate(pdfDirectory!.path));
        final filePaths = result['files'] as List<String>;
        final modDates = result['modDates'] as Map<String, String>;

        setState(() {
          _pdfFiles = kIsWeb
              ? List<WebFileEntity>.generate(
                  filePaths.length, (_) => WebFileEntity())
              : filePaths.map((path) => File(path)).toList();
          _pdfModifiedDates = modDates;
        });
      } catch (e) {
        // Fallback to main thread if isolate fails
        final files = await pdfDirectory
            .list()
            .where((file) => file.path.endsWith('.pdf'))
            .toList();
        final modDates = <String, String>{};
        for (final file in files) {
          final last = File(file.path).lastModifiedSync();
          modDates[file.path] = _dateFormatter.format(last);
        }
        setState(() {
          _pdfFiles = files;
          _pdfModifiedDates = modDates;
        });
      }
    }
  }

  String _getLastModifiedDate(FileSystemEntity file) {
    return _pdfModifiedDates[file.path] ?? '';
  }

  Widget _buildShowPdfTab() {
    return FutureBuilder<List<FileSystemEntity>>(
      future: _getCachedPdfFiles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final pdfFiles = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(12.0),
          child: pdfFiles.isNotEmpty
              ? ListView.builder(
                  itemCount: pdfFiles.length,
                  // Performance optimizations
                  // Removed fixed itemExtent to avoid vertical overflow with wrapped text
                  cacheExtent: 500, // Cache more items for smoother scrolling
                  physics: const BouncingScrollPhysics(), // Better scroll feel
                  itemBuilder: (context, index) {
                    final pdfFile = pdfFiles[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        isThreeLine: true,
                        leading: const Icon(Icons.picture_as_pdf,
                            color: Colors.redAccent, size: 36),
                        title: Text(
                          _MemoizationCache.extractFileName(pdfFile.path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pdfFile.path,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Last modified: ${_getLastModifiedDate(pdfFile)}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share, color: Colors.blue),
                              onPressed: () => _sharePdf(pdfFile.path),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _showDeleteConfirmationDialog(pdfFile),
                            ),
                          ],
                        ),
                        onTap: () => _openPdf(pdfFile.path),
                      ),
                    );
                  },
                )
              : const EmptyState(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'No PDF Files',
                  description: 'Generated PDF invoices will appear here. Create your first cash memo to get started.',
                ),
        );
      },
    );
  }

  void _openPdf(String filePath) async {
    final result = await OpenFile.open(filePath, type: "application/pdf");
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening PDF: ${result.message}')),
      );
    }
  }

  void _showDeleteConfirmationDialog(FileSystemEntity file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete PDF"),
          content: const Text("Are you sure you want to delete this PDF file?"),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _cachedTheme!.colorScheme.surface,
                    Color.alphaBlend(
                        const Color(0x33000000),
                        _cachedTheme!
                            .colorScheme.surface), // surface.withOpacity(0.8)
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color.alphaBlend(
                      const Color(0x4D000000),
                      _cachedTheme!
                          .colorScheme.outline), // outline.withOpacity(0.3)
                ),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: _cachedTheme!.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _cachedTheme!.colorScheme.onSurface
                        .withAlpha(204), // withOpacity(0.8)
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFdc2626), // Professional red
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Color(
                        0x1Adc2626), // Simplified shadow with reduced opacity
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () {
                  _deletePdfFile(file);
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Delete",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> _deletePdfInIsolate(String filePath) async {
    try {
      await File(filePath).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  void _deletePdfFile(FileSystemEntity file) async {
    try {
      final success = await Isolate.run(() => _deletePdfInIsolate(file.path));

      if (success) {
        _refreshPdfCache();
        setState(() {
          _pdfFiles.remove(file);
          _pdfModifiedDates.remove(file.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF file deleted successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting file')),
        );
      }
    } catch (e) {
      // Fallback to main thread if isolate fails
      try {
        await file.delete();
        _refreshPdfCache();
        setState(() {
          _pdfFiles.remove(file);
          _pdfModifiedDates.remove(file.path);
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
  }

  void _sharePdf(String filePath) {
    Share.shareXFiles([XFile(filePath)], text: 'Check out this PDF file!');
  }

  Widget _buildSavedMemosTab() {
    final localizations = _cachedLocalizations!;

    return Column(
      children: [
        // Statistics Dashboard (only show if memos exist)
        if (_memos.isNotEmpty)
          StatisticsDashboard(memos: _memos),

        // Professional Create Button
        ProfessionalCreateButton(
          title: localizations.generateCashMemo,
          subtitle: 'Generate professional invoices instantly',
          onPressed: () async {
            Memo? newMemo = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CashMemoEdit(autoGenerate: true),
              ),
            );
            if (newMemo != null) {
              setState(() => _memos.add(newMemo));
              saveMemos();
            }
          },
        ),

        // Memos List or Empty State
        _memos.isNotEmpty
            ? Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: _memos.length,
                  cacheExtent: 1000,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final memo = _memos[index];
                    return ProfessionalMemoCard(
                      memo: memo,
                      index: index,
                      onEdit: _editMemo,
                      onDelete: _deleteMemo,
                      onPrint: _printMemo,
                    );
                  },
                ),
              )
            : Expanded(
                child: EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'No Memos Yet',
                  description: 'Create your first professional cash memo to get started with invoicing',
                  actionText: 'Create First Memo',
                  onAction: () async {
                    Memo? newMemo = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CashMemoEdit(autoGenerate: true),
                      ),
                    );
                    if (newMemo != null) {
                      setState(() => _memos.add(newMemo));
                      saveMemos();
                    }
                  },
                ),
              ),
      ],
    );
  }

  Future<void> _editMemo(int index) async {
    final memo = _memos[index];
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
      setState(() => _memos[index] = updatedMemo);
      saveMemos();
    }
  }

  void _deleteMemo(int index) {
    final localizations = _cachedLocalizations!;
    final theme = _cachedTheme!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          localizations.deleteMemo,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0f172a),
          ),
        ),
        content: Text(
          localizations.confirmDelete,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF64748b),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748b),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            child: Text(
              localizations.cancel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            onPressed: () {
              removeMemo(index);
              Navigator.of(context).pop();
            },
            child: Text(
              localizations.delete,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printMemo(int index) async {
    final memo = _memos[index];
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
  }
}

// Memoization caches for performance optimization
class _MemoizationCache {
  static final Map<String, String> _dateFormatCache = {};
  static final Map<String, String> _fileNameCache = {};

  static String formatDate(String date) {
    return _dateFormatCache.putIfAbsent(date, () {
      DateTime parsedDate = DateTime.parse(date);
      return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
    });
  }

  static String extractFileName(String filePath) {
    return _fileNameCache.putIfAbsent(filePath, () {
      return filePath.split(Platform.pathSeparator).last;
    });
  }

  static void clearCache() {
    _dateFormatCache.clear();
    _fileNameCache.clear();
  }
}

// Separate widget for memo items to improve performance
class MemoItem extends StatelessWidget {
  final Memo memo;
  final int index;
  final Function(int) onEdit;
  final Function(int) onDelete;
  final Function(int) onPrint;
  final ThemeData theme;
  final AppLocalizations localizations;

  const MemoItem({
    super.key,
    required this.memo,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.onPrint,
    required this.theme,
    required this.localizations,
  });

  String formatDate(String date) {
    return _MemoizationCache.formatDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFe2e8f0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header with customer info
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0x140f172a),
                    child: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF0f172a),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memo.customerName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0f172a),
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.currency_exchange,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '৳${memo.total.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Date and actions section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFf8fafc),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_outlined,
                        size: 16,
                        color: Color(0xFF64748b),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          memo.date != null && memo.date!.isNotEmpty
                              ? formatDate(memo.date!)
                              : localizations.dateNotAvailable,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF64748b),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const Spacer(),
                      Chip(
                        label: Text(
                          'MEMO',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF0f172a),
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                        backgroundColor: const Color(0x140f172a),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Edit button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onEdit(index),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                          ),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0f172a),
                            side: const BorderSide(
                              color: Color(0xFFe2e8f0),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Delete button
                      OutlinedButton(
                        onPressed: () => onDelete(index),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFef4444),
                          side: const BorderSide(
                            color: Color(0xFFef4444),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Print button section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                onPressed: () => onPrint(index),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.print_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      localizations.printCashMemo,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
