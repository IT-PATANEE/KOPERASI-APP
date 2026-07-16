import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/screen/create_pin_page.dart';
import 'package:koperasiapp/screen/inter_pin_page.dart';

class LoginOtpPage extends StatefulWidget {
  final String memberNo;
  final String brNo;
  final String mobile;
  final String statusPin; // "0" = มี PIN

  const LoginOtpPage({
    super.key,
    required this.memberNo,
    required this.brNo,
    required this.mobile,
    required this.statusPin,
  });

  @override
  State<LoginOtpPage> createState() => _LoginOtpPageState();
}

class _LoginOtpPageState extends State<LoginOtpPage> {
  final TextEditingController _otpController = TextEditingController();
  String expectedOtp = "123456"; // ตัวอย่าง OTP ที่ควรรับจาก server จริง

  void _verifyOtp() {
    if (_otpController.text == expectedOtp) {
      if (widget.statusPin == "0") {
        // มี PIN แล้ว → ไปกรอก PIN
        Navigator.of(context).pushReplacement(
          
          MaterialPageRoute(
            builder: (context) => InterPinPage(
              member_no: widget.memberNo,
              brNo: widget.brNo,
              mobile: widget.mobile, memberNo: '', statusPin: '',
            ),
          ),
        );
      } else {
        // ยังไม่มี PIN → ไปสร้าง PIN 
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CreatePinPage(
              member_no: widget.memberNo,
              brNo: widget.brNo,
              mobile: widget.mobile, memberNo: '', statusPin: '',
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP ไม่ถูกต้อง')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ยืนยัน OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text('กรุณากรอก OTP ที่ส่งไปยังเบอร์ ${widget.mobile}'),
            const SizedBox(height: 24),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'OTP 6 หลัก',
                border: OutlineInputBorder(),
              ),
              maxLength: 6,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _verifyOtp,
              child: const Text('ยืนยัน'),
            ),
          ],
        ),
      ),
    );
  }
}
