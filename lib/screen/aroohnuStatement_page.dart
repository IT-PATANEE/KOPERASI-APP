import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/screen/depositStatement_page.dart';
import 'package:koperasiapp/screen/share_page%20copy.dart';
import 'package:page_transition/page_transition.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ArrohnuStatementPage extends StatefulWidget {
  final String member_no;
  final String br_no;
  final String loanNo;
  final String loanId;

  const ArrohnuStatementPage(
      {required this.member_no,
      required this.br_no,
      required this.loanNo,
      required this.loanId});

  @override
  State<ArrohnuStatementPage> createState() => _ArrohnuStatementPageState();
}

class _ArrohnuStatementPageState extends State<ArrohnuStatementPage> {
  late String _memberNo;
  late String _branchNo;
  late String _loanNo;
  late String _loanId;
  String _token = '';
  Map<String, dynamic>? _loanStatementData;

  @override
  void initState() {
    super.initState();
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
    _loanNo = widget.loanNo;
    _loanId = widget.loanId;
    fetchShareData();
  }

  Future<void> fetchShareData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // Get the token from SharedPreferences

    if (token != null && token.isNotEmpty) {
      setState(() {
        _token = token; // Store token in a variable
      });
    }

    String url =
        'https://online.iscop.co.th/ws/MobileApp/arrohnu_statement.php';
    String fullUrl =
        '$url?member_no=$_memberNo&br_no=$_branchNo&token=$token&loan_no=$_loanNo&loan_id=$_loanId';

    try {
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token', // Send token in headers
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // ตรวจสอบว่าข้อมูลใน jsonResponse เป็นไปตามที่คาดหวัง
        if (jsonResponse['success'] == 1) {
          setState(() {
            _loanStatementData =
                jsonResponse['data']; // เก็บทั้ง master และ statement
            // print(
            //     'Share Data: $_taawoonData');
          });
        } else {
          print(
              'Error: ${jsonResponse['message']}'); // ถ้ามีข้อความผิดพลาดใน JSON
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      print("Error fetching data: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Constants.bg,
        appBar: AppBar(
          backgroundColor: Constants.primaryColor,
          title: const Center(
            child: Text(
              'สินเชื่ออัร-เราะห์นู',
              style:
                  TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
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
                      'รายละเอียดสินเชื่อ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                // Check if _taawoonData is available before rendering ShareCard
                _loanStatementData == null
                    ? const CircularProgressIndicator()
                    : (_loanStatementData!['master'] != null &&
                            _loanStatementData!['master'].isNotEmpty
                        ? loanCard(
                            text1: _loanStatementData!['master']
                                    ['loan_no_th'] ??
                                '',
                            text2:
                                _loanStatementData!['master']['balance'] ?? '',
                            text3: _loanStatementData!['master']
                                    ['loan_date_start'] ??
                                '',
                            text4: _loanStatementData!['master']
                                    ['loan_date_end'] ??
                                '',
                            text5: _loanStatementData!['master']
                                    ['loan_approve'] ??
                                '',
                            text6: _loanStatementData!['master']
                                    ['period_total'] ??
                                '',
                            text7: _loanStatementData!['master']
                                    ['period_pay'] ??
                                '',
                          )
                        : const Text('No master data available')),
                const SizedBox(height: 20.0),
                Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      BuildMenuButton(
                        imagePath: 'assets/images/icon-menu/loan_pay.png',
                        title: 'ชำระสินเชื่อ',
                        nextPage: const SharePage(
                          member_no: '',
                          br_no: '',
                        ),
                        memberNo: _memberNo,
                        branchNo: _branchNo,
                      ),
                      BuildMenuButton(
                        imagePath: 'assets/images/icon-menu/qr_code.png',
                        title: 'QR CODE',
                        nextPage: const SharePage(
                          member_no: '',
                          br_no: '',
                        ),
                        memberNo: _memberNo,
                        branchNo: _branchNo,
                      ),
                      BuildMenuButton(
                        imagePath: 'assets/images/icon-menu/cal.png',
                        title: 'คำนวณสินเชื่อ',
                        nextPage: const SharePage(
                          member_no: '',
                          br_no: '',
                        ),
                        memberNo: _memberNo,
                        branchNo: _branchNo,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
                Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'รายการย้อนหลัง',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_list_outlined,
                              color: Color.fromARGB(255, 0, 0, 0),
                              size: 20.0,
                            ),
                            Text(
                              'ตัวกรอง',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    // Check if statement data is available
                    if (_loanStatementData != null &&
                        _loanStatementData!['statement'] is List &&
                        _loanStatementData!['statement'].isNotEmpty) ...[
                      // Convert the statement data to the correct format
                      LoanStatementCard(
                        statementItems: List<Map<String, dynamic>>.from(
                            _loanStatementData!['statement'].map((item) => Map<
                                    String, dynamic>.from(
                                item))), //แปลงข้อมูลที่ได้รับจาก _taawoonData ให้อยู่ในรูปแบบที่สามารถใช้งานได้ใน TaawoonStatementCard
                      ),
                    ] else ...[
                      const Text('ไม่พบข้อมูล'),
                    ],
                    const SizedBox(height: 10.0),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'สิ้นสุดรายการทั้งหมด',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// TaawoonCard STYLE
class loanCard extends StatelessWidget {
  final String text1;
  final String text2;
  final String text3;
  final String text4;
  final String text5;
  final String text6;
  final String text7;
  // final String text4;

  const loanCard({
    Key? key,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.text4,
    required this.text5,
    required this.text6,
    required this.text7,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mediaSize = MediaQuery.of(context).size;
    return Container(
        // height: mediaSize.height * 0.35,
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
          child: IntrinsicHeight(
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'สินเชื่อคงเหลือ',
                                        style: TextStyle(
                                          fontSize: 16,
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
                              const Divider(),
                              const SizedBox(
                                height: 10.0,
                              ),
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        '',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            text2,
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
                                      const Text(
                                        'วันที่เริ่มสัญญา',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            text3,
                                            style: const TextStyle(
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'วันที่หมดสัญญา',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            text4,
                                            style: const TextStyle(
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'วงเงินกู้',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            text5,
                                            style: const TextStyle(
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'จัวนวนงวด',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            text6,
                                            style: const TextStyle(
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'ชำระต่องวด',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            text7,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}

// TaawoonStatementCard STYLE
class LoanStatementCard extends StatelessWidget {
  final List<Map<String, dynamic>> statementItems; // รับรายการ statement

  const LoanStatementCard({
    Key? key,
    required this.statementItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0xFFe8e8e8), blurRadius: 10.0, offset: Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(15.0),
          child: Column(
              children: List.generate(statementItems.length, (index) {
            final item = statementItems[index];
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['detail'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item['date'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      item['total'] ?? '',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 0, 87, 31),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'งวดที่',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      item['period'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'สินเชื่อคงเหลือ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      item['balance'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'เลขที่ใบเสร็จ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      item['receipt_no'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                // ตรวจสอบว่าเป็นข้อมูลสุดท้ายหรือไม่
                if (index < statementItems.length - 1) const Divider(),
              ],
            );
          })),
        ),
      ),
    );
  }
}
