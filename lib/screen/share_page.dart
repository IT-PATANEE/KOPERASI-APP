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
            // print(
            //     'Share Data: $_shareData');
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
     final theme = Theme.of(context); // <-- ใช้ ThemeData
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
                      'หุ้นสมาชิก',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                // Check if _shareData is available before rendering ShareCard
                _shareData == null
                    ? const CircularProgressIndicator()
                    : (_shareData!['master'] != null &&
                            _shareData!['master'].isNotEmpty
                        ? ShareCard(
                            text1: _shareData!['master']['share_accu'] ?? '',
                            text2: _shareData!['master']['share_sum_qty'] ?? '',
                            text3: _shareData!['master']['share_amount'] ?? '',
                          )
                        : const Text('No master data available')),
                const SizedBox(height: 20.0),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        BuildMenuButton(
                          imagePath: 'assets/images/icon-menu/share_pay.png',
                          title: 'ชำระค่าหุ้น',
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
                        BuildMenuButton(
                          imagePath: 'assets/images/icon-menu/recipt.png',
                          title: 'ใบเสร็จ',
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
                    if (_shareData != null &&
                        _shareData!['statement'] is List &&
                        _shareData!['statement'].isNotEmpty) ...[
                      // Convert the statement data to the correct format
                      ShareStatementCard(
                        statementItems: List<Map<String, dynamic>>.from(
                            _shareData!['statement'].map((item) => Map<String,
                                    dynamic>.from(
                                item))), //แปลงข้อมูลที่ได้รับจาก _shareData ให้อยู่ในรูปแบบที่สามารถใช้งานได้ใน ShareStatementCard
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

class BuildMenuButton extends StatelessWidget {
  final String imagePath;
  final String title;
  final Widget nextPage;
  final String memberNo;
  final String branchNo;

  const BuildMenuButton({
    Key? key,
    required this.imagePath,
    required this.title,
    required this.nextPage,
    required this.memberNo,
    required this.branchNo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mediaSize = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => nextPage,
            settings: RouteSettings(
              arguments: {'member_no': memberNo, 'br_no': branchNo},
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
          const SizedBox(height: 2),
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
                        Padding(
                          padding: const EdgeInsets.all(15.0),
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
                                    mainAxisAlignment: MainAxisAlignment.start,
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
  final List<Map<String, dynamic>> statementItems; // รับรายการ statement

  const ShareStatementCard({
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
                      'ฝากหุ้น',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${item['share_date'] ?? ''}',
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
                    const Text('', style: TextStyle(fontSize: 16)),
                    Text(
                      item['share_amount'] ?? '',
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
                      'จำนวนงวด',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      item['share_period']?.toString() ?? '',
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
                      'หุ้นสะสม',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      item['share_accu'] ?? '',
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
