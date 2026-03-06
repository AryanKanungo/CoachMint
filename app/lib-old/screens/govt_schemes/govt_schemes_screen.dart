import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/scheme_service.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';
import '../../common_widgets/widgets.dart';

class GovtSchemesScreen extends StatefulWidget {
  const GovtSchemesScreen({super.key});

  @override
  State<GovtSchemesScreen> createState() => _GovtSchemesScreenState();
}

class _GovtSchemesScreenState extends State<GovtSchemesScreen> {
  final SchemeService _service = SchemeService();
  late Future<List<Map<String, dynamic>>> _schemesFuture;

  @override
  void initState() {
    super.initState();
    _schemesFuture = _service.fetchWelfareSchemes();
  }

  Future<void> _launchSchemeURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No application link available for this scheme.')),
        );
      }
      return;
    }

    final Uri url = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Govt Schemes'),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _schemesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final schemes = snapshot.data ?? [];

          if (schemes.isEmpty) {
            return const EmptyState(
              icon: Icons.account_balance_rounded,
              title: 'No Schemes Found',
              subtitle:
                  'Government welfare schemes will appear here once loaded.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: schemes.length,
            itemBuilder: (context, index) {
              final scheme = schemes[index];
              return _SchemeCard(
                scheme: scheme,
                onApply: () => _launchSchemeURL(scheme['apply_url']),
              );
            },
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// _SchemeCard
// ════════════════════════════════════════════════════════════════

class _SchemeCard extends StatelessWidget {
  final Map<String, dynamic> scheme;
  final VoidCallback onApply;

  const _SchemeCard({required this.scheme, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Scheme Name ─────────────────────────────────────
          Text(
            scheme['name'] ?? 'Unknown Scheme',
            style: GoogleFonts.dmSans(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          // ── Description ─────────────────────────────────────
          Text(
            scheme['description'] ?? '',
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          // ── Divider ─────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.border, thickness: 1),
          ),

          // ── Eligibility & Documents ─────────────────────────
          _buildTag('Who can apply?', scheme['eligibility']),
          const SizedBox(height: 10),
          _buildTag('Required Documents', scheme['documents']),

          const SizedBox(height: 18),

          // ── CTA Button ───────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onApply,
              child: const Text('Apply Now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, dynamic data) {
    String displayValue;
    if (data is List) {
      displayValue = data.join(' • ');
    } else if (data is Map) {
      displayValue =
          data.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    } else {
      displayValue = data?.toString() ?? 'Not specified';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayValue,
          style: GoogleFonts.dmSans(
            color: AppColors.textPrimary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
