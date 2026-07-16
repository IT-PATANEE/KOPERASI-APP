import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/screen/arrohnu_page.dart';
import 'package:koperasiapp/screen/deposit_page.dart';
import 'package:koperasiapp/screen/loan_page.dart';
import 'package:koperasiapp/screen/share_page.dart';
import 'package:koperasiapp/screen/taawoon_page.dart';
import 'package:koperasiapp/screen/selecttransfer_page.dart';

class HomePage extends StatefulWidget {
  final String member_no;
  final String br_no;
  final String token;

  const HomePage(
      {super.key,
      required this.member_no,
      required this.br_no,
      required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _memberNo;
  late String _branchNo;
  late String _token;

  String memberName = "กำลังโหลดข้อมูล...";
  String memberImgUrl = "";

  String depositBalance = "0.00 บาท";
  String shareValue = "0.00 บาท";

  // สถานะเปิด-ปิดตา แยกการ์ดเงินฝากและหุ้นตามรูปภาพ
  bool isDepositVisible = false;
  bool isShareVisible = false;

  @override
  void initState() {
    super.initState();
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
    _token = widget.token;
    fetchMemberData();
  }

  Future<void> fetchMemberData() async {
    try {
      var jsonResponse = await sendGetRequest();
      if (jsonResponse.isNotEmpty && jsonResponse['data'] != null) {
        if (mounted) {
          setState(() {
            memberName = jsonResponse['data']['member_name'] ?? "ไม่ระบุชื่อ";
            memberImgUrl = jsonResponse['data']['member_img'] ?? "";
            depositBalance =
                jsonResponse['data']['deposit_balance'] ?? "0.00 บาท";
            shareValue = jsonResponse['data']['share_balance'] ?? "0.00 บาท";
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<Map<String, dynamic>> sendGetRequest() async {
    String url = 'https://online.iscop.co.th/ws/MobileApp/main_data.php';
    String fullUrl = '$url?member_no=$_memberNo&br_no=$_branchNo';
    try {
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (_) {}
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;
    return Scaffold(
      backgroundColor: const Color(
          0xFFF4F6F8), // พื้นหลังสีเทาอ่อนช่วยผลักให้การ์ดขาวเด่นชัดขึ้น
      body: Column(
        children: [
          _buildHead(
            member_no: _memberNo,
            br_no: _branchNo,
            memberName: memberName,
            memberImgUrl: memberImgUrl,
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildFinancialSection(
                        w, h), // ส่วนการ์ดเงินฝากและหุ้นแบบคู่ ซ้าย-ขวา
                    const SizedBox(height: 24),
                    _buildTitleSection(), // หัวข้อ "ธุรกรรมและผลิตภัณฑ์"
                    const SizedBox(height: 16),
                    _buildMenuGrid(), // Grid เมนู 3 คอลัมน์สไตล์การ์ดเดี่ยว
                    const SizedBox(height: 20),
                    // _buildOtherButton(), // ปุ่ม "อื่นๆ" ด้านล่างสุด
                    // const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. การ์ดยอดเงินฝากและหุ้นแบบคู่ (ซ้าย-ขวา) ตามภาพตัวอย่าง ---
  Widget _buildFinancialSection(double w, double h) {
    return Row(
      children: [
        // ฝั่งซ้าย: บัญชีเงินฝากรวม
        Expanded(
          child: _buildInfoCard(
            title: 'บัญชีเงินฝากรวม',
            value: depositBalance,
            isVisible: isDepositVisible,
            onToggle: () =>
                setState(() => isDepositVisible = !isDepositVisible),
            isStringValue: true,
            w: w, // ใส่ค่า w เพื่อป้องกัน Error และรองรับ Responsive
            h: h, // ใส่ค่า h เพื่อป้องกัน Error และรองรับ Responsive
            onCardTap: () {
              // 🚀 เมื่อกดที่การ์ด หรือ ไอคอนลูกศร ให้เปิดหน้า AccPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccPage(
                    member_no: _memberNo,
                    br_no: _branchNo,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        // ฝั่งขวา: บัญชีทุนเรือนหุ้น
        Expanded(
          child: _buildInfoCard(
            title: 'บัญชีทุนเรือนหุ้น',
            value: shareValue,
            isVisible: isShareVisible,
            onToggle: () => setState(() => isShareVisible = !isShareVisible),
            isStringValue: true,
            w: w, // ใส่ค่า w เพื่อป้องกัน Error และรองรับ Responsive
            h: h, // ใส่ค่า h เพื่อป้องกัน Error และรองรับ Responsive
            onCardTap: () {
              // 🚀 เมื่อกดที่การ์ด หรือ ไอคอนลูกศร ให้เปิดหน้า AccPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SharePage(
                    member_no: _memberNo,
                    br_no: _branchNo,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required dynamic value,
    required bool isVisible,
    required VoidCallback onToggle,
    required bool isStringValue,
    required double w,
    required double h,
    VoidCallback? onCardTap, // เพิ่มพารามิเตอร์สำหรับดักจับการกดที่ตัวการ์ด
  }) {
    String displayValue = 'XX.XX';
    if (isVisible) {
      if (isStringValue) {
        displayValue = value
            .toString(); // ถ้าเป็น String จาก API (มีคำว่า "บาท" แล้ว) ก็นำมาใช้ได้เลย
      } else {
        displayValue = '${(value as double).toStringAsFixed(2)} บาท';
      }
    }
    return GestureDetector(
      onTap: onCardTap, // ⚡ เปิดหน้าใหม่เมื่อกดที่การ์ด
      child: Container(
        padding: EdgeInsets.all(w * 0.032),
        height: h * 0.135,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4B5563),
                  ),
                ),
                // ไอคอนลูกศรจะสามารถกดได้พร้อมกับตัวการ์ดทันที
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: w * 0.028,
                  color: Colors.grey[400],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: double.infinity,
                  alignment: Alignment.centerRight,
                  child: Text(
                    displayValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: h * 0.005),
                // โซนสำหรับกด "ดูยอดเงิน" (แยกการทำงานออกจากการกดเปิดหน้าใหม่ชัดเจน)
                GestureDetector(
                  onTap: onToggle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'ดูยอดเงิน',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[500]),
                      ),
                      SizedBox(width: w * 0.015),
                      Icon(
                        isVisible ? Icons.visibility : Icons.visibility_off,
                        size: w * 0.032,
                        color: Colors.grey[500],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. ส่วนหัวข้อเมนูที่มีแถบสีเขียวตั้งด้านหน้า ---
  Widget _buildTitleSection() {
    return Row(
      children: [
        Container(
          width: 6,
          height: 18,
          decoration: BoxDecoration(
            color: Constants.greenColors,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'ธุรกรรมและผลิตภัณฑ์',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  // --- 3. Grid เมนูเรียง 3 แถว สไตล์การ์ดเดี่ยวมีขอบเงาตามภาพ ---
  Widget _buildMenuGrid() {
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': 'assets/images/icon-menu/icon_01.png',
        'title': 'โอน-ชำระ',
        'page': SelectTransferPage(
            member_no: _memberNo, br_no: _branchNo, token: _token)
      },
      {
        'icon': 'assets/images/icon-menu/icon_02.png',
        'title': 'ทุนเรือนหุ้น',
        'page': SharePage(member_no: _memberNo, br_no: _branchNo)
      },
      {
        'icon': 'assets/images/icon-menu/icon_03.png',
        'title': 'เงินฝาก',
        'page': AccPage(member_no: _memberNo, br_no: _branchNo)
      },
      {
        'icon': 'assets/images/icon-menu/icon_04.png',
        'title': 'สวัสดิการ',
        'page': SharePage(member_no: _memberNo, br_no: _branchNo)
      },
      {
        'icon': 'assets/images/icon-menu/icon_05.png',
        'title': 'ตะอาวุน',
        'page': TaawoonPage(member_no: _memberNo, br_no: _branchNo)
      },
      // {'icon': 'assets/images/icon-menu/icon_06.png', 'title': 'QR CODE', 'page': SharePage(member_no: _memberNo, br_no: _branchNo)},
      {
        'icon': 'assets/images/icon-menu/icon_07.png',
        'title': 'สินเชื่อ',
        'page': LoanPage(member_no: _memberNo, br_no: _branchNo)
      },
      {
        'icon': 'assets/images/icon-menu/icon_08.png',
        'title': 'อัรเราะห์นู',
        'page': ArrohnuPage(member_no: _memberNo, br_no: _branchNo)
      },
      {
        'icon': 'assets/images/icon-menu/icon_09.png',
        'title': 'โอนเงินธนาคาร',
        'page': SharePage(member_no: _memberNo, br_no: _branchNo)
      },
      {
        'icon': 'assets/images/icon-menu/icon_11.png',
        'title': 'อื่นๆ',
        'page': SharePage(member_no: _memberNo, br_no: _branchNo)
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menuItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio:
            1.25, // ปรับสัดส่วนให้เป็นทรงสี่เหลี่ยมผืนผ้าแนวนอนตามรูปภาพ
      ),
      itemBuilder: (context, index) {
        return _buildMenuButton(
          menuItems[index]['icon'],
          menuItems[index]['title'],
          menuItems[index]['page'],
        );
      },
    );
  }

  Widget _buildMenuButton(String imagePath, String title, Widget nextPage) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => nextPage,
            settings: RouteSettings(
                arguments: {'member_no': _memberNo, 'br_no': _branchNo}),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 42,
              height: 42,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.apps, color: Constants.greenColors, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. ปุ่มเมนู "อื่นๆ" (ไอคอน 4 จุด) แยกเดี่ยวตามรูปภาพ ---
  // Widget _buildOtherButton() {
  //   return Center(
  //     child: GestureDetector(
  //       onTap: () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) =>
  //                 SharePage(member_no: _memberNo, br_no: _branchNo),
  //           ),
  //         );
  //       },
  //       child: Container(
  //         width: 60,
  //         height: 60,
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(16),
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.black.withOpacity(0.03),
  //               blurRadius: 8,
  //               offset: const Offset(0, 2),
  //             )
  //           ],
  //         ),
  //         child: Icon(
  //           Icons.apps_rounded, // ไอคอนสี่เหลี่ยม 4 จุดสไตล์โมเดิร์น
  //           color: Colors.grey[400],
  //           size: 32,
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

// --- ปรับปรุงใหม่: ส่วนหัวสไตล์โมเดิร์นพรีเมียม พร้อมปุ่มแจ้งเตือนข้างโลโก้ ---
class _buildHead extends StatelessWidget {
  final String member_no;
  final String br_no;
  final String memberName;
  final String memberImgUrl;

  const _buildHead({
    required this.member_no,
    required this.br_no,
    required this.memberName,
    required this.memberImgUrl,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;
    final double statusBarHeight = media.padding.top;

    return Container(
      padding: EdgeInsets.only(
        top: statusBarHeight + (h * 0.02),
        left: w * 0.05,
        right: w * 0.05,
        bottom: h * 0.048,
      ),
      decoration: BoxDecoration(
        // เปลี่ยนเป็นไล่เฉดสีเขียว (Gradient) เพิ่มมิติความหรูหรา ทันสมัย ไม่ดูแบน
        gradient: LinearGradient(
          colors: [
            Constants.greenColors,
            Constants.greenColors.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // แถวบนสุด: ข้อมูลผู้ใช้ (ฝั่งซ้าย) | โลโก้และแจ้งเตือน (ฝั่งขวา)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 👤 ฝั่งซ้าย: รูปโปรไฟล์และชื่อสมาชิกในแนวราบ (Row) ดูแพงและคลีน
              Expanded(
                child: Row(
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            width: 2, color: Colors.white.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: memberImgUrl.isNotEmpty
                            ? Image.network(
                                memberImgUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset('assets/images/avatar_man.png',
                                        fit: BoxFit.cover),
                              )
                            : Image.asset('assets/images/avatar_man.png',
                                fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'ยินดีต้อนรับ',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            memberName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // 🏛️ ฝั่งขวา: กลุ่มโลโก้และปุ่มแจ้งเตือนตามโจทย์
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ปุ่มแจ้งเตือนโมเดิร์น อยู่ข้างๆ โลโก้
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded,
                            color: Colors.white, size: 26),
                        onPressed: () {
                          // โค้ดเปิดหน้าแจ้งเตือนของคุณ
                        },
                      ),
                      // จุดสีแดงแจ้งเตือนเล็กๆ เพิ่มความสมจริงและทันสมัย
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(width: 4),
                  // โลโก้สหกรณ์ในกรอบขาวมนตามภาพตัวอย่าง
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/icon_logo.png',
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.business_rounded,
                          color: Constants.greenColors,
                          size: 24),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
