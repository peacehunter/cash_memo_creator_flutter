import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController companyNameController;
  late TextEditingController companyAddressController;
  late TextEditingController watermarkTextController;
  late TextEditingController nbController; // N.B. controller for special message
  String? logoPath;
  String? watermarkImagePath;
  int selectedWatermarkOption = 0; // 0: Text, 1: Image, 2: Both, 3: None
  String selectedLanguage = 'en'; // Default language

  @override
  void initState() {
    super.initState();
    companyNameController = TextEditingController();
    companyAddressController = TextEditingController();
    watermarkTextController = TextEditingController();
    nbController = TextEditingController(); // Initialize N.B. controller
    _tabController = TabController(length: 4, vsync: this); // Update length to 4 for language tab
    loadCompanyInfo();
    loadLanguagePreference(); // Load language preference
  }

  Future<void> loadCompanyInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('companyName');
    String? address = prefs.getString('companyAddress');
    String? logo = prefs.getString('companyLogo');
    String? watermarkText = prefs.getString('watermarkText');
    String? watermarkImage = prefs.getString('watermarkImage');
    String? nbMessage = prefs.getString('nbMessage'); // Load N.B. message
    int? watermarkOption = prefs.getInt('watermarkOption'); // Load watermark option

    if (name != null) companyNameController.text = name;
    if (address != null) companyAddressController.text = address;
    if (watermarkText != null) watermarkTextController.text = watermarkText;
    if (nbMessage != null) nbController.text = nbMessage; // Set N.B. message text
    logoPath = logo;
    watermarkImagePath = watermarkImage;

    if (watermarkOption != null) {
      selectedWatermarkOption = watermarkOption;
    }

    setState(() {});
  }

  Future<void> loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    selectedLanguage = prefs.getString('appLanguage') ?? 'en'; // Default to English
    setState(() {});
  }

  Future<void> saveCompanyInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('companyName', companyNameController.text);
    await prefs.setString('companyAddress', companyAddressController.text);
    await prefs.setString('companyLogo', logoPath ?? '');
    await prefs.setString('watermarkText', watermarkTextController.text);
    await prefs.setString('watermarkImage', watermarkImagePath ?? '');
    await prefs.setString('nbMessage', nbController.text); // Save N.B. message
    await prefs.setInt('watermarkOption', selectedWatermarkOption); // Save watermark option
    await prefs.setString('appLanguage', selectedLanguage); // Save language preference
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Settings saved!')));
  }

  Future<void> pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        logoPath = image.path;
      });
    }
  }

  Future<void> pickWatermarkImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        watermarkImagePath = image.path;
      });
    }
  }

  @override
  void dispose() {
    companyNameController.dispose();
    companyAddressController.dispose();
    watermarkTextController.dispose();
    nbController.dispose(); // Dispose N.B. controller
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Company Info', icon: Icon(Icons.business)),
            Tab(text: 'Watermark', icon: Icon(Icons.water)),
            Tab(text: 'N.B.', icon: Icon(Icons.note)), // Add N.B. tab
            Tab(text: 'Language', icon: Icon(Icons.language)), // Add Language tab
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.white,
        ),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCompanyInfoTab(),
                _buildWatermarkTab(),
                _buildNBTab(), // Add N.B. tab content
                _buildLanguageTab(), // Add Language tab content
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: saveCompanyInfo,
              child: Text(
                'Save Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.teal.shade700,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customize Your Company Info',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _buildInputField(
            label: 'Company Name',
            controller: companyNameController,
            icon: Icons.business,
          ),
          SizedBox(height: 20),
          _buildInputField(
            label: 'Company Address',
            controller: companyAddressController,
            icon: Icons.location_on,
          ),
          SizedBox(height: 30),
          Text(
            'Company Logo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          logoPath == null
              ? Text('No logo selected', style: TextStyle(color: Colors.grey))
              : Image.file(File(logoPath!), height: 100),
          SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: pickLogo,
              icon: Icon(Icons.image),
              label: Text('Select Logo'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.teal.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWatermarkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Watermark Settings',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            label: 'Watermark Text',
            controller: watermarkTextController,
            icon: Icons.text_fields,
          ),
          const SizedBox(height: 20),
          const Text(
            'Watermark Image',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          watermarkImagePath == null
              ? const Text('No watermark image selected', style: TextStyle(color: Colors.grey))
              : Image.file(File(watermarkImagePath!), height: 100),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: pickWatermarkImage,
              icon: const Icon(Icons.image),
              label: const Text('Select Watermark Image'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.teal.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          SizedBox(height: 40),
          const Text(
            'Select Watermark Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          RadioListTile(
            title: Text("Text"),
            value: 0,
            groupValue: selectedWatermarkOption,
            onChanged: (value) {
              setState(() {
                selectedWatermarkOption = value as int;
              });
            },
          ),
          RadioListTile(
            title: Text("Image"),
            value: 1,
            groupValue: selectedWatermarkOption,
            onChanged: (value) {
              setState(() {
                selectedWatermarkOption = value as int;
              });
            },
          ),
          RadioListTile(
            title: Text("Both"),
            value: 2,
            groupValue: selectedWatermarkOption,
            onChanged: (value) {
              setState(() {
                selectedWatermarkOption = value as int;
              });
            },
          ),
          RadioListTile(
            title: Text("None"),
            value: 3,
            groupValue: selectedWatermarkOption,
            onChanged: (value) {
              setState(() {
                selectedWatermarkOption = value as int;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNBTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'N.B. (Note Well)',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _buildInputField(
            label: 'Special Message',
            controller: nbController,
            icon: Icons.note,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Language',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          RadioListTile(
            title: Text("English"),
            value: 'en',
            groupValue: selectedLanguage,
            onChanged: (value) {
              setState(() {
                selectedLanguage = value as String;
              });
            },
          ),
          RadioListTile(
            title: Text("Bengali"),
            value: 'bn',
            groupValue: selectedLanguage,
            onChanged: (value) {
              setState(() {
                selectedLanguage = value as String;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
