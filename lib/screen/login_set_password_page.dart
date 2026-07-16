import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/screen/login_page.dart';
import 'package:koperasiapp/screen/receipt_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/screen/register_step_progress.dart';
import 'package:page_transition/page_transition.dart';
import 'register_confirm_page.dart';

class LoginSetPasswordPage extends StatefulWidget {
  final String forgetPass; // "1", "2", หรืออื่นๆ

  const LoginSetPasswordPage({super.key, required this.forgetPass});

  @override
  State<LoginSetPasswordPage> createState() => _LoginSetPasswordPageState();
}

class _LoginSetPasswordPageState extends State<LoginSetPasswordPage> {
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // สถานะ
  bool _isLoading = false;
  bool _isNewPassHidden = true;
  bool _isConfirmPassHidden = true;

  // ข้อมูลสมาชิกที่ดึงจาก Session
  String memberNo = '';
  String brNo = '';
  String mobile = '';

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // แสดง Toast Message
  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      memberNo = prefs.getString('member_no') ?? '';
      brNo = prefs.getString('br_no') ?? '';
      mobile = prefs.getString('mobile') ?? '';
    });
  }

  // --- Logic สำหรับการตั้งรหัสผ่าน (SetNewPasswordTask) ---
  Future<void> _setNewPassword() async {
    // ปิดการทำงานหากยังอยู่ในสถานะ Loading
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final newPassword = _newPassController.text.trim();
    final confirmPassword = _confirmPassController.text.trim();

    // Validation เพิ่มเติม
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กำหนดรหัสผ่านมากกว่า 6 หลัก')),
      );
      // _showToast('กำหนดรหัสผ่านมากกว่า 6 หลัก');
      return;
    }
    if (newPassword != confirmPassword) {
      _showToast('รหัสผ่านไม่ตรงกัน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      const String baseUrl = 'https://online.iscop.co.th/ws/';
      const String endpoint = 'password_set1.php';
      final url = Uri.parse('$baseUrl$endpoint');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';
      print('tokentest: $token');

      // ส่ง JSON
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'member_no': memberNo,
            'br_no': brNo,
            'token': token,
            'mobile': mobile,
            'password': newPassword,
          }));

      final data = jsonDecode(response.body);
      print('datatest: $data');

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (data['success'] == 1) {
        _showToast('บันทึกรหัสผ่านสำเร็จ');

        // นำทางตามค่า forgetPass
        Widget nextPage;
        if (widget.forgetPass == "1") {
          nextPage = ReceiptPage(); // ลืมรหัสผ่าน -> ตั้ง PIN ใหม่
        } else if (widget.forgetPass == "2") {
          nextPage = ReceiptPage(); // ลงทะเบียน -> ตั้ง PIN ครั้งแรก
        } else {
          nextPage = ReceiptPage(); // ค่าอื่น -> หน้า PIN ปกติ
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => nextPage),
          (route) => false,
        );
      } else {
        _showToast(data['error_message'] ?? 'ไม่สามารถบันทึกรหัสผ่านได้');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showToast('เกิดข้อผิดพลาด: $e');
    }
  }

  // --- Logic สำหรับการยกเลิก (Registercancle) ---
  Future<void> _cancelRegistration() async {
    setState(() => _isLoading = true);
    // final response = await CopServer.registerCancel(memberNo, brNo);

    try {
      const String baseUrl = 'https://online.iscop.co.th/ws/MobileApp/';
      const String endpoint = 'register_cancel.php';
      final url = Uri.parse('$baseUrl$endpoint');

      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'member_no': memberNo,
            'br_no': brNo,
          }));

      final data = jsonDecode(response.body);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (data['success'] == 1) {
        _showToast('ยกเลิกการลงทะเบียนเรียบร้อย');

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('session_key_id');

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } else {
        _showToast(data['error_message'] ?? 'ไม่สามารถยกเลิกได้');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showToast('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> _confirmDecline() async {
    // ฟังก์ชันที่ผูกกับปุ่ม 'ยกเลิก' หรือปุ่ม Close ใน AppBar
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการยกเลิก'),
        content: const Text(
          'คุณแน่ใจหรือไม่ว่าต้องการยกเลิกการตั้งรหัสผ่าน? การยกเลิกจะนำคุณกลับไปยังหน้าเข้าสู่ระบบ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ไม่ยกเลิก'),
          ),
          FilledButton.tonal(
              onPressed: () =>
                  Navigator.pop(ctx, true), // ส่งค่า true เพื่อยืนยัน
              style: FilledButton.styleFrom(
                backgroundColor: Constants.greenColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('ตกลง')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // เมื่อผู้ใช้กด 'ตกลง' ใน Dialog ให้เรียก API ยกเลิก
      await _cancelRegistration();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'กำหนดรหัสผ่าน',
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
                currentStep: 5,
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
                    _buildHeaderField(textTheme),
                    SizedBox(height: h * 0.03),
                    Form(
                      key: _formKey,
                      child: _buildPasswordFields(),
                    ),
                    // _buildPasswordFields(),
                    SizedBox(height: h * 0.03),
                    const Text(
                      'คำแนะนำ: รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
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
                    // child: _isLoading
                    //     ? const SizedBox(
                    //         height: 20,
                    //         width: 20,
                    //         child: CircularProgressIndicator(strokeWidth: 2),
                    //       )
                    //     : const Text('ยกเลิก'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    // onPressed: () {},
                    onPressed: _setNewPassword,
                    style: FilledButton.styleFrom(
                      backgroundColor: Constants.greenColor, // สีพื้นหลังปุ่ม
                      foregroundColor: Colors.white, // สีข้อความ
                      padding: const EdgeInsets.symmetric(
                          vertical: 20), // ความสูงปุ่ม
                    ),
                    child: const Text('ยืนยัน'),
                    // child: _isLoading
                    //     ? const SizedBox(
                    //         height: 20,
                    //         width: 20,
                    //         child: CircularProgressIndicator(
                    //           strokeWidth: 2,
                    //           color: Colors.white,
                    //         ),
                    //       )
                    //     : const Text('ยืนยัน'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderField(TextTheme textTheme) {
    final media = MediaQuery.of(context);
    final h = media.size.height;
    final w = media.size.width;
    final textScale = w * 0.04; // ขนาดฟอนต์ตามความกว้างจอ
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('กำหนดรหัสผ่านและยืนยัน',
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        // ช่องรหัสผ่านใหม่
        TextFormField(
          controller: _newPassController,
          obscureText: _isNewPassHidden,
          keyboardType: TextInputType.number,
          // keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            labelText: 'รหัสผ่านใหม่',
            labelStyle: const TextStyle(color: Color.fromARGB(255, 14, 53, 15)),

            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color.fromARGB(255, 14, 53, 15))),
            // label: const Text('รหัสผ่านใหม่'),
            // labelStyle: const TextStyle(color: Color.fromARGB(255, 14, 53, 15)),
            // hintText: 'กรอกรหัสผ่านใหม่',
            // hintStyle: const TextStyle(
            //   color: Colors.black26,
            // ),
            suffixIcon: IconButton(
              icon: Icon(
                _isNewPassHidden ? Icons.visibility_off : Icons.visibility,
                color: Constants.greenColor,
              ),
              onPressed: () {
                setState(() {
                  _isNewPassHidden = !_isNewPassHidden;
                });
              },
            ),
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))),
            // focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Constants.greenColor)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณากรอกรหัสผ่าน';
            }
            if (value.length < 6) {
              return 'กำหนดรหัสผ่านมากกว่า 6 หลัก';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // ช่องยืนยันรหัสผ่านใหม่
        TextFormField(
          controller: _confirmPassController,
          obscureText: _isConfirmPassHidden,
          keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            labelText: 'ยืนยันรหัสผ่านใหม่',
            labelStyle: const TextStyle(color: Color.fromARGB(255, 14, 53, 15)),
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color.fromARGB(255, 14, 53, 15))),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPassHidden ? Icons.visibility_off : Icons.visibility,
                color: Constants.greenColor,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPassHidden = !_isConfirmPassHidden;
                });
              },
            ),
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))),
            // focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Constants.greenColor)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณายืนยันรหัสผ่าน';
            }
            if (value != _newPassController.text) {
              return 'รหัสผ่านไม่ตรงกัน';
            }
            return null;
          },
        ),
      ],
    );
  }
}
