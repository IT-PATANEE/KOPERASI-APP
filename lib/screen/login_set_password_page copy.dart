import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:koperasiapp/constants.dart';
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
  bool _isLoading = true;
  bool _isNewPassHidden = true;
  bool _isConfirmPassHidden = true;

  // ข้อมูลสมาชิกที่ดึงจาก Session
  String memberNo = '';
  String brNo = '';

  @override
  void initState() {
    super.initState();
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

  // --- Logic สำหรับการยกเลิก (Registercancle) ---
  Future<void> _cancelRegistration() async {
    setState(() => _isLoading = true);
    // final response = await CopServer.registerCancel(memberNo, brNo);

    if (!mounted) return;
    setState(() => _isLoading = false);

    // if (response['success'] == '1') {
    //   _showToast('ยกเลิกการลงทะเบียนเรียบร้อย');
    //   // ล้าง Session Data ที่เกี่ยวข้องกับการลงทะเบียนที่ไม่สำเร็จ
    //   final prefs = await SharedPreferences.getInstance();
    //   await prefs.remove('session_key_id'); 
      
    //   Navigator.of(context).pushAndRemoveUntil(
    //     MaterialPageRoute(builder: (context) => const LoginPage()),
    //     (Route<dynamic> route) => false,
    //   );
    // } else {
    //   _showToast(response['error_message'] ?? 'ไม่สามารถยกเลิกได้');
    //   // หากยกเลิกไม่ได้ ก็ให้อยู่ในหน้านี้ต่อไป
    // }
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
      _showToast('กำหนดรหัสผ่านมากกว่า 6 หลัก');
      return;
    }
    if (newPassword != confirmPassword) {
      _showToast('รหัสผ่านไม่ตรงกัน');
      return;
    }

    setState(() => _isLoading = true); 

    // final response = await CopServer.savePassword(memberNo, brNo, newPassword);

    if (!mounted) return;
    setState(() => _isLoading = false);

    // if (response['success'] == '1') {
    //   _showToast('บันทึกรหัสผ่านสำเร็จ');
      
    //   // นำทางตามค่า forget_pass
    //   Widget nextPage;
    //   if (widget.forgetPass == "1") {
    //     nextPage =  ReceiptPage(); // ลืมรหัสผ่าน -> ตั้ง PIN ใหม่
    //   } else if (widget.forgetPass == "2") {
    //     nextPage =  ReceiptPage(); // ลงทะเบียน -> ตั้ง PIN ครั้งแรก
    //   } else {
    //     nextPage =  ReceiptPage(); // ค่าอื่น -> หน้า PIN ปกติ
    //   }

    //   Navigator.of(context).pushAndRemoveUntil(
    //     MaterialPageRoute(builder: (context) => nextPage),
    //     (Route<dynamic> route) => false,
    //   );

    // } else {
    //   _showToast(response['error_message'] ?? 'ไม่สามารถบันทึกรหัสผ่านได้');
    // }
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
              onPressed: () => Navigator.pop(ctx, true), // ส่งค่า true เพื่อยืนยัน
              style: FilledButton.styleFrom(
                backgroundColor: Constants.greenColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('ตกลง')),
        ],
      ),
    );
    
    // if (confirmed == true && mounted) {
    //   // เมื่อผู้ใช้กด 'ตกลง' ใน Dialog ให้เรียก API ยกเลิก
    //   await _cancelRegistration(); 
    // }
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
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                SizedBox(height: h * 0.01),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                  child: const StepProgressIndicator( 
                    currentStep: 5, // ขั้นตอนที่ 5
                    totalSteps: 5,
                  ),
                ),
                SizedBox(height: h * 0.01),
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
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderField(textTheme),
                            SizedBox(height: h * 0.03),
                            _buildPasswordFields(),
                            SizedBox(height: h * 0.02),
                            const Text(
                              'คำแนะนำ: รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          
        ],
      ),
      
    );
  }

  Widget _buildHeaderField(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('กำหนดรหัสผ่านและยืนยัน',
            style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700, fontSize: 18, color: Constants.greenColor)),
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
          keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            labelText: 'รหัสผ่านใหม่',
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
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            // focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Constants.greenColor)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณากรอกรหัสผ่าน';
            }
            if (value.length < 6) {
              return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
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
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
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