import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/screen/depositStatement_page.dart';
import 'package:koperasiapp/screen/load_qrcode_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class QrcodeDataPage extends StatefulWidget {
  final String member_no;
  final String br_no;
  final int type;
  final String memberName;

  const QrcodeDataPage({
    Key? key,
    required this.member_no,
    required this.br_no,
    required this.type,
    required this.memberName,
  }) : super(key: key);

  @override
  _QrcodeDataPageState createState() => _QrcodeDataPageState();
}

class _QrcodeDataPageState extends State<QrcodeDataPage> {
  String? selectedType; // เก็บค่าที่เลือก
  final TextEditingController _amountController = TextEditingController();

  late String _memberNo;
  late String _branchNo;
  String _token = '';

  String memberName = '';
  String otherMemberName = ''; // ตัวแปรใหม่สำหรับบัญชีผู้อื่น
  String number = 'รอข้อมูล...'; // หรือค่าเริ่มต้นอื่น
  List<dynamic> _accounts = [];
  Map<String, dynamic>? _selectedAccount;
  String _toAccountNo = '';

  Future<void> fetchQrcodeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // Get the token from SharedPreferences
    if (token != null && token.isNotEmpty) {
      setState(() {
        _token = token; // เก็บ token ไว้ในตัวแปร
      });
    }
    String url = 'https://online.iscop.co.th/ws/MobileApp/load_qrcode.php';
    String fullUrl =
        '$url?member_no=$_memberNo&br_no=$_branchNo&type=${widget.type}&token=$token';
    print('Request URL: $fullUrl');

    final response = await http.get(
      Uri.parse(fullUrl),
      headers: {
        'Authorization': 'Bearer $token', // Send token in headers
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      print(jsonResponse);
      print('type คือ ${widget.type}');
      // print('บัญชีทั้งหมด คือ $_accounts');
      setState(() {
        memberName = jsonResponse['data']['member_name'];
        number = jsonResponse['data']['number'];
        _accounts = (jsonResponse['data']['accounts'] as List<dynamic>?) ??
            []; // เก็บข้อมูล accounts หากเป็น null ให้เป็นลิสต์ว่าง
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
    fetchQrcodeData();
  }

  void onAccountTypeSelected(String type) {
    setState(() {
      selectedType = type;
    });
    // You can trigger fetching data for other account if needed
    if (type == '2') {
      fetchQrcodeData(); // Fetch data for 'other account'
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.bg,
      appBar: AppBar(
        backgroundColor: Constants.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // ปิดหน้าเมื่อกดปุ่มย้อนกลับ
          },
        ),
        title: const Center(
          child: Text(
            'เลือกรูปแบบบัญชี',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AccountSelectionButton(
                  title: 'บัญชีของฉัน',
                  type: '1',
                  selectedType: selectedType,
                  onTap: () {
                    setState(() {
                      selectedType = '1';
                    });
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('คุณเลือก: บัญชีตัวเอง ${widget.type}')),
                    );
                  },
                ),
                const SizedBox(width: 10),
                AccountSelectionButton(
                  title: 'บัญชีผู้อื่น',
                  type: '2',
                  selectedType: selectedType,
                  onTap: () {
                    setState(() {
                      selectedType = '2';
                    });
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('คุณเลือก: บัญชีผู้อื่น ${widget.type}'),
                        // duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (selectedType == '1') _buildMyAccountDetails(),
            if (selectedType == '2') _buildOtherAccountDetails(),
            if (selectedType != null) // แสดงปุ่มเมื่อมีการเลือกบัญชี
              Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 87, 31),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 50),
                  ),
                  onPressed: () async {
                    final amountText = _amountController.text.trim();
                    if (amountText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณากรอกจำนวนเงิน')),
                      );
                      return;
                    }
                    try {
                      final amount = double.parse(amountText);
                      final int type = widget.type; // ใช้ type จาก widget
                      if (selectedType == '2' && toMem.isEmpty) {
                        // ตรวจสอบกรณีที่เลือก "บัญชีผู้อื่น"
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('กรุณากรอกหมายเลขสมาชิก')),
                        );
                        return;
                      }
                      // ส่งข้อมูล toMem ไปตรวจสอบใน API
                      await validateMemberNumber();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoadQrcodePage(
                            memberNo: widget.member_no, // ส่งค่า memberNo เดิม
                            brNo: widget.br_no, // ส่งค่า brNo เดิม
                            type: type,
                            amount: amount,
                            memberName: widget.memberName,
                            toMem: selectedType == '2' ? toMem : '',
                            ref2:
                                '', // ใช้ _selectedAccountNo เฉพาะเมื่อ type == 2
                            toAccountNo: type == 2
                                ? _toAccountNo
                                : '', // ใช้ _selectedAccountNo เฉพาะเมื่อ type == 2
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('จำนวนเงินต้องเป็นตัวเลขเท่านั้น')),
                      );
                    }
                  },
                  child: const Text(
                    'ถัดไป',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyAccountDetails() {
    if (widget.type == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: const Color.fromARGB(255, 0, 87, 31),
                  width: 2.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          memberName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '',
                          style: TextStyle(
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
                        Text(
                          '${widget.br_no}-01-${widget.member_no}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        Text(
                          number,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'จำนวนเงิน',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 0, 87, 31),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (widget.type == 2) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.stop,
                  color: Color.fromARGB(255, 0, 87, 31),
                  size: 30.0,
                ),
                SizedBox(width: 8),
                Text(
                  'เลือกบัญชี',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // ตรวจสอบว่ามีบัญชีหรือไม่
            _accounts != null && _accounts.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _accounts.length,
                    itemBuilder: (context, index) {
                      final account = _accounts[index];
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromARGB(255, 0, 87, 31),
                          ),
                          borderRadius: BorderRadius.circular(35),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        margin: const EdgeInsets.symmetric(
                            vertical: 5), // เพิ่ม margin ระหว่างบัญชี
                        child: ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account['ACCOUNT_NAME'] ?? 'ไม่ระบุชื่อ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              // เพิ่มข้อความบรรทัดที่ 1 โดยแบ่งเป็น 2 ฝั่ง
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${account['ACCOUNT_NO'] ?? '-'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      account['ACC_DESC'],
                                      textAlign: TextAlign
                                          .end, // จัดตำแหน่งข้อความทางขวา
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'ยอดเงินคงเหลือ(บาท)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  account['AVAILABLE'],
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedAccount =
                                  account; // กำหนดบัญชีที่เลือกให้กับ _selectedAccount
                              _toAccountNo = account[
                                  'ACCOUNT_NO']; // เก็บค่า ACCOUNT_NO ไว้ใน _selectedAccountNo
                            });
                            sendAccountDataToAPI(); // เรียกใช้ฟังก์ชันส่งข้อมูลไปยัง API
                          },
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      'ไม่มีข้อมูลบัญชี',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
            const SizedBox(height: 30),

            // ตรวจสอบว่าเลือกบัญชีแล้วหรือยัง
            _selectedAccount != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'จำนวนเงิน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 0, 87, 31),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : SizedBox.shrink(), // ไม่แสดงอะไรเลยถ้ายังไม่ได้เลือกบัญชี
          ],
        ),
      );
    } else if (widget.type == 3) {
      // แสดงข้อมูลสำหรับประเภทที่ 2
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // รูปแบบ UI สำหรับประเภทที่ 2
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.blue,
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: const [
                    Text(
                      'ข้อมูลประเภทที่ 3',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    // ข้อมูลเพิ่มเติม
                  ],
                ),
              ),
            ),
            // ข้อมูลเพิ่มเติมอื่นๆ สำหรับประเภทที่ 2
          ],
        ),
      );
    } else if (widget.type == 4) {
      // แสดงข้อมูลสำหรับประเภทที่ 2
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // รูปแบบ UI สำหรับประเภทที่ 2
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.blue,
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: const [
                    Text(
                      'ข้อมูลประเภทที่ 4',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    // ข้อมูลเพิ่มเติม
                  ],
                ),
              ),
            ),
            // ข้อมูลเพิ่มเติมอื่นๆ สำหรับประเภทที่ 2
          ],
        ),
      );
    } else if (widget.type == 5) {
      // แสดงข้อมูลสำหรับประเภทที่ 2
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // รูปแบบ UI สำหรับประเภทที่ 2
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.blue,
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: const [
                    Text(
                      'ข้อมูลประเภทที่ 5',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    // ข้อมูลเพิ่มเติม
                  ],
                ),
              ),
            ),
            // ข้อมูลเพิ่มเติมอื่นๆ สำหรับประเภทที่ 2
          ],
        ),
      );
    } else {
      return Container(); // หรือแสดงข้อมูลที่เหมาะสม
    }
  }

  String toMem = ''; // เพิ่มตัวแปรเก็บค่า to_mem
  String sele = ''; // เพิ่มตัวแปรเก็บค่า to_mem
  final TextEditingController _toMemController =
      TextEditingController(); // Controller สำหรับ TextField
  Widget _buildOtherAccountDetails() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                'เลขที่สมาชิก',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _toMemController, // ใช้ Controller ที่สร้างไว้
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color.fromARGB(255, 14, 53, 15))),
                    label: const Text('หมายเลขสมาชิก 10 หลัก'),
                    hintStyle: const TextStyle(
                      color: Color.fromARGB(255, 0, 87, 31),
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 0, 87, 31),
                      ),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 0, 87, 31),
                      ),
                      borderRadius: BorderRadius.circular(35),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'โปรดกรอกเลขทะเบียนสมาชิก 10 หลัก';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      toMem = value.replaceAll("-", ""); // ลบเครื่องหมาย "-"
                    });
                    if (value.length >= 5) {
                      // ตรวจสอบเมื่อป้อนครบ 10 หลัก
                      validateMemberNumber();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: const [
              Icon(
                Icons.stop,
                color: Color.fromARGB(255, 0, 87, 31),
                size: 30.0,
              ),
              Text(
                'ชื่อบัญชี',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(255, 0, 87, 31),
                      // width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Text(
                    otherMemberName, // แสดงชื่อสมาชิกที่ตรวจสอบได้
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Color.fromARGB(255, 0, 87, 31), // สีของข้อความ
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'จำนวนเงิน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            decoration: const InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color.fromARGB(255, 0, 87, 31),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> sendAccountDataToAPI() async {
// ตัวอย่างบัญชี
    // ตรวจสอบว่ามีบัญชีที่เลือกหรือไม่
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกบัญชี')),
      );
      return;
    }
    print('บัญชีที่เลือก :$_selectedAccount');
    print('toAccountNo :$_toAccountNo');
  }

  Future<void> validateMemberNumber() async {
    if (selectedType != '2' || toMem.isEmpty) {
      return; // ตรวจสอบเฉพาะบัญชีผู้อื่น
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // Get the token from SharedPreferences

    if (token != null && token.isNotEmpty) {
      setState(() {
        _token = token; // เก็บ token ไว้ในตัวแปร
      });
    }

    // ตรวจสอบว่าค่า toMem มีความยาว 10 หลักหรือไม่
    if (toMem.length == 10) {
      String othermemberNo = toMem.substring(5); // 5 หลักสุดท้าย
      String otherbranchNo = toMem.substring(0, 3); // หลักที่ 1-3

      // ใช้ member_no และ br_no ที่แบ่งได้ใน API request
      String url = 'https://online.iscop.co.th/ws/MobileApp/load_qrcode.php';
      String fullUrl =
          '$url?member_no=$othermemberNo&br_no=$otherbranchNo&type=${widget.type}&token=$_token'; // ส่ง toMem ไปตรวจสอบ
      print('Validating Member URL: $fullUrl');

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $_token', // ส่ง token ใน headers
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('test : $jsonResponse');
        if (jsonResponse['data'] != null) {
          // ถ้า API ส่งข้อมูลสมาชิกกลับมา
          setState(() {
            otherMemberName =
                jsonResponse['data']['member_name']; // รับชื่อสมาชิกจาก API
          });
        } else {
          // ถ้าไม่พบข้อมูลสมาชิก
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบหมายเลขสมาชิกในระบบ')),
          );
        }
      } else {
        // ถ้าเกิดข้อผิดพลาดในการเรียก API
        throw Exception('เกิดข้อผิดพลาดในการตรวจสอบสมาชิก');
      }
    }
  }
}

class AccountSelectionButton extends StatelessWidget {
  final String title;
  final String type;
  final String? selectedType;
  final VoidCallback onTap;

  const AccountSelectionButton({
    required this.title,
    required this.type,
    required this.selectedType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: selectedType == type
                ? const Color.fromARGB(255, 198, 167, 66)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: selectedType == type
                  ? const Color.fromARGB(255, 198, 167, 66)
                  : Colors.grey,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
