import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoadQrcodePage extends StatefulWidget {
  final String memberNo;
  final String brNo;
  final int type;

  const LoadQrcodePage({
    Key? key,
    required this.memberNo,
    required this.brNo,
    required this.type,
  }) : super(key: key);

  @override
  State<LoadQrcodePage> createState() => _LoadQrcodePageState();
}

class _LoadQrcodePageState extends State<LoadQrcodePage> {
  late String _memberNo;
  late String _branchNo;
  late int type;
  String _token = '';

  Future<void> fetchAccountData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // Get the token from SharedPreferences
    if (token != null && token.isNotEmpty) {
      setState(() {
        _token = token; // เก็บ token ไว้ในตัวแปร
      });
    }

    String url = 'https://online.iscop.co.th/ws/MobileApp/load_qrcode.php';
    String fullUrl = '$url?member_no=$_memberNo&br_no=$_branchNo&token=$token';
    final response = await http.get(
      Uri.parse(fullUrl),
      headers: {
        'Authorization': 'Bearer $token', // Send token in headers
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _memberNo = widget.memberNo;
    _branchNo = widget.brNo;
    type = widget.type;
    fetchAccountData();
  }

  @override
  Widget build(BuildContext context) {
    // สร้างข้อมูลสำหรับ QR Code
    // final qrData = '|$memberNo\n$brNo\n$brNo\n20000';
    // สร้างข้อความหรือข้อมูล QR Code ตาม type
    String qrData;
    if (type == 1) {
      qrData = '|$_memberNo\n$_branchNo\n$_branchNo\n20000';
    } else if (type == 2) {
      qrData = '|$_memberNo\n$_branchNo\n$_branchNo\n20000';
    } else {
      qrData = "Unknown QR Type";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR CODE ชำระหุ้น'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // แสดง QR Code
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
              errorStateBuilder: (context, error) => const Center(
                child: Text(
                  "ไม่สามารถสร้าง QR Code ได้",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // แสดงข้อมูลที่ใช้สร้าง QR Code
            Text(
              "QR Code สำหรับ Member: $_memberNo\nBranch: $_branchNo\ntype: $type\n $qrData",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
