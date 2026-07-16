import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaawoonPage extends StatefulWidget {
  final String member_no;
  final String br_no;
  const TaawoonPage({Key? key, required this.member_no, required this.br_no})
      : super(key: key);

  @override
  State<TaawoonPage> createState() => _TaawoonPageState();
}

class _TaawoonPageState extends State<TaawoonPage> {
  late String _memberNo;
  late String _branchNo;
  String _token = '';
  Map<String, dynamic>? _taawoonData;

  @override
  void initState() {
    super.initState();
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
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

    String url = 'https://online.iscop.co.th/ws/MobileApp/taawoon.php';
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

        // ตรวจสอบว่าข้อมูลใน jsonResponse เป็นไปตามที่คาดหวัง
        if (jsonResponse['success'] == 1) {
          setState(() {
            _taawoonData =
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
              'ตะอาวุน',
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
                      'ตะอาวุน',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                // Check if _taawoonData is available before rendering ShareCard
                _taawoonData == null
                    ? const CircularProgressIndicator()
                    : (_taawoonData!['master'] != null &&
                            _taawoonData!['master'].isNotEmpty
                        ? TaawoonCard(
                            text1: _taawoonData!['master']['taw_id'] ?? '',
                            text2: _taawoonData!['master']['taw_date'] ?? '',
                            text3: _taawoonData!['master']['taw_group'] ?? '',
                            text4: _taawoonData!['master']['taw_amount'] ?? '',
                            text5:
                                _taawoonData!['master']['taw_exc_date'] ?? '',
                          )
                        : const Text('No master data available')),
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
                    if (_taawoonData != null &&
                        _taawoonData!['statement'] is List &&
                        _taawoonData!['statement'].isNotEmpty) ...[
                      // Convert the statement data to the correct format
                      TaawoonStatementCard(
                        statementItems: List<Map<String, dynamic>>.from(
                            _taawoonData!['statement'].map((item) => Map<String,
                                    dynamic>.from(
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
class TaawoonCard extends StatelessWidget {
  final String text1;
  final String text2;
  final String text3;
  final String text4;
  final String text5;
  // final String text4;

  const TaawoonCard({
    Key? key,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.text4,
    required this.text5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mediaSize = MediaQuery.of(context).size;
    return Container(
        height: mediaSize.height * 0.27,
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
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'รหัสสมาชิก',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          text1,
                                          style: const TextStyle(
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
                                          'วันที่เป็นสมาชิก',
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
                                          'สังกัดกลุ่ม',
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
                                          'รวมเงินสะสม',
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
                                          'วันที่กำหนดครบชำระ',
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

// TaawoonStatementCard STYLE
class TaawoonStatementCard extends StatelessWidget {
  final List<Map<String, dynamic>> statementItems; // รับรายการ statement

  const TaawoonStatementCard({
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
                    const Text(
                      'ชำระตะอาวุน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${item['taw_date_today'] ?? ''}',
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
                      'งวดที่/ประจำปี',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      (item['taw_pay_time'] ?? '') +
                          ('/') +
                          (item['taw_year'] ?? ''),
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
                      'จำนวนเงินสะสมรายปี',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      item['taw_pay_year'] ?? '',
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
                      'ค่าบำรุงรายปี',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      item['taw_maintain'] ?? '',
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
                      'เงินสะสม',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      item['taw_amount'] ?? '',
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
                      item['taw_receipt_no'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
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
