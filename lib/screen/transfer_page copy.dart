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

  const TransferPage({
    Key? key,
    required this.member_no,
    required this.br_no,
    required this.type,
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
  String _token = '';

  String memberName = '';
  List _accounts = [];
  bool _isLoading = true;

  List _toAccounts = [];
  String to_account_no = '';
  String account_no = '';

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
        return account['ACCOUNT_NO']?.toString() ?? '';
      case 2:
        return account['ACCOUNT_NO']?.toString() ?? '';
      case 3:
        return account['LCONT_ID']?.toString() ?? '';
      case 9:
        return account['LCONT_ID']?.toString() ?? '';
      case 4:
      case 17:
        return account['TAAWUN_NO']?.toString() ?? ''; // สมมติ: ตะอาวุน
      case 5:
        return (account['MEM_ID'] ?? '').toString();
      case 10:
        return account['SHARE_TYPE']?.toString() ?? ''; // สมมติ: หุ้น
      case 18:
      case 19:
        return account['LCONT_ID']?.toString() ?? '';
      default:
        return account['ACCOUNT_NO']?.toString() ?? '';
    }
  }

  Future<void> fetchQrcodeData() async {
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
    // memberName = widget.memberName;

    fetchQrcodeData();

    debugPrint("===== TransferPage Debug =====");
    debugPrint("type: ${widget.type}");
    debugPrint("member_no: ${widget.member_no}");
    debugPrint("branch_no: ${widget.br_no}");
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
    final theme = Theme.of(context);
    final w = media.size.width;
    final h = media.size.height;
    // if (selectedType == null) return null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: h * 0.015,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Constants.greenColors,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(35),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
          // onPressed: () {},
          onPressed: account_no.isEmpty
              ? null
              : () {
                  print("บัญชีที่เลือก: $account_no");
                  print("บัญชีปลายทาง: $to_account_no");
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
    );
  }

  Widget _buildTransferContent() {
    switch (widget.type) {
      case 1:
        return _depositMyAccount();

      case 2:
        return _depositMyAccount();

      case 3:
        return _loanMyAccount();

      case 9:
        return _depositMyAccount();

      case 5:
        return _shareMyAccount();

      case 10:
        return _depositMyAccount();

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

  // type for MyAccount
  Widget _depositMyAccount() {
    return Column(
      children: [
        _buildTopSection(),
        Expanded(
          child: _buildDepositMyAccountLayout(),
        ),
      ],
    );
  }

  Widget _loanMyAccount() {
    return Column(
      children: [
        _buildTopSection(),
        Expanded(
          child: _buildLoanMyAccountLayout(),
        ),
      ],
    );
  }

  Widget _arrahnuMyAccount() {
    return Column(
      children: [
        _buildTopSection(),
        Expanded(
          child: _buildArrahnuMyAccountLayout(),
        ),
      ],
    );
  }

  Widget _shareMyAccount() {
    return Column(
      children: [
        _buildTopSection(),
        Expanded(
          child: _buildShareMyAccountLayout(),
        ),
      ],
    );
  }
  // end type for MyAccount

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

  // type for detail MyAccount
  Widget _buildDepositMyAccountLayout() {
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
            _buildMemoField(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanMyAccountLayout() {
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
            _buildMemoField(),
          ],
        ),
      ),
    );
  }

  Widget _buildArrahnuMyAccountLayout() {
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
            _buildMemoField(),
          ],
        ),
      ),
    );
  }

  Widget _buildShareMyAccountLayout() {
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
            _buildMemoField(),
          ],
        ),
      ),
    );
  }
  // end type for detail MyAccount

  Widget _buildToAccount(String accNo, String accName, String balance,
      {bool isSelected = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Constants.greenColors,
          width: 2.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  accName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  accNo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  balance,
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
    );
  }

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
    final String accountDesc =
        (acc['DEP_TYPE_DESC'] ?? 'บัญชีเงินฝาก').toString();

    return AnimatedContainer(
      // 🟢 1. ใส่แอนิเมชันให้เอฟเฟกต์แสงเงาและกรอบเปลี่ยนผ่านอย่างนุ่มนวลเหมือนฝั่งสินเชื่อ
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: double
          .infinity, // 🟢 2. ขยายความกว้างเต็มพื้นที่เท่ากับหน้าอื่น ๆ และช่อง Memo
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        color: Colors
            .transparent, // 🟢 เปลี่ยนเป็น transparent เพื่อไม่ให้สีขาวของ Material ไปทับเส้นขอบและเงา
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(
                18), // ระยะ พิกัดความโปร่งสบายตาเท่ากันเป๊ะ
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    Constants.greenColors, // เส้นขอบหนา 2 สีหลักเมื่อถูกเลือก
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // แถวที่ 1: ชื่อบัญชี และประเภทบัญชี (ขวา) + ลูกศรนำทาง
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        accountName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight
                              .w600, // ปรับตัวหนาเน้นความสำคัญเป็นจุดนำสายตา
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      // 🟢 มีตลับ Tag Badge เล็กๆ บอกประเภทบัญชีเงินฝากสอดรับกับฝั่งสินเชื่อ
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

                // แถวที่ 2: เลขที่บัญชี และ ยอดเงินที่ถอนได้/ยอดคงเหลือ
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
        color: Colors
            .transparent, 
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Constants.greenColors,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$pTitle$fName $lName",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text("เลขทะเบียนสมาชิก $brNo-01-$memNo",
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToArrahnuSelected() {
    // ค้นหาข้อมูลตั๋วสัญญาอัรเราะห์นูใน _toAccounts
    final arrahnuAcc = _toAccounts.firstWhere(
      (e) => e['LCONT_ID']?.toString() == to_account_no,
      orElse: () => {},
    );

    if (arrahnuAcc.isEmpty || arrahnuAcc['LCONT_ID'] == null) {
      return const SizedBox.shrink();
    }

    // ✅ ดักจับ Null และแปลงค่าเป็น String ปลอดภัยไว้ก่อน
    final String contractId = arrahnuAcc['LCONT_ID'].toString();
    final String amountSalStr =
        (arrahnuAcc['LCONT_AMOUNT_SAL'] ?? '0').toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.white,
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
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Constants.greenColors,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              contractId, // ✅ ใช้ตัวแปรที่การันตีว่าเป็น String แน่นอนแล้ว
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ยอดคงเหลือทั้งหมด',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                            formatter.format(
                              double.tryParse(amountSalStr) ??
                                  0, // ✅ ปลอดภัยจาก Null แน่นอน
                            ),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
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
      ),
    );
  }

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

  Widget _buildMemoField() {
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
        TextField(
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'เพิ่มบันทึก (ถ้ามี)',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Constants.greenColors,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Constants.greenColors,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
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
            fontSize: 18,
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
