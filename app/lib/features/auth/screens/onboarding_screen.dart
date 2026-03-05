import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/widgets.dart';
// ✅ Fixed import: SmsService lives in core/sms/, NOT in services/
import '../../../core/sms/sms_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  bool _saving = false;

  // Step 1
  String _incomeType = 'gig';
  // Step 2
  final _balCtrl = TextEditingController();
  // Step 3
  final _incAmtCtrl = TextEditingController();
  DateTime? _nextIncome;
  // Step 4
  final _billNameCtrl = TextEditingController();
  final _billAmtCtrl  = TextEditingController();
  DateTime? _billDate;

  final _incomeTypes  = ['gig', 'student', 'salaried', 'freelancer'];
  final _incomeLabels = ['Gig Worker', 'Student', 'Salaried', 'Freelancer'];
  final _incomeIcons  = [
    Icons.delivery_dining,
    Icons.school,
    Icons.business_center,
    Icons.computer,
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _balCtrl.dispose();
    _incAmtCtrl.dispose();
    _billNameCtrl.dispose();
    _billAmtCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 3) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
      setState(() => _page++);
    } else {
      _save();
    }
  }

  void _back() {
    if (_page > 0) {
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
      setState(() => _page--);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final userId =
          Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client
          .from('users')
          .update({'income_type': _incomeType})
          .eq('id', userId);

      await Supabase.instance.client.from('user_profile').upsert({
        'user_id':             userId,
        'starting_balance':    double.tryParse(_balCtrl.text) ?? 0,
        'current_wallet':      double.tryParse(_balCtrl.text) ?? 0,
        'next_income_date':    _nextIncome?.toIso8601String().split('T')[0],
        'expected_income':     double.tryParse(_incAmtCtrl.text),
        'income_source_label': _incomeLabels[
        _incomeTypes.indexOf(_incomeType)],
        'onboarding_complete': true,
      });

      final billName = _billNameCtrl.text.trim();
      final billAmt  = double.tryParse(_billAmtCtrl.text);
      if (billName.isNotEmpty && billAmt != null && _billDate != null) {
        await Supabase.instance.client.from('bills').insert({
          'user_id':  userId,
          'name':     billName,
          'amount':   billAmt,
          'due_date': _billDate!.toIso8601String().split('T')[0],
        });
      }

      // ✅ Start SMS listener after onboarding — creates SmsService locally,
      //    no global variable needed.
      await SmsService().init();

      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: List.generate(4, (i) => Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i <= _page
                          ? AppTheme.brand
                          : AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1(
                    selected: _incomeType,
                    types:    _incomeTypes,
                    labels:   _incomeLabels,
                    icons:    _incomeIcons,
                    onSelect: (v) => setState(() => _incomeType = v),
                  ),
                  _Step2(controller: _balCtrl),
                  _Step3(
                    amtCtrl:  _incAmtCtrl,
                    selected: _nextIncome,
                    onPicked: (d) => setState(() => _nextIncome = d),
                  ),
                  _Step4(
                    nameCtrl: _billNameCtrl,
                    amtCtrl:  _billAmtCtrl,
                    selected: _billDate,
                    onPicked: (d) => setState(() => _billDate = d),
                  ),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_page > 0) ...[
                    Expanded(
                      child: CMButton(
                          label: 'Back',
                          onPressed: _back,
                          outline: true),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: CMButton(
                      label: _page == 3 ? 'Get Started' : 'Continue',
                      onPressed: () => context.go('/dashboard'),
                      loading: _saving,
                      icon: _page == 3
                          ? Icons.rocket_launch_rounded
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 1: Income type ───────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final String selected;
  final List<String> types, labels;
  final List<IconData> icons;
  final ValueChanged<String> onSelect;

  const _Step1({
    required this.selected,
    required this.types,
    required this.labels,
    required this.icons,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('How do you earn?',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text('Helps us personalise your advice.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          ...List.generate(types.length, (i) {
            final active = selected == types[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onSelect(types[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: active
                        ? AppTheme.brand.withOpacity(0.1)
                        : AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active ? AppTheme.brand : AppTheme.border,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Icon(icons[i],
                        color: active
                            ? AppTheme.brand
                            : AppTheme.textMuted),
                    const SizedBox(width: 14),
                    Text(labels[i],
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? AppTheme.brand
                                : AppTheme.textPrimary)),
                    const Spacer(),
                    if (active)
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.brand, size: 20),
                  ]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Step 2: Wallet balance ────────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final TextEditingController controller;
  const _Step2({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Your wallet right now',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Roughly how much is in your account today?',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(children: [
              const Text('₹',
                  style: TextStyle(
                      fontSize: 32,
                      color: AppTheme.brand,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'))
                  ],
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const CMCard(
            child: Row(children: [
              Icon(Icons.lock_outline,
                  size: 16, color: AppTheme.brand),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SMS auto-updates this. This is just your starting point.',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Next income ───────────────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  final TextEditingController amtCtrl;
  final DateTime? selected;
  final ValueChanged<DateTime> onPicked;

  const _Step3({
    required this.amtCtrl,
    required this.selected,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Next income',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'When do you expect to get paid?',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: amtCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Expected amount (₹)', prefixText: '₹ '),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate:
                DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate:
                DateTime.now().add(const Duration(days: 60)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(
                        primary: AppTheme.brand,
                        surface: AppTheme.surfaceCard),
                  ),
                  child: child!,
                ),
              );
              if (d != null) onPicked(d);
            },
            child: AbsorbPointer(
              child: TextField(
                decoration: InputDecoration(
                  labelText: selected != null
                      ? '${selected!.day}/${selected!.month}/${selected!.year}'
                      : 'Pick date',
                  suffixIcon: const Icon(
                      Icons.calendar_today_rounded,
                      color: AppTheme.brand),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 4: Upcoming bill ─────────────────────────────────────────────────────

class _Step4 extends StatelessWidget {
  final TextEditingController nameCtrl, amtCtrl;
  final DateTime? selected;
  final ValueChanged<DateTime> onPicked;

  const _Step4({
    required this.nameCtrl,
    required this.amtCtrl,
    required this.selected,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Any upcoming bills?',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Add one to start. Skip if you have none.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          TextField(
              controller: nameCtrl,
              decoration:
              const InputDecoration(labelText: 'Bill name')),
          const SizedBox(height: 16),
          TextField(
            controller: amtCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+\.?\d{0,2}'))
            ],
            decoration: const InputDecoration(
                labelText: 'Amount', prefixText: '₹ '),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate:
                DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate:
                DateTime.now().add(const Duration(days: 365)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(
                        primary: AppTheme.brand,
                        surface: AppTheme.surfaceCard),
                  ),
                  child: child!,
                ),
              );
              if (d != null) onPicked(d);
            },
            child: AbsorbPointer(
              child: TextField(
                decoration: InputDecoration(
                  labelText: selected != null
                      ? '${selected!.day}/${selected!.month}/${selected!.year}'
                      : 'Due date',
                  suffixIcon: const Icon(
                      Icons.calendar_today_rounded,
                      color: AppTheme.brand),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}