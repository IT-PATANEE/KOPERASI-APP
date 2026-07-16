import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/screen/depositStatement_page.dart';
import 'package:koperasiapp/screen/load_qrcode_page.dart';
import 'package:koperasiapp/screen/select_toacc_page.dart';
import 'package:koperasiapp/screen/select_toqr_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
  final formatter = NumberFormat('#,##0.00');

  late String _memberNo;
  late String _branchNo;
  String _token = '';

  bool _isLoading = true;

  String memberName = '';
  String otherMemberName = ''; // ตัวแปรใหม่สำหรับบัญชีผู้อื่น
  String otherAccno = ''; // ตัวแปรใหม่สำหรับบัญชีผู้อื่น
  String number = 'รอข้อมูล...'; // หรือค่าเริ่มต้นอื่น
  List<dynamic> _accounts = [];
  List<dynamic> _loans = [];
  List<dynamic> _arrahnu = [];
  Map<String, dynamic>? _selectedAccount;
  String _toAccountNo = '';
  String toMemId = '';
  bool _isAccountValid = false; // สถานะว่าบัญชีถูกต้องหรือยัง

  // ฟังก์ชันในการสร้าง _toAccountNo
  // String _generateToAccountNo(String brNo, String acc, String loanCode) {
  //   String data2 = brNo + acc;
  //   String code = loanCode.padLeft(7, '0'); // เติม 0 ให้ CODE มีความยาว 7 หลัก
  //   String ref2 = data2.substring(1) + code;
  //   return ref2;
  // }

  Future<void> fetchQrcodeData() async {
    try {
      // ✅ เปิดสถานะ Loading (และสามารถเคลียร์ค่าบัญชีเก่าตรงนี้ได้ถ้าต้องการ)
      setState(() {
        _isLoading = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token != null && token.isNotEmpty) {
        if (mounted) {
          setState(() {
            _token = token; // เก็บ token ไว้ในตัวแปร
          });
        }
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

        if (jsonResponse['data'] != null) {
          final data = jsonResponse['data'];

          if (mounted) {
            setState(() {
              memberName = data['member_name'];
              number = data['number'];
              _accounts = (data['accounts'] as List<dynamic>?) ?? [];
              _loans = (data['loans'] as List<dynamic>?) ?? [];
              _arrahnu = (data['arrahnu'] as List<dynamic>?) ?? [];
            });
          }
        }
      } else {
        throw Exception('Failed to load data (Status: ${response.statusCode})');
      }
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleNext() async {
    final amountText = _amountController.text.trim();

    if (amountText.isEmpty) {
      _showSnack('กรุณากรอกจำนวนเงิน');
      return;
    }

    double amount;

    try {
      amount = double.parse(amountText);
    } catch (e) {
      _showSnack('จำนวนเงินต้องเป็นตัวเลขเท่านั้น');
      return;
    }

    if (selectedType == '2' && toMem.isEmpty) {
      _showSnack('กรุณากรอกหมายเลขสมาชิก');
      return;
    }

    await validateMemberNumber();

    final int type = widget.type;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadQrcodePage(
          memberNo: widget.member_no,
          brNo: widget.br_no,
          type: type,
          amount: amount,
          memberName: memberName,
          toMem: selectedType == '2' ? toMem : '',
          toMemName: selectedType == '2' ? otherMemberName : '',
          ref2: '',
          toAccountNo: (type == 1 || type == 2 || type == 3 || type == 4)
              ? _toAccountNo
              : '',
          selectedType: selectedType == '1' ? 1 : 2,
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
    selectedType = '1'; //ค่าเริ่มต้นเป็นบัญชีของฉัน
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
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final w = media.size.width;
    final h = media.size.height;

    return Scaffold(
      backgroundColor: Constants.bg,
      resizeToAvoidBottomInset: false, // ✅ ป้องกันคีย์บอร์ดดัน layout
      appBar: AppBar(
        backgroundColor: Constants.greenColors,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true, // ให้ title อยู่กลางจริง ๆ
        title: Text(
          'เลือกรูปแบบบัญชี',
          style: theme.textTheme.titleLarge!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: _buildNextButton(),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // ===== ส่วนหัว (พื้นหลังสีเทาเฉพาะตรงนี้) =====
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Constants.greyLight,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AccountSelectionButton(
                      title: 'บัญชีของฉัน',
                      type: '1',
                      selectedType: selectedType,
                      onTap: () {
                        setState(() => selectedType = '1');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AccountSelectionButton(
                      title: 'บัญชีผู้อื่น',
                      type: '2',
                      selectedType: selectedType,
                      onTap: () {
                        setState(() => selectedType = '2');
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ===== ส่วนรายละเอียด (พื้นขาวปกติ) =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (selectedType == '1') _buildMyAccountDetails(),
                  if (selectedType == '2') _buildOtherAccountDetails(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildNextButton() {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final w = media.size.width;
    final h = media.size.height;
    if (selectedType == null) return null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: h * 0.015,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Constants.greenColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(35),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: _handleNext,
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
    );
  }

  Widget _buildMyAccountDetails() {
    if (widget.type == 1) {
      return _buildType1MyAcc();
    } else if (widget.type == 2) {
      return _buildType2MyAcc();
    } else if (widget.type == 3) {
      return _buildType3MyAcc();
    } else if (widget.type == 4) {
      return _buildType4MyAcc();
    } else if (widget.type == 5) {
      return _buildType1MyAcc();
    } else {
      return Container(); // หรือแสดงข้อมูลที่เหมาะสม
    }
  }

  Widget _buildType1MyAcc() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🟢 การ์ดแสดงข้อมูลบัญชีสมาชิกของตนเอง (ปรับโครงสร้างแอนิเมชัน เงา และขอบตามตัวบน)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Constants.greenColors.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Constants.greenColors.withValues(alpha: 0.02),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding:
                    const EdgeInsets.all(18), // ระยะ Padding สบายตาเท่ากันเป๊ะ
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Constants
                        .greenColors, // เส้นขอบหนา 2 สีหลักเมื่อถูกเลือก
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // แถวที่ 1: ชื่อสมาชิก และ Tag Badge บอกประเภท (ขวา)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            memberName.isNotEmpty
                                ? memberName
                                : 'กำลังโหลดข้อมูล...',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight
                                  .w600, // ปรับความหนาตัวอักษรเป็นจุดนำสายตา
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                Constants.greenColors.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "ทุนเรือนหุ้น",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Constants.greenColors,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14.0),

                    // เส้นคั่นบาง ๆ สไตล์มินิมอลแบ่งสัดส่วนโครงสร้างภายใน
                    Divider(
                        color: Colors.grey.withValues(alpha: 0.1), height: 1),
                    const SizedBox(height: 12.0),

                    // แถวที่ 2: เลขทะเบียนสมาชิก
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "เลขทะเบียนสมาชิก",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          "${widget.br_no}-01-${widget.member_no}",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 🟢 ช่องสำหรับกรอกจำนวนเงิน (เรียกใช้ฟังก์ชันเดิมของคุณ)
          _buildAmountInputField(),
        ],
      ),
    );
  }

  Widget _buildType2MyAcc() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อ "เลือกบัญชี"
          Row(
            children: [
              Icon(
                Icons.stop,
                color: Constants.greenColors,
                size: 30.0,
              ),
              const SizedBox(width: 8),
              const Text(
                'เลือกบัญชี',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // รายการบัญชี
          _accounts != null && _accounts.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _accounts.length,
                  itemBuilder: (context, index) {
                    final account = _accounts[index];

                    final String accountName =
                        (account['ACCOUNT_NAME'] ?? 'ไม่ระบุชื่อ').toString();
                    final String accountNo =
                        (account['ACCOUNT_NO'] ?? '-').toString();
                    final String balanceStr =
                        (account['AVAILABLE'] ?? '0').toString();
                    final String accountDesc =
                        (account['ACC_DESC'] ?? 'บัญชีเงินฝาก').toString();

                    // เช็กว่าบัญชีนี้ถูกเลือกหรือไม่
                    final bool isSelected =
                        _toAccountNo == account['ACCOUNT_NO'];

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white, // พื้นหลังสีขาวล้วนคงเดิม
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Constants.greenColors
                                      .withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Constants.greenColors
                                      .withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            setState(() {
                              _selectedAccount = account;
                              _toAccountNo = account['ACCOUNT_NO'];
                            });
                            sendAccountDataToAPI();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              // 🟢 เฉพาะเส้นขอบที่เปลี่ยน: เลือก=เขียวหนา 2.5 / ไม่เลือก=เทาบาง 1.0
                              border: Border.all(
                                color: isSelected
                                    ? Constants.greenColors
                                    : Colors.grey.withValues(alpha: 0.2),
                                width: isSelected ? 2.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        accountName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight
                                              .w500, // 🟢 ใช้ความหนาและสีเดียวกันทั้งสองสถานะ
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // แสดงประเภทบัญชี (Tag)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Constants.greenColors
                                            .withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        accountDesc,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Constants.greenColors),
                                      ),
                                    ),

                                    // 🟢 แสดงไอคอนติ๊กถูกสีเขียวเฉพาะตอนที่ถูกเลือกเท่านั้น
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: Constants.greenColors,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 14.0),
                                Divider(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    height: 1),
                                const SizedBox(height: 12.0),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      accountNo,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey
                                            .shade600, // 🟢 สีเลขบัญชีคงที่
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          formatter.format(double.tryParse(
                                                  balanceStr.replaceAll(
                                                      ',', '')) ??
                                              0),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors
                                                .black87, // 🟢 สียอดเงินคงที่
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "บาท",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey
                                                .shade600, // 🟢 สีคำว่าบาทคงที่
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
                  },
                )
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'ไม่มีข้อมูลบัญชี',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ),
          const SizedBox(height: 30),

          // ตรวจสอบเพื่อเปิดช่องกรอกเงิน
          _selectedAccount != null
              ? _buildAmountInputField()
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildType3MyAcc() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อ "เลือกบัญชี"
          Row(
            children: [
              Icon(
                Icons.stop,
                color: Constants.greenColors,
                size: 30.0,
              ),
              const SizedBox(width: 8),
              const Text(
                'เลือกบัญชี',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // รายการบัญชีเงินกู้
          _loans != null && _loans.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _loans.length,
                  itemBuilder: (context, index) {
                    final loans = _loans[index];

                    final String loanId =
                        (loans['LCONT_ID'] ?? 'ไม่ระบุชื่อ').toString();
                    final String regSalInt =
                        (loans['LREG_SALINT'] ?? '0').toString();
                    final String amountSal =
                        (loans['LCONT_AMOUNT_SAL'] ?? '0').toString();

                    final Map<String, String> lcontStatusFlags = {
                      "1": "ชำระได้ตามปกติ",
                      "4": "หมดสัญญา",
                    };
                    final String statusFlag =
                        (loans['LCONT_STATUS_FLAG'] ?? '').toString();
                    final String loanDesc =
                        lcontStatusFlags[statusFlag] ?? 'สัญญาเงินกู้';

                    final String currentLoanToAccountNo = generateToAccountNo(
                      brNo: widget.br_no,
                      lcontId: loans['LCONT_ID'] ?? '',
                      code: loans['CODE'],
                    );
                    final bool isSelected =
                        _toAccountNo == currentLoanToAccountNo;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                            15), // เปลี่ยนเป็นความโค้ง 15 เท่ากับ Type 2
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Constants.greenColors
                                      .withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Constants.greenColors
                                      .withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            setState(() {
                              _selectedAccount = loans;
                              _toAccountNo = currentLoanToAccountNo;
                            });
                            sendAccountDataToAPI();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected
                                    ? Constants.greenColors
                                    : Colors.grey.withValues(alpha: 0.2),
                                width: isSelected ? 2.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // บรรทัดบน: เลขที่สัญญา และ Tag/ไอคอนติ๊กถูก
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        loanId,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // แสดงประเภทบัญชี/สถานะ (ปรับ Tag ให้เข้าชุดกัน)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Constants.greenColors
                                            .withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        loanDesc,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Constants.greenColors),
                                      ),
                                    ),

                                    // แสดงไอคอนติ๊กถูกสีเขียวเฉพาะตอนที่ถูกเลือก
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: Constants.greenColors,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 14.0),
                                Divider(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    height: 1),
                                const SizedBox(height: 12.0),

                                // ส่วนแสดงรายละเอียด ยอดชำระต่อเดือน
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'ยอดชำระต่อเดือน',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      '$regSalInt บาท',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6.0),

                                // ส่วนแสดงรายละเอียด ยอดชำระคงเหลือ (เน้นตัวหนา/ใหญ่ด้านล่างตามสไตล์ Type 2)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      'ยอดชำระคงเหลือ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          amountSal,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "บาท",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
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
                  },
                )
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'ไม่มีข้อมูลบัญชี',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ),
          const SizedBox(height: 30),

          // ตรวจสอบเพื่อเปิดช่องกรอกเงิน
          _selectedAccount != null
              ? _buildAmountInputField()
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildType4MyAcc() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อ "เลือกบัญชี"
          Row(
            children: [
              Icon(
                Icons.stop,
                color: Constants.greenColors,
                size: 30.0,
              ),
              const SizedBox(width: 8),
              const Text(
                'เลือกบัญชี',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // รายการบัญชี
          _arrahnu != null && _arrahnu.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _arrahnu.length,
                  itemBuilder: (context, index) {
                    final arrahnu = _arrahnu[index];

                    final String loanId =
                        (arrahnu['LCONT_ID'] ?? 'ไม่ระบุชื่อ').toString();
                    final String regSalInt =
                        (arrahnu['LREG_SALINT'] ?? '0').toString();
                    final String amountSal =
                        (arrahnu['LCONT_AMOUNT_SAL'] ?? '0').toString();

                    final Map<String, String> lcontStatusFlags = {
                      "1": "ชำระได้ตามปกติ",
                      "4": "หมดสัญญา",
                    };
                    final String statusFlag =
                        (arrahnu['LCONT_STATUS_FLAG'] ?? '').toString();
                    final String loanDesc =
                        lcontStatusFlags[statusFlag] ?? 'สัญญาเงินกู้';

                    final String currentLoanToAccountNo = generateToAccountNo(
                      brNo: widget.br_no,
                      lcontId: arrahnu['LCONT_ID'] ?? '',
                      code: arrahnu['CODE'],
                    );
                    final bool isSelected =
                        _toAccountNo == currentLoanToAccountNo;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Constants.greenColors
                                      .withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Constants.greenColors
                                      .withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            setState(() {
                              _selectedAccount = arrahnu;
                              _toAccountNo = currentLoanToAccountNo;
                            });
                            sendAccountDataToAPI();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected
                                    ? Constants.greenColors
                                    : Colors.grey.withValues(alpha: 0.2),
                                width: isSelected ? 2.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // บรรทัดบน: เลขที่สัญญา และ ไอคอนติ๊กถูก (ถ้าถูกเลือก)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        loanId,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Constants.greenColors
                                            .withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        loanDesc,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Constants.greenColors),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: Constants.greenColors,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 14.0),
                                Divider(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    height: 1),
                                const SizedBox(height: 12.0),

                                // ส่วนแสดงรายละเอียด ยอดชำระต่อเดือน
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'ยอดชำระต่อเดือน',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      '$regSalInt บาท',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6.0),

                                // ส่วนแสดงรายละเอียด ยอดชำระคงเหลือ (เน้นตัวหนา/ใหญ่ด้านล่าง)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      'ยอดชำระคงเหลือ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          amountSal,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "บาท",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
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
                  },
                )
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'ไม่มีข้อมูลบัญชี',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ),
          const SizedBox(height: 30),

          // ตรวจสอบเพื่อเปิดช่องกรอกเงิน
          _selectedAccount != null
              ? _buildAmountInputField()
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildOtherAccountDetails() {
    if (widget.type == 1) {
      return _buildType1OtherAcc();
    } else if (widget.type == 2) {
      return _buildType2OtherAcc();
    } else if (widget.type == 3) {
      return _buildType3OtherAcc();
    } else if (widget.type == 4) {
      return _buildType4OtherAcc();
    } else if (widget.type == 5) {
      return _buildType1OtherAcc();
    } else {
      return Container(); // หรือแสดงข้อมูลที่เหมาะสม
    }
  }

  String toMem = ''; // เพิ่มตัวแปรเก็บค่า to_mem
  String sele = ''; // เพิ่มตัวแปรเก็บค่า to_mem
  final TextEditingController _toMemController =
      TextEditingController(); // Controller สำหรับ TextField

  Widget _buildType1OtherAcc() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.stop,
                color: Constants.greenColors,
                size: 30.0,
              ),
              const SizedBox(width: 8),
              const Text(
                'เลขทะเบียนสมาชิกปลายทาง',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _toMemController, // คงเดิม
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _MemberNumberFormatter(), // ถอดแบบมาจากหน้าต้นแบบดั้งเดิมของคุณ
                  ],
                  decoration: InputDecoration(
                    hintText: "เลขทะเบียนสมาชิก 10 หลัก",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide:
                          BorderSide(color: Constants.greenColors, width: 2),
                    ),
                  ),
                  validator: (value) {
                    // 🟢 คง Logic การเช็คตัวแปรดั้งเดิมของคุณ
                    if (value!.isEmpty) {
                      return 'โปรดกรอกเลขทะเบียนสมาชิก 10 หลัก';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // 🟢 คง Logic การตัดขีดและการอัปเดต State เดิมของคุณไว้ 100% ไม่เปลี่ยนแปลง
                    setState(() {
                      toMem = value.replaceAll("-", ""); // ลบเครื่องหมาย "-"
                    });
                    if (value.length >= 10) {
                      // ตรวจสอบเมื่อป้อนครบ 10 หลัก
                      _toAccountNo = toMem;
                      validateMemberNumber();
                    }
                  },
                ),
              ),
            ],
          ),
          if (otherMemberName.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.stop,
                  color: Constants.greenColors,
                  size: 30.0,
                ),
                const SizedBox(width: 8),
                const Text(
                  'ชื่อ-สกุล บัญชีเงินฝากปลายทาง',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Constants.greenColors.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    color: Constants.greenColors.withValues(alpha: 0.2)),
              ),
              child: Text(
                otherMemberName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Constants.greenColors,
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          if (otherMemberName.isNotEmpty && _toAccountNo.isNotEmpty)
            _buildAmountInputField(),
        ],
      ),
    );
  }

  Widget _buildType2OtherAcc() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.stop,
                color: Constants.greenColors,
                size: 30.0,
              ),
              const SizedBox(width: 8),
              const Text(
                'เลขที่บัญชีเงินฝากปลายทาง',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ช่องกรอกเลขที่บัญชีเงินฝาก (เพิ่มตัวช่วยใส่ขีดอัตโนมัติ)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _toMemController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  // 🟢 เพิ่มอินพุตฟอร์แมตเตอร์สำหรับจัดฟอร์แมตขีด (-) อัตโนมัติขณะพิมพ์
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _AccountNumberFormatter(), // ถอดแบบมาจากหน้าต้นแบบดั้งเดิมของคุณ
                  ],
                  decoration: InputDecoration(
                    hintText: "เลขที่บัญชีเงินฝาก 11 หลัก",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide:
                          BorderSide(color: Constants.greenColors, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'โปรดกรอกเลขที่บัญชีเงินฝาก 11 หลัก';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // 🟢 ลบเครื่องหมาย "-" ออกก่อนเก็บค่าดิบลงตัวแปรหลักสำหรับเอาไปเช็ค Logic 11 หลักตามโค้ดเดิม
                    final String cleanValue = value.replaceAll("-", "");

                    setState(() {
                      toMem = cleanValue;
                    });

                    // 🟢 เช็คจากความยาวตัวเลขดิบ (ไม่นับขีด) หากครบ 11 หลัก ให้ยิงตรวจสอบทันที
                    if (cleanValue.length == 11) {
                      _toAccountNo = toMem;
                      validateMemberAccount();
                    }
                  },
                ),
              ),
            ],
          ),

          // ส่วนแสดงชื่อบัญชีปลายทางที่ดึงแบบ Real-time
          if (otherMemberName.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.stop,
                  color: Constants.greenColors,
                  size: 30.0,
                ),
                const SizedBox(width: 8),
                const Text(
                  'ชื่อ-สกุล บัญชีเงินฝากปลายทาง',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Constants.greenColors.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    color: Constants.greenColors.withValues(alpha: 0.2)),
              ),
              child: Text(
                otherMemberName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Constants.greenColors,
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          // เงื่อนไขเปิดช่องกรอกเงินตาม Logic เดิม
          if (otherMemberName.isNotEmpty && _toAccountNo.isNotEmpty)
            _buildAmountInputField(),
        ],
      ),
    );
  }

  Widget _buildType3OtherAcc() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ส่วนกรอกเลขทะเบียนสมาชิกปลายทาง (คงเดิมตามโครงสร้างคุณ)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.stop, color: Constants.greenColors, size: 30.0),
              const SizedBox(width: 8),
              const Text(
                'เลขทะเบียนสมาชิกปลายทาง',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _toMemController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _MemberNumberFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: "เลขทะเบียนสมาชิก 10 หลัก",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide:
                          BorderSide(color: Constants.greenColors, width: 2),
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
                      toMem = value.replaceAll("-", "");
                    });
                    if (value.length >= 10) {
                      _toAccountNo = toMem;
                      validateMemberNumber();
                    }
                  },
                ),
              ),
            ],
          ),

          // 2. ส่วนแสดงชื่อเมื่อพบสมาชิก และเปิดให้เลือกสัญญาปลายทาง
          if (otherMemberName.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.stop, color: Constants.greenColors, size: 30.0),
                const SizedBox(width: 8),
                const Text(
                  'ชื่อ-สกุล สมากชิกปลายทาง',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Constants.greenColors.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    color: Constants.greenColors.withValues(alpha: 0.2)),
              ),
              child: Text(
                otherMemberName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Constants.greenColors,
                ),
              ),
            ),

            // 🟢 จุดศัลยกรรมหลัก: ย้ายจุดเช็คเงื่อนไขมาไว้ที่นี่แบบ Clean Code
            if (toMem.length == 10) ...[
              const SizedBox(height: 24),
              _buildLoanSelectionSection(
                accountList: _loans,
                placeholderTitle: "เลือกเลขที่สัญญาสินเชื่อ",
              )
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildType4OtherAcc() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ส่วนกรอกเลขทะเบียนสมาชิกปลายทาง (ถอดแบบมาจาก Type 3)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.stop, color: Constants.greenColors, size: 30.0),
              const SizedBox(width: 8),
              const Text(
                'เลขทะเบียนสมาชิกปลายทาง',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _toMemController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _MemberNumberFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: "เลขทะเบียนสมาชิก 10 หลัก",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide:
                          BorderSide(color: Constants.greenColors, width: 2),
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
                      toMem = value.replaceAll("-", "");
                    });
                    if (value.length >= 10) {
                      validateMemberNumber(); // 🟢 Logic เดิมของ Type 4
                    }
                  },
                ),
              ),
            ],
          ),

          // 2. ส่วนแสดงชื่อเมื่อพบสมาชิก และเปิดให้เลือกบัญชีปลายทาง
          if (otherMemberName.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.stop, color: Constants.greenColors, size: 30.0),
                const SizedBox(width: 8),
                const Text(
                  'ชื่อ-สกุล สมาชิกปลายทาง',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Constants.greenColors.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    color: Constants.greenColors.withValues(alpha: 0.2)),
              ),
              child: Text(
                otherMemberName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Constants.greenColors,
                ),
              ),
            ),

            // 3. ส่วนแสดงรายการบัญชีสินเชื่อ (Arrahnu) หรือ ข้อความเตือน (เมื่อพิมพ์ครบ 10 หลัก)
            if (toMem.length == 10) ...[
              const SizedBox(height: 24),
              // เรียกใช้ฟังก์ชันเดียวกัน แต่เปลี่ยนไปส่ง _arrahnu แทน ✨
              _buildLoanSelectionSection(
                accountList: _arrahnu,
                placeholderTitle: "เลือกเลขที่สัญญาปลายทาง",
              ),
            ]
          ],
        ],
      ),
    );
  }

  Widget _buildAmountInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // ใช้เฉพาะตัวเลข
          ],
          decoration: const InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
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
    );
  }

  Widget _buildLoanSelectionSection({
    required List<dynamic> accountList, // รับได้ทั้ง _loans หรือ _arrahnu
    required String placeholderTitle, // ข้อความในปุ่มตอนยังไม่เลือก
  }) {
    // เคสที่ไม่มีสัญญาสินเชื่อจาก API เลย
    if (accountList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            'ไม่พบข้อมูลเลขที่สัญญาสินเชื่อ',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
      );
    }

    final bool isSelected = _selectedAccount != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.stop, color: Constants.greenColors, size: 30.0),
            const SizedBox(width: 8),
            Text(
              isSelected
                  ? 'เลขที่สัญญาสินเชื่อที่เลือก'
                  : 'เลือกเลขที่สัญญาสินเชื่อ',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ปุ่มจิ้มเพื่อเปิดหน้าใหม่ หรือ แสดงข้อมูลสัญญาที่ถูกเลือกไปแล้ว
        GestureDetector(
          onTap: () async {
            // 🟢 เปิดไปที่ SelectToqrPage โดยส่งลิสต์ที่แมปเข้ากับปุ่มนั้น ๆ (เช่น _loans หรือ _arrahnu)
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SelectToqrPage(
                  accounts: accountList,
                  type: widget.type,
                ),
              ),
            );

            // 🟢 พอกลับมาที่หน้านี้ ดึงข้อมูลกลับเข้า State
            if (result != null) {
              setState(() {
                _selectedAccount = result;
                _toAccountNo = generateToAccountNo(
                  brNo: result['BR_NO'] ?? '',
                  lcontId: result['LCONT_ID'] ?? '',
                  code: result['CODE'],
                );
              });
              sendAccountDataToAPI(); // เรียกใช้ Logic API เดิมที่มีโครงสร้างร่วมกันได้เลย
            }
          },
          child: isSelected
              ? _buildSelectedCardStyle() // เรียกใช้การ์ดใบที่เลือก (รวม Logic ดึง Key)
              : _buildSelectorPlaceholder(title: placeholderTitle),
        ),

        // 🟢 เงื่อนไข: ถ้าเลือกบัญชีสัญญาเรียบร้อยแล้ว ให้แสดงช่องกรอกจำนวนเงินทันทีด้านล่าง
        if (isSelected) ...[
          const SizedBox(height: 30),
          _buildAmountInputField(),
        ],
      ],
    );
  }

  Widget _buildSelectorPlaceholder({required String title}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }

// หน้าตาแบบกล่องการ์ด หลังจากที่ทำการเลือกสัญญาเสร็จสิ้นแล้ว
  Widget _buildSelectedCardStyle() {
    if (_selectedAccount == null) return const SizedBox.shrink();

    // ดึงเลขสัญญา (ลองของ Type 3 ก่อน ถ้าไม่มีให้เอาของ Type 4)
    final String accountId = (_selectedAccount!['LOAN_ID'] ??
            _selectedAccount!['LCONT_ID'] ??
            'ไม่ระบุเลขที่สัญญา')
        .toString();

    // ดึงยอดเงิน (ลองของ Type 3 ก่อน ถ้าไม่มีให้เอาของ Type 4)
    final String amount = (_selectedAccount!['LREG_SALINT'] ??
            _selectedAccount!['LREG_SALINT'] ??
            '0.00')
        .toString();

    final String statusFlag =
        (_selectedAccount!['LCONT_STATUS_FLAG'] ?? '').toString();
    final Map<String, String> lcontStatusFlags = {
      "1": "ชำระได้ตามปกติ",
      "4": "หมดสัญญา"
    };
    final String loanDesc = lcontStatusFlags[statusFlag] ?? 'สัญญาเงินกู้';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Constants.greenColors, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  accountId,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Constants.greenColors.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  loanDesc,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Constants.greenColors),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'ยอดชำระต่อเดือน',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    amount,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(width: 4),
                  Text('บาท',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ],
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
            _loans = jsonResponse['data']['loans'] ?? []; // เพิ่มส่วนนี้
            _arrahnu = jsonResponse['data']['arrahnu'] ?? []; // เพิ่มส่วนนี้

            // otherAccno =
            //     jsonResponse['data']['loans']; // รับชื่อสมาชิกจาก API
          });
        } else {
          // ถ้าไม่พบข้อมูลสมาชิก
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบหมายเลขสมาชิกในระบบ')),
          );
          setState(() {
            otherMemberName = '';
            _loans = []; // ล้างรายการเก่า
          });
        }
      } else {
        // ถ้าเกิดข้อผิดพลาดในการเรียก API
        throw Exception('เกิดข้อผิดพลาดในการตรวจสอบสมาชิก');
      }
    }
  }

  Future<void> validateMemberAccount() async {
    final accountNo = toMem;

    try {
      final response = await http.post(
        Uri.parse('https://online.iscop.co.th/ws/MobileApp/load_qrcode.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'ajax': '1',
          'do': 'get_account_info',
          'id': accountNo,
        },
      );

      print('Response: ${response.body}');
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (jsonResponse['status'] == 1) {
        setState(() {
          otherMemberName = jsonResponse['data']['ACCOUNT_NAME'];
          // toMemId = jsonResponse['data']['member_id']; // ถ้ามี
        });
      } else {
        setState(() {
          otherMemberName = 'บัญชีรับโอนไม่ถูกต้อง';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        otherMemberName = 'เกิดข้อผิดพลาดในการเชื่อมต่อ';
      });
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
    bool isActive = selectedType == type;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Constants.greenColors : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            // เปลี่ยนสีตัวอักษรตามสถานะ
            color: isActive ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

String generateToAccountNo({
  required String brNo,
  required String lcontId,
  required String? code,
}) {
  // แปลง LCONT_ID ตามกฎ
  String acc = lcontId.replaceAll('/', '').replaceAll('-', '');

  // แทนรหัสพิเศษ
  final replacements = {
    'ฉพ': '10',
    'สม': '20',
    'สจ': '21',
    'สศ': '22',
    'สท': '23',
    'สห': '24',
    'สฉ': '25',
    'สป': '26',
    'กฉ': '30',
    'กส': '31',
    'กท': '32',
    'คอ': '40',
    'คจ': '41',
    'คท': '42',
  };

  replacements.forEach((key, value) {
    acc = acc.replaceAll(key, value);
  });

  // สร้าง ref2 ตามโค้ด PHP
  String data2 = '$brNo$acc';
  String ref2 = data2.length > 2 ? data2.substring(2) : data2;
  String paddedCode = code != null ? code.padLeft(7, '0') : '0000000';
  ref2 += paddedCode;

  return ref2;
}

class _AccountNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 3 || nonZeroIndex == 5 || nonZeroIndex == 10) {
        if (nonZeroIndex != text.length) buffer.write('-');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _MemberNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      // 🟢 จัดตำแหน่งตามฟอร์แมต 001-01-57768 (ขีดหลังตำแหน่งที่ 3 และ 5)
      if (nonZeroIndex == 3 || nonZeroIndex == 5) {
        if (nonZeroIndex != text.length) buffer.write('-');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
