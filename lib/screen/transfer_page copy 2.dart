import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/screen/select_toacc_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TransferPage extends StatefulWidget {
  final String member_no;
  final String br_no;
  final int type;
  final String token;

  const TransferPage({
    Key? key,
    required this.member_no,
    required this.br_no,
    required this.type,
    required this.token,
  }) : super(key: key);

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final PageController _pageController = PageController();
  final TextEditingController _amountController = TextEditingController();
  final formatter = NumberFormat('#,##0.00');

  late String _memberNo;
  late String _branchNo;
  late TextEditingController memoController;
  String _token = '';

  String memberName = '';
  List _accounts = [];
  bool _isLoading = true;

  List _toAccounts = [];
  String to_account_no = '';
  String to_account_name = '';
  String account_no = '';

  String to_member_no = '';
  String clean_to_member_no = '';
  String to_member_name = '';

  String extracted_br_no = '';
  String extracted_member_no = '';

  int _currentPage = 0;

// หัวข้อหน้าจอตามประเภท (Type)
  String get _appBarTitle {
    switch (widget.type) {
      case 1:
        return 'โอนเงินระหว่างบัญชีตนเอง';
      case 2:
        return 'โอนเงินให้ผู้อื่น';
      case 3:
        return 'ชำระสินเชื่อ';
      case 4:
        return 'ชำระตะอาวุน';
      case 5:
        return 'ชำระหุ้น';
      case 9:
        return 'ชำระสินเชื่อให้ผู้อื่น';
      case 10:
        return 'ชำระหุ้นให้ผู้อื่น';
      case 17:
        return 'ชำระตะอาวุนให้ผู้อื่น';
      case 18:
        return 'ชำระอัรเราะห์นู';
      case 19:
        return 'ชำระอัรเราะห์นูให้ผู้อื่น';
      default:
        return 'โอนเงินฝาก'; // ค่า Default ดั้งเดิมของคุณ
    }
  }

  String _determineToAccountNo(Map<String, dynamic> account, int type) {
    switch (type) {
      case 1:
      case 2:
        return account['ACCOUNT_NO']?.toString() ?? '';
      case 3:
      case 9:
        return account['LCONT_ID']?.toString() ?? '';
      case 4:
      case 17:
        return account['MEM_ID']?.toString() ?? ''; // สมมติ: ตะอาวุน
      case 5:
      case 10:
        return (account['MEM_ID'] ?? '').toString();
      case 18:
      case 19:
        return account['LCONT_ID']?.toString() ?? '';
      default:
        return account['ACCOUNT_NO']?.toString() ?? '';
    }
  }

  Future<void> fetchTransData() async {
    try {
      // ✅ เพิ่มจุดนี้: เคลียร์ค่าเริ่มต้นก่อนเผื่อมีการสลับประเภทธุรกรรมไปมา
      setState(() {
        _isLoading = true;
        account_no = '';
        to_account_no = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        setState(() {
          _token = token;
        });
      }
      String url = 'https://online.iscop.co.th/ws/MobileApp/load_transfer.php';
      String fullUrl =
          '$url?member_no=$_memberNo&br_no=$_branchNo&type=${widget.type}&token=$token';
      print('Request URL: $fullUrl');

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print(jsonResponse);
        print('type คือ ${widget.type}');

        setState(() {
          _accounts = jsonResponse['data']['from_accounts'] ?? [];
          _toAccounts = jsonResponse['data']['to_accounts'] ?? [];

          // บัญชีต้นทาง (From Account)
          if (_accounts.isNotEmpty) {
            account_no = _accounts[0]['ACCOUNT_NO'] ?? '';
            _currentPage = 0;
          }

          // บัญชีปลายทาง/สัญญา (To Account)
          if (_toAccounts.isNotEmpty) {
            // ✅ ตรงนี้ของเดิมดีอยู่แล้วครับ มันจะวิ่งไปดึง LCONT_ID สำหรับเคส 18 ให้โดยอัตโนมัติ
            to_account_no = _determineToAccountNo(_toAccounts[0], widget.type);
          } else {
            to_account_no = '';
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
    memoController = TextEditingController(text: "");
    // memberName = widget.memberName;

    fetchTransData();

    debugPrint("===== TransferPage Debug =====");
    debugPrint("type: ${widget.type}");
    debugPrint("member_no: ${widget.member_no}");
    debugPrint("branch_no: ${widget.br_no}");
    debugPrint("token: ${widget.token}");
  }

  void _fetchOtherTarget(String inputNo) async {
    String cleanNo = inputNo.replaceAll('-', '');

    bool isAccountMode = (widget.type == 2);
    // กำหนดความยาวที่ต้องการ: เงินฝาก 11 หลัก / หุ้น 10 หลัก
    int requiredLength = isAccountMode ? 11 : 10;

    if (cleanNo.length == requiredLength) {
      try {
        // ค่าเริ่มต้นดึงจากของตัวผู้ใช้งาน (เจ้าของแอป) เองก่อน
        String finalBrNo = widget.br_no.toString();
        String finalMemberNo = widget.member_no.toString();

        // Map ข้อมูลพื้นฐานส่งไป API
        Map<String, String> queryParams = {
          'type': widget.type.toString(),
          'token': widget.token.toString(),
        };

        if (isAccountMode) {
          // กรณีเงินฝากบุคคลอื่น (Type 2)
          queryParams['member_no'] = finalMemberNo;
          queryParams['br_no'] = finalBrNo;
          queryParams['to_account_no'] = cleanNo; // ใช้เลขบัญชี 11 หลัก
        } else {
          // กรณีโอนหุ้นบุคคลอื่น (Type 10) -> สับส่วนแยกตาม "ตัวเลือก ก"
          finalBrNo =
              cleanNo.substring(0, 3); // เอา 3 ตัวแรกสุด (index 0, 1, 2)
          finalMemberNo =
              cleanNo.substring(5); // เอา 5 ตัวสุดท้าย (ข้ามหลักที่ 4 และ 5 ไป)

          queryParams['member_no'] =
              finalMemberNo; // แทนที่ด้วยเลขสมาชิกปลายทาง
          queryParams['br_no'] = finalBrNo; // แทนที่ด้วยเลขสาขาปลายทาง

          // 💡 เก็บค่าที่ตัดได้ลงตัวแปรของคลาสด้วย เพื่อเอาไปใช้ส่งต่อในปุ่มกดยืนยันโอนเงิน
          setState(() {
            extracted_br_no = finalBrNo;
            extracted_member_no = finalMemberNo;
          });
        }

        // ประกอบ URL พร้อมแนบพารามิเตอร์ที่เปลี่ยนไปตามเงื่อนไข
        final url = Uri.parse(
                'https://online.iscop.co.th/ws/MobileApp/load_transfer.php')
            .replace(queryParameters: queryParams);

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          if (responseData['success'] == 1) {
            final toAccounts = responseData['data']['to_accounts'] as List;
            if (toAccounts.isNotEmpty) {
              setState(() {
                String titleName = toAccounts[0]['PTITLE_NAME'] ?? '';
                String firstName = toAccounts[0]['FNAME'] ?? '';
                String lastName = toAccounts[0]['LNAME'] ?? '';
                if (isAccountMode) {
                  to_account_name = toAccounts[0]['ACCOUNT_NAME'];
                } else {
                  // รวมคำนำหน้า ชื่อ และนามสกุลเข้าด้วยกันอย่างปลอดภัย
                  to_member_name = "$titleName$firstName $lastName".trim();
                }

                switch (widget.type) {
                  case 2: // โหมดเงินฝาก (isAccountMode)
                    memoController.text =
                        'โอนเงินฝากไปยังชื่อบัญชี $to_account_name';
                    break;

                  case 10: // ตัวอย่าง: ชำระหุ้นบุคคลอื่น
                    memoController.text = 'ชำระหุ้นให้ $to_member_name';
                    break;

                  case 9: // ตัวอย่าง: ชำระสินเชื่อบุคคลอื่น
                    memoController.text = 'ชำระสินเชื่อให้ $to_member_name';
                    break;

                  case 17: // ตัวอย่าง: ชำระตะอาวุนบุคคลอื่น
                    memoController.text = 'ชำระตะอาวุนให้ $to_member_name';
                    break;

                  case 19: // ตัวอย่าง: ชำระตะอาวุนบุคคลอื่น
                    memoController.text = 'ชำระอัรเราะห์นูให้ $to_member_name';
                    break;

                  default:
                    // ค่าเริ่มต้นหากไม่ตรงกับเคสไหนเลย (กันเหนียวไว้ครับ)
                    memoController.text = isAccountMode
                        ? 'โอนเงินฝากไปยังชื่อบัญชี $to_account_name'
                        : 'โอนเงินให้ $to_member_name';
                }
              });
            } else {
              _handleErrorText("ไม่พบข้อมูลปลายทาง");
            }
          } else {
            _handleErrorText(responseData['error_message'] ?? "ไม่พบข้อมูล");
          }
        } else {
          _handleErrorText("เซิร์ฟเวอร์ขัดข้อง (${response.statusCode})");
        }
      } catch (e) {
        _handleErrorText("เกิดข้อผิดพลาดในการเชื่อมต่อ");
      }
    } else {
      // พิมพ์ยังไม่ครบจำนวนหลักที่กำหนด ให้ล้างค่าชื่อและตัวแปรสับส่วนรอไว้
      setState(() {
        if (isAccountMode) {
          to_account_name = '';
        } else {
          to_member_name = '';
          extracted_br_no = ''; // ล้างค่าออกเมื่อผู้ใช้ลบตัวเลขเพื่อกรอกใหม่
          extracted_member_no =
              ''; // ล้างค่าออกเมื่อผู้ใช้ลบตัวเลขเพื่อกรอกใหม่
        }
      });
    }
  }

  void _handleErrorText(String message) {
    setState(() {
      if (widget.type == 2) {
        to_account_name = message;
      } else {
        to_member_name = message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final w = media.size.width;
    final h = media.size.height;
    return Scaffold(
      backgroundColor: Constants.bg,
      resizeToAvoidBottomInset: true, // ✅ ป้องกันคีย์บอร์ดดัน layout
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
          _appBarTitle,
          style: theme.textTheme.titleLarge!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTransferContent(),
      bottomNavigationBar: _buildNextButton(),
    );
  }

  Widget? _buildNextButton() {
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;

    // 🟢 1. ตรวจสอบเงื่อนไขความพร้อมของข้อมูลก่อนกดปุ่มแยกตามประเภท (Validation)
    bool isReady = false;

    if (widget.type == 2) {
      // ฝั่งเงินฝากอื่น: ต้องกรอกบัญชีต้นทาง และ ต้องดึงชื่อบัญชีปลายทางสำเร็จแล้ว (ไม่ใช่ค่าว่าง และไม่ติด error text)
      isReady = account_no.isNotEmpty &&
          to_account_no.replaceAll('-', '').length == 11 &&
          to_account_name.isNotEmpty &&
          !to_account_name.contains("ไม่พบ") &&
          !to_account_name.contains("ขัดข้อง");
    } else if (widget.type == 10) {
      // ฝั่งหุ้นอื่น: ต้องกรอกบัญชีต้นทาง และ ตัวแปรที่สับส่วน (10 หลัก) ต้องถูกเซ็ตค่าเรียบร้อย ชื่อต้องเช็คผ่าน
      isReady = account_no.isNotEmpty &&
          extracted_br_no.isNotEmpty &&
          extracted_member_no.isNotEmpty &&
          to_member_name.isNotEmpty &&
          !to_member_name.contains("ไม่พบ") &&
          !to_member_name.contains("ขัดข้อง");
    } else {
      // สำหรับ type อื่นๆ ที่เป็นบัญชีตัวเอง (ถ้ามี) เช็คแค่เลือกบัญชีต้นทางไว้ก็พอ
      isReady = account_no.isNotEmpty;
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: h * 0.015,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            // 🟢 ถ้ายังไม่พร้อม ให้ปุ่มเปลี่ยนเป็นสีเทา หรือจางลง (UX ที่ดี)
            backgroundColor: isReady ? Constants.greenColors : Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(35),
            ),
            minimumSize: const Size(double.infinity, 50),
            elevation: isReady ? 2 : 0,
          ),
          // 🟢 ถ้าข้อมูลยังไม่พร้อม คืนค่า null เพื่อ disable ปุ่มกดทันที
          onPressed: !isReady
              ? null
              : () {
                  //ดึงจำนวนเงินและบันทึกช่วยจำมาเตรียมไว้ (ปรับชื่อคอนโทรลเลอร์ตามของคุณนะครับ)
                  // String amount = amountController.text;
                  // String memo = memoController.text;

                  if (widget.type == 2) {
                    // 🟢 [CASE 2: เงินฝากบุคคลอื่น]
                    String accountToSend = to_account_no.replaceAll('-', '');

                    debugPrint("--- ส่งข้อมูลโอนเงินฝากอื่น ---");
                    debugPrint("บัญชีต้นทาง: $account_no");
                    debugPrint("เลขบัญชีปลายทาง (ไม่มีขีด): $accountToSend");
                    debugPrint("ชื่อบัญชีปลายทาง: $to_account_name");
                    debugPrint("บันทึกช่วยจำ: ${memoController.text}");

                    // TODO: ส่งข้อมูลไปลอจิกหรือหน้าถัดไปของคุณ เช่น
                    // _confirmTransfer(accountNo: accountToSend);
                  } else if (widget.type == 10) {
                    // 🟢 [CASE 10: โอนหุ้นบุคคลอื่น]
                    debugPrint("--- ส่งข้อมูลโอนหุ้นอื่น ---");
                    debugPrint("บัญชีต้นทาง: $account_no");
                    debugPrint("รหัสสาขาปลายทางที่แยกได้: $extracted_br_no");
                    debugPrint(
                        "เลขสมาชิกปลายทางที่แยกได้: $extracted_member_no");
                    debugPrint("ชื่อสมาชิกปลายทาง: $to_member_name");
                    debugPrint("บันทึกช่วยจำ: ${memoController.text}");

                    // TODO: ส่งข้อมูลไปลอจิกโอนหุ้นของคุณ เช่น
                    // _confirmShareTransfer(brNo: extracted_br_no, memberNo: extracted_member_no);
                  } else if (widget.type == 9) {
                    // 🟢 [CASE 10: โอนหุ้นบุคคลอื่น]
                    debugPrint("--- ส่งข้อมูลโอนหุ้นอื่น ---");
                    debugPrint("บัญชีต้นทาง: $account_no");
                    debugPrint("รหัสสาขาปลายทางที่แยกได้: $extracted_br_no");
                    debugPrint(
                        "เลขสมาชิกปลายทางที่แยกได้: $extracted_member_no");
                    debugPrint("ชื่อสมาชิกปลายทาง: $to_member_name");
                    debugPrint("บันทึกช่วยจำ: ${memoController.text}");

                    // TODO: ส่งข้อมูลไปลอจิกโอนหุ้นของคุณ เช่น
                    // _confirmShareTransfer(brNo: extracted_br_no, memberNo: extracted_member_no);
                  } else {
                    // CASE อื่นๆ ของคุณ (โอนบัญชีตัวเอง)
                    debugPrint("--- โอนบัญชีตัวเอง / เมนูอื่นๆ ---");
                    debugPrint("บัญชีต้นทาง: $account_no");
                  }
                },
          child: Text(
            'ถัดไป',
            style: TextStyle(
              // 🟢 ตัวหนังสือเปลี่ยนสีตามสถานะปุ่ม
              color: isReady ? Colors.white : Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransferContent() {
    switch (widget.type) {
      case 1:
        return _depositMyAccount();

      case 2:
        return _depositOtherAccount();

      case 3:
        return _loanMyAccount();

      case 9:
        return _loanOtherAccount();

      case 5:
        return _shareMyAccount();

      case 10:
        return _shareOtherAccount();

      case 4:
        return _depositMyAccount();

      case 17:
        return _depositMyAccount();

      case 18:
        return _arrahnuMyAccount();

      case 19:
        return _depositMyAccount();

      default:
        return const Center(child: Text("ไม่พบประเภทการโอน"));
    }
  }

  // ======================= การจัดกลุ่มข้อมูลตามประเภทธุรกรรม =======================
  Widget _depositMyAccount() {
    return Column(
      children: [
        _buildTopSection(),
        Expanded(
          child: _buildDepositMyAccountLayout(memoController),
        ),
      ],
    );
  }

  Widget _depositOtherAccount() {
    return Column(
      children: [
        _buildTopSection(),
        Expanded(
          child: _buildDepositOtherAccLayout(memoController),
        ),
      ],
    );
  }

  Widget _loanMyAccount() {
    return Column(
      children: [
        _buildTopSection(),
        Expanded(
          child: _buildLoanMyAccountLayout(memoController),
        ),
      ],
    );
  }

  Widget _loanOtherAccount() {
    return Column(
      children: [
        _buildTopSection(),
        Expanded(
          child: _buildLoanOtherAccLayout(memoController),
        ),
      ],
    );
  }

  Widget _arrahnuMyAccount() {
    return Column(
      children: [
        _buildTopSection(),
        Expanded(
          child: _buildArrahnuMyAccountLayout(memoController),
        ),
      ],
    );
  }

  Widget _shareMyAccount() {
    return Column(
      children: [
        _buildTopSection(),
        Expanded(
          child: _buildShareMyAccountLayout(memoController),
        ),
      ],
    );
  }

  Widget _shareOtherAccount() {
    return Column(
      children: [
        _buildTopSection(),
        Expanded(
          child: _buildShareOtherAccLayout(memoController),
        ),
      ],
    );
  }
  // ============================================================================

  // ======================= หัวหลักเลือกบัญชีโอนเงิน =======================

  Widget _buildTopSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Constants.greenColors, // เขียว
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "เลือกบัญชีโอนเงิน",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 12),

          AspectRatio(
            aspectRatio: 2.2,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _accounts.length,
              onPageChanged: (index) {
                final acc = _accounts[index];

                setState(() {
                  _currentPage = index;
                  account_no = acc['ACCOUNT_NO'] ?? '';
                });
              },
              itemBuilder: (context, index) {
                final acc = _accounts[index];

                return _accountCard(
                  acc['ACCOUNT_NO'] ?? '',
                  acc['ACCOUNT_NAME'] ?? '',
                  formatter.format(
                    double.tryParse(acc['BALANCE']?.toString() ?? '0') ?? 0,
                  ),
                  acc['ACC_DESC'] ?? '',
                  isSelected: account_no == acc['ACCOUNT_NO'],
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          /// indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _accounts.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 10 : 6,
                height: _currentPage == index ? 10 : 6,
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.white : Colors.white54,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ============================================================================

  // ======================= type for detail MyAccount =======================

  Widget _buildDepositMyAccountLayout(TextEditingController memoController) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle("ไปยัง"),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SelectToaccPage(
                      accounts: _toAccounts,
                      type: widget.type,
                    ),
                  ),
                );

                if (result != null) {
                  setState(() {
                    to_account_no = result['ACCOUNT_NO'];
                  });
                }
              },
              child: to_account_no.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("เลือกบัญชีปลายทาง"),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    )
                  : _buildToAccountSelected(),
            ),
            const SizedBox(height: 28),
            _buildAmountInputField(),
            const SizedBox(height: 28),
            _buildMemoField(memoController),
          ],
        ),
      ),
    );
  }

  Widget _buildDepositOtherAccLayout(TextEditingController memoController) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle("ไปยังเลขที่บัญชีเงินฝาก"),
            const SizedBox(height: 12),
            TextFormField(
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              // ตัวช่วยใส่ขีดอัตโนมัติ 999-99-99999-9 (ใส่เพิ่มถ้ามี หรือลบออกหากพิมพ์ยาวๆ)
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _AccountNumberFormatter(),
              ],
              decoration: InputDecoration(
                hintText: "เลขที่บัญชีเงินฝากปลายทาง",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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
              onChanged: (value) {
                setState(() {
                  to_account_no = value; // เก็บค่าลงตัวแปรหลัก
                });
                // วิ่งไปเช็คชื่อเมื่อพิมพ์ครบความยาวที่กำหนด
                _fetchOtherTarget(value);
              },
            ),

            // ส่วนแสดงชื่อบัญชีปลายทางที่ดึงแบบ Real-time
            if (to_account_name.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'ชื่อ - สกุลบัญชีปลายทาง', // หัวข้ออยู่ด้านบนนอกกล่อง (สไตล์เดียวกับบันทึกช่วยจำ)
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity, // ขยายให้เต็มความกว้างจอ
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Constants.greenColors.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Text(
                  to_account_name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Constants.greenColors,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            _buildAmountInputField(),
            const SizedBox(height: 28),
            _buildMemoField(memoController),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanMyAccountLayout(TextEditingController memoController) {
    final loanAcc = _toAccounts.firstWhere(
      (e) => e['LCONT_ID']?.toString() == to_account_no,
      orElse: () => {},
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle("เลือกเลขที่สัญญาสินเชื่อ"),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SelectToaccPage(
                      accounts: _toAccounts,
                      type: widget.type,
                    ),
                  ),
                );

                if (result != null) {
                  setState(() {
                    to_account_no = _determineToAccountNo(result, widget.type);
                  });
                }
              },
              child: to_account_no.isEmpty || loanAcc.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("เลือกเลขที่สัญญาปลายทาง"),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    )
                  : _buildToLoanSelected(),
            ),
            const SizedBox(height: 28),
            _buildAmountInputField(),
            const SizedBox(height: 28),
            _buildMemoField(memoController),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanOtherAccLayout(TextEditingController memoController) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle("ไปยังเลขทะเบียนสมาชิก"),
            const SizedBox(height: 12),

            TextFormField(
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(
                    10), // ล็อกให้กรอกได้ไม่เกิน 10 หลัก
              ],
              decoration: InputDecoration(
                hintText: "เลขทะเบียนสมาชิก 10 หลัก",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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
              onChanged: (value) {
                String cleanInput = value.replaceAll('-', '');

                setState(() {
                  to_member_no = value;
                  // เคลียร์ชื่อเก่าออกทันทีเมื่อกำลังลบหรือพิมพ์ใหม่ (ยังไม่ครบ 10 หลัก)
                  if (cleanInput.length < 10) {
                    to_member_name = '';
                    memoController.text = '';
                  }
                });
                // if (cleanInput.length == 10) {
                //   // 🟢 ตัวอย่าง: พอพิมพ์ครบ 10 หลัก ให้เปลี่ยนข้อความในบันทึกอัตโนมัติ
                //   memoController.text = 'ชำระหุ้นให้ $to_member_name';
                // }

                _fetchOtherTarget(value);
              },
            ),
            const SizedBox(height: 12),

            // 🟢 แสดงแถบชื่อสมาชิกปลายทาง (จะขึ้นมาเฉพาะตอนดึงชื่อสำเร็จแล้วเท่านั้น)
            if (to_member_name.isNotEmpty) ...[
              const Text(
                'ชื่อ - สกุลสมาชิกปลายทาง', // หัวข้ออยู่ด้านบนนอกกล่อง (สไตล์เดียวกับบันทึกช่วยจำ)
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity, // ขยายให้เต็มความกว้างจอ
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Constants.greenColors.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Text(
                  to_member_name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Constants.greenColors,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),
            _buildAmountInputField(),
            const SizedBox(height: 28),
            _buildMemoField(memoController),
          ],
        ),
      ),
    );
  }

  Widget _buildArrahnuMyAccountLayout(TextEditingController memoController) {
    // ดึงข้อมูลสัญญาปัจจุบันมาเช็คความว่างเปล่า
    final arrahnuAcc = _toAccounts.firstWhere(
      (e) => e['LCONT_ID']?.toString() == to_account_no,
      orElse: () => {},
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle("เลือกเลขที่สัญญาอัร-เราะห์นู"),
            const SizedBox(height: 12),

            // ✅ ตรวจสอบเงื่อนไข: ถ้ามีข้อมูลล่าสุดที่เซ็ตมาจากโหลดครั้งแรกแล้ว ให้แสดง Widget ใหม่ทันที
            to_account_no.isEmpty || arrahnuAcc.isEmpty
                ? GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SelectToaccPage(
                            accounts: _toAccounts,
                            type: widget.type,
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          to_account_no =
                              _determineToAccountNo(result, widget.type);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("เลือกเลขที่สัญญาปลายทาง"),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  )
                : _buildToArrahnuSelected(), // ✅ เรียกใช้ Widget ตัวใหม่ที่คุณเพิ่มเข้ามา

            const SizedBox(height: 28),
            _buildAmountInputField(),
            const SizedBox(height: 28),
            _buildMemoField(memoController),
          ],
        ),
      ),
    );
  }

  Widget _buildShareMyAccountLayout(TextEditingController memoController) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle("บัญชีทุนเรือนหุ้นปลายทาง"),
            const SizedBox(height: 12),

            // ✅ แสดงผลข้อมูลหุ้นของสมาชิกรายนี้ทันที ไม่ต้องเปิดหน้าเลือกให้ซ้ำซ้อน
            _buildToShareSelected(),

            const SizedBox(height: 28),
            _buildAmountInputField(),
            const SizedBox(height: 28),
            _buildMemoField(memoController),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOtherAccLayout(TextEditingController memoController) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle("ไปยังเลขทะเบียนสมาชิก"),
            const SizedBox(height: 12),

            TextFormField(
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(
                    10), // ล็อกให้กรอกได้ไม่เกิน 10 หลัก
              ],
              decoration: InputDecoration(
                hintText: "เลขทะเบียนสมาชิก 10 หลัก",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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
              onChanged: (value) {
                String cleanInput = value.replaceAll('-', '');

                setState(() {
                  to_member_no = value;
                  // เคลียร์ชื่อเก่าออกทันทีเมื่อกำลังลบหรือพิมพ์ใหม่ (ยังไม่ครบ 10 หลัก)
                  if (cleanInput.length < 10) {
                    to_member_name = '';
                    memoController.text = '';
                  }
                });
                // if (cleanInput.length == 10) {
                //   // 🟢 ตัวอย่าง: พอพิมพ์ครบ 10 หลัก ให้เปลี่ยนข้อความในบันทึกอัตโนมัติ
                //   memoController.text = 'ชำระหุ้นให้ $to_member_name';
                // }

                _fetchOtherTarget(value);
              },
            ),
            const SizedBox(height: 12),

            // 🟢 แสดงแถบชื่อสมาชิกปลายทาง (จะขึ้นมาเฉพาะตอนดึงชื่อสำเร็จแล้วเท่านั้น)
            if (to_member_name.isNotEmpty) ...[
              const Text(
                'ชื่อ - สกุลสมาชิกปลายทาง', // หัวข้ออยู่ด้านบนนอกกล่อง (สไตล์เดียวกับบันทึกช่วยจำ)
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity, // ขยายให้เต็มความกว้างจอ
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Constants.greenColors.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Text(
                  to_member_name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Constants.greenColors,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),
            _buildAmountInputField(),
            const SizedBox(height: 28),
            _buildMemoField(memoController),
          ],
        ),
      ),
    );
  }
  // ============================================================================

  // ======================= บัญชีที่เลือก =======================

  Widget _buildToAccountSelected() {
    final acc = _toAccounts.firstWhere(
      (e) => e['ACCOUNT_NO'] == to_account_no,
      orElse: () => {},
    );
    if (acc.isEmpty || acc['ACCOUNT_NO'] == null) {
      return const SizedBox.shrink();
    }

    final String accountName = (acc['ACCOUNT_NAME'] ?? '').toString();
    final String accountNo = (acc['ACCOUNT_NO'] ?? '').toString();
    final String balanceStr = (acc['BALANCE'] ?? '0').toString();
    final String accountDesc = (acc['ACC_DESC'] ?? 'บัญชีเงินฝาก').toString();

    return AnimatedContainer(
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
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SelectToaccPage(
                  accounts: _toAccounts,
                  type: widget.type,
                ),
              ),
            );

            if (result != null) {
              setState(() {
                to_account_no = _determineToAccountNo(result, widget.type);
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Constants.greenColors,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        accountName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                        color: Constants.greenColors.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        accountDesc,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Constants.greenColors,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 14.0),

                // เส้นคั่นบาง ๆ สไตล์มินิมอลแบ่งสัดส่วน
                Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
                const SizedBox(height: 12.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      accountNo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatter.format(double.tryParse(balanceStr) ?? 0),
                          style: TextStyle(
                            fontSize:
                                20, // 🟢 ขยายตัวเลขยอดเงินเด่นๆ เป็นสีเขียวประจำแอป
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
  }

  Widget _buildToLoanSelected() {
    // ค้นหาข้อมูลสัญญาเงินกู้โดยใช้คีย์ LCONT_ID
    final loanAcc = _toAccounts.firstWhere(
      (e) => e['LCONT_ID']?.toString() == to_account_no,
      orElse: () => {},
    );
    if (loanAcc.isEmpty || loanAcc['LCONT_ID'] == null) {
      return const SizedBox.shrink();
    }

    final String contractId = loanAcc['LCONT_ID'].toString();
    final String inteSalStr = (loanAcc['LCONT_INTESAL'] ?? '0').toString();
    final Map<String, String> lcontStatusFlags = {
      "1": "ชำระได้ตามปกติ",
      "4": "หมดสัญญา",
    };
    final String statusFlag = (loanAcc['LCONT_STATUS_FLAG'] ?? '').toString();
    final String loanDesc = lcontStatusFlags[statusFlag] ?? 'สัญญาเงินกู้';

    return AnimatedContainer(
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
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SelectToaccPage(
                  accounts: _toAccounts,
                  type: widget.type,
                ),
              ),
            );

            if (result != null) {
              setState(() {
                to_account_no = _determineToAccountNo(result, widget.type);
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Constants.greenColors,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        contractId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                        color: Constants.greenColors.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        loanDesc,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Constants.greenColors,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 14.0),

                // เส้นคั่นบาง ๆ สไตล์มินิมอลแบ่งสัดส่วน
                Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
                const SizedBox(height: 12.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'ยอดชำระต่อเดือน',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatter.format(double.tryParse(inteSalStr) ?? 0),
                          style: TextStyle(
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
  }

  Widget _buildToShareSelected() {
    if (_toAccounts.isEmpty) return const SizedBox.shrink();

    // ดึงข้อมูลสมาชิกแถวแรกออกมา
    final shareAcc = _toAccounts[0];

    final String memNo = (shareAcc['MEM_ID'] ?? '').toString();
    final String brNo = (shareAcc['BR_NO'] ?? '').toString();
    final String pTitle = (shareAcc['PTITLE_NAME'] ?? '').toString();
    final String fName = (shareAcc['FNAME'] ?? '').toString();
    final String lName = (shareAcc['LNAME'] ?? '').toString();

    return AnimatedContainer(
      // 🟢 1. ใส่แอนิเมชันและการไล่เฉดเงาด้วย .withValues(alpha: ...) สไตล์เดียวกับตัวอื่น ๆ
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
          padding: const EdgeInsets.all(18), // ระยะ Padding สบายตาเท่ากันเป๊ะ
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Constants.greenColors, // เส้นขอบหนา 2 สีหลักเมื่อถูกเลือก
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // แถวที่ 1: ชื่อ-นามสกุลสมาชิก และ Tag Badge บอกประเภท (ขวา)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "$pTitle$fName $lName",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight
                            .w600, // ปรับความหนาตัวอักษรเป็นจุดนำสายตา
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    // 🟢 2. เพิ่มกล่องข้อความกำกับประเภท "ทุนเรือนหุ้น" ล้อไปกับพวกข้อความสถานะ/ประเภทบัญชี
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Constants.greenColors.withValues(alpha: 0.08),
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
              Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
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
                    "$brNo-01-$memNo",
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
    );
  }

  Widget _buildToArrahnuSelected() {
    // ค้นหาข้อมูลสัญญาเงินกู้โดยใช้คีย์ LCONT_ID
    final arrahnuAcc = _toAccounts.firstWhere(
      (e) => e['LCONT_ID']?.toString() == to_account_no,
      orElse: () => {},
    );
    if (arrahnuAcc.isEmpty || arrahnuAcc['LCONT_ID'] == null) {
      return const SizedBox.shrink();
    }

    final String contractId = arrahnuAcc['LCONT_ID'].toString();
    final String amountSalStr =
        (arrahnuAcc['LCONT_AMOUNT_SAL'] ?? '0').toString();
    final Map<String, String> lcontStatusFlags = {
      "1": "ชำระได้ตามปกติ",
      "4": "หมดสัญญา",
    };
    final String statusFlag =
        (arrahnuAcc['LCONT_STATUS_FLAG'] ?? '').toString();
    final String loanDesc = lcontStatusFlags[statusFlag] ?? 'สัญญาเงินกู้';

    return AnimatedContainer(
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
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SelectToaccPage(
                  accounts: _toAccounts,
                  type: widget.type,
                ),
              ),
            );

            if (result != null) {
              setState(() {
                to_account_no = _determineToAccountNo(result, widget.type);
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Constants.greenColors,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        contractId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                        color: Constants.greenColors.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        loanDesc,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Constants.greenColors,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 14.0),

                // เส้นคั่นบาง ๆ สไตล์มินิมอลแบ่งสัดส่วน
                Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
                const SizedBox(height: 12.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'ยอดคงเหลือทั้งหมด',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatter.format(double.tryParse(amountSalStr) ?? 0),
                          style: TextStyle(
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
  }

  // ============================================================================

  Widget _accountCard(String accNo, String accName, String balance, String desc,
      {bool isSelected = false}) {
    final w = MediaQuery.of(context).size.width;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      padding:
          EdgeInsets.all(w * 0.045), // เพิ่มความโปร่งให้การ์ดหายใจสะดวกขึ้น
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected
              ? Constants.greenColors
              : Colors.grey.withOpacity(0.15),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Constants.greenColors.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  accName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                accNo,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey.shade600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Constants.greenColors.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  desc,
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
          // เส้นคั่นบางๆ แบ่งสัดส่วนยอดเงิน
          Divider(color: Colors.grey.withOpacity(0.1), height: 1),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "ยอดเงินที่ถอนได้",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey.shade600,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    balance,
                    style: TextStyle(
                      fontSize: 20, //
                      fontWeight: FontWeight.bold,
                      color: Constants.greenColors,
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
    );
  }

  Widget _buildMemoField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'บันทึกช่วยจำ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: Constants.greenColors.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
          ),
          child: TextField(
            controller:
                controller, // 🟢 นำ Controller ที่ส่งมาผูกเข้ากับช่องพิมพ์ตรงนี้
            maxLength: 50,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'เพิ่มบันทึก (ถ้ามี)',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
              counterText: "",
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
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
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Constants.greenColors,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(String text) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _dot(bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 10 : 6,
      height: active ? 10 : 6,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white54,
        shape: BoxShape.circle,
      ),
    );
  }
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
