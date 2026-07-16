import 'package:flutter/material.dart';
import 'package:flutter_launcher_icons/xml_templates.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/constants.dart';
import 'package:koperasiapp/home.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class InterPinPage extends StatefulWidget {
  final String memberNo;
  final String brNo;
  final String mobile;
  final String token;

  const InterPinPage({
    super.key,
    // required this.member_no,
    required this.memberNo,
    required this.brNo,
    required this.mobile,
    required this.token,
    required String statusPin,
  });

  @override
  State<InterPinPage> createState() => _InterPinPageState();
}

class _InterPinPageState extends State<InterPinPage> {
  // final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  List<String> _pin = [];

  void _addDigit(String digit) {
    if (_pin.length < 6) {
      setState(() => _pin.add(digit));
      if (_pin.length == 6) {
        _submitPin();
      }
    }
  }

  void _deleteDigit() {
    if (_pin.isNotEmpty) {
      setState(() => _pin.removeLast());
    }
  }

  bool _isSubmitting = false;

  Future<void> _submitPin() async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    String pin = _pin.join();
    setState(() => _isLoading = true);

    //--------------- anita add 03082025 ---------------
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';
      print('tokentest: $token');

      final response = await http.post(
        Uri.parse('https://online.iscop.co.th/ws/flutter_chk_pin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'member_no': widget.memberNo,
          'br_no': widget.brNo,
          'token': token,
          'pincode': pin,
          'login_type': 'android'
        }),
      );

      final data = jsonDecode(response.body);
      print('status: ${response.statusCode}');
      print('body: ${response.body}');

      if (data['success'].toString() == '1') {
        await prefs.setString('token', data['token']);
        await prefs.setString('pincode', data['pincode']);
        await prefs.setString(
            'last_login_time', DateTime.now().toIso8601String());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ')),
        );

        // ไปหน้าเมนูหลัก (คุณสามารถเปลี่ยนชื่อหน้าตามโปรเจกต์)
        Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) => Home(
                          member_no: widget.memberNo,
                          br_no: widget.brNo,
                          token: widget.token,
                        )),
              );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error_message'] ?? 'เกิดข้อผิดพลาด1')),
        );
        setState(() => _pin.clear());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด2: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
      _isSubmitting = false;
    }

    //--------------- anita end 03082025 ---------------
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          margin: const EdgeInsets.all(8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _pin.length
                ? Color.fromARGB(255, 0, 164, 81)
                : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildKeypadButton(String label, {VoidCallback? onPressed}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(24),
            // backgroundColor: Color.fromARGB(255, 0, 164, 81),
            backgroundColor: Constants.greenColors,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 26, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      children: [
        for (var row in keys)
          Row(
            children: row
                .map((key) =>
                    _buildKeypadButton(key, onPressed: () => _addDigit(key)))
                .toList(),
          ),
        Row(
          children: [
            Expanded(child: Container()), // เว้นช่องซ้าย
            _buildKeypadButton('0', onPressed: () => _addDigit('0')),
            _buildKeypadButton('⌫', onPressed: _deleteDigit),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('ป้อน PIN'),
      //   backgroundColor: Colors.green.shade700,
      // ),
      body: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/bg_pin.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenHeight = constraints.maxHeight;
                final screenWidth = constraints.maxWidth;

                return Center(
                  child: SingleChildScrollView(
                    // ✅ ป้องกันล้นจอแนวตั้งบนจอเล็ก
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.08,
                      vertical: screenHeight * 0.03,
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, // ✅ สูงเท่าที่จำเป็นเท่านั้น
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 🔳 Logo
                        Image.asset(
                          'assets/images/icon_logo.png',
                          width: screenWidth * 0.25,
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'ใส่รหัส PIN เพื่อดำเนินการต่อ',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),
                        _buildPinDots(),
                        SizedBox(height: screenHeight * 0.04),

                        if (_isLoading)
                          const CircularProgressIndicator()
                        else
                          _buildKeypad(),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
