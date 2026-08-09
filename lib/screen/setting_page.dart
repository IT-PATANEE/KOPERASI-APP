import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/screen/depositStatement_page.dart';
import 'package:koperasiapp/screen/load_qrcode_page.dart';
import 'package:koperasiapp/screen/profile_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class SettingPage extends StatefulWidget {
  final String member_no;
  final String br_no;
  final String token;

  const SettingPage(
      {super.key,
      required this.member_no,
      required this.br_no,
      required this.token});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late String _memberNo;
  late String _branchNo;
  late String _token;

  @override
  void initState() {
    super.initState();
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
    _token = widget.token; // <-- เพิ่มบรรทัดนี้เพื่อเก็บค่า Token ไว้ใช้งาน
    print("กำลังส่งข้อมูล: member_no=$_memberNo, br_no=$_branchNo");
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final w = media.size.width;
    final h = media.size.height;

    return Scaffold(
      backgroundColor: Constants.bg,
      // resizeToAvoidBottomInset: false, // ✅ ป้องกันคีย์บอร์ดดัน layout
      appBar: AppBar(
        backgroundColor: Constants.greenColors,
        automaticallyImplyLeading: false, // ปิดการสร้างปุ่มย้อนกลับอัตโนมัติ
        centerTitle: true, // ให้ title อยู่กลางจริง ๆ
        title: Text(
          'ตั้งค่าการใช้งาน',
          style: theme.textTheme.titleLarge!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              _showLogoutDialog(); // ✅ เรียก Dialog ออกจากระบบที่ทำไว้แล้วได้เลย
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Column(
        children: [
          // ส่วนของรายการเมนูตั้งค่า
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // กลุ่มที่ 1: ตั้งค่าทั่วไป / ตั้งค่าความปลอดภัย / ข้อกำหนดและเงื่อนไข
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingItem(
                        title: 'ตั้งค่าข้อมูลทั่วไป',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProfilePage(
                                      member_no: _memberNo,
                                      br_no: _branchNo,
                                      token: _token,
                                    )),
                          );
                        },
                      ),
                      Divider(height: 1, color: Colors.grey.shade100),
                      _buildSettingItem(
                        title: 'ตั้งค่าความปลอดภัย',
                        onTap: () {
                          // TODO: ใส่ Action หรือเปิดหน้าถัดไปที่นี่
                        },
                      ),
                      Divider(height: 1, color: Colors.grey.shade100),
                      _buildSettingItem(
                        title: 'ข้อกำหนดและเงื่อนไข',
                        onTap: () {
                          // TODO: ใส่ Action หรือเปิดหน้าถัดไปที่นี่
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // กลุ่มที่ 2: ติดต่อเรา
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildSettingItem(
                    title: 'ติดต่อเรา',
                    onTap: () {
                      // TODO: ใส่ Action หรือเปิดหน้าถัดไปที่นี่
                    },
                  ),
                ),

                // ✅ ย้ายข้อความเวอร์ชันเข้ามาอยู่ใน ListView ใต้ "ติดต่อเรา" ตรงนี้ครับ
                const SizedBox(height: 24), // เว้นระยะห่างจากกล่องลงมาเล็กน้อย
                const Padding(
                  padding: EdgeInsets.only(
                      left: 16.0), // เขยิบเข้ามาให้ตรงกับแนวข้อความด้านบนเป๊ะๆ
                  child: Text(
                    'เวอร์ชัน 2.0.1',
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //  Widget ย่อยสำหรับสร้างแถวเมนูแต่ละช่อง
  Widget _buildSettingItem(
      {required String title, required VoidCallback onTap}) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.black26,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  // ฟังก์ชันแสดงหน้าต่างยืนยันก่อนออกจากระบบ
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // ป้องกันผู้ใช้กดพื้นที่ว่างด้านนอกเพื่อปิดไดอะล็อก (เพิ่มความชัวร์ในการตัดสินใจ)
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
          contentPadding:
              const EdgeInsets.only(top: 10, bottom: 20, left: 24, right: 24),
          actionsPadding: EdgeInsets.zero,
          title: const Text(
            'ออกจากระบบ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          content: const Text(
            'คุณต้องการออกจากระบบใช่หรือไม่?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(height: 1, color: Colors.grey.shade200),
                Row(
                  children: [
                    // ปุ่มยกเลิก (ฝั่งซ้าย)
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(
                                  14), // ปรับให้เท่ากับความมนของกล่องหลัก (14)
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // เส้นแบ่งแนวตั้ง
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.grey.shade200,
                    ),
                    // ปุ่มยืนยันออกจากแอป (ฝั่งขวา)
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(
                                  14), // ปรับให้เท่ากับความมนของกล่องหลัก (14)
                            ),
                          ),
                        ),
                        onPressed: () async {
                          if (mounted) {
                            Navigator.of(context).pop();
                            await SystemNavigator
                                .pop(); // ออกจากแอปพลิเคชันทันที
                          }
                        },
                        child: const Text(
                          'ยืนยัน',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
