import 'dart:io';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
// import 'package:image_picker/image_picker.dart'; // 📌 สำหรับเปิดกล้อง/อัลบั้มเพื่อเปลี่ยนรูป

class MemberInfoPage extends StatefulWidget {
  final String member_no;
  final String br_no;

  const MemberInfoPage(
      {super.key, required this.member_no, required this.br_no});

  @override
  State<MemberInfoPage> createState() => _MemberInfoPageState();
}

class _MemberInfoPageState extends State<MemberInfoPage> {
  File? _imageFile; // เก็บไฟล์รูปภาพที่ผู้ใช้เลือกเปลี่ยน
  late String _memberNo;
  late String _branchNo;
  String serverResponse = 'กำลังรอข้อมูลจากเซิร์ฟเวอร์...';
  String member_name = '';
  String memberName = "Loading...";
  String memberImgUrl = "";

  // ฟังก์ชันสำหรับจำลองการกดเปลี่ยนรูปภาพ
  Future<void> _pickImage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เปิดคลังภาพเพื่อเปลี่ยนรูปโปรไฟล์')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final w = media.size.width;
    final h = media.size.height;

    final appBarExpandedHeight = h * 0.32;

    return Scaffold(
      backgroundColor: Constants.bg,
      // 🛠️ ใช้ CustomScrollView เพื่อผสานความพริ้วไหวของการเลื่อนและล็อกพื้นหลังไม่ให้หลุดแยก
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // 🟢 1. ส่วนหัวที่เป็นผืนเดียวกับ AppBar และ แผงโปรไฟล์สีเขียวด้านบน
          SliverAppBar(
            backgroundColor: Constants.greenColors,
            elevation: 0,
            pinned: true, // ล็อกแถบหัวข้อไว้ด้านบนสุดเวลาเลื่อนขึ้น
            expandedHeight:
                appBarExpandedHeight, // ใช้ค่าสัดส่วนความสูงที่คำนวณจากหน้าจอจริง
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
            // ตัวล็อกพื้นหลังสีเขียวไม่ให้ฉีกขาดเวลาดึงหน้าจอลงมา
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode
                  .pin, // ตรึงสีเขียวไว้แน่นไม่ให้แยกออกจากตัวเครื่อง
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
                    SizedBox(
                        height: h *
                            0.03), // เว้นระยะด้านล่างอย่างยืดหยุ่นตามขนาดหน้าจอ
                  ],
                ),
              ),
            ),
          ),

          // 📄 2. ส่วนเนื้อหาการ์ดข้อมูลด้านล่าง แสดงต่อท้ายแผงสีเขียว ไม่วิ่งไปซ้อนทับบังด้านบน
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
                        'เลขประจำตัวบัตรประชาชน', '1-1002-xxxxx-xx-x'),
                    _buildInfoRow('วันเดือนปีเกิด', '15 มกราคม 2535'),
                    _buildInfoRow('อายุ', '34 ปี'),
                    _buildInfoRow('วันที่เข้าเป็นสมาชิก', '01 เมษายน 2560'),
                    _buildInfoRow('อายุการเป็นสมาชิก', '9 ปี 1 เดือน'),
                  ],
                ),
                const SizedBox(height: 16),

                // กลุ่มที่ 2: การทำงานและรายได้
                _buildInfoCard(
                  title: 'การทำงานและรายได้',
                  icon: Icons.work_outline,
                  items: [
                    _buildInfoRow('อาชีพ', 'ข้าราชการครู'),
                    _buildInfoRow('ที่ทำงาน', 'โรงเรียนอนุบาลประจำจังหวัด'),
                    _buildInfoRow('เงินเดือน', '35,000 บาท'),
                    _buildInfoRow('สาขาที่สังกัด', 'สาขาเมืองปัตตานี'),
                  ],
                ),
                const SizedBox(height: 16),

                // กลุ่มที่ 3: ช่องทางการติดต่อ
                _buildInfoCard(
                  title: 'ช่องทางการติดต่อ',
                  icon: Icons.contact_mail_outlined,
                  items: [
                    _buildInfoRow('ที่อยู่ปัจจุบัน',
                        '123/4 ม.5 ต.รูสะมิแล อ.เมือง จ.ปัตตานี 94000'),
                    _buildInfoRow('โทรศัพท์มือถือ', '089-765-xxxx'),
                    _buildInfoRow('โทรศัพท์บ้าน', '073-33xxxx (ถ้ามี)'),
                    _buildInfoRow('อีเมล', 'member.coop@email.com'),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // 👤 ย้ายเฉพาะดีไซน์เนื้อหาภายในโปรไฟล์แยกออกมา เพื่อนำไปวางล็อกตำแหน่งไว้ด้านบน
  Widget _buildProfileHeaderContent() {
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
                  radius: 48, // ปรับขนาดให้กระชับสมส่วนกับหน้าจอขึ้นเล็กน้อย
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : const AssetImage('assets/images/default_avatar.png')
                          as ImageProvider,
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
                  child: const Icon(Icons.camera_alt,
                      size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'สมชาย ใจดีมั่งมี',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'ทะเบียนสมาชิก : REG-25600412',
          style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
              letterSpacing: 0.5),
        ),
      ],
    );
  }

  // 🏷️ แสดงประเภทและสถานภาพสมาชิกในแถวเดียวกัน
  Widget _buildStatusSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusBadge('ประเภทสมาชิก', 'สมาชิกสามัญ',
              Colors.blue.shade50, Colors.blue.shade700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusBadge('สถานภาพ', 'ปกติ / ขับเคลื่อน',
              Colors.green.shade50, Constants.greenColors),
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
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: textColor.withOpacity(0.7))),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  // 📦 วิดเจ็ตสร้างกลุ่มการ์ดข้อมูลส่วนต่าง ๆ
  Widget _buildInfoCard(
      {required String title,
      required IconData icon,
      required List<Widget> items}) {
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
                      color: Colors.black87),
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

  // 📝 รายการข้อมูลย่อยในแต่ละแถว
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
                  fontWeight: FontWeight.w400),
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
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
