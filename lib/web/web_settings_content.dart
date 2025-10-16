import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebSettingsContent extends StatefulWidget {
  const WebSettingsContent({Key? key}) : super(key: key);
  @override
  State<WebSettingsContent> createState() => _WebSettingsContentState();
}

class _WebSettingsContentState extends State<WebSettingsContent> {
  late TextEditingController nameController;
  String language = 'en';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      language = prefs.getString('appLanguage') ?? 'en';
      nameController.text = prefs.getString('companyName') ?? '';
    });
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('companyName', nameController.text);
    await prefs.setString('appLanguage', language);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 28),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Company Name'),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Language'),
            value: language,
            onChanged: (val) => setState(() => language = val ?? 'en'),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'bn', child: Text('Bengali')),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            onPressed: saveSettings,
            label: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}
