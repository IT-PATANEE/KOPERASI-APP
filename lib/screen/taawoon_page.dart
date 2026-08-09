import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/screen/share_page.dart';
import 'package:koperasiapp/screen/selecttransfer_page.dart';
import 'package:koperasiapp/screen/selectqrcode_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TaawoonPage extends StatefulWidget {
  final String member_no;
  final String br_no;
  const TaawoonPage({Key? key, required this.member_no, required this.br_no})
      : super(key: key);

  @override
  State<TaawoonPage> createState() => _TaawoonPageState();
}

class _TaawoonPageState extends State<TaawoonPage> {
  late String _memberNo;
  late String _branchNo;
  String _token = '';
  Map<String, dynamic>? _taawoonData;

  @override
  void initState() {
    super.initState();
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
    fetchShareData();
  }

  Future<void> fetchShareData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      setState(() {
        _token = token;
      });
    }

    String url = 'https://online.iscop.co.th/ws/MobileApp/taawoon.php';
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
            _taawoonData = jsonResponse['data'];
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
          'ตะอาวุน',
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
                    'ตะอาวุน',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15.0),
              _taawoonData == null
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Constants.greenColors,
                      ),
                    )
                  : (_taawoonData!['master'] != null &&
                          _taawoonData!['master'].isNotEmpty
                      ? TaawoonCard(
                          text1: _taawoonData!['master']['taw_id'] ?? '',
                          text2: _taawoonData!['master']['taw_date'] ?? '',
                          text3: _taawoonData!['master']['taw_group'] ?? '',
                          text4: _taawoonData!['master']['taw_amount'] ?? '',
                          text5:
                              _taawoonData!['master']['taw_exc_date'] ?? '',
                        )
                      : const Text('ไม่พบข้อมูลรายละเอียดตะอาวุน')),
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
                  if (_taawoonData != null &&
                      _taawoonData!['statement'] is List &&
                      _taawoonData!['statement'].isNotEmpty) ...[
                    TaawoonStatementCard(
                      statementItems: List<Map<String, dynamic>>.from(
                        _taawoonData!['statement'].map(
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

// TaawoonCard STYLE
class TaawoonCard extends StatelessWidget {
  final String text1; // taw_id
  final String text2; // taw_date
  final String text3; // taw_group
  final String text4; // taw_amount
  final String text5; // taw_exc_date

  const TaawoonCard({
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
    final double? parsedVal = double.tryParse(text4.replaceAll(',', ''));
    final String formattedBalance =
        parsedVal != null ? formatter.format(parsedVal) : text4;

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
          // Row 1: Member ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'รหัสสมาชิก',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                text1,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Row 2: Total Savings Label & Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'รวมเงินสะสม',
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
                    formattedBalance,
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

          // Details Rows
          if (text2.trim().isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'วันที่เป็นสมาชิก',
                  style: TextStyle(
                    fontSize: 14,
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
            const SizedBox(height: 8.0),
          ],
          if (text3.trim().isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'สังกัดกลุ่ม',
                  style: TextStyle(
                    fontSize: 14,
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
            const SizedBox(height: 8.0),
          ],
          if (text5.trim().isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'วันที่กำหนดครบชำระ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  text5,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// TaawoonStatementCard STYLE
class TaawoonStatementCard extends StatelessWidget {
  final List<Map<String, dynamic>> statementItems;

  const TaawoonStatementCard({
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
              return TaawoonStatementItemTile(
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

class TaawoonStatementItemTile extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isLast;

  const TaawoonStatementItemTile({
    Key? key,
    required this.item,
    this.isLast = false,
  }) : super(key: key);

  @override
  State<TaawoonStatementItemTile> createState() => _TaawoonStatementItemTileState();
}

class _TaawoonStatementItemTileState extends State<TaawoonStatementItemTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    const String titleText = 'ชำระตะอาวุน';
    final String dateText = (item['taw_date_today'] ?? '').toString();
    final String amountText = (item['taw_amount'] ?? '').toString();

    final String payTimeText = (item['taw_pay_time'] ?? '').toString();
    final String yearText = (item['taw_year'] ?? '').toString();
    final String periodYearStr = (payTimeText.isNotEmpty || yearText.isNotEmpty)
        ? '$payTimeText/$yearText'
        : '';
    final String payYearText = (item['taw_pay_year'] ?? '').toString();
    final String maintainText = (item['taw_maintain'] ?? '').toString();
    final String receiptText = (item['taw_receipt_no'] ?? '').toString();

    final bool hasPeriodYear = periodYearStr.trim().isNotEmpty;
    final bool hasPayYear = payYearText.trim().isNotEmpty;
    final bool hasMaintain = maintainText.trim().isNotEmpty;
    final bool hasReceipt = receiptText.trim().isNotEmpty;
    final bool hasExtraDetails =
        hasPeriodYear || hasPayYear || hasMaintain || hasReceipt;

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
                      Text(
                        titleText,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (dateText.isNotEmpty) ...[
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
                if (hasPeriodYear)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'งวดที่/ประจำปี',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          periodYearStr,
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
                if (hasPeriodYear &&
                    (hasPayYear || hasMaintain || hasReceipt))
                  const SizedBox(height: 8.0),
                if (hasPayYear)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'เงินสะสมรายปี',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          payYearText,
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
                if (hasPayYear && (hasMaintain || hasReceipt))
                  const SizedBox(height: 8.0),
                if (hasMaintain)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ค่าบำรุงรายปี',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          maintainText,
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
                if (hasMaintain && hasReceipt) const SizedBox(height: 8.0),
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

