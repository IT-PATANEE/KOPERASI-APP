// Flutter Terms & Conditions UX – production-style example
// - Disabled "Accept" until scrolled to bottom AND user ticks a consent checkbox
// - Reading progress indicator
// - Sticky bottom action bar with Decline/Accept
// - Links to Privacy Policy / Help (placeholders)
// - Returns `true` via Navigator when accepted
//
// Drop this file into `lib/terms_page.dart` and set `home: TermsPage()` in MaterialApp
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

import 'package:flutter/gestures.dart';

// void main() {
//   runApp(const TermsDemoApp());
// }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final ScrollController _scroll = ScrollController();
  bool _scrolledToBottom = false;
  bool _consentChecked = false;
  double _progress = 0.0; // 0..1 reading progress

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final offset = _scroll.offset.clamp(0.0, max);
    final p = max == 0 ? 1.0 : (offset / max);
    final atBottom = _scroll.position.pixels >= max - 8; // allow tiny tolerance
    if (mounted) {
      setState(() {
        _progress = p;
        _scrolledToBottom = atBottom;
      });
    }
  }

  bool get _canAccept => _scrolledToBottom && _consentChecked;

  Future<void> _confirmDecline() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการปฏิเสธ?'),
        content: const Text(
          'คุณยังไม่ได้ยอมรับข้อกำหนดและเงื่อนไข หากปฏิเสธ คุณจะไม่สามารถดำเนินการต่อได้.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก')),
          FilledButton.tonal(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ปฏิเสธ')),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.pop(context, false);
    }
  }

  void _onAccept() {
    // Persist a local flag if needed (e.g., SharedPreferences) then pop
    // For demo, we just pop with result=true
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อกำหนดและเงื่อนไข'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: _progress.clamp(0.02, 1.0)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: const [
                _MetaHeader(),
                SizedBox(height: 12),
                _Callouts(),
                SizedBox(height: 16),
                _TermsContent(),
                SizedBox(height: 80), // breathing room above sticky actions
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _consentChecked,
                  onChanged: (v) =>
                      setState(() => _consentChecked = v ?? false),
                ),
                const Expanded(
                  child: Text(
                      'ฉันได้อ่านและยอมรับข้อกำหนดและเงื่อนไข รวมถึงนโยบายความเป็นส่วนตัว'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _confirmDecline,
                    child: const Text('ปฏิเสธ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _canAccept ? _onAccept : null,
                    child: const Text('ยอมรับและดำเนินการต่อ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaHeader extends StatelessWidget {
  const _MetaHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ข้อตกลงผู้ใช้ (User Agreement)',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('ปรับปรุงล่าสุด: 15 สิงหาคม 2025  ·  เวอร์ชัน 1.0',
            style: textTheme.bodySmall),
        const SizedBox(height: 12),
        Text(
            'โปรดอ่านโดยละเอียด การกดยอมรับหมายถึงคุณยอมรับข้อกำหนดทั้งหมดด้านล่างนี้ รวมถึงนโยบายความเป็นส่วนตัวและแนวปฏิบัติด้านข้อมูล.',
            style: textTheme.bodyMedium),
      ],
    );
  }
}

class _Callouts extends StatelessWidget {
  const _Callouts();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoCard(
          icon: Icons.verified_user,
          title: 'ความปลอดภัยของบัญชี',
          body:
              'อย่าเปิดเผยรหัสผ่าน/OTP กับผู้อื่น ทีมงานจะไม่ถามข้อมูลนี้ทางแชตหรือโทรศัพท์.',
        ),
        const SizedBox(height: 8),
        _InfoCard(
          icon: Icons.privacy_tip,
          title: 'นโยบายความเป็นส่วนตัว',
          body:
              'เราเก็บข้อมูลเท่าที่จำเป็นเพื่อให้บริการ คุณสามารถอ่านรายละเอียดเพิ่มได้ที่ Privacy Policy.',
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _InfoCard(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: '1) การยอมรับข้อตกลง',
          child: const Text(
            'โดยการสร้างบัญชีหรือใช้งานแอพนี้ คุณตกลงว่าจะปฏิบัติตามข้อกำหนดและนโยบายทั้งหมดที่ระบุไว้ในเอกสารฉบับนี้.',
          ),
        ),
        _Section(
          title: '2) การเก็บและใช้ข้อมูล',
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                const TextSpan(
                  text:
                      'เราเก็บข้อมูลส่วนบุคคลเท่าที่จำเป็นเพื่อให้บริการตามวัตถุประสงค์ เช่น การยืนยันตัวตนและการให้บริการลูกค้า รายละเอียดเพิ่มเติมโปรดอ่าน ',
                ),
                TextSpan(
                  text: 'นโยบายความเป็นส่วนตัว',
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: Navigate to Privacy Policy page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('เปิด Privacy Policy (ตัวอย่าง)')),
                      );
                    },
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        const _Section(
          title: '3) ความปลอดภัยของบัญชี',
          child: Text(
            'คุณต้องรับผิดชอบต่อการเก็บรักษาความลับของข้อมูลเข้าสู่ระบบ หากพบการใช้งานที่ไม่ได้รับอนุญาตโปรดติดต่อฝ่ายสนับสนุนทันที.',
          ),
        ),
        const _Section(
          title: '4) ข้อจำกัดความรับผิด',
          child: Text(
            'เราไม่รับผิดชอบต่อความเสียหายทางอ้อมหรือผลสืบเนื่องที่เกิดขึ้นจากการใช้งาน เว้นแต่ที่กฎหมายบังคับกำหนดไว้อย่างชัดแจ้ง.',
          ),
        ),
        const _Section(
          title: '5) การแก้ไขข้อกำหนด',
          child: Text(
            'เราอาจปรับปรุงข้อกำหนดเป็นครั้งคราว โดยจะแจ้งให้ทราบล่วงหน้าในแอพก่อนมีผลบังคับใช้.',
          ),
        ),
        const _Section(
          title: '6) การยุติการให้บริการ',
          child: Text(
            'เราอาจระงับหรือยุติการให้บริการแก่บัญชีที่ฝ่าฝืนข้อกำหนดหรือมีพฤติกรรมที่ไม่เหมาะสมตามดุลยพินิจของเรา.',
          ),
        ),
        _Section(
          title: '7) ติดต่อเรา',
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                const TextSpan(text: 'ต้องการความช่วยเหลือ? ติดต่อ '),
                TextSpan(
                  text: 'ฝ่ายสนับสนุน',
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: open support/contact
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('เปิดหน้าติดต่อ (ตัวอย่าง)')),
                      );
                    },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'หมายเหตุ: เนื้อหานี้เป็นตัวอย่างเพื่อการออกแบบ UX เท่านั้น โปรดปรึกษาทนายหรือทีมกฎหมายเพื่อข้อความฉบับจริง.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
