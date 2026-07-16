import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/constants.dart';

import 'package:koperasiapp/screen/create_pin_page.dart';
import 'package:koperasiapp/screen/inter_pin_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> sendOtpRequest({
  required String member_no,
  required String br_no,
  required String mobile,
}) async {
  const String baseUrl = 'https://online.iscop.co.th/ws/MobileApp/';
  const String endpoint = 'login_otp_send.php';
  const int timeout = 1000; // Timeout duration in seconds

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String token = prefs.getString('token') ?? '';

  Map<String, String> headers = {
    'Content-Type': 'application/json;charset=utf-8',
  };
  Map<String, String> data = {
    'member_no': member_no,
    'br_no': br_no,
    'mobile': mobile
  };

  var body = json.encode(data);
  debugPrint(body);

  try {
    final response = await http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: body,
        )
        .timeout(const Duration(seconds: timeout));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // throw Exception('Failed to load data : ${response.statusCode}');
      throw Exception('Failed to load data : ${response.body}');
    }
  } catch (e) {
    debugPrint(e.toString());
    return {};
  }
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
  String? otpToken;
  // String? otpToken;
  String? refCode;
  String? sessionId;
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

    if (response.isNotEmpty && response['success'] == 1) {
      setState(() {
        otpToken = response['otp_token'];
        refCode = response['ref_code'];
        sessionId = response['session_id'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response['error_message'] ?? 'ไม่สามารถรับ OTP ได้')),
      );
    }
    debugPrint('otp_token: $otpToken');
    debugPrint('ref_code: $refCode');
    debugPrint('session_id: $sessionId');
    debugPrint("Response from API: $response");
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    // ตรวจสอบความถูกต้องเบื้องต้นก่อนเรียก API
    if (otp.length != 6 ||
        !RegExp(r'^\d{6}$').hasMatch(otp) ||
        otpToken == null ||
        refCode == null ||
        sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก OTP 6 หลักให้ถูกต้อง')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://online.iscop.co.th/ws/login_otp_chk.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'member_no': widget.memberNo,
          'br_no': widget.brNo,
          'mobile': widget.mobile,
          'otp': otp,
          'session_id': sessionId!,
          'otp_token': otpToken!,
          'ref_code': refCode!,
          'flg_accept': '1',
          'login_type': 'mobile',
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint("Raw Response: ${response.body}");

        if (result['success'] == 1) {
          // OTP ผ่าน → ไปหน้าตามสถานะ PIN
          final nextPage = widget.statusPin == "0"
              ? InterPinPage(
                  memberNo: widget.memberNo,
                  brNo: widget.brNo,
                  mobile: widget.mobile,
                  statusPin: widget.statusPin,
                  token: '',
                )
              : CreatePinPage(
                  memberNo: widget.memberNo,
                  brNo: widget.brNo,
                  mobile: widget.mobile,
                  statusPin: widget.statusPin,
                );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => nextPage),
          );
        } else {
          // OTP ผิด
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['error_message'] ?? 'OTP ไม่ถูกต้อง')),
          );
        }
      } else {
        // HTTP error (เช่น 500, 403, ฯลฯ)
        debugPrint("HTTP Error: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถติดต่อเซิร์ฟเวอร์ได้')),
        );
      }
    } catch (e) {
      // กรณี response ไม่เป็น JSON หรือ timeout, network error
      debugPrint("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String lastDigits = widget.mobile.length >= 10
        ? widget.mobile.substring(widget.mobile.length - 4)
        : 'xxxx';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white, // พื้นหลังสีขาว
          surfaceTintColor: Colors.white, // ป้องกัน Material3 tint
          elevation: 0, // ไม่มีเงา
          centerTitle: true, // กึ่งกลาง
          title: const Text(
            'ยืนยัน OTP',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          )),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ระบบได้ทำการจัดส่งรหัส (OTP) ไปยัง : xxx-xxx-$lastDigits\nรหัสอ้างอิง : ${refCode ?? "-"}',
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _otpController,
                              decoration: InputDecoration(
                                focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            Color.fromARGB(255, 14, 53, 15))),
                                label: const Text('รหัส OTP 6 หลัก'),
                                labelStyle: const TextStyle(
                                    color: Color.fromARGB(255, 14, 53, 15)),
                                hintText: 'กรอกรหัส OTP 6 หลัก',
                                hintStyle: const TextStyle(
                                  color: Colors.black26,
                                ),
                                border: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color:
                                        Colors.black12, // Default border color
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color:
                                        Colors.black12, // Default border color
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'โปรดกรอกรหัส OTP 6 หลัก';
                                }
                                return null;
                              },
                            ),
                            // const SizedBox(height: 24),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () async {
                                  setState(() => isLoading = true);
                                  await _loadOtpFromServer();
                                },
                                child: const Text(
                                  'ส่ง OTP อีกครั้ง',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 14, 53, 15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.greenColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 20),
                        ),
                        child: const Text(
                          'ยืนยัน',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
