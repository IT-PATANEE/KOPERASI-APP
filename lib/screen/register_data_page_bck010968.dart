import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/widgets/custtom_scaffold.dart';
import 'package:page_transition/page_transition.dart';

class RegisterDataPage extends StatefulWidget {
  const RegisterDataPage({super.key});

  @override
  State<RegisterDataPage> createState() => _RegisterDataPageState();
}

class _RegisterDataPageState extends State<RegisterDataPage> {
  final ScrollController _scroll = ScrollController();
  bool _scrolledToBottom = false;
  bool _consentChecked = false;
  double _progress = 0.0; // 0..1 reading progress
  final _formKey = GlobalKey<FormState>();
  final _memberNoController = TextEditingController();
  final _idCardController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final offset = _scroll.offset.clamp(0.0, max);
    final p = max == 0 ? 1.0 : (offset / max);
    final atBottom = _scroll.position.pixels >= max - 8; // allow tiny tolerance
    if (mounted) {
      setState(() {
        _progress = p;
        _scrolledToBottom = atBottom;
      });
    }
  }

  bool get _canAccept => _scrolledToBottom && _consentChecked;

  Future<void> _confirmDecline() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการปฏิเสธ?'),
        content: const Text(
          'คุณยังไม่ได้ยอมรับข้อกำหนดและเงื่อนไข หากปฏิเสธ คุณจะไม่สามารถดำเนินการต่อได้.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก')),
          FilledButton.tonal(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ปฏิเสธ')),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.pop(context, false);
    }
  }

  void _onAccept() {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: const RegisterDataPage(),
        // duration: const Duration(milliseconds: 300), // ความเร็วแอนิเมชัน
      ),
    );
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isPortrait = media.orientation == Orientation.portrait;
    final theme = Theme.of(context); // <-- ใช้ ThemeData
    final w = media.size.width;
    final h = media.size.height;
    final textScale = w * 0.04; // ขนาดฟอนต์ตามความกว้างจอ
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, // พื้นหลังสีขาว
        surfaceTintColor: Colors.white, // ป้องกัน Material3 tint
        elevation: 0, // ไม่มีเงา
        centerTitle: true, // กึ่งกลาง
        title: const Text(
          'สมัครใช้งาน KOPERASI SMART',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // ย้อนกลับหน้าเดิม
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              Align(
                alignment: Alignment.centerLeft,
                // child: Text(
                //   'กรอกข้อมูลการลงทะเบียน',
                //   style: TextStyle(
                //     fontSize: 16,
                //     fontWeight: FontWeight.bold,
                //     color: Color.fromARGB(255, 14, 53, 15),
                //   ),
                // ),
                child: Text('กรอกข้อมูลการลงทะเบียน',
                    style: textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 20),

              // Member Number
              TextFormField(
                controller: _memberNoController,
                decoration: InputDecoration(
                  label: const Text('เลขทะเบียนสมาชิก 10 หลัก(ดูจากสมุดหุ้น)'),
                  labelStyle:
                      const TextStyle(color: Color.fromARGB(255, 14, 53, 15)),
                  hintText: 'กรอกเลขทะเบียนสมาชิก 10 หลัก',
                  hintStyle: const TextStyle(color: Colors.black26),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 14, 53, 15), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'โปรดกรอกเลขทะเบียนสมาชิก 10 หลัก';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // ID Card
              TextFormField(
                controller: _idCardController,
                decoration: InputDecoration(
                  label: const Text('เลขบัตรประชาชน'),
                  labelStyle:
                      const TextStyle(color: Color.fromARGB(255, 14, 53, 15)),
                  hintText: 'กรอกเลขบัตรประชาชน',
                  hintStyle: const TextStyle(color: Colors.black26),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 14, 53, 15), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'โปรดกรอกเลขบัตรประชาชน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  label: const Text('เบอร์โทรศัพท์'),
                  labelStyle:
                      const TextStyle(color: Color.fromARGB(255, 14, 53, 15)),
                  hintText: 'กรอกเบอร์โทรศัพท์',
                  hintStyle: const TextStyle(color: Colors.black26),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 14, 53, 15), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'โปรดกรอกเบอร์โทรศัพท์';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.015),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.greenColor,
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04, vertical: h * 0.015),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
              ),
              child: const Text(
                'ถัดไป',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
