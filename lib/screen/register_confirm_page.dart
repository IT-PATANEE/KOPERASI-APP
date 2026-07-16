// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';

import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/screen/register_step_progress.dart';
import 'package:koperasiapp/widgets/custtom_scaffold.dart';

import 'login_page.dart';
import 'register_otp_page.dart';

class RegisterConfirmPage extends StatefulWidget {
  final String username;
  final String idCard;
  final String tel;
  final String memberNo;
  final String brNo;
  final String statusPin;
  final String flgAccept;
  final String forgetPass;

  const RegisterConfirmPage({
    Key? key,
    // this.brNo = '000', // สมมติค่าเริ่มต้นสำหรับ Branch No.
    required this.memberNo,
    required this.username,
    required this.idCard,
    required this.tel,
    required this.brNo,
    this.statusPin = '1', // สมมติว่าต้องการให้ไปหน้าสร้าง PIN
    this.flgAccept = '1',
    this.forgetPass = '2',
  }) : super(key: key);

  @override
  State<RegisterConfirmPage> createState() => _RegisterConfirmPageState();
}

class _RegisterConfirmPageState extends State<RegisterConfirmPage> {
  void _navigateToOtpPage() {
    // ในขั้นตอนการลงทะเบียนนี้ จะคล้ายกับ LoginMobileActivity.onPostExecute
    // คือนำทางไปยังหน้า OTP โดยส่งข้อมูลสำคัญไปด้วย

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterOtpPage(
          memberNo: widget.memberNo, // เลขทะเบียนสมาชิก
          brNo: widget.brNo, // รหัสสาขา
          mobile: widget.tel, // เบอร์โทรศัพท์
          statusPin: widget.statusPin, // สถานะ PIN (0 หรือ 1)
          flgAccept: widget.flgAccept,
          forgetPass: widget.forgetPass,
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ตรวจสอบข้อมูลการลงทะเบียน',
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
                currentStep: 3,
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
                    _buildInfoRow('เลขทะเบียนสมาชิก', widget.username),
                    SizedBox(height: h * 0.02),
                    _buildInfoRow('เลขบัตรประชาชน', widget.idCard),
                    SizedBox(height: h * 0.02),
                    _buildInfoRow('เบอร์โทรศัพท์', widget.tel),
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
                    onPressed: _navigateToOtpPage,
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
        Text('กรุณาตรวจสอบข้อมูลก่อนยืนยัน',
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
        // SizedBox(height: h * 0.01),
        // Text('ปรับปรุงล่าสุด: 15 สิงหาคม 2025  ·  เวอร์ชัน 1.0',
        //     style: textTheme.bodySmall),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
