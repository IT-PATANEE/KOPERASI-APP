
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/screen/loanStatement_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LoanPage extends StatefulWidget {
  final String member_no;
  final String br_no;
  const LoanPage({Key? key, required this.member_no, required this.br_no})
      : super(key: key);

  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  List<Map<String, dynamic>> _loans = [];
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

    String url = 'https://online.iscop.co.th/ws/MobileApp/loan.php';
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
            _loans = List<Map<String, dynamic>>.from(jsonResponse['data']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _loans = [];
            _isLoading = false;
          });
          print('Error: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      setState(() {
        _loans = [];
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
          'สินเชื่อ',
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
          : _loans.isEmpty
              ? const Center(
                  child: Text(
                    'ไม่พบข้อมูลสินเชื่อ',
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
                          itemCount: _loans.length,
                          itemBuilder: (context, index) {
                            final loan = _loans[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 15.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoanstatementPage(
                                        loanNo: loan['loan_no'] ?? '',
                                        loanId: loan['loan_no_th'] ?? '',
                                        member_no: _memberNo,
                                        br_no: _branchNo,
                                      ),
                                    ),
                                  );
                                },
                                child: LoanCard(
                                  text1: loan['loan_no_th'] ?? '',
                                  text2: loan['balance'] ?? '',
                                  text3: loan['period_total'] ?? '',
                                  text4: loan['period_pay'] ?? '',
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
  final String text1; // loan_no_th
  final String text2; // balance
  final String text3; // period_total
  final String text4; // period_pay

  const LoanCard({
    super.key,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.text4,
  });

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
          // Row 1: Loan Contract No
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

          // Row 2: Remaining Loan Balance Label & Amount
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

