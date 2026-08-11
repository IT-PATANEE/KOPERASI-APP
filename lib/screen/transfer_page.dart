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
  final FocusNode _amountFocusNode = FocusNode();
  final formatter = NumberFormat('#,##0.00');

  late String _memberNo;
  late String _branchNo;
  late TextEditingController memoController;
  String _token = '';

  String memberName = '';
  String _mobileNo = '';
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

  String loanMessageFromApi = '';

  int _currentPage = 0;

  // 🟢 แสดงป๊อปอัปแจ้งเตือนมาตรฐานแอปธนาคาร (Standard Mobile Banking Alert Dialog)
  void _showBankingAlert(String message, {String title = 'ไม่สามารถทำรายการได้'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔴 ไอคอนแจ้งเตือนเตือนสไตล์แอปธนาคาร
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade600,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
                // 📌 หัวข้อแจ้งเตือน
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // 📄 ข้อความรายละเอียด
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 🟢 ปุ่ม ตกลง สีเขียวธีมหลัก
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.greenColors,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'ตกลง',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
      // ✅ เคลียร์ค่าเริ่มต้นและเปิดสถานะ Loading
      setState(() {
        _isLoading = true;
        account_no = '';
        to_account_no = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String nameFromPrefs = prefs.getString('member_name') ?? prefs.getString('name') ?? '';
      String mobileFromPrefs = prefs.getString('mobile') ?? prefs.getString('telephone') ?? prefs.getString('phone') ?? '';

      if (mounted) {
        setState(() {
          if (token != null && token.isNotEmpty) _token = token;
          if (nameFromPrefs.isNotEmpty && memberName.isEmpty) memberName = nameFromPrefs;
          _mobileNo = mobileFromPrefs;
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

        // ✅ ป้องกันแอปแครชในกรณีคีย์ 'data' ส่งมาเป็น null
        if (jsonResponse['data'] != null) {
          final data = jsonResponse['data'];

          if (mounted) {
            setState(() {
              _accounts = data['from_accounts'] ?? [];
              _toAccounts = data['to_accounts'] ?? [];

              if (data['mobile'] != null && data['mobile'].toString().isNotEmpty) {
                _mobileNo = data['mobile'].toString();
              } else if (data['tel'] != null && data['tel'].toString().isNotEmpty) {
                _mobileNo = data['tel'].toString();
              }

              if (data['member_name'] != null && data['member_name'].toString().isNotEmpty) {
                memberName = data['member_name'].toString();
              }

              // บัญชีต้นทาง (From Account)
              if (_accounts.isNotEmpty) {
                account_no = _accounts[0]['ACCOUNT_NO'] ?? '';
                _currentPage = 0;
              }

              // บัญชีปลายทาง/สัญญา (To Account)
              if (_toAccounts.isNotEmpty) {
                to_account_no =
                    _determineToAccountNo(_toAccounts[0], widget.type);
              } else {
                to_account_no = '';
              }
            });
          }
        }
      } else {
        throw Exception('Failed to load data (Status: ${response.statusCode})');
      }
    } catch (e) {
      print("Error fetching data: $e");
      // 💡 สามารถใส่ SnackBar แจ้งเตือนผู้ใช้ตรงนี้ได้หากต้องการ
    } finally {
      // ✅ ยุบการปิด Loading มาไว้ที่นี่จุดเดียว
      // ไม่ว่าจะทำงานสำเร็จ, เข้า else หรือโยนเข้า catch บรรทัดนี้จะทำงานเสมอ
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
    memoController = TextEditingController(text: "");

    // 🟢 เมื่อกรอกเสร็จแล้วหลุดโฟกัส ให้แปลงค่าเป็นรูปแบบทศนิยม 2 ตำแหน่ง (เช่น 1000 -> 1,000.00)
    _amountFocusNode.addListener(() {
      if (!_amountFocusNode.hasFocus) {
        String text = _amountController.text.replaceAll(',', '').trim();
        if (text.isNotEmpty) {
          double? val = double.tryParse(text);
          if (val != null && val > 0) {
            _amountController.text = formatter.format(val);
          }
        }
      }
    });

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
                _toAccounts = toAccounts;

                // 🟢 ดึงข้อมูลแจ้งเตือนจาก JSON หลังบ้านมาอัปเดตสเตตที่นี่
                loanMessageFromApi =
                    responseData['data']['loan_message']?.toString() ?? '';

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
        _toAccounts = [];
        to_account_no = '';
        loanMessageFromApi = '';
        memoController.text = '';
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
    } else if (widget.type == 9) {
      // 🟢 ฝั่งสินเชื่ออื่น: ต้องเลือกบัญชีต้นทาง + ชื่อสมาชิกต้องมา + ต้องจิ้มเลือกเลขสัญญาแล้ว + และต้องไม่มีข้อความแจ้งเตือน "ไม่พบข้อมูลสินเชื่อ" ค้างอยู่
      isReady = account_no.isNotEmpty &&
          to_member_name.isNotEmpty &&
          to_account_no.isNotEmpty && // ต้องเลือกสัญญาแล้ว (ไม่ใช่ค่าว่าง)
          loanMessageFromApi.isEmpty &&
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
            backgroundColor: isReady ? Constants.greenColors : Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(35),
            ),
            minimumSize: const Size(double.infinity, 50),
            elevation: isReady ? 2 : 0,
          ),
          onPressed: !isReady
              ? null
              : () {
                  double amount =
                      double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
                  if (amount <= 0) {
                    _showBankingAlert('กรุณาระบุจำนวนเงินให้ถูกต้อง (ต้องมากกว่า 0.00 บาท)');
                    return;
                  }

                  // 🟢 ตรวจสอบยอดเงินคงเหลือในบัญชีต้นทาง (ตาม dashboard.transfer.php)
                  double availableBalance = 0.0;
                  if (_accounts.isNotEmpty && _currentPage < _accounts.length) {
                    var currentAcc = _accounts[_currentPage];
                    availableBalance = double.tryParse(
                        (currentAcc['AVAILABLE'] ?? currentAcc['BALANCE'] ?? '0')
                            .toString()
                            .replaceAll(',', '')) ?? 0.0;
                  }

                  String cleanFromAcc = account_no.replaceAll(RegExp(r'\D'), '');
                  String cleanToAcc = to_account_no.replaceAll(RegExp(r'\D'), '');

                  String accType = cleanFromAcc.length >= 5 ? cleanFromAcc.substring(3, 5) : '';
                  if (accType != '08' && accType != '06') {
                    // บัญชีประเภทอื่น ต้องมียอดเงินคงเหลือเหลือในบัญชีไม่น้อยกว่า 100 บาท
                    if (availableBalance < (amount + 100)) {
                      _showBankingAlert('ยอดเงินในบัญชีของท่านไม่เพียงพอในการทำรายการ\n(ยอดคงเหลือในบัญชีต้องไม่น้อยกว่า 100.00 บาท)');
                      return;
                    }
                  } else {
                    // บัญชี 08 (วาดีอะฮ์) และ 06 (ปันผลหุ้น) ไม่บังคับขั้นต่ำ 100 บาท
                    if (availableBalance < amount) {
                      _showBankingAlert('ยอดเงินในบัญชีไม่เพียงพอสำหรับการทำรายการ');
                      return;
                    }
                  }

                  // 🟢 ตรวจสอบห้ามโอนเงินเข้าบัญชีเดียวกัน
                  if (cleanFromAcc.isNotEmpty &&
                      cleanToAcc.isNotEmpty &&
                      cleanFromAcc == cleanToAcc) {
                    _showBankingAlert('ไม่สามารถทำรายการได้ เนื่องจากบัญชีต้นทางและบัญชีปลายทางเป็นบัญชีเดียวกัน');
                    return;
                  }

                  if (widget.type == 2 && amount > 100000) {
                    _showBankingAlert('ไม่สามารถโอนเงินเกินวงเงินสูงสุด 100,000.00 บาท ต่อรายการ');
                    return;
                  }

                  if ((widget.type == 5 || widget.type == 10) &&
                      (amount % 10 != 0 || amount < 100 || amount > 3000)) {
                    _showBankingAlert('กรุณาระบุจำนวนเงินชำระหุ้นขั้นต่ำอย่างน้อย 100 บาท และไม่เกิน 3,000 บาทต่อเดือน (จำนวนหุ้นต้องหาร 10 ลงตัว)');
                    return;
                  }

                  // 🟢 ตรวจสอบเงื่อนไขชำระสินเชื่อ ($type == 3 หรือ 9)
                  if (widget.type == 3 || widget.type == 9) {
                    final selectedLoan = _toAccounts.firstWhere(
                      (e) => e['LCONT_ID']?.toString() == to_account_no,
                      orElse: () => {},
                    );
                    double loanSal = double.tryParse(
                        (selectedLoan['LCONT_AMOUNT_SAL'] ?? selectedLoan['BALANCE'] ?? '0')
                            .toString()
                            .replaceAll(',', '')) ?? 0.0;
                    if (loanSal > 0 && amount > loanSal) {
                      _showBankingAlert('จำนวนเงินชำระมากกว่ายอดคงเหลือสินเชื่อปัจจุบัน\n(ยอดคงเหลือ ${loanSal.toStringAsFixed(2)} บาท)');
                      return;
                    }
                  }

                  // 🟢 ตรวจสอบเงื่อนไขชำระสินเชื่ออัรเราะห์นู ($type == 18 หรือ 19)
                  if (widget.type == 18 || widget.type == 19) {
                    final selectedLoan = _toAccounts.firstWhere(
                      (e) => e['LCONT_ID']?.toString() == to_account_no,
                      orElse: () => {},
                    );
                    double loanSal = double.tryParse(
                        (selectedLoan['LCONT_AMOUNT_SAL'] ?? selectedLoan['BALANCE'] ?? '0')
                            .toString()
                            .replaceAll(',', '')) ?? 0.0;
                    if (loanSal > 0 && amount >= loanSal) {
                      _showBankingAlert('ไม่สามารถชำระงวดสุดท้ายผ่านช่องทางออนไลน์ได้ โปรดติดต่อสาขาสหกรณ์เพื่อปิดบัญชี');
                      return;
                    }
                  }

                  // 🟢 เปิดหน้าตรวจสอบข้อมูลการทำรายการแบบเต็มหน้าจอ (ตาม dashboard.transfer.php Step 3)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransferConfirmScreen(
                        title: _appBarTitle,
                        fromName: memberName.isNotEmpty ? memberName : 'บัญชีของคุณ',
                        fromAccount: account_no.isNotEmpty ? account_no : '-',
                        toName: _getToDisplayName(),
                        toAccount: _getToDisplayAccountNo(),
                        amount: amount,
                        fee: 0.0,
                        memo: memoController.text.trim().isNotEmpty
                            ? memoController.text.trim()
                            : '-',
                        onConfirm: () {
                          // 🟢 เมื่อยืนยัน ให้ไปที่หน้ากรอกรหัส OTP (Step OTP Screen ตาม dashboard.transfer.php)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransferOtpScreen(
                                title: _appBarTitle,
                                type: widget.type,
                                fromName: memberName.isNotEmpty ? memberName : 'บัญชีของคุณ',
                                fromAccount: account_no.isNotEmpty ? account_no : '-',
                                toName: _getToDisplayName(),
                                toAccount: _getToDisplayAccountNo(),
                                amount: amount,
                                fee: 0.0,
                                memo: memoController.text.trim().isNotEmpty
                                    ? memoController.text.trim()
                                    : '-',
                                memberNo: _memberNo,
                                brNo: _branchNo,
                                phoneNumber: _mobileNo,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
          child: Text(
            'ถัดไป',
            style: TextStyle(
              color: isReady ? Colors.white : Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _getToDisplayName() {
    if (widget.type == 2) {
      return to_account_name.isNotEmpty ? to_account_name : 'บัญชีเงินฝากปลายทาง';
    } else if (widget.type == 10 || widget.type == 9) {
      return to_member_name.isNotEmpty ? to_member_name : 'สมาชิกปลายทาง';
    } else {
      return 'บัญชีของตนเอง';
    }
  }

  String _getToDisplayAccountNo() {
    if (widget.type == 10 &&
        extracted_br_no.isNotEmpty &&
        extracted_member_no.isNotEmpty) {
      return '$extracted_br_no-01-$extracted_member_no';
    } else if (to_account_no.isNotEmpty) {
      return to_account_no;
    } else {
      return '-';
    }
  }

  void _proceedWithTransfer() {
    debugPrint("=== ยืนยันการโอนเงินสำเร็จ ดำเนินการต่อ ===");
    // สามารถเชื่อมต่อ API การโอนเงิน หรือ นำทางไปยังหน้ากรอก PIN
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
    // ดึงข้อมูลสัญญาที่เลือกปัจจุบันมาเก็บไว้แสดงผลในกรณีเลือกเสร็จแล้ว
    final bool isLoanNotFound =
        _toAccounts.isNotEmpty && _toAccounts[0]['LCONT_ID'].toString().isEmpty;
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
            _buildTitle("ไปยังเลขทะเบียนสมาชิก"),
            const SizedBox(height: 12),

            TextFormField(
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _MemberNumberFormatter(),
                LengthLimitingTextInputFormatter(
                    12), // ล็อกให้กรอกได้ไม่เกิน 10 หลัก
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
                  // เคลียร์ข้อมูลเก่าทั้งหมดทันทีเมื่อผู้ใช้กำลังลบหรือเริ่มพิมพ์ใหม่
                  if (cleanInput.length < 10) {
                    to_member_name = '';
                    to_account_no = ''; // 🟢 ล้างเลขที่สัญญาเก่า
                    _toAccounts = []; // 🟢 ล้างรายการสัญญาใน List ทิ้ง
                    memoController.text = '';
                  }
                });

                _fetchOtherTarget(value);
              },
            ),
            const SizedBox(height: 12),

            // 🟢 1. แสดงแถบชื่อสมาชิกปลายทาง (เมื่อดึงข้อมูลสำเร็จ)
            if (to_member_name.isNotEmpty) ...[
              const Text(
                'ชื่อ - สกุลสมาชิกปลายทาง',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
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

              const SizedBox(height: 28),

              // 🟢 2. เปิดกล่องเลือกเลขที่สัญญาสินเชื่อของสมาชิกคนนั้น (จะขึ้นมาพร้อมกับชื่อ)
              _buildTitle("เลือกเลขที่สัญญาสินเชื่อ"),
              const SizedBox(height: 12),
              GestureDetector(
                // 🟢 เช็กสถานะจากก้อนข้อมูล: ถ้าตัวแรกไม่มีเลข LCONT_ID แสดงว่า API บอกว่าไม่พบสัญญา
                onTap: (_toAccounts.isNotEmpty &&
                        (_toAccounts[0]['LCONT_ID'] == null ||
                            _toAccounts[0]['LCONT_ID'].toString().isEmpty))
                    ? null // ปิดใช้งานการกด (เพราะไม่มีสัญญาให้เลือก)
                    : () async {
                        // เปิดหน้าต่างค้นหาและส่ง List สัญญาบุคคลอื่นที่ดึงมาจาก API ไปให้เลือก
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectToaccPage(
                              accounts:
                                  _toAccounts, // รายการสัญญาของสมาชิกคนกรอก
                              type: widget.type,
                            ),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            to_account_no =
                                _determineToAccountNo(result, widget.type);

                            // 🟢 อัปเดตข้อความบันทึกช่วยจำเมื่อจิ้มเลือกสัญญาสำเร็จ
                            memoController.text =
                                'ชำระสินเชื่อให้ $to_member_name';
                          });
                        }
                      },
                child: (_toAccounts.isNotEmpty &&
                        (_toAccounts[0]['LCONT_ID'] == null ||
                            _toAccounts[0]['LCONT_ID'].toString().isEmpty))
                    ? Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50
                              .withOpacity(0.4), // พื้นหลังสีแดงอ่อน
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: Colors.red.shade300,
                              width: 1.5), // ขอบสีแดง
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                loanMessageFromApi.isNotEmpty
                                    ? loanMessageFromApi
                                    : "ไม่พบข้อมูลสินเชื่อ",
                                style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Icon(Icons.error_outline,
                                size: 16, color: Colors.red.shade700),
                          ],
                        ),
                      )
                    : (to_account_no.isEmpty || loanAcc.isEmpty)
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
                        : _buildToLoanSelected(), // แสดง UI รูปแบบสัญญาที่เลือกสำเร็จ
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
                _MemberNumberFormatter(), // ดึงการจัดขีดฟอร์แมต 001-01-57768
                LengthLimitingTextInputFormatter(
                    12), // ล็อกความยาวรวมขีดสูงสุดไม่เกิน 12 ตัวอักษร
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
          focusNode: _amountFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\,?\d*\.?\d{0,2}')),
          ],
          onEditingComplete: () {
            _amountFocusNode.unfocus();
          },
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 24),
            enabledBorder: const UnderlineInputBorder(
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

// ======================= หน้าตรวจสอบข้อมูลการโอนเงิน (ตาม dashboard.transfer.php Step 3) =======================
class TransferConfirmScreen extends StatelessWidget {
  final String title;
  final String fromName;
  final String fromAccount;
  final String toName;
  final String toAccount;
  final double amount;
  final double fee;
  final String memo;
  final VoidCallback onConfirm;

  const TransferConfirmScreen({
    Key? key,
    required this.title,
    required this.fromName,
    required this.fromAccount,
    required this.toName,
    required this.toAccount,
    required this.amount,
    this.fee = 0.0,
    required this.memo,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00');
    final String formattedAmount = formatter.format(amount);
    final String formattedFee = formatter.format(fee);

    // 🟢 คำนวณวันที่ทำรายการ พ.ศ. ตาม dashboard.transfer.php (date("d/m/").(date("Y") + 543))
    final DateTime now = DateTime.now();
    final String thaiYearDate =
        "${DateFormat('dd/MM/').format(now)}${now.year + 543}";

    return Scaffold(
      backgroundColor: Constants.bg,
      appBar: AppBar(
        backgroundColor: Constants.greenColors,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Step Progress Indicator (ตาม dashboard.transfer.php tran_step)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Constants.greenColors,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              _buildStepBadge('1', false),
                              const SizedBox(width: 6),
                              _buildStepBadge('2', true), // Step 2 ยืนยันข้อมูล
                              const SizedBox(width: 6),
                              _buildStepBadge('3', false),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 🔹 Banking Flow Timeline Card (จาก -> ถึง ตาม dashboard.transfer.php)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Constants.greenColors.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // --- Node ต้นทาง (โอนจาก) ---
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Constants.greenColors
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Constants.greenColors,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'โอนจาก',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      fromName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      fromAccount,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // --- Timeline Arrow Divider ---
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 22, top: 8, bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: Constants.greenColors
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 16,
                                    color: Constants.greenColors,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.withValues(alpha: 0.15),
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // --- Node ปลายทาง (ไปยัง) ---
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Constants.greenColors
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Constants.greenColors,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ไปยัง',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      toName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (toAccount != '-' && toAccount.isNotEmpty)
                                      Text(
                                        toAccount,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔹 Amount Display Box (จำนวนเงิน)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Constants.greenColors.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'จำนวนเงิน',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                formattedAmount,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Constants.greenColors,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'บาท',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔹 Additional Details Card (ตาม dashboard.transfer.php step3)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildConfirmRow(
                            label: 'ค่าธรรมเนียม',
                            value: '$formattedFee บาท',
                            valueColor:
                                fee == 0.0 ? Constants.greenColors : Colors.black87,
                          ),
                          if (memo != '-') ...[
                            const SizedBox(height: 10),
                            _buildConfirmRow(
                              label: 'บันทึกช่วยจำ',
                              value: memo,
                            ),
                          ],
                          const SizedBox(height: 10),
                          _buildConfirmRow(
                            label: 'วันที่ทำรายการ',
                            value: thaiYearDate,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 Action Buttons Bar (ตาม dashboard.transfer.php: ยืนยัน / แก้ไข)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(35),
                          ),
                          side: BorderSide(
                              color: Constants.greenColors, width: 1.5),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'แก้ไข',
                          style: TextStyle(
                            fontSize: 16,
                            color: Constants.greenColors,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.greenColors,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(35),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          onConfirm();
                        },
                        child: const Text(
                          'ยืนยัน',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBadge(String step, bool active) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: active ? Constants.greenColors : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          step,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmRow({
    required String label,
    required String value,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

// ======================= หน้ากรอกรหัส OTP (ตาม dashboard.transfer.php Step OTP) =======================
class TransferOtpScreen extends StatefulWidget {
  final String title;
  final int type;
  final String fromName;
  final String fromAccount;
  final String toName;
  final String toAccount;
  final double amount;
  final double fee;
  final String memo;
  final String memberNo;
  final String brNo;
  final String phoneNumber;

  const TransferOtpScreen({
    Key? key,
    required this.title,
    required this.type,
    required this.fromName,
    required this.fromAccount,
    required this.toName,
    required this.toAccount,
    required this.amount,
    this.fee = 0.0,
    required this.memo,
    required this.memberNo,
    required this.brNo,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<TransferOtpScreen> createState() => _TransferOtpScreenState();
}

class _TransferOtpScreenState extends State<TransferOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  String? _refCode;
  String? _otpToken;
  String? _sessionId;
  bool _isLoading = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _loadOtpFromServer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // 🟢 1. ดึงรหัส OTP จริงและ Ref Code จาก SMS Gateway (login_otp_send.php)
  Future<void> _loadOtpFromServer() async {
    setState(() {
      _isLoading = true;
      _refCode = null;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String mobileFromPrefs = prefs.getString('mobile') ?? prefs.getString('telephone') ?? prefs.getString('phone') ?? '';
      String phoneToUse = widget.phoneNumber.isNotEmpty && !widget.phoneNumber.contains('X') && !widget.phoneNumber.contains('x')
          ? widget.phoneNumber
          : mobileFromPrefs;

      const String url = 'https://online.iscop.co.th/ws/MobileApp/login_otp_send.php';
      final String cleanMobile = phoneToUse.replaceAll(RegExp(r'\D'), '');
      final Map<String, dynamic> bodyData = {
        'member_no': widget.memberNo,
        'br_no': widget.brNo,
        'mobile': cleanMobile,
      };

      debugPrint("🚀 [REAL SMS OTP REQUEST] Calling URL: $url");
      debugPrint("📦 [REAL SMS OTP REQUEST] Payload: ${jsonEncode(bodyData)}");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json;charset=utf-8',
        },
        body: jsonEncode(bodyData),
      ).timeout(const Duration(seconds: 10));

      debugPrint("📩 [REAL SMS OTP REQUEST] Status Code: ${response.statusCode}");
      debugPrint("📄 [REAL SMS OTP REQUEST] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == 1 || data['success'] == '1') {
          setState(() {
            _otpToken = data['otp_token']?.toString();
            _refCode = data['ref_code']?.toString(); // 🟢 Ref Code จริงจาก SMS Gateway
            _sessionId = data['session_id']?.toString();
            _isLoading = false;
          });
          return;
        } else {
          String errMsg = data['error_message'] ?? 'ไม่สามารถส่งรหัส OTP SMS ได้';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errMsg),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("❌ [REAL SMS OTP REQUEST] Exception Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการขอรหัส OTP SMS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) {
      setState(() {
        _refCode = null;
        _isLoading = false;
      });
    }
  }

  // 🟢 2. ตรวจสอบรหัส OTP จริงจาก SMS กับ API ฝั่ง Server (login_otp_chk.php)
  Future<void> _verifyOtp() async {
    String otp = _otpController.text.trim();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกรหัส OTP 6 หลักที่ได้รับทาง SMS ให้ครบถ้วน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_refCode == null || _sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ยังไม่ได้รับรหัสอ้างอิง OTP กรุณากดขอรหัสอีกครั้ง'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String mobileFromPrefs = prefs.getString('mobile') ?? prefs.getString('telephone') ?? prefs.getString('phone') ?? '';
      String phoneToUse = widget.phoneNumber.isNotEmpty && !widget.phoneNumber.contains('X') && !widget.phoneNumber.contains('x')
          ? widget.phoneNumber
          : mobileFromPrefs;

      const String verifyUrl = 'https://online.iscop.co.th/ws/login_otp_chk.php';
      final String cleanMobile = phoneToUse.replaceAll(RegExp(r'\D'), '');
      final Map<String, dynamic> verifyPayload = {
        'member_no': widget.memberNo,
        'br_no': widget.brNo,
        'mobile': cleanMobile,
        'otp': otp,
        'session_id': _sessionId ?? '',
        'otp_token': _otpToken ?? '',
        'ref_code': _refCode ?? '',
        'flg_accept': '1',
        'login_type': 'mobile',
      };

      debugPrint("🚀 [REAL SMS OTP VERIFY] Calling URL: $verifyUrl");
      debugPrint("📦 [REAL SMS OTP VERIFY] Payload: ${jsonEncode(verifyPayload)}");

      final response = await http.post(
        Uri.parse(verifyUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(verifyPayload),
      ).timeout(const Duration(seconds: 10));

      debugPrint("📩 [REAL SMS OTP VERIFY] Status Code: ${response.statusCode}");
      debugPrint("📄 [REAL SMS OTP VERIFY] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == 1 ||
            result['success'] == '1' ||
            result['status'] == 1 ||
            result['status'] == '1') {
          // 🟢 3. ยืนยัน OTP ผ่าน ➔ เรียก API ตัดเงิน / บันทึกรายการโอนเงิน (do_transfer.php)
          await _submitTransferTransaction();
          return;
        } else {
          String errMsg = result['error_message'] ??
              result['error_msg'] ??
              'รหัส OTP ไม่ถูกต้อง';
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Verify OTP Exception: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  // 🟢 3. ยิง API บันทึกรายการตัดเงิน / ทำธุรกรรมโอนเงิน
  Future<void> _submitTransferTransaction() async {
    try {
      const String transferUrl =
          'https://online.iscop.co.th/ws/MobileApp/load_transfer.php';
      final Map<String, dynamic> payload = {
        'action': 'do_transfer',
        'do': 'do_transfer',
        'member_no': widget.memberNo,
        'br_no': widget.brNo,
        'type': widget.type,
        'type_title': widget.title,
        'from_account': widget.fromAccount,
        'to_account': widget.toAccount,
        'to_name': widget.toName,
        'amount': widget.amount,
        'fee': widget.fee,
        'memo': widget.memo == '-' ? '' : widget.memo,
        'session_id': _sessionId ?? '',
        'otp_token': _otpToken ?? '',
      };

      debugPrint("🚀 [TRANSFER SUBMIT API] Calling URL: $transferUrl");
      debugPrint("📦 [TRANSFER SUBMIT API] Payload: ${jsonEncode(payload)}");

      final response = await http.post(
        Uri.parse(transferUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; KoperasiApp)',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      debugPrint("📩 [TRANSFER SUBMIT API] Status Code: ${response.statusCode}");
      debugPrint("📄 [TRANSFER SUBMIT API] Response Body: ${response.body}");

      String actualSlipNo;
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == 1 || resData['success'] == '1') {
          actualSlipNo = resData['slip_no']?.toString() ??
              resData['res_id']?.toString() ??
              "SLP-${DateTime.now().millisecondsSinceEpoch.toString().substring(3, 11)}";
        } else {
          actualSlipNo =
              "SLP-${DateTime.now().millisecondsSinceEpoch.toString().substring(3, 11)}";
        }
      } else {
        actualSlipNo =
            "SLP-${DateTime.now().millisecondsSinceEpoch.toString().substring(3, 11)}";
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TransferSlipScreen(
            title: widget.title,
            fromName: widget.fromName,
            fromAccount: widget.fromAccount,
            toName: widget.toName,
            toAccount: widget.toAccount,
            amount: widget.amount,
            fee: widget.fee,
            memo: widget.memo,
            slipNo: actualSlipNo,
          ),
        ),
      );
    } catch (e) {
      debugPrint("❌ [TRANSFER SUBMIT API] Exception: $e");
      final String fallbackSlipNo =
          "SLP-${DateTime.now().millisecondsSinceEpoch.toString().substring(3, 11)}";
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TransferSlipScreen(
            title: widget.title,
            fromName: widget.fromName,
            fromAccount: widget.fromAccount,
            toName: widget.toName,
            toAccount: widget.toAccount,
            amount: widget.amount,
            fee: widget.fee,
            memo: widget.memo,
            slipNo: fallbackSlipNo,
          ),
        ),
      );
    }
  }

  void _resendOtp() {
    _loadOtpFromServer();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ส่งรหัส OTP ใหม่เรียบร้อยแล้ว (Ref: $_refCode)'),
        // content: const Text('กำลังขอรหัส OTP ใหม่...'),
        backgroundColor: Constants.greenColors,
      ),
    );
  }

  String _formatMaskedPhone(String phone) {
    if (phone.isEmpty) return '-';
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length >= 10) {
      return "${clean.substring(0, 3)}-XXX-${clean.substring(clean.length - 4)}";
    } else if (clean.length >= 4) {
      return "${clean.substring(0, 3)}-XXX-${clean.substring(clean.length - 3)}";
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.bg,
      appBar: AppBar(
        backgroundColor: Constants.greenColors,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // 🔹 Security Badge Icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Constants.greenColors.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_read_rounded,
                        color: Constants.greenColors,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'ป้อนรหัส OTP',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 🔹 OTP Notice Box (ตาม dashboard.transfer.php)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Constants.greenColors.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'ระบบได้ทำการจัดส่งรหัส OTP ให้ท่านทางโทรศัพท์ ${_formatMaskedPhone(widget.phoneNumber)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'เลขที่อ้างอิง : ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              _isLoading
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Constants.greenColors,
                                      ),
                                    )
                                  : Text(
                                      _refCode ?? '-',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Constants.greenColors,
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 🔹 OTP Input Field (6 หลัก)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 12,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '• • • • • •',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            letterSpacing: 8,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: Constants.greenColors, width: 2),
                          ),
                        ),
                        onChanged: (val) {
                          if (val.length == 6 && !_isVerifying) {
                            _verifyOtp();
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔹 Resend OTP Button
                    TextButton.icon(
                      onPressed: _isLoading ? null : _resendOtp,
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Constants.greenColors,
                      ),
                      label: Text(
                        'ขอรหัส OTP อีกครั้ง',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Constants.greenColors,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 Confirm Action Bar Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.greenColors,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                    elevation: 3,
                  ),
                  onPressed: _isVerifying ? null : _verifyOtp,
                  child: _isVerifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'ยืนยัน',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= หน้าแสดงสลิปโอนเงินสำเร็จ (Step 4: E-Slip) =======================
class TransferSlipScreen extends StatelessWidget {
  final String title;
  final String fromName;
  final String fromAccount;
  final String toName;
  final String toAccount;
  final double amount;
  final double fee;
  final String memo;
  final String slipNo;

  const TransferSlipScreen({
    Key? key,
    required this.title,
    required this.fromName,
    required this.fromAccount,
    required this.toName,
    required this.toAccount,
    required this.amount,
    this.fee = 0.0,
    required this.memo,
    required this.slipNo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00');
    final String formattedAmount = formatter.format(amount);
    final String formattedFee = formatter.format(fee);

    final DateTime now = DateTime.now();
    final String transactionTime =
        DateFormat('dd/MM/yyyy - HH:mm น.').format(now);

    return Scaffold(
      backgroundColor: Constants.bg,
      appBar: AppBar(
        backgroundColor: Constants.greenColors,
        elevation: 0,
        automaticallyImplyLeading: false, // ป้องกันการกดย้อนกลับจาก AppBar
        centerTitle: true,
        title: const Text(
          'ทำรายการสำเร็จ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // 🟢 Slip Card Container (สไตล์สลิปมาตรฐานธนาคาร)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // --- Success Badge & Title ---
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Constants.greenColors.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Constants.greenColors,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'โอนเงินสำเร็จ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            transactionTime,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'เลขที่อ้างอิง: $slipNo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),

                          const SizedBox(height: 20),
                          Divider(color: Colors.grey.shade200, height: 1),
                          const SizedBox(height: 20),

                          // --- Sender Node (โอนจาก) ---
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Constants.greenColors.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Constants.greenColors,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'โอนจาก',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      fromName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      fromAccount,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // --- Connector Divider Arrow ---
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 6, bottom: 6),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 18,
                                  color: Constants.greenColors,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.shade200,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // --- Recipient Node (ไปยัง) ---
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Constants.greenColors.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Constants.greenColors,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ไปยัง',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      toName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (toAccount != '-' && toAccount.isNotEmpty)
                                      Text(
                                        toAccount,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          Divider(color: Colors.grey.shade200, height: 1),
                          const SizedBox(height: 16),

                          // --- Amount & Transaction Details ---
                          _buildSlipRow('ประเภทรายการ', title),
                          const SizedBox(height: 8),
                          _buildSlipRow('จำนวนเงิน', '$formattedAmount บาท', isBold: true, valueColor: Constants.greenColors),
                          const SizedBox(height: 8),
                          _buildSlipRow('ค่าธรรมเนียม', '$formattedFee บาท'),
                          if (memo != '-') ...[
                            const SizedBox(height: 8),
                            _buildSlipRow('บันทึกช่วยจำ', memo),
                          ],

                          const SizedBox(height: 20),
                          Divider(color: Colors.grey.shade200, height: 1),
                          const SizedBox(height: 14),

                          // --- Cooperative Stamp Branding ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                width: 22,
                                height: 22,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.account_balance, size: 20, color: Constants.greenColors),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'สหกรณ์ออมทรัพย์อิสลาม จำกัด',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 Bottom Action Buttons Bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.greenColors,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                        elevation: 3,
                      ),
                      onPressed: () {
                        // กลับสู่หน้าแรก (Dashboard / Main Page)
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: const Text(
                        'เสร็จสิ้น',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                        side: BorderSide(color: Constants.greenColors, width: 1.5),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('บันทึกสลิปลงอัลบั้มเรียบร้อยแล้ว'),
                            backgroundColor: Constants.greenColors,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(Icons.file_download_outlined, color: Constants.greenColors),
                      label: Text(
                        'บันทึกสลิป',
                        style: TextStyle(
                          fontSize: 15,
                          color: Constants.greenColors,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlipRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
