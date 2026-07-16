import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SelectToaccPage extends StatefulWidget {
  final List accounts;
  final int type;

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
                        _getAppBarTitle(),
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

                  String displayTitle =
                      ''; // ข้อความหัวการ์ด (เช่น เลขบัญชี หรือ เลขสัญญา)
                  String displaySubtitle =
                      ''; // ข้อความบรรทัดล่างซ้าย (เช่น บัญชีเงินฝาก หรือ ยอดคงเหลือทั้งหมด)
                  String desc = ''; // สถานะข้อความภาษาไทยในตลับ Badge
                  double rawAmount = 0.0;

                  // กำหนดแมปแปลงสถานะสำหรับกลุ่มเงินกู้/อัรเราะห์นู
                  final Map<String, String> lcontStatusFlags = {
                    "1": "ชำระได้ตามปกติ",
                    "4": "หมดสัญญา",
                  };
                  final String statusFlag =
                      (acc['LCONT_STATUS_FLAG'] ?? '').toString().trim();

                  // ======================= แยกการจัดกลุ่มข้อมูลตามประเภทธุรกรรม =======================
                  switch (widget.type) {
                    case 1: // โอนเงินฝาก
                    case 2:
                      displayTitle = (acc['ACCOUNT_NO'] ?? '').toString();
                      displaySubtitle =
                          (acc['ACCOUNT_NAME'] ?? 'บัญชีเงินฝาก').toString();
                      desc = (acc['ACC_DESC'] ?? 'เงินฝากออมทรัพย์').toString();
                      rawAmount =
                          double.tryParse(acc['BALANCE'].toString()) ?? 0.0;
                      break;

                    case 3:
                      displayTitle = (acc['LCONT_ID'] ?? '')
                          .toString(); // เอาเลขสัญญาขึ้นหัวการ์ด
                      displaySubtitle = 'ยอดคงเหลือทั้งหมด';
                      desc = lcontStatusFlags[statusFlag] ?? 'สัญญาเงินกู้';
                      rawAmount =
                          double.tryParse(acc['LCONT_AMOUNT_SAL'].toString()) ??
                              0.0;
                      break;
                    case 9:
                      displayTitle = (acc['LCONT_ID'] ?? '')
                          .toString(); // เอาเลขสัญญาขึ้นหัวการ์ด
                      displaySubtitle = 'ยอดชำระต่อเดือน';
                      desc = lcontStatusFlags[statusFlag] ?? 'สัญญาเงินกู้';
                      rawAmount =
                          double.tryParse(acc['LCONT_INTESAL'].toString()) ??
                              0.0;
                      break;

                    case 18: // อัรเราะห์นู (Ar-Rahnu)
                      displayTitle = (acc['LCONT_ID'] ?? '').toString();
                      displaySubtitle = 'ยอดคงเหลือทั้งหมด';
                      desc = lcontStatusFlags[statusFlag] ?? 'อัรเราะห์นู';
                      rawAmount =
                          double.tryParse(acc['LCONT_AMOUNT_SAL'].toString()) ??
                              0.0;
                      break;
                    case 19:
                      displayTitle = (acc['LCONT_ID'] ?? '').toString();
                      displaySubtitle = 'ยอดคงเหลือทั้งหมด';
                      desc = lcontStatusFlags[statusFlag] ?? 'อัรเราะห์นู';
                      rawAmount =
                          double.tryParse(acc['LCONT_AMOUNT_SAL'].toString()) ??
                              0.0;
                      break;
                  }
                  // ============================================================================

                  final String uniqueId = displayTitle;

                  return _buildCardToAcc(
                    title: displayTitle,
                    subtitle: displaySubtitle,
                    balance: formatter.format(rawAmount),
                    badgeText: desc,
                    isSelected: selectedAccNo == uniqueId,
                    onTap: () {
                      setState(() {
                        selectedAccNo = uniqueId;
                      });
                      Future.delayed(const Duration(milliseconds: 180), () {
                        if (mounted) Navigator.pop(context, acc);
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

  String _getAppBarTitle() {
    switch (widget.type) {
      case 3:
      case 9:
      case 18:
      case 19:
        return "เลือกสัญญาปลายทาง";
      default:
        return "เลือกบัญชีปลายทาง";
    }
  }

  Widget _buildCardToAcc({
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
                                color: Constants.greenColors,
                              ),
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
                const SizedBox(height: 12),
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
                        Text(
                          "บาท",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
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
}
