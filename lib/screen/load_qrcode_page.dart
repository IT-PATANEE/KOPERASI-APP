import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:koperasiapp/constants.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class LoadQrcodePage extends StatefulWidget {
  final String memberNo;
  final String brNo;
  final int type;
  final double amount;
  final String memberName;
  final String toMem;
  final String toMemName;
  final String ref2;
  final String toAccountNo;
  final int selectedType; // '1' = บัญชีตัวเอง, '2' = บัญชีผู้อื่น

  LoadQrcodePage({
    Key? key,
    required this.memberNo,
    required this.brNo,
    required this.type,
    required this.amount,
    required this.memberName,
    required this.toMem,
    required this.toMemName,
    required this.ref2,
    required this.toAccountNo,
    required this.selectedType,
  }) : super(key: key);

  @override
  State<LoadQrcodePage> createState() => _LoadQrcodePageState();
}

String _getTitleByType(int type) {
  switch (type) {
    case 1:
      return 'QR CODE ชำระหุ้น';
    case 2:
      return 'QR CODE เงินฝาก';
    case 3:
      return 'QR CODE ชำระสินเชื่อ';
    case 4:
      return 'QR CODE ชำระอัรเราะห์นู';
    case 5:
      return 'QR CODE ชำระตะอาวุน';
    default:
      return 'QR CODE ชำระเงิน';
  }
}

class _LoadQrcodePageState extends State<LoadQrcodePage> {
  final GlobalKey _repaintKey = GlobalKey();
  bool dirExists = false;
  dynamic externalDir = '/storage/emulated/0/Download/Qr_code';

  String _qrCodeContent = '';
  bool _isLoading = true;
  String _token = '';

  @override
  void initState() {
    super.initState();
    fetchQrcodeData();
  }

  Future<void> fetchQrcodeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';

    if (_token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token is missing.')),
      );
      return;
    }

    String url = 'https://online.iscop.co.th/call_qrcode_flutter.php';
    Map<String, dynamic> data = {
      'ref1': '${widget.brNo}01${widget.memberNo}',
      'ref2': (widget.type == 2 || widget.type == 3 || widget.type == 4) &&
              widget.toAccountNo.isNotEmpty
          ? widget.toAccountNo
          : widget.toMem.isNotEmpty
              ? '${widget.toMem.substring(0, 3)}01${widget.toMem.substring(widget.toMem.length - 5)}'
              : '${widget.brNo}01${widget.memberNo}',
      'bal': '${(widget.amount * 100).round()}',
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        body: data,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['content'] != null) {
          setState(() {
            _qrCodeContent = responseData['content'];
            _isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No QR Code content received')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('QR Code load error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAsImage() async {
    try {
      RenderRepaintBoundary boundary = _repaintKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 4.0);

      //Drawing White Background because Qr Code is Black
      final whitePaint = Paint()..color = Colors.white;
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()));
      canvas.drawRect(
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          whitePaint);
      canvas.drawImage(image, Offset.zero, Paint());

      final picture = recorder.endRecording();
      final img = await picture.toImage(image.width, image.height);
      ByteData? byteData = await img.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      //Check for duplicate file name to avoid Override
      String fileName = 'qr_code';
      int i = 1;
      while (await File('$externalDir/$fileName.png').exists()) {
        fileName = 'qr_code_$i';
        i++;
      }

      // Check if Directory Path exists or not
      dirExists = await File(externalDir).exists();
      //if not then create the path
      if (!dirExists) {
        await Directory(externalDir).create(recursive: true);
        dirExists = true;
      }

      final file = await File('$externalDir/$fileName.png').create();
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      const snackBar = SnackBar(content: Text('QR code saved to gallery'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      print('Save image error: $e');
      if (!mounted) return;
      const snackBar = SnackBar(content: Text('ไม่สามารถบันทึกรูปภาพได้'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isPortrait = media.orientation == Orientation.portrait;
    final theme = Theme.of(context); // <-- ใช้ ThemeData
    final w = media.size.width;
    final h = media.size.height;
    final textScale = w * 0.04; // ขนาดฟอนต์ตามความกว้างจอ

    return Scaffold(
      backgroundColor: Constants.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // 🔹 หัวบน
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: w * 0.04, vertical: h * 0.015),
                  child: SizedBox(
                    height: 40, // กำหนดความสูง header
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Text(
                            "รับเงินด้วย QR CODE",
                            style: theme.textTheme.titleLarge!.copyWith(
                              color: Colors.green[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: IconButton(
                            icon: Icon(Icons.close, color: Colors.green[900]),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                RepaintBoundary(
                  key: _repaintKey,
                  child: Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: w * 0.04),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green, width: 1),
                        ),
                        child: Column(
                          children: [
                            // 🔹 หัวข้อสีเขียว
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(h * 0.015),
                              decoration: BoxDecoration(
                                color: Colors.green[700],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _getTitleByType(widget.type),
                                  // _getTitleBySelectedType(widget.selectedType),
                                  style: theme.textTheme.titleLarge!.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            // 🔹 QR Code
                            Padding(
                              padding: EdgeInsets.all(h * 0.025),
                              child: QrImageView(
                                data: _qrCodeContent,
                                size: isPortrait ? w * 0.5 : h * 0.4,
                                backgroundColor: Colors.white,
                                embeddedImage: const AssetImage(
                                    'assets/images/logo_new.png'),
                                embeddedImageStyle: QrEmbeddedImageStyle(
                                  size: Size(w * 0.08, w * 0.08),
                                ),
                              ),
                            ),

                            Text(
                              "QR ของคุณได้ถูกสร้างแล้ว\nผู้จ่ายสามารถสแกนเพื่อชำระเงินได้",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),

                            const Divider(),

                            // ข้อมูลบัญชี
                            // แสดงรายละเอียดบัญชี ตาม selectedType
                            if (widget.selectedType == 1)
                              _buildMyAccountDetails()
                            else if (widget.selectedType == 2)
                              _buildOtherAccountDetails(),

                            SizedBox(height: h * 0.01),

                            Text(
                              "สมาชิกสามารถบันทึก QR CODE นี้\nเพื่อใช้ในการทำธุรกรรมในครั้งต่อไป",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall!.copyWith(
                                color: Colors.grey[700],
                              ),
                            ),

                            SizedBox(height: h * 0.02),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: w * 0.04, vertical: h * 0.015),
                  child: ElevatedButton.icon(
                    onPressed: _saveAsImage,
                    icon: const Icon(Icons.download),
                    label: const Text('บันทึก QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.greenColor,
                      foregroundColor: Colors.white,
                      textStyle: theme.textTheme.labelLarge,
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

// =================== ฟังก์ชันรายละเอียดบัญชี ===================
  Widget _buildMyAccountDetails() {
    final theme = Theme.of(context);
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.015),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("ชื่อสมาชิก :",
                  style: theme.textTheme.bodyMedium!
                      .copyWith(fontWeight: FontWeight.bold)),
              Text(widget.memberName, style: theme.textTheme.bodyMedium),
            ],
          ),
          SizedBox(height: h * 0.008),
          if (widget.type == 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("เลขที่สมาชิก :",
                    style: theme.textTheme.bodyMedium!
                        .copyWith(fontWeight: FontWeight.bold)),
                Text("${widget.brNo}${widget.memberNo}",
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
          if (widget.type == 2) ...[
            SizedBox(height: h * 0.008),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "เลขที่บัญชี :",
                  style: theme.textTheme.bodyMedium!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(widget.toAccountNo, style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
          if (widget.type == 3 || widget.type == 4) ...[
            SizedBox(height: h * 0.008),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "รหัสบัญชี :",
                  style: theme.textTheme.bodyMedium!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(widget.toAccountNo, style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOtherAccountDetails() {
    final theme = Theme.of(context);
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.015),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("ชื่อสมาชิก :",
                  style: theme.textTheme.bodyMedium!
                      .copyWith(fontWeight: FontWeight.bold)),
              Text(widget.toMemName, style: theme.textTheme.bodyMedium),
            ],
          ),
          SizedBox(height: h * 0.008),
          // type = 1 แสดง "เลขที่สมาชิก"
          if (widget.type == 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("เลขที่สมาชิก :",
                    style: theme.textTheme.bodyMedium!
                        .copyWith(fontWeight: FontWeight.bold)),
                Text(widget.toAccountNo, style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
          // type = 2 แสดง "เลขที่บัญชี"
          if (widget.type == 2) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("เลขที่บัญชี :",
                    style: theme.textTheme.bodyMedium!
                        .copyWith(fontWeight: FontWeight.bold)),
                Text(widget.toAccountNo, style: theme.textTheme.bodyMedium),
              ],
            ),
          ],

          // type = 3, 4 แสดง "รหัสบัญชี"
          if (widget.type == 3 || widget.type == 4) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("เลขที่บัญชี :",
                    style: theme.textTheme.bodyMedium!
                        .copyWith(fontWeight: FontWeight.bold)),
                Text(widget.toAccountNo, style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
        ],
      ),
    );
  }
  // String _getTitleBySelectedType(int selectedType) {
  //   if (selectedType == 1) return "บัญชีของตัวเอง";
  //   if (selectedType == 2) return "บัญชีผู้อื่น";
  //   return "รายละเอียดบัญชี";
  // }

// ปุ่มไอคอนแบบ responsive
  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onTap, double screenWidth) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.025),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green, size: screenWidth * 0.06),
          ),
          SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.green[900], fontSize: screenWidth * 0.03)),
        ],
      ),
    );
  }
}
