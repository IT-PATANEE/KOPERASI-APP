import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SelectToaccPage extends StatefulWidget {
  final List accounts;
  final int type; // ✅ เพิ่มตัวแปรเพื่อระบุประเภทธุรกรรมจากหน้าหลักชัดเจน (เช่น 18 = อัรเราะห์นู)

  SelectToaccPage({super.key, required this.accounts, required this.type});

  @override
  State<SelectToaccPage> createState() => _SelectToaccPageState();
}

class _SelectToaccPageState extends State<SelectToaccPage> {
  final formatter = NumberFormat('#,##0.00');
  String selectedAccNo = '';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context); 
    final w = media.size.width;
    final h = media.size.height;

    return Scaffold(
      backgroundColor: Constants.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: w * 0.04, vertical: h * 0.015),
              child: SizedBox(
                height: 40, 
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        _getAppBarTitle(), // ✅ แยกเคสหัวข้อตามประเภท
                        style: theme.textTheme.titleLarge!.copyWith(
                          color: Constants.greenColors,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Constants.greenColors,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.accounts.length,
                itemBuilder: (context, index) {
                  final acc = widget.accounts[index];

                  String displayAccNo = '';
                  String displayAccName = '';
                  double rawAmount = 0.0;

                  // ======================= แยกตามประเภท =======================
                  switch (widget.type) {
                    case 1: // โอนเงินฝาก
                      displayAccNo = (acc['ACCOUNT_NO'] ?? '').toString();
                      displayAccName = (acc['ACCOUNT_NAME'] ?? 'บัญชีเงินฝาก').toString();
                      rawAmount = double.tryParse(acc['BALANCE'].toString()) ?? 0.0; // ยอดเงินฝากคงเหลือ
                      break;
                    case 18: // อัรเราะห์นู (Ar-Rahnu)
                      displayAccNo = 'ยอดคงเหลือทั้งหมด';
                      displayAccName = (acc['LCONT_ID'] ?? '').toString();
                      rawAmount = double.tryParse(acc['LCONT_AMOUNT_SAL'].toString()) ?? 0.0; // ยอดคงเหลืออัรเราะห์นู
                      break;

                    case 3: // ชำระเงินกู้ (Loan)
                    case 9:
                      displayAccNo = 'ยอดคงเหลือทั้งหมด';
                      displayAccName = (acc['LCONT_ID'] ?? '').toString();
                      rawAmount = double.tryParse(acc['LCONT_AMOUNT_SAL'].toString()) ?? 0.0; // ยอดชำระเงินกู้ต่อเดือน
                      break;

                    case 5: // ชำระเงินกู้ (Loan)
                    case 10:
                      displayAccNo = 'ยอดคงเหลือทั้งหมด';
                      displayAccName = (acc['LCONT_ID'] ?? '').toString();
                      rawAmount = double.tryParse(acc['LCONT_AMOUNT_SAL'].toString()) ?? 0.0; // ยอดชำระเงินกู้ต่อเดือน
                      break;


                    default: // บัญชีเงินฝากปกติ (Deposit)
                      displayAccNo = (acc['ACCOUNT_NO'] ?? '').toString();
                      displayAccName = (acc['ACCOUNT_NAME'] ?? 'บัญชีเงินฝาก').toString();
                      rawAmount = double.tryParse(acc['BALANCE'].toString()) ?? 0.0; // ยอดเงินฝากคงเหลือ
                      break;
                  }
                  // ============================================================
                  
                  return _buildCardToAcc(
                    displayAccNo,
                    displayAccName,
                    formatter.format(rawAmount),
                    isSelected: selectedAccNo == displayAccNo,
                    onTap: () {
                      setState(() {
                        selectedAccNo = displayAccNo;
                      });
                      Navigator.pop(context, acc);
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  // ✅ ฟังก์ชันช่วยแยกเคสข้อความหัวข้อหน้าจอ
  String _getAppBarTitle() {
    switch (widget.type) {
      case 18:
        return "เลือกสัญญาอัรเราะห์นู";
      case 3:
      case 9:
        return "เลือกสัญญาเงินกู้";
      default:
        return "เลือกบัญชีปลายทาง";
    }
  }

  Widget _buildCardToAcc(
    String accNo,
    String accName,
    String balance, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Constants.greenColors, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        accName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: Constants.greenColors),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      accNo,
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    Text(
                      balance,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
}