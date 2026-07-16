import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/screen/create_pin_page.dart';
import 'package:koperasiapp/screen/inter_pin_page.dart';

Future<Map<String, dynamic>?> sendOtpRequest({
  required String member_no,
  required String br_no,
  required String mobile,
}) async {
  final url =
      Uri.parse('https://online.iscop.co.th/ws/MobileApp/login_otp_send.php');
  try {
    final response = await http.post(url, body: {
      'member_no': member_no,
      'br_no': br_no,
      'mobile': mobile,
      // 'login_type': 'android',
    }).timeout(const Duration(seconds: 10));
    debugPrint('member_no: $member_no');
    debugPrint('br_no: $br_no');
    debugPrint('mobile: $mobile');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'].toString() == '1') {
        return data;
      } else {
        debugPrint('API error: ${data['error_message']}');
        return null;
      }
    }
  } catch (e) {
    debugPrint('sendOtpRequest error: $e');
  }
  return null;
}

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
  String? expectedOtp;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOtpFromServer();
  }

  Future<void> _loadOtpFromServer() async {
    final response = await sendOtpRequest(
      member_no: widget.memberNo,
      br_no: widget.brNo,
      mobile: widget.mobile,
    );

    if (response != null) {
      setState(() {
        expectedOtp = response['otp_token'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถรับ OTP ได้')),
      );
    }
  }

  void _verifyOtp() {
    if (_otpController.text == expectedOtp) {
      if (widget.statusPin == "0") {
        // มี PIN แล้ว → ไปกรอก PIN
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => InterPinPage(
            memberNo: widget.memberNo,
            brNo: widget.brNo,
            mobile: widget.mobile,
            statusPin: widget.statusPin,
          ),
        ));
      } else {
        // ยังไม่มี PIN → ไปสร้าง PIN
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CreatePinPage(
              memberNo: widget.memberNo,
              brNo: widget.brNo,
              mobile: widget.mobile,
              statusPin: widget.statusPin,
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
