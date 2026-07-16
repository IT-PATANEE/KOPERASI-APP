import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/screen/register_step_progress.dart';
import 'package:page_transition/page_transition.dart';
import 'register_confirm_page.dart';

import 'login_page.dart';

class RegisterDataPage extends StatefulWidget {
  const RegisterDataPage({super.key});

  @override
  State<RegisterDataPage> createState() => _RegisterDataPageState();
}

class _RegisterDataPageState extends State<RegisterDataPage> {
  final ScrollController _scroll = ScrollController();
  bool _scrolledToBottom = false;
  bool _consentChecked = false;
  double _progress = 0.0; // 0..1 reading progress
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _idCardController = TextEditingController();
  final _telController = TextEditingController();

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

  // ฟังก์ชันเรียก API และส่งข้อมูลต่อไปยังหน้ายืนยัน (ได้รับการแก้ไข)
  Future<void> _registerUser() async {
    final url =
        Uri.parse('https://online.iscop.co.th/ws/MobileApp/register.php');

    // สร้าง Map ของข้อมูลที่จะส่ง
    final requestBody = {
      'member_no': _usernameController.text.trim(),
      'id_card': _idCardController.text.trim(),
      'member_tel': _telController.text.trim(),
      'login_type': 'MOBILE',
    };

    // 🔥 debug ข้อมูลที่จะส่ง
    print('Request body: $requestBody');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody), //
      );

      // 🔥 debug ข้อมูลตอบกลับ
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // ต้อง cast เป็น Map<String, dynamic> เพื่อให้มั่นใจในการเข้าถึงคีย์
        final data = jsonDecode(response.body) as Map<String, dynamic>; 

        // 🔹 debug JSON ตอบกลับสวย ๆ
        print(JsonEncoder.withIndent('  ').convert(data));

        if (data['success'] == 1) {
          // 1. ดึง Map 'data' ที่อยู่ภายใน response
          final responseData = data['data'] as Map<String, dynamic>?;

          // 2. ดึงค่าที่จำเป็นจาก API response เพื่อส่งต่อ
          // br_no ต้องเข้าถึงผ่าน responseData['br_no']
          final brNo = responseData?['br_no']?.toString() ?? '000';
          final fallbackMemberNo = _usernameController.text.length >= 5 
              ? _usernameController.text.substring(_usernameController.text.length - 5) 
              : _usernameController.text;
          final memberNo = responseData?['member_no']?.toString() ?? fallbackMemberNo;
          
          // ตัวแปรที่เหลือ (status_pin, flg_accept, forget_pass) 
          // // คาดว่าจะอยู่ที่ root level หรือใช้ค่า default ถ้าไม่มีใน response
          // final statusPin = data['status_pin']?.toString() ?? '1';
          // final flgAccept = data['flg_accept']?.toString() ?? '1';
          // final forgetPass = data['forget_pass']?.toString() ?? '2';
          
          // 3. ส่งค่าทั้งหมดไปยัง RegisterConfirmPage
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              child: RegisterConfirmPage(
                username: _usernameController.text,
                idCard: _idCardController.text,
                tel: _telController.text,
                // *** ส่งค่าที่ได้จาก API Response ไปด้วย ***
                memberNo: memberNo,
                brNo: brNo,
                // statusPin: statusPin,
                // flgAccept: flgAccept,
                // forgetPass: forgetPass,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error_message'] ?? 'เกิดข้อผิดพลาด')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, // พื้นหลังสีขาว
        surfaceTintColor: Colors.white, // ป้องกัน Material3 tint
        elevation: 0, // ไม่มีเงา
        centerTitle: true, // กึ่งกลาง
        title: const Text(
          'สมัครใช้งาน KOPERASI SMART',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // ย้อนกลับหน้าเดิม
          },
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
                currentStep: 2,
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
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          controller: _scroll,
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildUsernameField(),
                              SizedBox(height: h * 0.03),
                              _buildIdcardField(),
                              SizedBox(height: h * 0.03),
                              _buildtelField(),
                              SizedBox(height: h * 0.03),
                            ],
                          ),
                        ),
                      ),
                    ),
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
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _registerUser(); // 🔥 เรียก API
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Constants.greenColor, // สีพื้นหลังปุ่ม
                      foregroundColor: Colors.white, // สีข้อความ
                      padding: const EdgeInsets.symmetric(
                          vertical: 20), // ความสูงปุ่ม
                    ),
                    child: const Text('ต่อไป'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('กรอกข้อมูลการลงทะเบียนสมัครใช้งาน',
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
        // SizedBox(height: h * 0.01),
        // Text('ปรับปรุงล่าสุด: 15 สิงหาคม 2025 · เวอร์ชัน 1.0',
        //     style: textTheme.bodySmall),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.green[50], // พื้นหลังอ่อน ๆ
        prefixIcon: const Icon(
          Icons.person,
          color: Color.fromARGB(255, 14, 53, 15),
        ),
        labelText: 'เลขทะเบียนสมาชิก 10 หลัก',
        labelStyle: const TextStyle(
          color: Color.fromARGB(255, 14, 53, 15),
          fontWeight: FontWeight.w600,
        ),
        hintText: 'กรอกเลขทะเบียนสมาชิก 10 หลัก',
        hintStyle: TextStyle(color: Colors.grey[400]),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 14, 53, 15),
            width: 2,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'โปรดกรอกเลขทะเบียนสมาชิก 10 หลัก';
        }
        if (value.length != 10) {
          return 'เลขทะเบียนต้องมี 10 หลัก';
        }
        return null;
      },
    );
  }

  Widget _buildIdcardField() {
    return TextFormField(
      controller: _idCardController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 13, // จำกัดความยาวบัตรประชาชน
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        labelText: 'เลขบัตรประชาชน',
        labelStyle: const TextStyle(
          color: Color.fromARGB(255, 14, 53, 15),
          fontWeight: FontWeight.w600,
        ),
        hintText: 'กรอกเลขบัตรประชาชน',
        hintStyle: const TextStyle(color: Colors.black38),
        counterText: '', // ซ่อนตัวนับตัวอักษร
        filled: true,
        fillColor: Colors.green[50], // สีพื้นหลังฟิลด์
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none, // ไม่มีเส้นขอบ
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
              color: Color.fromARGB(255, 14, 53, 15), width: 2),
        ),
        prefixIcon: const Icon(
          Icons.credit_card,
          color: Color.fromARGB(255, 14, 53, 15),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'โปรดกรอกเลขบัตรประชาชน';
        }
        if (value.length != 13) {
          return 'เลขบัตรประชาชนต้องมี 13 หลัก';
        }
        return null;
      },
    );
  }

  Widget _buildtelField() {
    return TextFormField(
      controller: _telController,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 10, // จำกัด 10 หลักสำหรับเบอร์ไทย
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        labelText: 'เบอร์โทรศัพท์',
        labelStyle: const TextStyle(
          color: Color.fromARGB(255, 14, 53, 15),
          fontWeight: FontWeight.w600,
        ),
        hintText: 'กรอกเบอร์โทรศัพท์',
        hintStyle: const TextStyle(color: Colors.black38),
        counterText: '', // ซ่อนตัวนับตัวอักษร
        filled: true,
        fillColor: Colors.green[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
              color: Color.fromARGB(255, 14, 53, 15), width: 2),
        ),
        prefixIcon: const Icon(
          Icons.phone,
          color: Color.fromARGB(255, 14, 53, 15),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'โปรดกรอกเบอร์โทรศัพท์';
        }
        if (value.length != 10) {
          return 'เบอร์โทรศัพท์ต้องมี 10 หลัก';
        }
        return null;
      },
    );
  }
}
