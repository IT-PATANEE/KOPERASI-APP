import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/screen/arrohnu_page.dart';
import 'package:koperasiapp/screen/loan_page.dart';
import 'package:koperasiapp/screen/share_page.dart';
import 'package:koperasiapp/screen/taawoon_page.dart';
import 'package:koperasiapp/screen/selecttransfer_page.dart';

//================ anita add 280867 ================

//================ end anita add 280867 ================

class HomePage extends StatefulWidget {
  final String member_no;
  final String br_no;
  final String token;

  const HomePage({super.key, required this.member_no, required this.br_no, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _memberNo;
  late String _branchNo;
  late String _token;

  // String depositBalance = ''; // ตัวแปรสำหรับเก็บยอดคงเหลือ

  String serverResponse = 'กำลังรอข้อมูลจากเซิร์ฟเวอร์...';
  String member_name = '';
  String memberName = "Loading...";
  String memberImgUrl = "";
  @override
  void initState() {
    super.initState();
    // นำค่าจาก widget ไปเก็บในตัวแปรของ State
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
    _token = widget.token;
    // เรียกใช้ฟังก์ชันเพื่อส่งคำขอ GET ทันทีเมื่อโหลดหน้า
    fetchMemberData();
  }

// ฟังก์ชันที่ส่งคำขอ HTTP GET และดึงข้อมูลจาก API
  Future<void> fetchMemberData() async {
    try {
      var jsonResponse = await sendGetRequest(); // เรียกใช้ฟังก์ชันที่คุณเขียน

      // ตรวจสอบว่ามีข้อมูลใน response หรือไม่
      if (jsonResponse.isNotEmpty && jsonResponse['data'] != null) {
        setState(() {
          memberName = jsonResponse['data']['member_name'];
          memberImgUrl =
              jsonResponse['data']['member_img']; // ดึง URL ของรูปภาพจาก JSON
        });
      } else {
        setState(() {
          memberName = "No data found";
        });
      }
    } catch (e) {
      setState(() {
        memberName = "Error: $e";
      });
    }
  }

  // ฟังก์ชันสำหรับส่งคำขอ HTTP GET
  Future sendGetRequest() async {
    String url = 'https://online.iscop.co.th/ws/MobileApp/main_data.php';
    String fullUrl = '$url?member_no=$_memberNo&br_no=$_branchNo';

    try {
      // ส่งคำขอ HTTP GET
      final response = await http.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        print('yesss');
        return json.decode(response.body);
        // แปลงข้อมูล JSON เป็น Dart Map
      } else {
        // throw Exception('Failed to load data : ${response.statusCode}');
        throw Exception('Failed to load data : ${response.body}');
      }
    } catch (e) {
      print(e.toString());
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    var mediaSize = MediaQuery.of(context).size;
    return Scaffold(
      // backgroundColor: Constants.bg,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHead(
                  mediaSize: mediaSize,
                  member_no: _memberNo,
                  br_no: _branchNo,
                  memberName: memberName,
                  memberImgUrl: memberImgUrl,
                ),
                _buildmenu(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildmenu() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.stop,
                color: Constants.greenColors,
                size: 30.0,
              ),
              const Text(
                'ธุรกรรม',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMenuButton(
                    'assets/images/icon-menu/icon_01.png',
                    'โอนชำระ',
                    SelectTransferPage(
                        member_no: _memberNo, br_no: _branchNo, token: _token)),
                _buildMenuButton(
                    'assets/images/icon-menu/share_pay.png',
                    'ชำระค่าหุ้น',
                    SharePage(member_no: _memberNo, br_no: _branchNo)),
                _buildMenuButton(
                    'assets/images/icon-menu/loan_pay.png',
                    'ชำระสินเชื่อ',
                    SharePage(member_no: _memberNo, br_no: _branchNo)),
                _buildMenuButton(
                    'assets/images/icon-menu/rohnu_pay.png',
                    'ชำระอัรเราะห์นู',
                    SharePage(member_no: _memberNo, br_no: _branchNo)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMenuButton(
                    'assets/images/icon-menu/taawun_pay.png',
                    'ชำระตะอาวุน',
                    SharePage(member_no: _memberNo, br_no: _branchNo)),
                _buildMenuButton(
                    'assets/images/icon-menu/trans_bank.png',
                    'โอนไปยังธนาคาร',
                    SharePage(member_no: _memberNo, br_no: _branchNo)),
                _buildMenuButton(
                    'assets/images/icon-menu/qr_code.png',
                    'QR CODE',
                    SharePage(member_no: _memberNo, br_no: _branchNo)),
                _buildMenuButton(
                    'assets/images/icon-menu/rohnu_pay.png',
                    'แปะไว้ก่อน',
                    SharePage(member_no: _memberNo, br_no: _branchNo)),
              ],
            ),
          ],
        ),
        const SizedBox(
          height: 15,
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                Icons.stop,
                color: Constants.greenColors,
                size: 30.0,
              ),
              const Text(
                'ผลิตภัณฑ์และบริการ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMenuButton(
                    'assets/images/icon-menu/share.png',
                    'ทุนเรือนหุ้น',
                    SharePage(member_no: _memberNo, br_no: _branchNo)),
                _buildMenuButton('assets/images/icon-menu/loan.png', 'สินเชื่อ',
                    LoanPage(member_no: _memberNo, br_no: _branchNo)),
                _buildMenuButton(
                    'assets/images/icon-menu/rohnu.png',
                    'อัรเราะห์นู',
                    ArrohnuPage(member_no: _memberNo, br_no: _branchNo)),
                _buildMenuButton(
                    'assets/images/icon-menu/taawun.png',
                    'ตะอาวุน',
                    TaawoonPage(member_no: _memberNo, br_no: _branchNo)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMenuButton(
                    'assets/images/icon-menu/welfare.png',
                    'สวัสดิการ',
                    SharePage(member_no: _memberNo, br_no: _branchNo)),
                _buildMenuButton(
                    'assets/images/icon-menu/cal.png',
                    'คำนวณสินเชื่อ',
                    SharePage(member_no: _memberNo, br_no: _branchNo)),
                _buildMenuButton(
                    'assets/images/icon-menu/acc_online.png',
                    'เปิดบัญชีออนไลน์',
                    SharePage(member_no: _memberNo, br_no: _branchNo)),
                _buildMenuButton('assets/images/icon-menu/other.png', 'อื่นๆ',
                    SharePage(member_no: _memberNo, br_no: _branchNo)),
              ],
            ),
          ],
        ),
        const SizedBox(
          height: 15,
        ),
      ],
    );
  }

  Widget _buildMenuButton(String imagePath, String title, Widget nextPage) {
    var mediaSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => nextPage,
            settings: RouteSettings(
              arguments: {'member_no': _memberNo, 'br_no': _branchNo},
            ),
          ),
        );
      },
      child: Column(
        children: [
          Image.asset(
            imagePath,
            height: mediaSize.height * 0.1,
            fit: BoxFit.cover,
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _buildHead extends StatelessWidget {
  final String member_no;
  final String br_no;
  final Size mediaSize;
  final String memberName;
  final String memberImgUrl;

  const _buildHead(
      {required this.mediaSize,
      required this.member_no,
      required this.br_no,
      required this.memberName,
      required this.memberImgUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: mediaSize.height * 0.22,
      decoration: BoxDecoration(
        color: Constants.greenColors,
        image: const DecorationImage(
          image: AssetImage('assets/images/background/bg1.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 10, left: 10.0, top: 15),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.notifications,
                  color: Colors.white,
                ),
                SizedBox(width: 20),
                Icon(
                  Icons.logout_outlined,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Container(
                  height: 80.0,
                  width: 80.0,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(.1),
                            spreadRadius: 3)
                      ],
                      border: Border.all(
                        width: 1.5,
                        color: Colors.white,
                      ),
                      borderRadius: BorderRadius.circular(40.0)),
                  padding: const EdgeInsets.all(2),
                  // child: const CircleAvatar(
                  //   backgroundImage: AssetImage('assets/images/pro.png'),
                  // ),
                  child: CircleAvatar(
                    backgroundImage: memberImgUrl.isNotEmpty
                        ? FadeInImage.assetNetwork(
                            placeholder: 'assets/images/avatar_man.png',
                            image: memberImgUrl,
                            fit: BoxFit.cover,
                          ).image
                        : const AssetImage('assets/images/avatar_man.png'),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        memberName,
                        key: ValueKey<String>(memberName),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Text(
                          // "เลขทะเบียนสมาชิก : 0010200001",
                          'เลขทะเบียนสมาชิก : ${br_no}01$member_no',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
