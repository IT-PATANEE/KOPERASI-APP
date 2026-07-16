import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SelectToqrPage extends StatefulWidget {
  final List accounts;
  final int type;

  SelectToqrPage({super.key, required this.accounts, required this.type});

  @override
  State<SelectToqrPage> createState() => _SelectToqrPageState();
}

class _SelectToqrPageState extends State<SelectToqrPage> {
  final formatter = NumberFormat('#,##0.00');
  String selectedLoanId = '';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final w = media.size.width;
    final h = media.size.height;

    // 🟢 แยกข้อความหัวเรื่องตามเคส
    String pageTitle = "เลือกบัญชีสัญญาสินเชื่อ";
    if (widget.type == 4) {
      pageTitle = "เลือกเลขที่สัญญาอัรเราะห์นู";
    }

    return Scaffold(
      backgroundColor: Constants.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ส่วนหัวข้อด้านบน (App Bar)
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
                        pageTitle,
                        style: theme.textTheme.titleLarge!.copyWith(
                          color: Constants.greenColors,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.close, color: Constants.greenColors),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ส่วนแสดงรายการ
            Expanded(
              child: widget.accounts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: widget.accounts.length,
                      itemBuilder: (context, index) {
                        final item = widget.accounts[index];

                        // 🕵️‍♂️ [จุดเช็คสำคัญ] พิมพ์ Log เจาะจงออกมาเลยว่ารอบนี้แอปกำลังวาดไอเทมที่เท่าไหร่ และมีคีย์อะไรอยู่ข้างใน
                        print("====== [BUILDING ITEM $index] ======");
                        print(
                            "คีย์ที่มีทั้งหมดในไอเทมนี้: ${item.keys.toList()}");
                        print("ค่า LCONT_ID: ${item['LCONT_ID']} ${item['LREG_SALINT']} ${item['LREG_SALINT_BK']}");
                        print("====================================");

                        String loanId = '';
                        double amountValue = 0.0;
                        String balanceTitle = '';
                        String loanDesc = '';

                        switch (widget.type) {
                          case 3: // Type 3
                            loanId = (item['LCONT_ID'] ?? 'ไม่ระบุ').toString();

                            final rawAmount3 = (item['LREG_SALINT'] ?? '0')
                                .toString()
                                .replaceAll(',', '');
                            amountValue = double.tryParse(rawAmount3) ?? 0.0;

                            balanceTitle = 'ยอดชำระต่อเดือน';

                            final Map<String, String> lcontStatusFlags = {
                              "1": "ชำระได้ตามปกติ",
                              "4": "หมดสัญญา"
                            };
                            final String statusFlag =
                                (item['LCONT_STATUS_FLAG'] ?? '')
                                    .toString()
                                    .trim();
                            loanDesc =
                                lcontStatusFlags[statusFlag] ?? 'สัญญาเงินกู้';
                            break;

                          case 4: // Type 4
                            loanId = (item['LCONT_ID'] ?? 'ไม่ระบุ').toString();

                            final rawAmount4 = (item['LREG_SALINT'] ?? '0')
                                .toString()
                                .replaceAll(',', '');
                            amountValue = double.tryParse(rawAmount4) ?? 0.0;

                            balanceTitle = 'ยอดชำระต่อเดือน';

                            final Map<String, String> lcontStatusFlags = {
                              "1": "ชำระได้ตามปกติ",
                              "4": "หมดสัญญา"
                            };
                            final String statusFlag =
                                (item['LCONT_STATUS_FLAG'] ?? '')
                                    .toString()
                                    .trim();
                            loanDesc =
                                lcontStatusFlags[statusFlag] ?? 'สัญญาเงินกู้';
                            break;

                          default:
                            loanId = 'ไม่ระบุ';
                            balanceTitle = 'ยอดเงิน';
                            loanDesc = 'สัญญา';
                        }

                        return _buildAccountItemCard(
                          title: loanId,
                          subtitle: balanceTitle,
                          balance: formatter.format(amountValue),
                          badgeText: loanDesc,
                          isSelected: selectedLoanId == loanId,
                          onTap: () {
                            setState(() {
                              selectedLoanId = loanId;
                            });
                            Future.delayed(const Duration(milliseconds: 180),
                                () {
                              if (mounted) Navigator.pop(context, item);
                            });
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

  // UI การ์ดแสดงผลส่วนกลาง (แชร์ฟังก์ชันกันเพื่อความประหยัดโค้ด)
  Widget _buildAccountItemCard({
    required String title,
    required String subtitle,
    required String balance,
    required String badgeText,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? Constants.greenColors.withValues(alpha: 0.02)
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Constants.greenColors.withValues(alpha: 0.08)
                : Constants.greenColors.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected
                    ? Constants.greenColors
                    : Colors.grey.withValues(alpha: 0.15),
                width: isSelected ? 2 : 1,
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
                        title,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Constants.greenColors
                                : Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (badgeText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  Constants.greenColors.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Constants.greenColors),
                            ),
                          ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle,
                              color: Constants.greenColors, size: 22),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey.withValues(alpha: 0.08), height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      subtitle,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          balance,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isSelected
                                  ? Constants.greenColors
                                  : Colors.black87),
                        ),
                        const SizedBox(width: 4),
                        Text("บาท",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'ไม่พบข้อมูลเลขที่สัญญาสินเชื่อ',
            style: TextStyle(fontSize: 15, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
