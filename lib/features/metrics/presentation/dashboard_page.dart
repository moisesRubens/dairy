import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/format/formatters.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../data/metrics_repository.dart';
import '../domain/metrics.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(metricsSummaryProvider);
    final byPoint = ref.watch(revenueByPointProvider);

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () async {
        ref.invalidate(metricsSummaryProvider);
        ref.invalidate(revenueByPointProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text('PAINEL DO ADMINISTRADOR',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: AppSpacing.lg),
          AsyncValueWidget<MetricsSummary>(
            value: summary,
            onRetry: () => ref.invalidate(metricsSummaryProvider),
            data: (s) => Column(
              children: [
                _RevenueHeroCard(summary: s),
                const SizedBox(height: AppSpacing.md),
                if (s.pendingRequests > 0)
                  _PendingApprovalsCard(count: s.pendingRequests),
                const SizedBox(height: AppSpacing.md),
                _KpiRow(summary: s),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('FATURAMENTO POR PONTO',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.grey)),
          const SizedBox(height: AppSpacing.sm),
          AsyncValueWidget<List<PointRevenue>>(
            value: byPoint,
            onRetry: () => ref.invalidate(revenueByPointProvider),
            data: (points) => _RankingCard(points: points),
          ),
        ],
      ),
    );
  }
}

class _RevenueHeroCard extends StatelessWidget {
  final MetricsSummary summary;
  const _RevenueHeroCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(AppRadii.revenue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FATURAMENTO HOJE',
              style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1)),
          const SizedBox(height: AppSpacing.sm),
          Text(currencyBRL(summary.revenueToday),
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          Divider(color: Colors.grey[800], height: 1),
          const SizedBox(height: AppSpacing.sm),
          Text('Total acumulado   ${currencyBRL(summary.totalRevenue)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

class _PendingApprovalsCard extends StatelessWidget {
  final int count;
  const _PendingApprovalsCard({required this.count});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFEF6C00);
    // Borda uniforme + faixa lateral interna (não usar Border não-uniforme
    // com borderRadius — o Flutter não pinta e o card desaparece).
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.revenue),
      onTap: () => context.go('/admin/requests'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.revenue),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(AppRadii.revenue),
            border: Border.all(color: context.borderColor),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 5, color: orange),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: orange),
                        const SizedBox(width: AppSpacing.md),
                        const Expanded(
                          child: Text('Aprovações pendentes',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadii.table),
                          ),
                          child: Text('$count',
                              style: const TextStyle(
                                  color: orange, fontWeight: FontWeight.bold)),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final MetricsSummary summary;
  const _KpiRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _kpi(context, 'PEDIDOS', '${summary.ordersCount}'),
        const SizedBox(width: AppSpacing.md),
        _kpi(context, 'PRODUTOS', '${summary.productsCount}'),
        const SizedBox(width: AppSpacing.md),
        _kpi(context, 'VENDEDORES', '${summary.vendorsCount}'),
      ],
    );
  }

  Widget _kpi(BuildContext context, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: BorderRadius.circular(AppRadii.table),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.grey,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  final List<PointRevenue> points;
  const _RankingCard({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const EmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'Sem vendas ainda',
        subtitle: 'O ranking aparece quando os pontos registrarem vendas.',
      );
    }
    final maxRevenue = points
        .map((p) => p.revenue)
        .fold<double>(0, (a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity)
        .toDouble();

    return Container(
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.table),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          for (int i = 0; i < points.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.lg),
            _RankingRow(rank: i + 1, point: points[i], maxRevenue: maxRevenue),
          ],
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final int rank;
  final PointRevenue point;
  final double maxRevenue;
  const _RankingRow(
      {required this.rank, required this.point, required this.maxRevenue});

  @override
  Widget build(BuildContext context) {
    final double fraction = (point.revenue / maxRevenue).clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('$rank  ',
                style: const TextStyle(
                    color: AppColors.grey, fontWeight: FontWeight.bold)),
            Expanded(
              child: Text(point.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            Text(currencyBRL(point.revenue),
                style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.input),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: context.mutedSurface,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.green),
            ),
          ),
        ),
      ],
    );
  }
}
