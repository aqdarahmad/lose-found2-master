import '../api.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _imgCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  static const Color indianRed = Color(0xFFAC746C);
  static const Color rubyRed = Color(0xFF7F1F0E);

  Future<void> _loadUserData() async {
    try {
      final data = await Api.getMe();
      _nameCtrl.text = data['username'] as String;
      _bioCtrl.text = data['bio'] as String? ?? '';
      _imgCtrl.text = data['avatarURL'] as String;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await Api.updateMe(
        _nameCtrl.text.trim(),
        _bioCtrl.text.trim(),
        _imgCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _imgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFDAC1B1),
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF7F1F0E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Name',
              style: TextStyle(
                color: Color(0xFF7F1F0E),
                fontWeight: FontWeight.w200,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bio',
              style: TextStyle(
                color: Color(0xFF7F1F0E),
                fontWeight: FontWeight.w200,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioCtrl,
              style: const TextStyle(color: Colors.black),
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Avatar URL',
              style: TextStyle(
                color: Color(0xFF7F1F0E),
                fontWeight: FontWeight.w200,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _imgCtrl,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 60),
            Center(child:
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: indianRed,
                padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                  side: BorderSide(color: rubyRed.withOpacity(0.8), width: 2),
                ),
                elevation: 8,
                shadowColor: indianRed,
              ),
              child: const Text(
                'Save Change',
                style: TextStyle(color: Colors.white, fontSize: 16,fontWeight: FontWeight.w900,),
              ),
            ),
            )
          ],
        ),
      ),
    );
  }
}

