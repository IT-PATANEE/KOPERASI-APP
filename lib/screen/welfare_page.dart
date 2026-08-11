import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class WelfarePage extends StatefulWidget {
  final String member_no;
  final String br_no;
  final String? token;

  const WelfarePage({
    Key? key,
    required this.member_no,
    required this.br_no,
    this.token,
  }) : super(key: key);

  @override
  State<WelfarePage> createState() => _WelfarePageState();
}

class _WelfarePageState extends State<WelfarePage> {
  late String _memberNo;
  late String _branchNo;
  String _token = '';
  bool _isLoading = true;

  Map<String, dynamic>? _welfareData;
  String _selectedYear = 'ทั้งหมด';
  List<String> _availableYears = ['ทั้งหมด'];

  @override
  void initState() {
    super.initState();
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
    //  _memberNo = '48571';
    // _branchNo = '001';
    _token = widget.token ?? '';
    _fetchWelfareData();
  }

  Future<void> _fetchWelfareData() async {
    setState(() {
      _isLoading = true;
    });

    if (_token.isEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedToken = prefs.getString('token');
      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
      }
    }

    String url = 'https://online.iscop.co.th/ws/MobileApp/load_require_w.php';

    Map<String, dynamic> defaultData = {
      'member_no': _memberNo,
      'member_name': 'สมาชิกสหกรณ์',
      'share_amount': '0.00',
      'birth_age': '-',
      'member_date': '-',
      'member_age': '-',
      'history': [],
      'categories': _getWelfareCategories(),
    };

    try {
      print("DEBUG: Fetching Welfare API -> $url (member_no=$_memberNo, br_no=$_branchNo)");
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'member_no': _memberNo,
          'br_no': _branchNo,
        },
      ).timeout(const Duration(seconds: 8));

      print("DEBUG: Welfare API Status -> ${response.statusCode}");
      print("DEBUG: Welfare API Body -> ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final bool isSuccess = jsonResponse['success'] == 1 ||
            jsonResponse['success'] == "1" ||
            jsonResponse['success'] == true;

        if (isSuccess && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          if (data is Map<String, dynamic>) {
            defaultData.addAll(data);
          }
        }
      }
    } catch (e) {
      print("DEBUG: Welfare API error -> $e");
    }

    setState(() {
      _welfareData = defaultData;
      _extractYears();
      _isLoading = false;
    });
  }

  void _extractYears() {
    final history = _welfareData?['history'] as List?;
    if (history != null && history.isNotEmpty) {
      Set<String> years = {'ทั้งหมด'};
      for (var item in history) {
        if (item['year'] != null && item['year'].toString().isNotEmpty) {
          years.add(item['year'].toString());
        }
      }
      _availableYears = years.toList();
    } else {
      _availableYears = ['ทั้งหมด'];
    }
  }

  List<Map<String, dynamic>> _getWelfareCategories() {
    return [
      {
        'id': '1',
        'title': 'เจ็บป่วยเข้าโรงพยาบาล',
        'icon': Icons.local_hospital_outlined,
        'description':
            'วงเงิน 600 บาท/ปี (ปีละไม่เกิน 2 ครั้ง) คืนละ 100 บาท แต่ไม่เกิน 300 บาทต่อครั้ง\n• ต้องเป็นสมาชิกอย่างน้อย 3 ปี\n• มีใบรับรองแพทย์เป็นหลักฐาน',
      },
      {
        'id': '2',
        'title': 'สวัสดิการคลอดบุตร',
        'icon': Icons.child_care_outlined,
        'description':
            'วงเงิน 300 บาท (สมาชิกสหกรณ์) / 500 บาท (สมาชิกสหกรณ์และตะอาวุน)\n• ต้องเป็นสมาชิกอย่างน้อย 3 ปี\n• เบิกได้ครอบครัวละไม่เกิน 2 คน ภายใน 6 เดือนนับจากวันคลอด',
      },
      {
        'id': '3',
        'title': 'สวัสดิการชราภาพ',
        'icon': Icons.elderly_outlined,
        'description':
            'วงเงิน 1,200 บาทต่อคน\n• ต้องเป็นสมาชิก 15 ปีขึ้นไป และอายุ 65 ปีขึ้นไป\n• ไม่ขาดส่งหุ้นติดต่อกันเกินกำหนด',
      },
      {
        'id': '4',
        'title': 'กรณีเสียชีวิต / มรณกรรม',
        'icon': Icons.shield_outlined,
        'description':
            'วงเงิน ศพละ 2,000 บาท\n• ต้องเป็นสมาชิกอย่างน้อย 6 เดือน\n• ไม่ขาดส่งหุ้นติดต่อกันเกินกำหนด (หรือมีหุ้น 50,000 บาทขึ้นไป)',
      },
    ];
  }

  IconData _getIconForCategory(String title, String id) {
    if (title.contains('เจ็บป่วย') || id == '1') {
      return Icons.local_hospital_outlined;
    } else if (title.contains('คลอด') || id == '2') {
      return Icons.child_care_outlined;
    } else if (title.contains('ชราภาพ') || id == '3') {
      return Icons.elderly_outlined;
    } else if (title.contains('เสียชีวิต') || title.contains('มรณกรรม') || id == '4') {
      return Icons.shield_outlined;
    }
    return Icons.card_giftcard;
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
          'สวัสดิการสมาชิก',
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HEADER CARD (Share & Member Duration)
                  _buildHeaderCard(),

                  const SizedBox(height: 25.0),

                  // 2. YEARLY WELFARE HISTORY SECTION
                  _buildHistorySection(),

                  const SizedBox(height: 25.0),

                  // 3. WELFARE CATALOG & DETAILS SECTION
                  _buildCatalogSection(),

                  const SizedBox(height: 20.0),
                ],
              ),
            ),
    );
  }

  // Header Card showing Member Shares & Member Duration
  Widget _buildHeaderCard() {
    final String shareRaw =
        (_welfareData?['share_amount'] ?? '0.00').toString();
    final formatter = NumberFormat('#,##0.00');
    final double? parsedVal = double.tryParse(shareRaw.replaceAll(',', ''));
    final String formattedShare =
        parsedVal != null ? formatter.format(parsedVal) : shareRaw;

    final String memberName =
        (_welfareData?['member_name'] ?? 'สมาชิกสหกรณ์').toString();
    final String fullMemberNo = (_welfareData?['full_member_no'] ?? '').toString().isNotEmpty
        ? _welfareData!['full_member_no'].toString()
        : '$_branchNo-01-$_memberNo';
    final String birthAge = (
      _welfareData?['birth_age'] ??
      _welfareData?['member_birth_age'] ??
      _welfareData?['birth_age_str'] ??
      '-'
    ).toString();
    final String memberAge =
        (_welfareData?['member_age'] ?? '-').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member Name & Code Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memberName,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'เลขทะเบียนสมาชิก: $fullMemberNo',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Member Shares Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'ทุนเรือนหุ้นสะสม',
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
                    formattedShare,
                    style: TextStyle(
                      fontSize: 22,
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

          Divider(
            color: Colors.grey.withValues(alpha: 0.15),
            height: 1,
          ),
          const SizedBox(height: 12.0),

          // Member Age & Membership Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'สมาชิกอายุ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                birthAge,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'อายุการเป็นสมาชิก',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                memberAge,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Yearly History Section
  Widget _buildHistorySection() {
    final rawHistory = _welfareData?['history'] as List? ?? [];
    List filteredHistory = rawHistory;

    if (_selectedYear != 'ทั้งหมด') {
      filteredHistory = rawHistory
          .where((item) => item['year'].toString() == _selectedYear)
          .toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Right-Aligned Year Filter Dropdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.stop,
                  color: Constants.greenColors,
                  size: 24.0,
                ),
                const SizedBox(width: 8),
                const Text(
                  'ประวัติการใช้สวัสดิการ',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            // Year Selector Dropdown (Right-aligned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.25),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedYear,
                  isDense: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Constants.greenColors,
                    size: 20,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Constants.greenColors,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedYear = newValue;
                      });
                    }
                  },
                  items: _availableYears.map<DropdownMenuItem<String>>((String year) {
                    return DropdownMenuItem<String>(
                      value: year,
                      child: Text(
                        year == 'ทั้งหมด' ? 'เลือกปี: ทั้งหมด' : 'ปี $year',
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),

        // History List Items
        if (filteredHistory.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: const Center(
              child: Text(
                'ไม่พบประวัติการใช้สวัสดิการในปีที่เลือก',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: List.generate(filteredHistory.length, (index) {
                    final item = filteredHistory[index];
                    final isLast = index == filteredHistory.length - 1;
                    final String reqNo = (item['req_no'] ?? '').toString();

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: Welfare Title, Date, Request Number
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (item['title'] ?? '').toString(),
                                      softWrap: true,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6.0),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'วันที่: ${(item['date'] ?? '-').toString()}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (reqNo.isNotEmpty) ...[
                                      const SizedBox(height: 3.0),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.assignment_outlined,
                                            size: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'เลขที่คำขอ: $reqNo',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Right: Amount & Status Pill
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    (item['amount'] ?? '').toString(),
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
                        if (!isLast)
                          Divider(
                            color: Colors.grey.withValues(alpha: 0.15),
                            height: 1,
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Catalog Section listing welfare categories & external links
  Widget _buildCatalogSection() {
    final categories = _welfareData?['categories'] as List? ?? _getWelfareCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.stop,
              color: Constants.greenColors,
              size: 24.0,
            ),
            const SizedBox(width: 8),
            const Text(
              'รายละเอียดสวัสดิการสหกรณ์',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15.0),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final String title = (cat['title'] ?? '').toString();
            final String description = (cat['description'] ?? '').toString();
            final String catId = (cat['id'] ?? '').toString();
            
            IconData icon = cat['icon'] as IconData? ?? Icons.card_giftcard;
            if (cat['icon'] == null) {
              icon = _getIconForCategory(title, catId);
            }

            return Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12.0),
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
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    iconColor: Constants.greenColors,
                    collapsedIconColor: Colors.grey.shade600,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Constants.greenColors.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Constants.greenColors,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      title,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    children: [
                      const SizedBox(height: 4.0),
                      Text(
                        description,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
