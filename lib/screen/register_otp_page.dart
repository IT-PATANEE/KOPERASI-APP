import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/screen/create_pin_page.dart';
import 'package:koperasiapp/screen/inter_pin_page.dart';
import 'package:koperasiapp/screen/register_step_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_set_password_page.dart';
import 'login_page.dart';

Future<Map<String, dynamic>> sendOtpRequest({
  required String member_no,
  required String br_no,
  required String mobile,
}) async {
  const String baseUrl = 'https://online.iscop.co.th/ws/MobileApp/';
  const String endpoint = 'login_otp_send.php';
  const int timeout = 1000; // Timeout duration in seconds

  Map<String, String> headers = {
    'Content-Type': 'application/json;charset=utf-8',
  };
  Map<String, String> data = {
    'member_no': member_no,
    'br_no': br_no,
    'mobile': mobile
  };

  var body = json.encode(data);
  debugPrint('Requesting OTP body: $body');

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
      // โยน Exception เพื่อให้จัดการใน _loadOtpFromServer
      throw Exception('Failed to load data: HTTP ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('OTP Request Exception: $e');
    return {'success': 0, 'error_message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ'};
  }
}

class RegisterOtpPage extends StatefulWidget {
  final String memberNo;
  final String brNo;
  final String mobile;
  final String statusPin; // "0" = มี PIN
  final String flgAccept; // เพิ่ม flg_accept
  final String forgetPass; // เพิ่ม forget_pass (เทียบเท่า LoginOtpActivity)

  const RegisterOtpPage({
    super.key,
    required this.memberNo,
    required this.brNo,
    required this.mobile,
    this.statusPin = "1", // ตั้งค่าเริ่มต้นให้มีสถานะ
    this.flgAccept = "1", // ตั้งค่าเริ่มต้น
    this.forgetPass = "2", // ค่าคงที่ตาม LoginMobileActivity
  });

  @override
  State<RegisterOtpPage> createState() => _RegisterOtpPageState();
}

class _RegisterOtpPageState extends State<RegisterOtpPage> {
  final TextEditingController _otpController = TextEditingController();

  String? otpToken;
  String? refCode;
  String? sessionId;

  bool isLoading = true;
  bool isVerifying = false; // สำหรับป้องกันการกดซ้ำตอนตรวจสอบ

  @override
  void initState() {
    super.initState();
    _loadOtpFromServer();
  }

  Future<void> _confirmDecline() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยัน'),
        content: const Text(
          'กดปุ่ม ตกลง หากต้องการยกเลิก',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton.tonal(
              onPressed: () {
                // ย้อนกลับไปหน้า Login
                Navigator.of(ctx).pop(false); // ปิด dialog ก่อน
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Constants.greenColor, // สีพื้นหลังปุ่ม
                foregroundColor: Colors.white, // สีข้อความ
              ),
              child: const Text('ตกลง')),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.pop(context, false);
    }
  }

  Future<void> _loadOtpFromServer() async {
    setState(() => isLoading = true);

    final response = await sendOtpRequest(
      member_no: widget.memberNo,
      br_no: widget.brNo,
      mobile: widget.mobile,
    );

    if (mounted) {
      setState(() => isLoading = false);
      if (response.isNotEmpty && response['success'].toString() == '1') {
        setState(() {
          otpToken = response['otp_token'];
          refCode = response['ref_code'];
          sessionId = response['session_id'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งเลข OTP ใหม่แล้ว!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(response['error_message'] ?? 'ไม่สามารถรับ OTP ได้')),
        );
      }
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
        if (result['success'].toString() == '1') {
          // 2. OTP ถูกต้อง -> บันทึก Token (สมมติว่ามีการบันทึก token ใน SharedPreferences)
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('token', result['token']);
          prefs.setString('member_no', widget.memberNo);
          prefs.setString('br_no', widget.brNo);

          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text('กำลังตรวจสอบข้อมูล...')),
          // );

          // 3. นำทางไปยัง LoginSetPasswordActivity (เทียบเท่าใน Android)
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => LoginSetPasswordPage(
                forgetPass: widget.forgetPass, // ส่ง forget_pass ไป
              ),
            ),
          );
        } else {
          // 4. OTP ผิด
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['error_message'] ?? 'OTP ไม่ถูกต้อง')),
          );
          // 5. โหลดหน้าใหม่ (คล้าย onCreate(null)) แต่ใน Flutter แค่ setState ไม่ได้ต้องทำอย่างอื่น
          // เนื่องจากไม่มี onCreate(null) เราจะทำเพียงแค่เคลียร์ OTP และรอการป้อนใหม่
          _otpController.clear();
        }
      } else {
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
    final media = MediaQuery.of(context);
    final isPortrait = media.orientation == Orientation.portrait;
    final theme = Theme.of(context); // <-- ใช้ ThemeData
    final w = media.size.width;
    final h = media.size.height;
    final textScale = w * 0.04; // ขนาดฟอนต์ตามความกว้างจอ
    final textTheme = Theme.of(context).textTheme;

    // String lastDigits = widget.mobile.length >= 10
    //     ? widget.mobile.substring(widget.mobile.length - 4)
    //     : 'xxxx';

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
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            SizedBox(height: h * 0.01), // ระยะห่างด้านบน
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04),
              child: const StepProgressIndicator(
                currentStep: 4,
                totalSteps: 5,
              ),
            ),
            SizedBox(height: h * 0.01), // ช่องว่างระหว่าง Step กับกรอบ
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: w * 0.04),
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04, vertical: h * 0.01),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderField(),
                    SizedBox(height: h * 0.03),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 14, 53, 15))),
                        label: const Text('รหัส OTP 6 หลัก'),
                        labelStyle: const TextStyle(
                            color: Color.fromARGB(255, 14, 53, 15)),
                        hintText: 'กรอกรหัส OTP 6 หลัก',
                        hintStyle: const TextStyle(
                          color: Colors.black26,
                        ),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.black12, // Default border color
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.black12, // Default border color
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
                    const Spacer(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _confirmDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Constants.greenColor, // สีข้อความ
                      padding: const EdgeInsets.symmetric(
                          vertical: 20), // ความสูงปุ่ม
                    ),
                    child: const Text('ยกเลิก'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    // onPressed: () {},
                    onPressed: _verifyOtp,
                    style: FilledButton.styleFrom(
                      backgroundColor: Constants.greenColor, // สีพื้นหลังปุ่ม
                      foregroundColor: Colors.white, // สีข้อความ
                      padding: const EdgeInsets.symmetric(
                          vertical: 20), // ความสูงปุ่ม
                    ),
                    child: const Text('ยืนยัน'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderField() {
    final media = MediaQuery.of(context);
    final h = media.size.height;
    final w = media.size.width;
    final textScale = w * 0.04; // ขนาดฟอนต์ตามความกว้างจอ
    final textTheme = Theme.of(context).textTheme;
    String lastDigits = widget.mobile.length >= 10
        ? widget.mobile.substring(widget.mobile.length - 4)
        : 'xxxx';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'ระบบได้ทำการจัดส่งรหัส (OTP) \nไปยัง : xxx-xxx-$lastDigits รหัสอ้างอิง : ${refCode ?? "-"}',
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
        // SizedBox(height: h * 0.01),
        // Text('ปรับปรุงล่าสุด: 15 สิงหาคม 2025  ·  เวอร์ชัน 1.0',
        //     style: textTheme.bodySmall),
      ],
    );
  }
}
