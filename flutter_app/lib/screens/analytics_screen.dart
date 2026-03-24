import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/analytics_model.dart';
import '../services/supabase_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/section_header.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsSummary? _summary;
  bool _loading = true;
  String? _profileId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileService.instance.getOrCreateProfile();
    _profileId = profile.id;
    final summary = await SupabaseService.instance.fetchAnalytics(profile.id);
    if (mounted) setState(() { _summary = summary; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: ShaderMask(
          shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
          child: const Text(
            'Analytics',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                size: 20, color: AppColors.textSecondary),
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final s = _summary!;
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        setState(() => _loading = true);
        await _load();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Stat cards grid
          _buildStatsGrid(s).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 28),

          // Chart
          _buildViewsChart(s).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 28),

          // Source breakdown
          _buildSourceBreakdown(s).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 28),

          // Profile ID (for debug/sharing)
          _buildProfileId().animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AnalyticsSummary s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Overview'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            StatCard(
              label: 'Total Views',
              value: '${s.totalViews}',
              icon: Icons.visibility_rounded,
              color: AppColors.primary,
              subtitle: '+${s.viewsToday} today',
            ),
            StatCard(
              label: 'This Week',
              value: '${s.viewsThisWeek}',
              icon: Icons.trending_up_rounded,
              color: AppColors.accent,
            ),
            StatCard(
              label: 'Leads Captured',
              value: '${s.totalLeads}',
              icon: Icons.person_add_rounded,
              color: AppColors.success,
            ),
            StatCard(
              label: 'Contacts Saved',
              value: '${s.totalContacts}',
              icon: Icons.contacts_rounded,
              color: AppColors.warning,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewsChart(AnalyticsSummary s) {
    if (s.last30Days.isEmpty || s.totalViews == 0) {
      return const SizedBox.shrink();
    }

    final maxY = s.last30Days
        .map((d) => d.count.toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Views — Last 30 Days'),
        Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY == 0 ? 5 : maxY * 1.3,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY == 0 ? 1 : (maxY / 4).ceilToDouble(),
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.border,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textHint),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 7,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= s.last30Days.length) return const SizedBox();
                      final d = s.last30Days[idx].date;
                      return Text(
                        '${d.day}/${d.month}',
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.textHint),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: s.last30Days.asMap().entries.map((e) =>
                    FlSpot(e.key.toDouble(), e.value.count.toDouble()),
                  ).toList(),
                  isCurved: true,
                  gradient: const LinearGradient(
                    colors: [AppColors.gradStart, AppColors.gradEnd],
                  ),
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: spot.y == 0 ? 0 : 3,
                      color: AppColors.primary,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.primary.withOpacity(0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceBreakdown(AnalyticsSummary s) {
    if (s.viewsBySource.isEmpty) return const SizedBox.shrink();
    final total = s.totalViews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Views by Source'),
        ...s.viewsBySource.entries.map((entry) {
          final pct = total == 0 ? 0.0 : entry.value / total;
          return _SourceBar(
            label: entry.key.toUpperCase(),
            count: entry.value,
            pct: pct,
          );
        }),
      ],
    );
  }

  Widget _buildProfileId() {
    if (_profileId == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.fingerprint_rounded,
              size: 16, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Profile ID',
                    style: TextStyle(fontSize: 11,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w600)),
                Text(
                  _profileId!,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceBar extends StatelessWidget {
  final String label;
  final int count;
  final double pct;

  const _SourceBar({
    required this.label,
    required this.count,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const Spacer(),
              Text('$count',
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text('  ${(pct * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11,
                      color: AppColors.textHint)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
