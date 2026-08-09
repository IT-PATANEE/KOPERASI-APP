import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/screen/selecttransfer_page.dart';
import 'package:koperasiapp/screen/selectqrcode_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
    String? token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      setState(() {
        _token = token;
      });
    }

    String url = 'https://online.iscop.co.th/ws/MobileApp/share.php';
    String fullUrl = '$url?member_no=$_memberNo&br_no=$_branchNo&token=$token';

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
            _shareData = jsonResponse['data'];
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
  void initState() {
    super.initState();
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
    fetchShareData();
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
          'ทุนเรือนหุ้น',
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
                    'หุ้นสมาชิก',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15.0),
              _shareData == null
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Constants.greenColors,
                      ),
                    )
                  : (_shareData!['master'] != null &&
                          _shareData!['master'].isNotEmpty
                      ? ShareCard(
                          text1: _shareData!['master']['share_accu'] ?? '',
                          text2: _shareData!['master']['share_sum_qty'] ?? '',
                          text3: _shareData!['master']['share_amount'] ?? '',
                        )
                      : const Text('ไม่พบข้อมูลหุ้น')),
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
                      token: _token,
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
                  if (_shareData != null &&
                      _shareData!['statement'] is List &&
                      _shareData!['statement'].isNotEmpty) ...[
                    ShareStatementCard(
                      statementItems: List<Map<String, dynamic>>.from(
                        _shareData!['statement'].map(
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

// ShareCard STYLE
class ShareCard extends StatelessWidget {
  final String text1; // share_accu
  final String text2; // share_sum_qty
  final String text3; // share_amount

  const ShareCard({
    Key? key,
    required this.text1,
    required this.text2,
    required this.text3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00');
    final double? parsedVal = double.tryParse(text1.replaceAll(',', ''));
    final String formattedAccu =
        parsedVal != null ? formatter.format(parsedVal) : text1;

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
          // Row 1: Accumulated Share
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'หุ้นสะสม',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    formattedAccu,
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
          const SizedBox(height: 14.0),

          // Divider Line
          Divider(
            color: Colors.grey.withValues(alpha: 0.15),
            height: 1,
          ),
          const SizedBox(height: 12.0),

          // Row 2: Remaining Share Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'จำนวนหุ้นคงเหลือ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                text2,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Row 3: Monthly Share Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'หุ้นรายเดือน',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                text3,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ShareStatementCard STYLE
class ShareStatementCard extends StatelessWidget {
  final List<Map<String, dynamic>> statementItems;

  const ShareStatementCard({
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
              return ShareStatementItemTile(
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

class ShareStatementItemTile extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isLast;

  const ShareStatementItemTile({
    Key? key,
    required this.item,
    this.isLast = false,
  }) : super(key: key);

  @override
  State<ShareStatementItemTile> createState() => _ShareStatementItemTileState();
}

class _ShareStatementItemTileState extends State<ShareStatementItemTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final String amountText = (item['share_amount'] ?? '').toString();
    final String dateText = (item['share_date'] ?? '').toString();
    final String periodText = (item['share_period'] ?? '').toString();
    final String accuText = (item['share_accu'] ?? '').toString();
    final String receiptText = (item['receipt_no'] ?? '').toString();

    final bool hasPeriod = periodText.trim().isNotEmpty;
    final bool hasAccu = accuText.trim().isNotEmpty;
    final bool hasReceipt = receiptText.trim().isNotEmpty;
    final bool hasExtraDetails = hasPeriod || hasAccu || hasReceipt;

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
                // Title & Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ฝากหุ้น',
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        dateText,
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

                // Amount & Arrow Toggle Icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      amountText,
                      softWrap: true,
                      style: TextStyle(
                        color: Constants.greenColors,
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

        // Expanded Details Section
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
                if (hasPeriod)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'จำนวนงวด',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          periodText,
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
                if (hasPeriod && (hasAccu || hasReceipt))
                  const SizedBox(height: 8.0),
                if (hasAccu)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'หุ้นสะสม',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          accuText,
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
                if (hasAccu && hasReceipt) const SizedBox(height: 8.0),
                if (hasReceipt)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'เลขที่ใบเสร็จ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          receiptText,
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

