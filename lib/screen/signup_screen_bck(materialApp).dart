import 'package:flutter/material.dart';

/// แอพหลัก
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Register Flow Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const PreviewPage(),
    );
  }
}

/// 1. Preview Page
class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              "แอพสหกรณ์ออนไลน์เพื่อคุณ",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsPage()),
                );
              },
              child: const Text("ลงทะเบียน"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // TODO: ไปหน้า Login
              },
              child: const Text("เข้าสู่ระบบ"),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2. Terms & Conditions Page
class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange) {
        setState(() {
          _isAtBottom = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เงื่อนไขการใช้งาน")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: const Text(
                "นี่คือข้อความเงื่อนไขการใช้งาน...\n\n"
                "1. ผู้ใช้ต้องยอมรับ...\n"
                "2. ข้อมูลจะถูกจัดเก็บ...\n"
                "3. ข้อความอื่น ๆ\n\n"
                "เลื่อนลงมาจนสุดเพื่อกดยอมรับ...",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("ปฏิเสธ"),
              ),
              ElevatedButton(
                onPressed: _isAtBottom
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterPage()),
                        );
                      }
                    : null,
                child: const Text("ยอมรับ"),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// 3. Register Page
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _agree = false;

  // ตัวอย่าง TextController
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ลงทะเบียน")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "ชื่อ-นามสกุล"),
                validator: (val) =>
                    val!.isEmpty ? "กรุณากรอกชื่อ-นามสกุล" : null,
              ),
              TextFormField(
                controller: _idCtrl,
                decoration:
                    const InputDecoration(labelText: "เลขบัตรประชาชน/Member ID"),
                validator: (val) =>
                    val!.isEmpty ? "กรุณากรอกเลขบัตร" : null,
              ),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: "เบอร์โทรศัพท์"),
                keyboardType: TextInputType.phone,
                validator: (val) =>
                    val!.length != 10 ? "เบอร์โทรศัพท์ต้องมี 10 หลัก" : null,
              ),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "อีเมล"),
                keyboardType: TextInputType.emailAddress,
                validator: (val) =>
                    val!.contains("@") ? null : "อีเมลไม่ถูกต้อง",
              ),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: "รหัสผ่าน"),
                obscureText: true,
                validator: (val) =>
                    val!.length < 6 ? "รหัสผ่านต้อง >= 6 ตัวอักษร" : null,
              ),
              TextFormField(
                controller: _confirmPassCtrl,
                decoration: const InputDecoration(labelText: "ยืนยันรหัสผ่าน"),
                obscureText: true,
                validator: (val) =>
                    val != _passCtrl.text ? "รหัสผ่านไม่ตรงกัน" : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _agree,
                    onChanged: (val) {
                      setState(() {
                        _agree = val!;
                      });
                    },
                  ),
                  const Expanded(
                      child: Text("ยอมรับนโยบายความเป็นส่วนตัว")),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _agree
                    ? () {
                        if (_formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("ลงทะเบียนสำเร็จ (mock)")),
                          );
                          // TODO: call API -> OTP -> next page
                        }
                      }
                    : null,
                child: const Text("ลงทะเบียน"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
