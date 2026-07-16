import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/screen/depositStatement_page.dart';
import 'package:koperasiapp/screen/share_page%20copy.dart';
import 'package:page_transition/page_transition.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DepositStatementPage extends StatefulWidget {
  final String memberNo;
  final String branchNo;
  final String accountNo;
  final String token;

  const DepositStatementPage({
    Key? key,
    required this.accountNo,
    required this.memberNo,
    required this.branchNo,
    required this.token,
  }) : super(key: key);

  @override
  State<DepositStatementPage> createState() => _DepositStatementPageState();
}

class _DepositStatementPageState extends State<DepositStatementPage> {
  late String _memberNo;
  late String _branchNo;
  late String _accountNo;
  String _token = '';
  Map<String, dynamic>? _depositStatementData;
  String serverResponse = 'กำลังรอข้อมูลจากเซิร์ฟเวอร์...';

  @override
  void initState() {
    _memberNo = widget.memberNo;
    _branchNo = widget.branchNo;
    _accountNo = widget.accountNo;
    super.initState();
    fetchStatementData(); // เรียกข้อมูลเมื่อหน้าเริ่มต้น
  }

  Future<void> fetchStatementData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // Get the token from SharedPreferences

    if (token != null && token.isNotEmpty) {
      setState(() {
        _token = token; // Store token in a variable
      });
    }

    String url =
        'https://online.iscop.co.th/ws/MobileApp/deposit_statement.php';
    String fullUrl =
        '$url?member_no=$_memberNo&br_no=$_branchNo&token=$token&account_no=$_accountNo';

    try {
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token', // Send token in headers
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == 1) {
          setState(() {
            _depositStatementData =
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
    return Scaffold(
      backgroundColor: Constants.bg,
      appBar: AppBar(
        backgroundColor: Constants.primaryColor,
        title: const Center(
          child: Text(
            'บัญชีออมทรัพย์',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
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
                    'บัญชีเงินฝาก',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              // Check if _taawoonData is available before rendering ShareCard
              _depositStatementData == null
                  ? const CircularProgressIndicator()
                  : (_depositStatementData!['master'] != null &&
                          _depositStatementData!['master'].isNotEmpty
                      ? DepositCard(
                          text1: _depositStatementData!['master']
                                  ['account_name'] ??
                              '',
                          text2: _depositStatementData!['master']
                                  ['available'] ??
                              '',
                          text3: _depositStatementData!['master']
                                  ['account_no'] ??
                              '',
                          text4: _depositStatementData!['master']
                                  ['account_desc'] ??
                              '',
                          text5:
                              _depositStatementData!['master']['balance'] ?? '',
                          // text6: _depositStatementData!['master']
                          //         ['available'] ??
                          //     '',
                          // text7: _depositStatementData!['master']
                          //         ['available'] ??
                          //     '',
                        )
                      : const Text('No master data available')),
              const SizedBox(height: 20.0),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      BuildMenuButton(
                        imagePath: 'assets/images/icon-menu/pay.png',
                        title: 'โอนเงินฝาก',
                        nextPage: const SharePage(
                          member_no: '',
                          br_no: '',
                        ),
                        memberNo: _memberNo,
                        branchNo: _branchNo,
                      ),
                      BuildMenuButton(
                        imagePath: 'assets/images/icon-menu/trans_bank.png',
                        title: 'โอนไปยังธนาคาร',
                        nextPage: const SharePage(
                          member_no: '',
                          br_no: '',
                        ),
                        memberNo: _memberNo,
                        branchNo: _branchNo,
                      ),
                      BuildMenuButton(
                        imagePath: 'assets/images/icon-menu/ot.png',
                        title: 'เมนูอื่น ๆ',
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
                  if (_depositStatementData != null &&
                      _depositStatementData!['statement'] is List &&
                      _depositStatementData!['statement'].isNotEmpty) ...[
                    // Convert the statement data to the correct format
                    DepositStatementCard(
                      statementItems: List<Map<String, dynamic>>.from(
                          _depositStatementData!['statement'].map((item) => Map<
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

// ACC CARD STYLE
class DepositCard extends StatelessWidget {
  final String text1;
  final String text2;
  final String text3;
  final String text4;
  final String text5;
  // final String text6;
  // final String text7;
  // final String text4;

  const DepositCard({
    Key? key,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.text4,
    required this.text5,
    // required this.text6,
    // required this.text7,
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
                                        'ยอดเงินคงเหลือ',
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
                                        'เลขที่บัญชี',
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
                                        'ประเภทบัญชี',
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
                                        'ยอดเงินที่ถอนได้',
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

// DepositStatementCard STYLE
class DepositStatementCard extends StatelessWidget {
  final List<Map<String, dynamic>> statementItems; // รับรายการ statement

  const DepositStatementCard({
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
            final isDeposit = item['deposit'] != "0.00 บาท";
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
                    // Text(
                    //   item['withdraw'] ?? '',
                    //   style: const TextStyle(
                    //     color: Color.fromARGB(255, 0, 87, 31),
                    //     fontSize: 20,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                    Text(
                      isDeposit
                          ? item['deposit'] ?? ''
                          : item['withdraw'] ??
                              '', // แสดงจำนวนเงินฝากหรือถอนตามเงื่อนไข
                      style: TextStyle(
                        color: isDeposit
                            ? Constants.primaryColor
                            : Constants.redColor, // สีต่างกันสำหรับการฝากและถอน
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
                    Text(
                      isDeposit ? 'บัญชีต้นทาง' : 'บัญชีปลายทาง',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      item['detail1'] ?? '',
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
                      'หมายเหตุ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      item['detail2'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                // const SizedBox(height: 10.0),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     const Text(
                //       'เลขที่ใบเสร็จ',
                //       style: TextStyle(
                //         fontSize: 16,
                //         fontWeight: FontWeight.normal,
                //       ),
                //     ),
                //     Text(
                //       item['receipt_no'] ?? '',
                //       style: const TextStyle(
                //         fontSize: 16,
                //         fontWeight: FontWeight.normal,
                //       ),
                //     ),
                //   ],
                // ),
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
