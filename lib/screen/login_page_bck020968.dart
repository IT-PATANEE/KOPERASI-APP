import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/constants.dart';
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
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true, // ให้คีย์บอร์ดไม่บัง
      body: Stack(
        children: [
          // แถบสีเขียวด้านบน + โลโก้ตรงกลาง
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: h, // ลดความสูงลงนิด ให้สีขาวทับ
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Constants.greenColor!,
                    Constants.greenColor!.withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/images/background/bg1.png'),
                  fit: BoxFit.cover,
                ),
                // borderRadius: const BorderRadius.only(
                //   bottomLeft: Radius.circular(40),
                //   bottomRight: Radius.circular(40),
                // ),
              ),
              child: Align(
                alignment: Alignment.topCenter, // ขยับโลโก้ไปด้านบนตรงกลาง
                child: Image.asset(
                  'assets/images/logo_white.png',
                  width: w * 0.3,
                  // fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Card สีขาว ทับแถบสีเขียว
          Positioned(
            top: h * 0.23, // เลื่อนขึ้นให้ทับสีเขียว
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(80),
                  // topRight: Radius.circular(80),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: 20),
              child: SingleChildScrollView(
                child: Form(
                  key: _formSignInKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: h * 0.05,
                      ),
                      Center(
                        child: const Text(
                          'ยินดีต้อนรับเข้าสู่ระบบ',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color.fromARGB(255, 14, 53, 15),
                          ),
                        ),
                      ),
                      SizedBox(height: h * 0.03),
                      _buildUsernameField(),
                      SizedBox(height: h * 0.03),
                      _buildPasswordField(),
                      SizedBox(height: h * 0.01),
                      _buildRememberAndForgot(),
                      SizedBox(height: h * 0.03),
                      _buildLoginSection(),
                      // const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameField() {
  return TextFormField(
    controller: _usernameController,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    autovalidateMode: AutovalidateMode.onUserInteraction,
    style: const TextStyle(fontSize: 16, color: Colors.black87),
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.green[50], // พื้นหลังอ่อน ๆ
      prefixIcon: const Icon(
        Icons.person,
        color: Color.fromARGB(255, 14, 53, 15),
      ),
      labelText: 'เลขทะเบียนสมาชิก 10 หลัก',
      labelStyle: const TextStyle(
        color: Color.fromARGB(255, 14, 53, 15),
        fontWeight: FontWeight.w600,
      ),
      hintText: 'กรอกเลขทะเบียนสมาชิก 10 หลัก',
      hintStyle: TextStyle(color: Colors.grey[400]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 14, 53, 15),
          width: 2,
        ),
      ),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'โปรดกรอกเลขทะเบียนสมาชิก 10 หลัก';
      }
      if (value.length != 10) {
        return 'เลขทะเบียนต้องมี 10 หลัก';
      }
      return null;
    },
  );
}

  bool _obscurePassword = true; // ตัวแปร state สำหรับซ่อน/แสดงรหัส

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.green[50],
        prefixIcon: const Icon(
        Icons.lock,
        color: Color.fromARGB(255, 14, 53, 15),
      ),
        labelText: 'รหัสผ่าน',
        labelStyle: const TextStyle(
          color: Color.fromARGB(255, 14, 53, 15),
          fontWeight: FontWeight.w600,
        ),
        hintText: 'กรอกรหัสผ่าน',
        hintStyle: TextStyle(color: Colors.grey[400]),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 14, 53, 15),
            width: 2,
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Color.fromARGB(255, 14, 53, 15),
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) return 'โปรดกรอกรหัสผ่าน';
        return null;
      },
    );
  }

  Widget _buildRememberAndForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: rememberPassword,
              onChanged: (value) {
                setState(() {
                  rememberPassword = value!;
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              activeColor: const Color.fromARGB(255, 14, 53, 15),
            ),
            const Text(
              'จดจำการเข้าสู่ระบบ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            // TODO: ใส่การทำงานเมื่อกด "ลืมรหัสผ่าน"
          },
          child: const Text(
            'ลืมรหัสผ่าน?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 14, 53, 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // const Spacer(), // ดันเนื้อหาอื่นขึ้นด้านบน
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_formSignInKey.currentState!.validate()) _login();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: Constants.greenColor,
            ),
            child: const Text(
              'เข้าสู่ระบบ',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('เข้าใช้งานครั้งแรก '),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (e) => const RegisterTermsPage()),
                );
              },
              child: const Text(
                'ลงทะเบียนเข้าสู่ระบบที่นี่',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 14, 53, 15)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
