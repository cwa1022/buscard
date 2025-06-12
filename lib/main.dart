import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'card_model.dart';
import 'db_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Business Card Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CardListPage(),
    );
  }
}

class CardListPage extends StatefulWidget {
  const CardListPage({super.key});

  @override
  State<CardListPage> createState() => _CardListPageState();
}

class _CardListPageState extends State<CardListPage> {
  List<CardModel> cards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final data = await DBHelper().getCards();
    setState(() => cards = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Business Cards')),
      body: ListView.builder(
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return ListTile(
            leading: Image.file(File(card.imagePath), width: 50, height: 50, fit: BoxFit.cover),
            title: Text(card.name),
            subtitle: Text(card.company),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddCardPage()),
          );
          _loadCards();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String orientation = 'horizontal';
  File? imageFile;


  Future<void> _performOCR(File file) async {
    final inputImage = InputImage.fromFile(file);

    // Run text recognition for both Latin and Chinese scripts when available.
    final latinRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final latinText = await latinRecognizer.processImage(inputImage);
    await latinRecognizer.close();

    String chineseText = '';
    try {
      final chineseRecognizer =
          TextRecognizer(script: TextRecognitionScript.chinese);
      chineseText = (await chineseRecognizer.processImage(inputImage)).text;
      await chineseRecognizer.close();
    } catch (_) {
      // Chinese recognition libraries not present; ignore.
    }

    final combined = '${latinText.text}\n$chineseText'.trim();
    final lines = combined
        .split('\\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final phoneRegex =
        RegExp(r'(\\+?\\d{1,4}[\\s-]?)?(\\(?\\d{2,4}\\)?[\\s-]?)?\\d{3,4}[\\s-]?\\d{3,4}');
    final emailRegex = RegExp(r'\\S+@\\S+\\.\\S+');

    bool isCompany(String text) {
      const keywords = ['公司', '企業', '股份', '有限公司', 'Inc', 'Corp', 'Co.', 'LLC'];
      return keywords.any((k) => text.contains(k));
    }

    bool isLikelyName(String text) {
      final zhName = RegExp(r'^[\\u4e00-\\u9fa5]{2,4}\\$');
      final enName = RegExp(r'^[A-Z][a-z]+\\s[A-Z][a-z]+\\$');
      return zhName.hasMatch(text) || enName.hasMatch(text);
    }

    String? name;
    String? company;

    for (final line in lines) {
      if (emailRegex.hasMatch(line) && _emailController.text.isEmpty) {
        _emailController.text = emailRegex.firstMatch(line)!.group(0)!;
        continue;
      }
      if (phoneRegex.hasMatch(line) && _phoneController.text.isEmpty) {
        _phoneController.text = phoneRegex.firstMatch(line)!.group(0)!;
        continue;
      }
      if (company == null && isCompany(line)) {
        company = line;
        continue;
      }
      if (name == null && isLikelyName(line)) {
        name = line;
        continue;
      }
    }

    _nameController.text = name ?? (lines.isNotEmpty ? lines.first : '');
    _companyController.text = company ?? '';

    setState(() {});
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final newPath = p.join(directory.path, p.basename(picked.path));
    final newImage = await File(picked.path).copy(newPath);
    setState(() => imageFile = newImage);
    await _performOCR(newImage);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || imageFile == null) return;
    final card = CardModel(
      name: _nameController.text,
      company: _companyController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      orientation: orientation,
      imagePath: imageFile!.path,
    );
    await DBHelper().insertCard(card);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Card')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
              ),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Company'),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: orientation,
                decoration: const InputDecoration(labelText: 'Orientation'),
                items: const [
                  DropdownMenuItem(value: 'horizontal', child: Text('Horizontal')),
                  DropdownMenuItem(value: 'vertical', child: Text('Vertical')),
                ],
                onChanged: (value) => setState(() => orientation = value ?? 'horizontal'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Capture Image'),
              ),
              if (imageFile != null) ...[
                const SizedBox(height: 12),
                Image.file(imageFile!, height: 150),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
