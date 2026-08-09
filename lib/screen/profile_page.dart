import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final String member_no;
  final String br_no;
  final String token;

  const ProfilePage({
    super.key,
    required this.member_no,
    required this.br_no,
    required this.token,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile;
  late String _memberNo;
  late String _branchNo;
  late String _token;

  bool _isLoading = true;
  String _errorMessage = '';

  // เก็บข้อมูลแบบคู่ 'title' -> 'value' เพื่อหยิบใช้งานง่าย
  Map<String, String> profileData = {};

  @override
  void initState() {
    super.initState();
    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
    _token = widget.token;
    print("กำลังส่งข้อมูล: member_no=$_memberNo, br_no=$_branchNo");
    _fetchProfileData();
  }

  // 🌐 ฟังก์ชันดึงข้อมูลจาก API
  Future<void> _fetchProfileData() async {
    if (_token.isEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedToken = prefs.getString('token');
      if (savedToken != null && savedToken.isNotEmpty) {
        setState(() {
          _token = savedToken;
        });
      }
    }

    const String url = 'https://online.iscop.co.th/ws/MobileApp/profile.php';
    try {
      final response = await http.post(
        Uri.parse(url), // ใช้ URL เปล่าๆ ไม่มี ? ต่อท้าย
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type':
              'application/x-www-form-urlencoded', // กำหนดประเภทข้อมูล
        },
        body: {
          'member_no': _memberNo,
          'br_no': _branchNo,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        setState(() {
          if (jsonResponse['success'] == 1 && jsonResponse['data'] != null) {
            final List<dynamic> dataList = jsonResponse['data'];

            // วนลูปแปลงจาก List เป็น Map เพื่อให้ฟังก์ชัน _getValueOf ทำงานได้
            profileData = {
              for (var item in dataList)
                if (item['title'] != null && item['value'] != null)
                  item['title'].toString(): item['value'].toString()
            };

            _errorMessage = '';
          } else {
            _errorMessage =
                jsonResponse['error'] ?? 'เกิดข้อผิดพลาดในการดึงข้อมูล';
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'การเชื่อมต่อเซิร์ฟเวอร์ล้มเหลว (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ไม่สามารถเชื่อมต่อเครือข่ายได้';
        _isLoading = false;
      });
    }
  }

  // ดึงข้อมูลปลอดภัย ป้องกันแอปแครชหากไม่พบคีย์
  String _getValueOf(String titleKey, {String defaultValue = '-'}) {
    return profileData[titleKey] ?? defaultValue;
  }

  Future<void> _pickImage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เปิดคลังภาพเพื่อเปลี่ยนรูปโปรไฟล์')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final h = media.size.height;
    final appBarExpandedHeight = h * 0.32;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Constants.greenColors),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Constants.greenColors,
          leading: const BackButton(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Constants.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            backgroundColor: Constants.greenColors,
            elevation: 0,
            pinned: true,
            expandedHeight: appBarExpandedHeight,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            title: Text(
              'ข้อมูลทั่วไป',
              style: theme.textTheme.titleLarge!.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  color: Constants.greenColors,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildProfileHeaderContent(),
                    SizedBox(height: h * 0.03),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatusSection(),
                const SizedBox(height: 16),

                // กลุ่มที่ 1: ข้อมูลส่วนตัวและสมาชิก
                _buildInfoCard(
                  title: 'ข้อมูลทั่วไป',
                  icon: Icons.person_outline,
                  items: [
                    _buildInfoRow(
                        'เลขประจำตัวประชาชน', _getValueOf('บัตรประชาชน')),
                    _buildInfoRow(
                        'วันเดือนปีเกิด', _getValueOf('วันเดือนปีเกิด')),
                    _buildInfoRow('อายุ', _getValueOf('อายุ')),
                    _buildInfoRow('วันที่เข้าเป็นสมาชิก',
                        _getValueOf('วันที่เข้าเป็นสมาชิก')),
                    _buildInfoRow(
                        'อายุการเป็นสมาชิก', _getValueOf('อายุการเป็นสมาชิก')),
                    _buildInfoRow('สาขาที่สังกัด', _getValueOf('สาขา')),
                  ],
                ),
                const SizedBox(height: 16),

                // กลุ่มที่ 2: การทำงานและรายได้
                _buildInfoCard(
                  title: 'การทำงานและรายได้',
                  icon: Icons.work_outline,
                  items: [
                    _buildInfoRow('อาชีพ', _getValueOf('อาชีพ')),
                    _buildInfoRow('ที่ทำงาน', _getValueOf('ที่ทำงาน')),
                    _buildInfoRow('เงินเดือน', _getValueOf('เงินเดือน')),
                  ],
                ),
                const SizedBox(height: 16),

                // กลุ่มที่ 3: ช่องทางการติดต่อ
                _buildInfoCard(
                  title: 'ช่องทางการติดต่อ',
                  icon: Icons.contact_mail_outlined,
                  items: [
                    _buildInfoRow('ที่อยู่ปัจจุบัน', _getValueOf('ที่อยู่')),
                    _buildInfoRow('ที่อยู่จัดส่งเอกสาร',
                        _getValueOf('ที่อยู่จัดส่งเอกสาร')),
                    _buildInfoRow(
                        'โทรศัพท์มือถือ', _getValueOf('โทรศัพท์มือถือ')),
                    _buildInfoRow('โทรศัพท์บ้าน', _getValueOf('โทรศัพท์บ้าน')),
                    _buildInfoRow('อีเมล', _getValueOf('อีเมล์')),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderContent() {
    String avatarUrl = _getValueOf('รูปสมาชิก', defaultValue: '');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (avatarUrl.isNotEmpty && avatarUrl.startsWith('http')
                          ? NetworkImage(avatarUrl)
                          : const AssetImage(
                              'assets/images/avatar_man.png')) as ImageProvider,
                ),
              ),
            ),
            InkWell(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Constants.greenColors,
                  child: const Icon(
                    Icons.camera_alt,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _getValueOf('ชื่อ - สกุล', defaultValue: 'ไม่ระบุชื่อ'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'เลขทะเบียนสมาชิก : ${_getValueOf('เลขทะเบียนสมาชิก')}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.85),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusBadge(
            'ประเภทสมาชิก',
            _getValueOf('ประเภทสมาชิก'),
            Colors.blue.shade50,
            Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusBadge(
            'สถานภาพ',
            _getValueOf('สถานภาพสมาชิก'),
            Colors.green.shade50,
            Constants.greenColors,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
      String label, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Constants.greenColors),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
