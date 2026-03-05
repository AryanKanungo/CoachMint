import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/repositories/repositories.dart';
import '../../../shared/widgets/widgets.dart' hide formatInr;


final welfareMatchesProvider =
FutureProvider.autoDispose<List<WelfareMatch>>((ref) async {
  return ref.watch(welfareRepoProvider).getMatches();
});

class WelfareScreen extends ConsumerWidget {
  const WelfareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(welfareMatchesProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Welfare Schemes')),
      body: matchesAsync.when(
        loading: () =>
        const Center(child: CircularProgressIndicator(color: AppTheme.brand)),
        error: (_, __) => const Center(
            child: Text('Error', style: TextStyle(color: AppTheme.textMuted))),
        data: (matches) {
          if (matches.isEmpty) {
            return const EmptyState(
              icon: Icons.volunteer_activism_outlined,
              title: 'No schemes matched yet',
              subtitle:
              'CoachMint checks monthly for government schemes you may qualify for. Check back soon.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: matches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _SchemeCard(
              match: matches[i],
              onApply: () async {
                await ref.read(welfareRepoProvider).markApplied(matches[i].id);
                ref.invalidate(welfareMatchesProvider);
              },
              onDismiss: () async {
                await ref.read(welfareRepoProvider).dismiss(matches[i].id);
                ref.invalidate(welfareMatchesProvider);
              },
            ),
          );
        },
      ),
    );
  }
}

class _SchemeCard extends StatelessWidget {
  final WelfareMatch match;
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  const _SchemeCard({
    required this.match,
    required this.onApply,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return CMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_rounded,
                    color: AppTheme.brand, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  match.schemeName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary),
                ),
              ),
              if (match.isApplied)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Applied',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            match.schemeDescription,
            style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5),
          ),
          if (match.documents.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Documents needed',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: match.documents
                  .map((doc) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(doc,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary)),
              ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CMButton(
                  label: 'Apply Now',
                  onPressed: match.applyUrl != null
                      ? () async {
                    final uri = Uri.parse(match.applyUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                    onApply();
                  }
                      : onApply,
                  icon: Icons.open_in_new_rounded,
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: onDismiss,
                child: const Text('Not now',
                    style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}