import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/screen/depositStatement_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'qrcode_page.dart';
import 'register_terms_page.dart';

class AccPage extends StatefulWidget {
  final String member_no;
  final String br_no;
  const AccPage({super.key, required this.member_no, required this.br_no});

  @override
  State<AccPage> createState() => _AccPageState();
}

class _AccPageState extends State<AccPage> {
  Future<Map<String, dynamic>>? accountData;

  late String _memberNo;
  late String _branchNo;
  String _token = '';
  String serverResponse = 'กำลังรอข้อมูลจากเซิร์ฟเวอร์...';
  String memberName = "Loading...";

  List<dynamic> _accounts = [];
  String _totalBalance = '';

  Future<void> fetchAccountData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // Get the token from SharedPreferences
    if (token != null && token.isNotEmpty) {
      setState(() {
        _token = token; // เก็บ token ไว้ในตัวแปร
      });
    }

    String url = 'https://online.iscop.co.th/ws/MobileApp/deposit.php';
    String fullUrl = '$url?member_no=$_memberNo&br_no=$_branchNo&token=$token';
    final response = await http.get(
      Uri.parse(fullUrl),
      headers: {
        'Authorization': 'Bearer $token', // Send token in headers
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      setState(() {
        _accounts = jsonResponse['data']; // เก็บข้อมูล accounts
        _totalBalance = jsonResponse['total_balance']; // เก็บยอดรวม
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    super.initState();
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
    fetchAccountData();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final w = media.size.width;
    final h = media.size.height;
    final _formSignInKey = GlobalKey<FormState>();
    final _navigatorKey = GlobalKey<NavigatorState>();
    return Scaffold(
      // navigatorKey: _navigatorKey, // This is where the navigatorKey should go
        backgroundColor: Constants.bg,
        appBar: AppBar(
          backgroundColor: Constants.primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true, // ✅ ตัวนี้ทำให้ title อยู่กลางจริง
          title: Text(
            'บัญชีออมทรัพย์',
            style: theme.textTheme.titleLarge!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _accounts.isEmpty
            ? const Center(
                child:
                    CircularProgressIndicator()) // ถ้ายังไม่มีข้อมูลให้แสดง loading
            : Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.stop,
                          color: Color.fromARGB(255, 0, 87, 31),
                          size: 30.0,
                        ),
                        Text(
                          'บัญชีของฉัน',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _accounts.length,
                        itemBuilder: (context, index) {
                          final account =
                              _accounts[index]; // ข้อมูลบัญชีแต่ละรายการ

                          return Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  // เมื่อกด AccCard จะเปลี่ยนหน้าไปยังหน้าถัดไป
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DepositStatementPage(
                                        accountNo: account['account_no'],
                                        memberNo: _memberNo,
                                        branchNo: _branchNo,
                                        token: _token,
                                      ),
                                    ),
                                  );
                                },
                                child: AccCard(
                                  text1: 'บัญชี${account['account_desc']}',
                                  text2: account['account_name'],
                                  text3: account['balance'],
                                  text4: account['account_no'],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

// ACC CARD STYLE
class AccCard extends StatelessWidget {
  final String text1;
  final String text2;
  final String text3;
  final String text4;

  const AccCard(
      {Key? key,
      required this.text1,
      required this.text2,
      required this.text3,
      required this.text4})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mediaSize = MediaQuery.of(context).size;
    return Container(
        height: mediaSize.height * 0.22,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                  color: Color(0xFFe8e8e8),
                  blurRadius: 10.0,
                  offset: Offset(0, 5))
            ]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.white,
                    child: Stack(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: EdgeInsets.all(15.0),
                            child: Column(
                              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      text1,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ยอดเงินคงเหลือ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10.0,
                                ),
                                Divider(),
                                const SizedBox(
                                  height: 10.0,
                                ),
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          text2,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              text3,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 10.0,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          text4,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Positioned(
                                              // top: 50,
                                              // left: 10,
                                              child: Image.asset(
                                                'assets/images/credit-card.png',
                                                height: 40,
                                                fit: BoxFit.cover,
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
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ));
  }
}
