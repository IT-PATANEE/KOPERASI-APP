import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class InterPinPage extends StatefulWidget {
  final String memberNo;
  final String brNo;
  final String mobile;

  const InterPinPage({
    super.key,
    // required this.member_no,
    required this.memberNo,
    required this.brNo,
    required this.mobile,
    required String statusPin,
  });

  @override
  State<InterPinPage> createState() => _InterPinPageState();
}

class _InterPinPageState extends State<InterPinPage> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitPin() async {
    String pin = _pinController.text.trim();

    if (pin.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(pin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก PIN 6 หลัก (เฉพาะตัวเลข)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    //--------------- anita add 03082025 ---------------
    try {
      final response = await http.post(
        Uri.parse('https://online.iscop.co.th/ws/flutter_chk_pin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'member_no': widget.memberNo,
          'br_no': widget.brNo,
          'pincode': pin,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == '1') {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('pincode', data['pincode']);
        await prefs.setString(
            'last_login_time', DateTime.now().toIso8601String());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ')),
        );

        // ไปหน้าเมนูหลัก (คุณสามารถเปลี่ยนชื่อหน้าตามโปรเจกต์)
        Navigator.pushReplacementNamed(context, '/menu');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error_message'] ?? 'เกิดข้อผิดพลาด')),
        );
        _pinController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }

    //--------------- anita end 03082025 ---------------
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ป้อน PIN'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ป้อน PIN 6 หลัก',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'PIN',
                counterText: '',
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ยืนยัน', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
