import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/home.dart';
import 'package:koperasiapp/screen/home_page.dart';
import 'package:koperasiapp/screen/register_terms_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Function to get login response
Future<Map<String, dynamic>> getLogin(
    String member_no, String password, String br_no) async {
  const String baseUrl = 'https://online.iscop.co.th/ws/';
  const String endpoint = 'login_user_test.php';
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
  print(body);
  try {
    final response = await http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: body,
        )
        .timeout(const Duration(seconds: timeout));

    if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   print(token);
      // return data['token']; // สมมติว่า API ส่ง token ในค่านี้

      // Map<String, dynamic> data = jsonDecode(response.body);
      // if (data['success'] == '0'){
      //   print("so");
      //   return json.decode(response.body);
      // }
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

  void _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อผู้ใช้และรหัสผ่าน')),
      );
      return;
    }
//====================So add==========//
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
        print('anita');

        if (response['success'].toString() == '1') {
          if (response['is_first'].toString() == '1') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('คุณยังไม่ได้สมัครสมาชิก')),
            );
          } else {
            if (response['status_pin'].toString() == '0') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ')),
              );
              print('Member No: $member_no');
              print('Branch No: $br_no');
              // print('token: $token');

              // เปลี่ยนหน้าไปยังหน้าหลักแทนที่หน้าเดิม ผู้ใช้ไม่สามารถย้อนกลับไปหน้าเดิมได้
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) => Home(
                          member_no: member_no,
                          br_no: br_no,
                        )),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ดำเนินการสร้าง PIN ...')),
              );
            }
          }
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

  bool rememberPassword = true;

  @override
  Widget build(BuildContext context) {
    var mediaSize = MediaQuery.of(context).size;
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background/bg.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formSignInKey,
              child: Stack(children: [
                Positioned(top: 0, child: _buildTop()),
                Positioned(bottom: 0, child: _buildBottom()),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTop() {
    var mediaSize = MediaQuery.of(context).size;
    return SafeArea(
      child: Row(
        children: [
          SizedBox(
            width: mediaSize.width * 0.3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.png', fit: BoxFit.fill),
              ],
            ),
          ),
          const SizedBox(
            width: 10.0,
          ),
          SizedBox(
            width: mediaSize.width * 0.65,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "THE ISLAMIC CO-OPERATIVE OF PATTANI LIMITED",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                Text(
                  "KOPERASI",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 50,
                      letterSpacing: 2),
                ),
                Text(
                  "SMART",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                      letterSpacing: 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    var mediaSize = MediaQuery.of(context).size;
    return SizedBox(
      width: mediaSize.width,
      height: mediaSize.height * 0.7,
      child: Card(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        )),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 20.0,
          ),
          const Text(
            'ยินดีต้อนรับเข้าสู่ระบบ',
            style: TextStyle(
              fontSize: 30.0,
              fontWeight: FontWeight.w900,
              color: Color.fromARGB(255, 14, 53, 15),
            ),
          ),
          const SizedBox(
            height: 40.0,
          ),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              focusedBorder: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromARGB(255, 14, 53, 15))),
              label: const Text('เลขทะเบียนสมาชิก 10 หลัก'),
              labelStyle:
                  const TextStyle(color: Color.fromARGB(255, 14, 53, 15)),
              hintText: 'กรอกเลขทะเบียนสมาชิก 10 หลัก',
              hintStyle: const TextStyle(
                color: Colors.black26,
              ),
              border: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Colors.black12, // Default border color
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Colors.black12, // Default border color
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'โปรดกรอกเลขทะเบียนสมาชิก 10 หลัก';
              }
              return null;
            },
          ),
          const SizedBox(
            height: 40.0,
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            // obscuringCharacter: '*',
            decoration: InputDecoration(
              focusedBorder: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromARGB(255, 14, 53, 15))),
              label: const Text('รหัสผ่าน'),
              labelStyle:
                  const TextStyle(color: Color.fromARGB(255, 14, 53, 15)),
              hintText: 'กรอกรหัสผ่าน',
              hintStyle: const TextStyle(
                color: Colors.black26,
              ),
              border: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Colors.black12, // Default border color
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Colors.black12, // Default border color
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'โปรดกรอกรหัสผ่าน';
              }
              return null;
            },
          ),
          const SizedBox(
            height: 25.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: rememberPassword,
                    onChanged: (bool? value) {
                      setState(() {
                        rememberPassword = value!;
                      });
                    },
                    activeColor: const Color.fromARGB(255, 14, 53, 15),
                  ),
                  const Text(
                    'บันทึกข้อมูลการเข้าสู่ระบบ',
                    style: TextStyle(
                      color: Colors.black45,
                    ),
                  ),
                ],
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
          const SizedBox(
            height: 25.0,
          ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              child: const Text(
                'เข้าสู่ระบบ',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 25.0,
          ),
          // don't have an account
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'เข้าใช้งานครั้งแรก  ',
                // style: TextStyle(
                //   color: Colors.black12,
                // ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (e) => const SignupScreen(),
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
          const SizedBox(
            height: 30.0,
          ),
        ],
      ),
    );
  }
}
