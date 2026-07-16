import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SharePage extends StatefulWidget {
  final String member_no;
  final String br_no;
  const SharePage({Key? key, required this.member_no, required this.br_no})
      : super(key: key);

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  late String _memberNo;
  late String _branchNo;
  String _token = '';
  Map<String, dynamic>? _shareData;

  Future<void> fetchShareData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // Get the token from SharedPreferences

    if (token != null && token.isNotEmpty) {
      setState(() {
        _token = token; // Store token in a variable
      });
    }

    String url = 'https://online.iscop.co.th/ws/MobileApp/share.php';
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
          // หรือค่าที่เหมาะสมที่แสดงความสำเร็จ
          setState(() {
            _shareData = jsonResponse['data']; // เก็บทั้ง master และ statement
            print(
                'Share Data: $_shareData'); // พิมพ์ค่าที่ได้รับจาก API เพื่อการดีบัก
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
  void initState() {
    super.initState();
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
    fetchShareData();
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
              'ทุนเรือนหุ้น',
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
                        'หุ้นสมาชิก',
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
                  // Check if _shareData is available before rendering Card
                  _shareData == null
                      ? const CircularProgressIndicator()
                      : (_shareData!['master'] != null &&
                              _shareData!['master'].isNotEmpty
                          ? ShareCard(
                              text1: _shareData!['master']['share_accu'] ?? '',
                              text2:
                                  _shareData!['master']['share_sum_qty'] ?? '',
                              text3:
                                  _shareData!['master']['share_amount'] ?? '',
                            )
                          : const Text('No master data available')),
                  const SizedBox(
                    height: 20.0,
                  ),
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
                      const SizedBox(
                        height: 20.0,
                      ),
                      if (_shareData != null &&
                          _shareData!['statement'] is List &&
                          _shareData!['statement'].isNotEmpty)
                        Column(
                          children: List.generate(
                            _shareData!['statement'].length,
                            (index) {
                              final item = _shareData!['statement'][index];
                              return Column(
                                children: [
                                  ShareStatementCard(
                                    text1: item['share_date'] ?? '',
                                    text2: item['share_amount'] ?? '',
                                    text3: item['share_accu'] ?? '',
                                    text4: item['share_desc'] ?? '',
                                    text5: item['receipt_no'] ?? '',
                                  ),
                                  // Divider between statement items
                                  if (index <
                                      _shareData!['statement'].length - 1)
                                    const Divider(),
                                ],
                              );
                            },
                          ),
                        )
                      else
                        const Text('No statement data available'),
                    ],
                  ),
                ],
              )),
        ),
      ),
    );
  }
}

// ShareCard STYLE
class ShareCard extends StatelessWidget {
  final String text1;
  final String text2;
  final String text3;
  // final String text4;

  const ShareCard({
    Key? key,
    required this.text1,
    required this.text2,
    required this.text3,
  }) : super(key: key);

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
                                    const Text(
                                      'หุ้นสะสม',
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
                                          'จำนวนหุ้นคงเหลือ',
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
                                          'หุ้นรายเดือน',
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

// ShareStatementCard STYLE
class ShareStatementCard extends StatelessWidget {
  final String text1;
  final String text2;
  final String text3;
  final String text4;
  final String text5;

  const ShareStatementCard({
    Key? key,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.text4,
    required this.text5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          vertical: 8.0), // เพิ่มระยะห่างระหว่างการ์ด
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
        child: Expanded(
          // ใช้ Expanded เพื่อให้ Container ขยายเต็มพื้นที่ที่เหลือ
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ฝากหุ้น',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      text1,
                      style: const TextStyle(
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
                      '',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      text2,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'จำนวนงวด',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      text3,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'หุ้นสะสม',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      text4,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'เลขที่ใบเสร็จ',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      text5,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                const Divider(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
