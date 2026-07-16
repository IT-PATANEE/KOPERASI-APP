import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/screen/aroohnuStatement_page.dart';
import 'package:koperasiapp/screen/depositStatement_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArrohnuPage extends StatefulWidget {
  final String member_no;
  final String br_no;
  const ArrohnuPage({Key? key, required this.member_no, required this.br_no})
      : super(key: key);

  @override
  State<ArrohnuPage> createState() => _ArrohnuPageState();
}

class _ArrohnuPageState extends State<ArrohnuPage> {
  // Future<Map<String, dynamic>>? LoanData;

  List<Map<String, dynamic>> _arrohnus = [];
  bool _isLoading = true; // สถานะการโหลดข้อมูล

  late String _memberNo;
  late String _branchNo;
  String _token = '';

  @override
  void initState() {
    super.initState();
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
    fetchLoanData();
  }

  Future<void> fetchLoanData() async {
    setState(() {
      _isLoading = true; // แสดงสถานะการโหลดข้อมูล
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // Get the token from SharedPreferences

    if (token != null && token.isNotEmpty) {
      _token = token;
    }

    String url = 'https://online.iscop.co.th/ws/MobileApp/arrohnu.php';
    String fullUrl = '$url?member_no=$_memberNo&br_no=$_branchNo&token=$token';

    try {
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token', // Send token in headers
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // ตรวจสอบว่าการตอบสนองสำเร็จ
        if (jsonResponse['success'] == 1 && jsonResponse['data'] != null) {
          setState(() {
            // _arrohnus = jsonResponse['data']; // เก็บข้อมูล accounts
            // print(_arrohnus);
            _arrohnus = List<Map<String, dynamic>>.from(jsonResponse['data']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _arrohnus = []; // ตั้งค่าให้เป็นลิสต์ว่างกรณีไม่มีข้อมูล
            _isLoading = false;
          });
          print('Error: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      print("Error fetching data: $error");
      setState(() {
        _arrohnus = []; // ตั้งค่าให้เป็นลิสต์ว่างในกรณีเกิดข้อผิดพลาด
        _isLoading = false;
      });
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _arrohnus.isEmpty
                ? const Center(
                    child: Text(
                      'ไม่พบข้อมูลสินเชื่ออัร-เราะห์นู',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  )
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
                              'สินเชื่อของฉัน',
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
                            itemCount: _arrohnus.length,
                            itemBuilder: (context, index) {
                              final arrohnu =
                                  _arrohnus[index]; // ข้อมูลบัญชีแต่ละรายการ

                              return Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      // เมื่อกด LoanCard จะเปลี่ยนหน้าไปยัง LoanDetailPage พร้อมส่งข้อมูล
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ArrohnuStatementPage(
                                            loanNo: arrohnu['loan_no'],
                                            loanId: arrohnu['loan_no_th'],
                                            member_no: _memberNo,
                                            br_no: _branchNo,
                                          ),
                                        ),
                                      );
                                    },
                                    child: LoanCard(
                                      text1: arrohnu['loan_no_th'],
                                      text2: arrohnu['balance'],
                                      text3: arrohnu['period_total'],
                                      text4: arrohnu['period_pay'],
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
      ),
    );
  }
}

// ShareCard STYLE
// ACC CARD STYLE
class LoanCard extends StatelessWidget {
  final String text1;
  final String text2;
  final String text3;
  final String text4;

  const LoanCard({
    Key? key,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.text4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mediaSize = MediaQuery.of(context).size;
    return Container(
        // height: mediaSize.height * 0.22,
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'สินเชื่อคงเหลือ',
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
                                      const Text(
                                        '',
                                        // style: const TextStyle(
                                        //   fontSize: 16,
                                        //   fontWeight: FontWeight.bold,
                                        // ),
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
                                        'จำนวนงวด',
                                        style: const TextStyle(
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
                                        'ชำระต่องวด',
                                        style: const TextStyle(
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
