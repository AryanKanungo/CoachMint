import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/widgets.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _ctrls =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;
  int _resend = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() { if (_resend > 0) _resend--; });
      return _resend > 0;
    });
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  void _onDigit(int i, String v) {
    if (v.length == 1 && i < 5) _nodes[i + 1].requestFocus();
    if (_otp.length == 6) _verify();
  }


  Future<void> _verify() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    await Supabase.instance.client.from('users').upsert(
        {'id': userId, 'phone_hash': userId, 'income_type': 'gig'},
        onConflict: 'id');
    context.go('/onboarding');
    if (_otp.length != 6) return;
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.verifyOTP(
          phone: widget.phone, token: _otp, type: OtpType.sms);
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('users').upsert(
          {'id': userId, 'phone_hash': userId, 'income_type': 'gig'},
          onConflict: 'id');
      if (mounted) context.go('/onboarding');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Invalid OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(backgroundColor: AppTheme.surface),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter OTP',
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(
              'Sent to ${widget.phone}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 40),

            // OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => SizedBox(
                width: 48,
                child: TextField(
                  controller: _ctrls[i],
                  focusNode: _nodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  autofocus: i == 0,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.brand, width: 2),
                    ),
                  ),
                  onChanged: (v) => _onDigit(i, v),
                ),
              )),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  style: const TextStyle(
                      color: AppTheme.danger, fontSize: 13)),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: CMButton(
                  label: 'Verify OTP',
                  onPressed: _verify,
                  loading: _loading),
            ),
            const SizedBox(height: 20),

            // Resend
            Center(
              child: GestureDetector(
                onTap: () async {
                  if (_resend > 0) return;
                  await Supabase.instance.client.auth
                      .signInWithOtp(phone: widget.phone);
                  setState(() => _resend = 30);
                  _startTimer();
                },
                child: Text(
                  _resend > 0
                      ? 'Resend in ${_resend}s'
                      : 'Resend OTP',
                  style: TextStyle(
                      color: _resend > 0
                          ? AppTheme.textMuted
                          : AppTheme.brand,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}