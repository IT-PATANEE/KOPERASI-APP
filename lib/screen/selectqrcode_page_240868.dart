import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/screen/depositStatement_page.dart';
import 'package:koperasiapp/screen/load_qrcode_page.dart';
import 'package:koperasiapp/screen/qrcode_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SelectQrcodePage extends StatefulWidget {
  final String member_no;
  final String br_no;
  const SelectQrcodePage({
    super.key,
    required this.member_no,
    required this.br_no,
  });

  @override
  State<SelectQrcodePage> createState() => _SelectQrcodePageState();
}

class _SelectQrcodePageState extends State<SelectQrcodePage> {
  late String _memberNo;
  late String _branchNo;
  String _token = '';

  String memberName = '';

  // Future<void> fetchQrcodeData() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? token =
  //       prefs.getString('token'); // Get the token from SharedPreferences
  //   if (token != null && token.isNotEmpty) {
  //     setState(() {
  //       _token = token; // เก็บ token ไว้ในตัวแปร
  //     });
  //   }

  //   String url = 'https://online.iscop.co.th/ws/MobileApp/load_qrcode.php';
  //   String fullUrl = '$url?member_no=$_memberNo&br_no=$_branchNo&token=$token';
  //   print('$fullUrl');
  //   final response = await http.get(
  //     Uri.parse(fullUrl),
  //     headers: {
  //       'Authorization': 'Bearer $token', // Send token in headers
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic> jsonResponse = json.decode(response.body);
  //     setState(() {
  //       memberName = jsonResponse['data']['member_name'];
  //     });
  //   } else {
  //     throw Exception('Failed to load data');
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;

    // fetchQrcodeData();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isPortrait = media.orientation == Orientation.portrait;
    final theme = Theme.of(context); // <-- ใช้ ThemeData
    final w = media.size.width;
    final h = media.size.height;
    final textScale = w * 0.04; // ขนาดฟอนต์ตามความกว้างจอ
    return Scaffold(
      backgroundColor: Constants.bg,
      appBar: AppBar(
        backgroundColor: Constants.greenColor,
        automaticallyImplyLeading: false, // ปิดปุ่มย้อนกลับ (ปุ่มย้อนกลับจะขึ้นมาโดยอัตโนมัติถ้า หน้าเปิดด้วย Navigator.push)
        title: Center(
          child: Text(
            'เลือกรูปแบบการสร้าง QR CODE',
            style: theme.textTheme.titleLarge!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.pop(context); // ปิดหน้าเมื่อกดปุ่มกากบาท
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Icon(
                    Icons.stop,
                    color: Color.fromARGB(255, 0, 87, 31),
                    size: 30.0,
                  ),
                  Text(
                    'เลือกประเภทธุรกรรม',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 25.0,
              ),
              buildQrMenuItem('QR CODE ชำระหุ้น',
                  'assets/images/icon-menu/share_pay.png', 1),
              buildQrMenuItem(
                  'QR CODE เงินฝาก', 'assets/images/icon-menu/pay.png', 2),
              buildQrMenuItem('QR CODE ชำระสินเชื่อ',
                  'assets/images/icon-menu/loan_pay.png', 3),
              buildQrMenuItem('QR CODE ชำระอัรเราะห์นู',
                  'assets/images/icon-menu/rohnu_pay.png', 4),
              buildQrMenuItem('QR CODE ชำระตะอาวุน',
                  'assets/images/icon-menu/taawun_pay.png', 5),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildQrMenuItem(String title, String imagePath, int type) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QrcodeDataPage(
                  member_no: _memberNo,
                  br_no: _branchNo,
                  type: type,
                  memberName: memberName,
                ),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                imagePath,
                height: 50, // ปรับขนาดรูปภาพ
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        const Divider(),
        const SizedBox(height: 15),
      ],
    );
  }
}

void main() {
  runApp(const MaterialApp(
      home: SelectQrcodePage(
    member_no: '',
    br_no: '',
  )));
}
