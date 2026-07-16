import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:http/http.dart' as http;

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
  Uint8List _backgroundImage = Uint8List.fromList([]);
  Uint8List _qrCodeImage = Uint8List.fromList([]);
  bool _isLoading = true; // To track loading state

  Future<void> fetchImages() async {
    String qrCodeUrl =
        await _generateQrCode(); // Function to generate QR code URL
    try {
      final qrCodeResponse = await http.get(Uri.parse(qrCodeUrl));
      if (qrCodeResponse.statusCode == 200) {
        print('qr : $_qrCodeImage');
        setState(() {
          _qrCodeImage = qrCodeResponse.bodyBytes;
        });
      } else {
        throw Exception('Failed to load QR code');
      }
    } catch (e) {
      print('Error loading images: $e');
    } finally {
      setState(() {
        _isLoading = false; // Stop loading once both images are fetched
      });
    }
  }

  Future<String> _generateQrCode() async {
    String url = 'https://online.iscop.co.th/call_qrcode_flutter.php';
    Map<String, dynamic> data = {
      'type': widget.type.toString(),
      'ref1': '${widget.brNo}01${widget.memberNo}',
      'ref2': widget.toMem.isNotEmpty
          ? '${widget.toMem.substring(0, 3)}01${widget.toMem.substring(widget.toMem.length - 5)}'
          : '${widget.brNo}01${widget.memberNo}',
      'bal': '${widget.amount.toString()}00',
    };

    final response = await http.post(
      Uri.parse(url),
      body: data,
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData.containsKey('qrcode_base64')) {
        return 'data:image/png;base64,' + responseData['qrcode_base64'];
      } else {
        throw Exception('No QR Code content received');
      }
    } else {
      throw Exception('Error generating QR Code: ${response.statusCode}');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchImages();
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
                    // Display background image
                    if (_backgroundImage.isNotEmpty)
                      Image.memory(
                        _backgroundImage,
                        fit: BoxFit.cover,
                      )
                    else
                      const Text("ไม่สามารถโหลดภาพพื้นหลังได้"),

                    // Display QR Code
                    if (_qrCodeImage.isNotEmpty)
                      Image.memory(
                        _qrCodeImage,
                        fit: BoxFit.contain,
                      )
                    else
                      const Text("ไม่สามารถโหลด QR Code ได้"),
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
      return 'https://online.iscop.co.th/images/source_slips_qrcode/Slips-QR_group_share.jpg'; // Default image
  }
}
