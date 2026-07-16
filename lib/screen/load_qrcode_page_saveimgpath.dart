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
      var image = await boundary.toImage(pixelRatio: 3.0);

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
      if(!dirExists){
        await Directory(externalDir).create(recursive: true);
        dirExists = true;
      }

      final file = await File('$externalDir/$fileName.png').create();
      await file.writeAsBytes(pngBytes);

      if(!mounted)return;
      const snackBar = SnackBar(content: Text('QR code saved to gallery'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

    } catch (e) {
      print('Save image error: $e');
      if(!mounted)return;
      const snackBar = SnackBar(content: Text('ไม่สามารถบันทึกรูปภาพได้'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Constants.bg,
        appBar: AppBar(
          backgroundColor: Constants.primaryColor,
          title: Center(
            child: Text(
              _getTitleByType(widget.type),
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RepaintBoundary(
                      key: _repaintKey,
                      child: Card(
                        elevation: 8,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ชื่อบัญชี: ${widget.toMemName}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'เลขที่บัญชี: ${widget.toAccountNo}',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 20),
                              if (_qrCodeContent.isNotEmpty)
                                QrImageView(
                                  data: _qrCodeContent,
                                  version: QrVersions.auto,
                                  size: 200.0,
                                  backgroundColor: Colors.white,
                                  errorStateBuilder: (context, error) =>
                                      const Center(
                                    child: Text("ไม่สามารถสร้าง QR Code ได้"),
                                  ),
                                )
                              else
                                const Text("ไม่สามารถโหลด QR Code ได้"),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _saveAsImage,
                      icon: const Icon(Icons.download),
                      label: const Text('บันทึกเป็นภาพ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
