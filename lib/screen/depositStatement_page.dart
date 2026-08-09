import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/screen/share_page.dart';
import 'package:koperasiapp/screen/selecttransfer_page.dart';
import 'package:koperasiapp/screen/selectqrcode_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
  Map<String, dynamic>? _depositStatementData;
  String serverResponse = 'กำลังรอข้อมูลจากเซิร์ฟเวอร์...';

  @override
  void initState() {
    _memberNo = widget.memberNo;
    _branchNo = widget.branchNo;
    _accountNo = widget.accountNo;
    super.initState();
    fetchStatementData();
  }

  Future<void> fetchStatementData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    String url =
        'https://online.iscop.co.th/ws/MobileApp/deposit_statement.php';
    String fullUrl =
        '$url?member_no=$_memberNo&br_no=$_branchNo&token=$token&account_no=$_accountNo';

    try {
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == 1) {
          setState(() {
            _depositStatementData = jsonResponse['data'];
          });
        } else {
          print('Error: ${jsonResponse['message']}');
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Constants.greenColors,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Text(
          'บัญชีออมทรัพย์',
          style: theme.textTheme.titleLarge!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.stop,
                    color: Constants.greenColors,
                    size: 24.0,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'บัญชีเงินฝาก',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15.0),
              _depositStatementData == null
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Constants.greenColors,
                      ),
                    )
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
                        )
                      : const Text('ไม่พบข้อมูลบัญชี')),
              const SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  BuildMenuButton(
                    imagePath: 'assets/images/icon-menu/icon_01.png',
                    title: 'โอน-ชำระ',
                    nextPage: SelectTransferPage(
                      member_no: _memberNo,
                      br_no: _branchNo,
                      token: widget.token,
                    ),
                    memberNo: _memberNo,
                    branchNo: _branchNo,
                  ),
                  BuildMenuButton(
                    imagePath: 'assets/images/icon-menu/icon_09.png',
                    title: 'โอนเงินไปยังธนาคาร',
                    nextPage: SharePage(
                      member_no: _memberNo,
                      br_no: _branchNo,
                    ),
                    memberNo: _memberNo,
                    branchNo: _branchNo,
                  ),
                  BuildMenuButton(
                    imagePath: 'assets/images/icon-menu/icon_06.png',
                    title: 'QR Code',
                    nextPage: SelectQrcodePage(
                      member_no: _memberNo,
                      br_no: _branchNo,
                    ),
                    memberNo: _memberNo,
                    branchNo: _branchNo,
                  ),
                ],
              ),
              const SizedBox(height: 25.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'รายการย้อนหลัง',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_list_outlined,
                            color: Colors.grey.shade700,
                            size: 20.0,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ตัวกรอง',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15.0),
                  if (_depositStatementData != null &&
                      _depositStatementData!['statement'] is List &&
                      _depositStatementData!['statement'].isNotEmpty) ...[
                    DepositStatementCard(
                      statementItems: List<Map<String, dynamic>>.from(
                        _depositStatementData!['statement'].map(
                          (item) => Map<String, dynamic>.from(item),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: Text(
                          'ไม่พบข้อมูลรายการย้อนหลัง',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20.0),
                  Center(
                    child: Text(
                      'สิ้นสุดรายการทั้งหมด',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              imagePath,
              height: 38,
              width: 38,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.widgets_outlined,
                color: Constants.greenColors,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ACC CARD STYLE
class DepositCard extends StatelessWidget {
  final String text1; // account_name
  final String text2; // available
  final String text3; // account_no
  final String text4; // account_desc
  final String text5; // balance

  const DepositCard({
    Key? key,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.text4,
    required this.text5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00');
    final double? parsedVal = double.tryParse(text2.replaceAll(',', ''));
    final String formattedAvailable =
        parsedVal != null ? formatter.format(parsedVal) : text2;
    final String cleanDesc = text4.replaceAll('บัญชี', '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Account Name (Allows wrapping if name is long)
          Text(
            text1,
            softWrap: true,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12.0),

          // Row 2: Account Number & Tag Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text3,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey.shade600,
                ),
              ),
              if (cleanDesc.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Constants.greenColors.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cleanDesc,
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

          // Divider Line
          Divider(
            color: Colors.grey.withValues(alpha: 0.15),
            height: 1,
          ),
          const SizedBox(height: 12.0),

          // Row 3: Withdrawable Balance Label & Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'ยอดเงินที่ถอนได้',
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
                    formattedAvailable,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Constants.greenColors,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'บาท',
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
}

// DepositStatementCard STYLE
class DepositStatementCard extends StatelessWidget {
  final List<Map<String, dynamic>> statementItems;

  const DepositStatementCard({
    Key? key,
    required this.statementItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: List.generate(statementItems.length, (index) {
              return DepositStatementItemTile(
                item: statementItems[index],
                isLast: index == statementItems.length - 1,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class DepositStatementItemTile extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isLast;

  const DepositStatementItemTile({
    Key? key,
    required this.item,
    this.isLast = false,
  }) : super(key: key);

  @override
  State<DepositStatementItemTile> createState() =>
      _DepositStatementItemTileState();
}

class _DepositStatementItemTileState extends State<DepositStatementItemTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDeposit = item['deposit'] != null &&
        item['deposit'] != "0.00 บาท" &&
        item['deposit'] != "0.00" &&
        item['deposit'] != "0";
    final String amountText = isDeposit
        ? (item['deposit'] ?? '')
        : (item['withdraw'] ?? '');

    final bool hasDetail1 =
        item['detail1'] != null && item['detail1'].toString().trim().isNotEmpty;
    final bool hasDetail2 =
        item['detail2'] != null && item['detail2'].toString().trim().isNotEmpty;
    final bool hasExtraDetails = hasDetail1 || hasDetail2;

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: hasExtraDetails
              ? () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Info: Detail & Date (Allows multi-line wrapping on overflow)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['detail'] ?? '',
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        item['date'] ?? '',
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12.0),

                // Amount & Arrow Toggle Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      amountText,
                      softWrap: true,
                      style: TextStyle(
                        color: isDeposit
                            ? Constants.greenColors
                            : Constants.redColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasExtraDetails) ...[
                      const SizedBox(width: 4.0),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        // Expanded Details Section (Hidden by default, wraps multiline text)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                if (hasDetail1)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isDeposit ? 'บัญชีต้นทาง' : 'บัญชีปลายทาง',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['detail1'] ?? '',
                          textAlign: TextAlign.right,
                          softWrap: true,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (hasDetail1 && hasDetail2) const SizedBox(height: 8.0),
                if (hasDetail2)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'หมายเหตุ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['detail2'] ?? '',
                          textAlign: TextAlign.right,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),

        if (!widget.isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Divider(
              color: Colors.grey.withValues(alpha: 0.15),
              height: 1,
            ),
          ),
      ],
    );
  }
}



