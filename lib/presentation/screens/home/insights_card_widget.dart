import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/insights/insight_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/insights_provider.dart';

class InsightsCardWidget extends ConsumerWidget {
  const InsightsCardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);

    return insightsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (insights) {
        if (insights.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: insights.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _InsightCard(insight: insights[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Insight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgColor(insight.type),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor(insight.type), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon(insight.type),
                  size: 20, color: _iconColor(insight.type)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _iconColor(insight.type),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              insight.message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            insight.action,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _bgColor(InsightType type) {
    switch (type) {
      case InsightType.warning:
        return const Color(0xFFFFF4EC);
      case InsightType.tip:
        return const Color(0xFFF0F7F5);
      case InsightType.achievement:
        return const Color(0xFFF0F9F0);
    }
  }

  Color _borderColor(InsightType type) {
    switch (type) {
      case InsightType.warning:
        return AppColors.warning.withOpacity(0.4);
      case InsightType.tip:
        return AppColors.primary.withOpacity(0.3);
      case InsightType.achievement:
        return AppColors.onTrack.withOpacity(0.4);
    }
  }

  Color _iconColor(InsightType type) {
    switch (type) {
      case InsightType.warning:
        return AppColors.warning;
      case InsightType.tip:
        return AppColors.primary;
      case InsightType.achievement:
        return AppColors.onTrack;
    }
  }

  IconData _icon(InsightType type) {
    switch (type) {
      case InsightType.warning:
        return Icons.warning_amber_rounded;
      case InsightType.tip:
        return Icons.lightbulb_outline;
      case InsightType.achievement:
        return Icons.emoji_events;
    }
  }
}
