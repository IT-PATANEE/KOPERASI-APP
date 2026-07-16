import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:http/http.dart' as http;
import 'package:koperasiapp/screen/transfer_page.dart';

class SelectTransferPage extends StatefulWidget {
  final String member_no;
  final String br_no;
  final String token;

  const SelectTransferPage({
    super.key,
    required this.member_no,
    required this.br_no,
    required this.token,
  });

  @override
  State<SelectTransferPage> createState() => _SelectTransferPageState();
}

class _SelectTransferPageState extends State<SelectTransferPage> {
  late String _memberNo;
  late String _branchNo;
  String _token = '';

  String memberName = '';
  bool isMyAccount = true; // สถานะเลือก Tab

  @override
  void initState() {
    super.initState();

    _memberNo = widget.member_no;
    _branchNo = widget.br_no;
    _token = widget.token;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final w = media.size.width;
    final h = media.size.height;
    return Scaffold(
      backgroundColor: Constants.bg,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. Header Section ---
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
                        "เลือกรูปแบบการโอนเงิน",
                        style: theme.textTheme.titleLarge!.copyWith(
                          color: Constants.greenColors,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Constants.greenColors,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // const Divider(thickness: 1),

            // --- 2. Tab Selector (บัญชีของฉัน / บัญชีผู้อื่น) ---
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Constants.greyLight,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _buildTabButton("บัญชีของฉัน", isMyAccount, () {
                    setState(() => isMyAccount = true);
                  }),
                  _buildTabButton("บัญชีผู้อื่น", !isMyAccount, () {
                    setState(() => isMyAccount = false);
                  }),
                ],
              ),
            ),

            // --- 3. Grid Menu Items ---
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: GridView.count(
                  key: ValueKey(isMyAccount), // สำคัญมาก
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  crossAxisCount: 3,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 10,
                  children:
                      isMyAccount ? _myAccountMenus() : _otherAccountMenus(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _myAccountMenus() {
    return [
      _buildMenuItem("โอนเงินฝาก", 'assets/images/icon-menu/icon_09.png', '1'),
      _buildMenuItem(
          "ชำระสินเชื่อ", 'assets/images/icon-menu/icon_trf2.png', '3'),
      _buildMenuItem("ชำระหุ้น", 'assets/images/icon-menu/icon_trf3.png', '5'),
      _buildMenuItem(
          "ชำระตะอาวุน", 'assets/images/icon-menu/icon_trf4.png', '4'),   
      _buildMenuItem(
          "ชำระอัร-เราะห์นู", 'assets/images/icon-menu/icon_trf5.png', '18'),
    ];
  }

  List<Widget> _otherAccountMenus() {
    return [
      _buildMenuItem("โอนเงินฝาก", 'assets/images/icon-menu/icon_09.png', '2'),
      _buildMenuItem(
          "ชำระสินเชื่อ", 'assets/images/icon-menu/icon_trf2.png', '9'),
      _buildMenuItem("ชำระหุ้น", 'assets/images/icon-menu/icon_trf3.png', '10'),
      _buildMenuItem(
          "ชำระตะอาวุน", 'assets/images/icon-menu/icon_trf4.png', '17'),
      _buildMenuItem(
          "ชำระอัร-เราะห์นู", 'assets/images/icon-menu/icon_trf5.png', '19'),
    ];
  }

  Widget _buildTabButton(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Constants.greenColors : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String label, String imagePath, String type) {
    final theme = Theme.of(context);
    final w = MediaQuery.of(context).size.width;

    double circleSize = w * 0.2;

    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransferPage(
              member_no: _memberNo,
              br_no: _branchNo,
              token: widget.token,
              type: int.parse(type),
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Constants.greenColors, width: 2),
            ),
            child: Image.asset(
              imagePath,
              width: circleSize * 0.8,
              height: circleSize * 0.8,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge!
                .copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
