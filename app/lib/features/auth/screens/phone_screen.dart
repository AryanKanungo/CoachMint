import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/widgets.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _ctrl.text.trim();
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid 10-digit number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth
          .signInWithOtp(phone: '+91$phone');
      if (mounted) context.push('/otp', extra: '+91$phone');
    } catch (_) {
      setState(() => _error = 'Failed to send OTP. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),

              // Logo mark
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.brand.withOpacity(0.3)),
                ),
                child: const Center(
                  child: Text('₹',
                      style: TextStyle(
                          fontSize: 24, color: AppTheme.brand)),
                ),
              ),
              const SizedBox(height: 24),

              Text('CoachMint',
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                "Your money. Your rules.\nLet's build your financial safety net.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary, height: 1.5),
              ),

              const Spacer(flex: 3),

              Text('Mobile Number',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),

              // Phone input row
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 15),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Text('+91',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                        hintText: '9876543210', counterText: ''),
                    onSubmitted: (_) => _sendOtp(),
                  ),
                ),
              ]),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: const TextStyle(
                        color: AppTheme.danger, fontSize: 13)),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CMButton(
                    label: 'Get OTP',
                    onPressed: _sendOtp,
                    loading: _loading,
                    icon: Icons.arrow_forward_rounded),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Your number is never shared or stored in plain text.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textMuted),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}