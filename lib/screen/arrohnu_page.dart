import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/screen/aroohnuStatement_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ArrohnuPage extends StatefulWidget {
  final String member_no;
  final String br_no;
  const ArrohnuPage({Key? key, required this.member_no, required this.br_no})
      : super(key: key);

  @override
  State<ArrohnuPage> createState() => _ArrohnuPageState();
}

class _ArrohnuPageState extends State<ArrohnuPage> {
  List<Map<String, dynamic>> _arrohnus = [];
  bool _isLoading = true;

  late String _memberNo;
  late String _branchNo;

  @override
  void initState() {
    super.initState();
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
    fetchLoanData();
  }

  Future<void> fetchLoanData() async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    String url = 'https://online.iscop.co.th/ws/MobileApp/arrohnu.php';
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

        if (jsonResponse['success'] == 1 && jsonResponse['data'] != null) {
          setState(() {
            _arrohnus = List<Map<String, dynamic>>.from(jsonResponse['data']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _arrohnus = [];
            _isLoading = false;
          });
          print('Error: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      print("Error fetching data: $error");
      setState(() {
        _arrohnus = [];
        _isLoading = false;
      });
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
          'สินเชื่ออัร-เราะห์นู',
          style: theme.textTheme.titleLarge!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Constants.greenColors,
              ),
            )
          : _arrohnus.isEmpty
              ? const Center(
                  child: Text(
                    'ไม่พบข้อมูลสินเชื่ออัร-เราะห์นู',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Padding(
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
                            'สินเชื่อของฉัน',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15.0),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _arrohnus.length,
                          itemBuilder: (context, index) {
                            final arrohnu = _arrohnus[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 15.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ArrohnuStatementPage(
                                        loanNo: arrohnu['loan_no'] ?? '',
                                        loanId: arrohnu['loan_no_th'] ?? '',
                                        member_no: _memberNo,
                                        br_no: _branchNo,
                                      ),
                                    ),
                                  );
                                },
                                child: LoanCard(
                                  text1: arrohnu['loan_no_th'] ?? '',
                                  text2: arrohnu['balance'] ?? '',
                                  text3: arrohnu['period_total'] ?? '',
                                  text4: arrohnu['period_pay'] ?? '',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// LoanCard STYLE
class LoanCard extends StatelessWidget {
  final String text1;
  final String text2;
  final String text3;
  final String text4;

  const LoanCard({
    Key? key,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.text4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00');
    final double? parsedVal = double.tryParse(text2.replaceAll(',', ''));
    final String formattedBalance =
        parsedVal != null ? formatter.format(parsedVal) : text2;

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
          // Row 1: Contract No
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

          // Row 2: Remaining Balance Label & Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'สินเชื่อคงเหลือ',
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

          // Row 3: Period Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'จำนวนงวด',
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
          const SizedBox(height: 8.0),

          // Row 4: Period Pay
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ชำระต่องวด',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                text4,
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
