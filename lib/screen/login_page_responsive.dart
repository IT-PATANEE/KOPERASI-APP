import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/home.dart';
import 'package:koperasiapp/screen/home_page.dart';
import 'package:koperasiapp/screen/inter_pin_page.dart';
// import 'package:koperasiapp/screen/login_otp_page.dart';
import 'package:koperasiapp/screen/register_terms_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_otp_page.dart';

// Function to get login response
Future<Map<String, dynamic>> getLogin(
    String member_no, String password, String br_no) async {
  const String baseUrl = 'https://online.iscop.co.th/ws/MobileApp/';
  //----- add 210468 -----
  // const String baseUrl = 'https://cors-anywhere.herokuapp.com/https://online.iscop.co.th/ws/MobileApp/';
  //----- end add 210468 -----
  const String endpoint = 'login_user.php';
  const int timeout = 1000; // Timeout duration in seconds

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String token = prefs.getString('token') ?? '';

  Map<String, String> headers = {
    'Content-Type': 'application/json;charset=utf-8',
  };

  Map<String, String> data = {
    'member_no': member_no,
    'br_no': br_no,
    'password': password,
    'token': token,
    'login_type': 'android'
  };

  // print(data);
  var body = json.encode(data);
  print('bodytest: $body');
  try {
    final response = await http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: body,
        )
        .timeout(const Duration(seconds: timeout));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // throw Exception('Failed to load data : ${response.statusCode}');
      throw Exception('Failed to load data : ${response.body}');
    }
  } catch (e) {
    print(e.toString());
    return {};
  }
}

// Function to get member_no and br_no
String getMemberNo(String username) {
  return username.substring(5, 10);
}

String getMemberBr(String username) {
  return username.substring(0, 3);
}

// Function to perform login in background
Future<Map<String, dynamic>> performLogin(
    String username, String password, bool status) async {
  Map<String, dynamic> json = {};

  if (status) {
    String member_no = getMemberNo(username);
    String br_no = getMemberBr(username);

    json = await getLogin(member_no, password, br_no);
  }

  return json;
}

//--------------- anita add 14072025 ---------------

//--------------- anita end 14072025 ---------------

// Flutter widget
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formSignInKey = GlobalKey<FormState>();
  // add 230767
  final _navigatorKey =
      GlobalKey<NavigatorState>(); //เมื่อทำการ login เสร็จทำการเปลี่ยนหน้า
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _status = true; // Example status variable
  bool rememberPassword = true;

  //--------------- anita add 03082025 ---------------
  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool remember = prefs.getBool('rememberLogin') ?? false;

    setState(() {
      rememberPassword = remember; // อัปเดต checkbox ให้ถูกต้อง
    });

    if (remember) {
      String? savedUsername = prefs.getString('username');
      String? savedPassword = prefs.getString('password');

      if (savedUsername != null && savedPassword != null) {
        // เติมค่า controller ด้วยข้อมูลที่บันทึกไว้
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;

        // เรียก login อัตโนมัติ
        Map<String, dynamic> response =
            await performLogin(savedUsername, savedPassword, true);

        if (response.isNotEmpty && response['success'].toString() == '1') {
          String member_no = getMemberNo(savedUsername);
          String br_no = getMemberBr(savedUsername);
          String mobile = response['mobile'];
          String statusPin = response['status_pin'].toString();
          String token = response['token'].toString();

          // ไปหน้า OTP หรือหน้าหลัก
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => InterPinPage(
                memberNo: member_no,
                brNo: br_no,
                mobile: mobile,
                statusPin: statusPin,
                token: token,
              ),
            ),
          );
        } else {
          // ถ้า login ไม่สำเร็จ เคลียร์สถานะจำ login
          await prefs.setBool('rememberLogin', false);
        }
      }
    }
  }

  //--------------- anita end 03082025 ---------------

  void _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อผู้ใช้และรหัสผ่าน')),
      );
      return;
    }
//====================So add==========
    if (username.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เลขทะเบียนสมาชิกไม่ถูกต้อง')),
      );
      return;
    }
//========================End so add==============

    String member_no = getMemberNo(username);
    String br_no = getMemberBr(username);

    try {
      Map<String, dynamic> response =
          await performLogin(username, password, _status);

      if (response.isNotEmpty) {
        // Login successful
        //=======================so add

        print(response);

        if (response['success'].toString() == '1') {
          if (response['is_first'].toString() == '1') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('คุณยังไม่ได้สมัครสมาชิก')),
            );
            return;
          }

          final statusPin = response['status_pin'].toString();
          final token = response['token'].toString();
          final mobile = response['mobile'];

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', response['token']);

          //--------------- anita add 03082025 ---------------
          if (rememberPassword) {
            await prefs.setString('username', username);
            await prefs.setString('password', password);
            await prefs.setBool('rememberLogin', true);
          } else {
            await prefs.remove('username');
            await prefs.remove('password');
            await prefs.setBool('rememberLogin', false);
          }
          //--------------- anita end 03082025 ---------------
          print('rememberPassword: $rememberPassword');
          print(
              'SharedPref: username=${prefs.getString('username')}, password=${prefs.getString('password')}');

          if (statusPin == '0') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ดำเนินการสร้าง PIN ...')),
            );
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => LoginOtpPage(
                memberNo: member_no,
                brNo: br_no,
                mobile: mobile,
                statusPin: statusPin,
              ),
            ),
          );

          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(
          //     builder: (context) => InterPinPage(
          //       memberNo: member_no,
          //       brNo: br_no,
          //       mobile: mobile,
          //       statusPin: statusPin,
          //       token:token,
          //     ),
          //   ),
          // );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('ทะเบียนสมาชิก หรือ รหัสผ่าน ไม่ถูกต้อง')),
          );
        }

        //==================end so add
      } else {
        // Login failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เข้าสู่ระบบล้มเหลว')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเข้าสู่ระบบ: $e')),
      );
    }
  }

  // bool rememberPassword = true;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    final padding = mediaSize.width * 0.05; // ขนาด padding responsive

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background/bg.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Form(
                        key: _formSignInKey,
                        child: Column(
                          children: [
                            _buildTop(mediaSize),
                            const SizedBox(height: 20),
                            Expanded(
                              child: _buildBottom(mediaSize),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTop(Size mediaSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 3,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            height: mediaSize.height * 0.1,
          ),
        ),
        const SizedBox(width: 10.0),
        Flexible(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                "THE ISLAMIC CO-OPERATIVE OF PATTANI LIMITED",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
              FittedBox(
                child: Text(
                  "KOPERASI",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 50,
                      letterSpacing: 2),
                ),
              ),
              FittedBox(
                child: Text(
                  "SMART",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                      letterSpacing: 2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottom(Size mediaSize) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'ยินดีต้อนรับเข้าสู่ระบบ',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color.fromARGB(255, 14, 53, 15),
          ),
        ),
        const SizedBox(height: 30),
        _buildTextField(
          controller: _usernameController,
          label: "เลขทะเบียนสมาชิก 10 หลัก",
          hint: "กรอกเลขทะเบียนสมาชิก 10 หลัก",
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _passwordController,
          label: "รหัสผ่าน",
          hint: "กรอกรหัสผ่าน",
          obscure: true,
        ),
        const SizedBox(height: 20),

        // Remember me + forgot password
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Checkbox(
                    value: rememberPassword,
                    onChanged: (val) {
                      setState(() {
                        rememberPassword = val ?? false;
                      });
                    },
                    activeColor: const Color.fromARGB(255, 14, 53, 15),
                  ),
                  Flexible(
                    child: Text(
                      'บันทึกข้อมูลการเข้าสู่ระบบ',
                      style: const TextStyle(color: Colors.black45),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              child: const Text(
                'ลืมรหัสผ่าน?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 14, 53, 15),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_formSignInKey.currentState!.validate()) {
                _login();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 14, 53, 15),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'เข้าสู่ระบบ',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Sign up link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('เข้าใช้งานครั้งแรก  '),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (e) => const RegisterTermsPage(),
                  ),
                );
              },
              child: const Text(
                'ลงทะเบียนเข้าสู่ระบบที่นี่',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 14, 53, 15),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color.fromARGB(255, 14, 53, 15))),
        labelStyle: const TextStyle(color: Color.fromARGB(255, 14, 53, 15)),
        hintStyle: const TextStyle(color: Colors.black26),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'โปรดกรอก $label';
        }
        return null;
      },
    );
  }
}
