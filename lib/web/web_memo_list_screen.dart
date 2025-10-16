import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../Memo.dart';
import 'web_memo_dashboard_content.dart';
import 'web_pdf_dashboard_content.dart';
import 'web_settings_content.dart';

class WebMemoListScreen extends StatefulWidget {
  final List<Memo> memos;
  const WebMemoListScreen({Key? key, this.memos = const []}) : super(key: key);
  @override
  State<WebMemoListScreen> createState() => _WebMemoListScreenState();
}

class _WebMemoListScreenState extends State<WebMemoListScreen> {
  int selectedIndex = 0;
  final sectionTitles = ["Memos", "PDFs", "Settings"];
  // Use mobile colors
  static const Color sidebarColor = Color(0xFF0f172a);
  static const Color sidebarHighlight = Color(0xFF059669);
  static const Color sidebarText = Colors.white70;
  static const Color sidebarSelectedBg = Color(0x33059669);
  static const Color contentBackground = Color(0xFFf8fafc);
  static const Color contentCard = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x110f172a);

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (selectedIndex) {
      case 0:
        content = WebMemoDashboardContent();

        break;
      case 1:
        content = const WebPDFDashboardContent();
        break;
      case 2:
        content = const WebSettingsContent();
        break;
      default:
        content = const SizedBox.shrink();
    }
    return Scaffold(
      backgroundColor: contentBackground,
      body: Row(
        children: [
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: sidebarColor,
              boxShadow: [
                BoxShadow(
                    blurRadius: 14, color: Colors.black26, offset: Offset(1, 0))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 36, horizontal: 22),
                  child: const Text(
                    'Cash Memo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                Divider(color: Colors.white.withOpacity(0.13)),
                SidebarTile(
                  icon: Icons.receipt_long,
                  label: 'Memos',
                  selected: selectedIndex == 0,
                  highlight: sidebarHighlight,
                  color: sidebarText,
                  selectedBg: sidebarSelectedBg,
                  onTap: () => setState(() => selectedIndex = 0),
                ),
                SidebarTile(
                  icon: Icons.picture_as_pdf,
                  label: 'PDFs',
                  selected: selectedIndex == 1,
                  highlight: sidebarHighlight,
                  color: sidebarText,
                  selectedBg: sidebarSelectedBg,
                  onTap: () => setState(() => selectedIndex = 1),
                ),
                SidebarTile(
                  icon: Icons.settings,
                  label: 'Settings',
                  selected: selectedIndex == 2,
                  highlight: sidebarHighlight,
                  color: sidebarText,
                  selectedBg: sidebarSelectedBg,
                  onTap: () => setState(() => selectedIndex = 2),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(
                      bottom: 24, left: 16, right: 16, top: 28),
                  child: Text(
                    '© 2025 CashMemo Creator',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.50),
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: contentBackground,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  margin:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  decoration: BoxDecoration(
                    color: contentCard,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          blurRadius: 24,
                          color: cardShadow,
                          offset: Offset(0, 8))
                    ],
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color highlight;
  final Color color;
  final Color selectedBg;
  final VoidCallback onTap;
  const SidebarTile(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.highlight,
      required this.color,
      required this.selectedBg,
      required this.onTap,
      Key? key})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: selected ? highlight : color, size: 25),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? highlight : color,
          fontWeight: selected ? FontWeight.bold : FontWeight.w600,
          fontSize: 16,
          fontFamily: 'Inter',
        ),
      ),
      selected: selected,
      selectedTileColor: selectedBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 6),
      onTap: onTap,
      hoverColor: highlight.withOpacity(.10),
    );
  }
}
