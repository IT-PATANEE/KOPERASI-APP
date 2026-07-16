import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoadQrcodePage extends StatefulWidget {
  final String memberNo;
  final String brNo;
  final int type;
  final double amount;
  final String memberName;
  final String toMem;
  final String ref2;

  const LoadQrcodePage({
    Key? key,
    required this.memberNo,
    required this.brNo,
    required this.type,
    required this.amount,
    required this.memberName,
    required this.toMem,
    required this.ref2,
  }) : super(key: key);

  @override
  State<LoadQrcodePage> createState() => _LoadQrcodePageState();
}

class _LoadQrcodePageState extends State<LoadQrcodePage> {
  late String _memberNo;
  late String _branchNo;
  late int type;
  String _token = '';
  String _qrCodeContent = ''; // To store the content returned from API
  Uint8List _backgroundImage = Uint8List.fromList([]);
  bool _isLoading = true; // To track loading state

  Future<void> generateQrCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // Get the token from SharedPreferences

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token is missing.')),
      );
      return;
    }
    String url = 'https://online.iscop.co.th/call_qrcode_flutter.php';
    Map<String, dynamic> data = {
      'ref1': '${widget.brNo}01${widget.memberNo}',
      'ref2': widget.toMem.isNotEmpty
          ? '${widget.toMem.substring(0, 3)}01${widget.toMem.substring(widget.toMem.length - 5)}'
          : '${widget.brNo}01${widget.memberNo}', // ใช้ toMem ถ้ามีค่า
      'bal': '${widget.amount.toString()}00', // Append "00" to the amount
      // 'token': _token, // Send the token for validation
    };
    try {
      final response = await http.post(
        Uri.parse(url),
        body: data,
        headers: {
          'Authorization': 'Bearer $_token', // Send token in headers
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('content') &&
            responseData['content'] != null) {
          setState(() {
            _qrCodeContent = responseData['content']; // Store QR code content
            print('qrcode : $_qrCodeContent');
            // _loadBackgroundImage();
            // _isLoading = false; // Stop loading
          });
          _loadBackgroundImage(); // โหลดภาพพื้นหลังหลังจากได้รับ QR Code
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No QR Code content received')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending data: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error loading QR Code: $e'); // Debug error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: $e')),
      );
      setState(() {
        _isLoading = false; // Stop loading on error
      });
    }
  }

  Future<void> _loadBackgroundImage() async {
    String imageUrl = _getImageUrlByType(widget.type); // เลือก URL ตามประเภท
    print("Loading background image from: $imageUrl"); // Debug URL

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        setState(() {
          _backgroundImage = response.bodyBytes;
          _isLoading = false; // Stop loading once image is loaded
        });
      } else {
        throw Exception('Failed to load image');
      }
    } catch (e) {
      print('Error loading image: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _memberNo = widget.memberNo;
    _branchNo = widget.brNo;
    type = widget.type;
    generateQrCode();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Constants.bg,
        appBar: AppBar(
          backgroundColor: Constants.primaryColor,
          title: const Center(
            child: Text(
              'QR CODE ชำระหุ้น',
              style:
                  TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                Navigator.pop(context); // Close the LoadQrcodePage
                Navigator.pop(context); // Close the InputQrDataPage
              },
            ),
          ],
        ),
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator() // Show loading spinner while waiting
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    // ตรวจสอบก่อนแสดงภาพพื้นหลัง
                    if (_backgroundImage.isNotEmpty)
                      Image.memory(
                        _backgroundImage,
                        fit: BoxFit.cover,
                      )
                    else
                      const Text("ไม่สามารถโหลดภาพพื้นหลังได้"),

                    // แสดง QR Code เมื่อมีข้อมูล
                    if (_qrCodeContent.isNotEmpty)
                      QrImageView(
                        data: _qrCodeContent,
                        version: QrVersions.auto,
                        size: 190.0,
                        backgroundColor: Colors.transparent,
                        errorStateBuilder: (context, error) => const Center(
                          child: Text("ไม่สามารถสร้าง QR Code ได้"),
                        ),
                      )
                    else
                      const Text("ไม่สามารถโหลด QR Code ได้"),

                    Positioned(
                      top: 100, // ตำแหน่งของข้อความ
                      child: Column(
                        children: [
                          Text(
                            "ชื่อ: ${widget.memberName}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0), // สีข้อความ
                            ),
                          ),
                          Text(
                            "จำนวนเงิน: ${widget.amount} บาท",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

String _getImageUrlByType(int type) {
  switch (type) {
    case 1:
      return 'https://online.iscop.co.th/images/source_slips_qrcode/Slips-QR_share1.jpg';
    case 2:
      return 'https://online.iscop.co.th/images/source_slips_qrcode/Slips-QR_saving1.jpg';
    case 3:
      return 'https://online.iscop.co.th/images/source_slips_qrcode/Slips-QR_loan1.jpg';
    case 4:
      return 'https://online.iscop.co.th/images/source_slips_qrcode/Slips-QR_arrahnu1.jpg';
    case 5:
      return 'https://online.iscop.co.th/images/source_slips_qrcode/Slips-QR_taawoon1.jpg';
    default:
      return 'https://online.iscop.co.th/images/source_slips_qrcode/Slips-QR_group_share.jpg'; // รูป default
  }
}
