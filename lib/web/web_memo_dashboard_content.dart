import 'package:flutter/material.dart';
import '../Memo.dart';
import '../services/memo_firestore_service.dart';
import 'web_memo_create_dialog.dart';
import 'web_memo_detail_panel.dart';

/// Dashboard for web that shows the list of cash memos coming directly
/// from Firestore (scoped to the current user via MemoFirestoreService).
class WebMemoDashboardContent extends StatefulWidget {
  const WebMemoDashboardContent({super.key});

  @override
  State<WebMemoDashboardContent> createState() =>
      _WebMemoDashboardContentState();
}

class _WebMemoDashboardContentState extends State<WebMemoDashboardContent> {
  Memo? _selectedMemo;

  void _openCreateDialog({Memo? initial}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WebMemoCreateDialog(
        initialMemo: initial,
        onSave: (_) {
          // MemoFirestoreService.upsertMemo is already called inside the dialog.
          // No extra action required; the stream will update automatically.
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedMemo != null) {
      return WebMemoDetailPanel(
        memo: _selectedMemo!,
        onBack: () => setState(() => _selectedMemo = null),
      );
    }

    return StreamBuilder<List<Memo>>(
      stream: MemoFirestoreService.memoStream(),
      builder: (context, snapshot) {
        final memos = snapshot.data ?? [];
        print("MEMO DATA DB: ${memos.length}");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (memos.isEmpty) {
          return Stack(
            children: [
              const Center(child: Text('No memos saved yet.')),
              _buildFab(),
            ],
          );
        }

        return Stack(
          children: [
            ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: memos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final memo = memos[index];
                return _buildMemoCard(memo);
              },
            ),
            _buildFab(),
          ],
        );
      },
    );
  }

  Widget _buildFab() {
    return Positioned(
      bottom: 24,
      right: 32,
      child: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Create Memo'),
        onPressed: () => _openCreateDialog(),
      ),
    );
  }

  Widget _buildMemoCard(Memo memo) {
    return Card(
      elevation: 5,
      shadowColor: const Color(0x200f172a),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openCreateDialog(initial: memo),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFF0f172a),
                child: Icon(Icons.description_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memo.companyName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0f172a),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person,
                            color: Color(0xFF94a3b8), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          memo.customerName,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF64748b)),
                        ),
                        const Spacer(),
                        const Icon(Icons.calendar_today_outlined,
                            color: Color(0xFF94a3b8), size: 17),
                        const SizedBox(width: 4),
                        Text(
                          (memo.date ?? '').isNotEmpty
                              ? memo.date!.split('T').first
                              : '',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF8B9CB6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.sell,
                            color: Color(0xFF059669), size: 16),
                        const SizedBox(width: 3),
                        const Text(
                          'Memo total:',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Color(0xFF475569)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '৳${memo.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF475569), size: 34),
            ],
          ),
        ),
      ),
    );
  }
}
