import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:koperasiapp/constants.dart';
import 'package:http/http.dart' as http;

class ReceiptPage extends StatefulWidget {
  // final String member_no;
  // final String br_no;
  const ReceiptPage({super.key});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Constants.bg,
        appBar: AppBar(
          backgroundColor: Constants.primaryColor,
          title: const Center(
            child: Text(
              'ใบเสร็จ',
              style:
                  TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
        ),
        body: const SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.stop,
                        color: Color.fromARGB(255, 0, 87, 31),
                        size: 30.0,
                      ),
                      Text(
                        'ใบเสร็จของฉัน',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                ],
              )),
        ),
      ),
    );
  }
}
