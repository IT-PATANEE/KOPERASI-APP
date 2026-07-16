import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreatePinPage extends StatefulWidget {
 final String memberNo;
  final String brNo;
  final String mobile;


  const CreatePinPage({
    super.key,
    required this.memberNo,
    required this.brNo,
    required this.mobile, 
    required String statusPin

  });

  @override
  State<CreatePinPage> createState() => _CreatePinPageState();
}

class _CreatePinPageState extends State<CreatePinPage> {
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

    // try {
    //   final response = await http.post(
    //     Uri.parse('https://your-api.com/api/set_pin.php'), // เปลี่ยน URL ให้ตรงกับ backend จริง
    //     headers: {'Content-Type': 'application/json'},
    //     body: jsonEncode({
    //       'member_no': widget.member_no,
    //       'br_no': widget.brNo,
    //       'pin': pin,
    //       'token': widget.token,
    //     }),
    //   );

    //   final Map<String, dynamic> res = jsonDecode(response.body);

    //   if (res['success'].toString() == '1') {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text('สร้าง PIN สำเร็จ')),
    //     );
    //     // ไปหน้า Home หรือหน้าหลักหลังสร้าง PIN
    //     Navigator.pushReplacementNamed(context, '/home');
    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text(res['error_message'] ?? 'เกิดข้อผิดพลาด')),
    //     );
    //   }
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
    //   );
    // } finally {
    //   setState(() => _isLoading = false);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้าง PIN'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'กรุณากรอก PIN 6 หลัก',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: InputDecoration(
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
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'ยืนยัน',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
