import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/analytics_model.dart';
import '../services/supabase_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

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
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 0),
            child: Row(
              children: [
                // Back button — only shown when pushed onto a navigator stack
                if (Navigator.of(context).canPop())
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.chevron_left_rounded,
                          size: 28, color: AppColors.textPrimary),
                    ),
                  ),
                const Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () { setState(() => _loading = true); _load(); },
                  child: const Icon(Icons.refresh_rounded,
                      size: 18, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Body ─────────────────────────────────────────────────────────────
          if (_loading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 1.5),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: () async { setState(() => _loading = true); await _load(); },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
                  children: [
                    _buildStatPills(_summary!),
                    const SizedBox(height: 32),
                    if (_summary!.totalViews > 0) ...[
                      _buildChart(_summary!),
                      const SizedBox(height: 32),
                    ],
                    if (_summary!.viewsBySource.isNotEmpty) ...[
                      _buildSourceBreakdown(_summary!),
                      const SizedBox(height: 32),
                    ],
                    if (_summary!.recentViewers.isNotEmpty) ...[
                      _buildRecentViewers(_summary!.recentViewers),
                      const SizedBox(height: 32),
                    ],
                    if (_profileId != null) _buildProfileId(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Stat pills ────────────────────────────────────────────────────────────────

  Widget _buildStatPills(AnalyticsSummary s) {
    final pills = [
      ('TOTAL VIEWS', '${s.totalViews}'),
      ('THIS WEEK',   '${s.viewsThisWeek}'),
      ('TODAY',       '${s.viewsToday}'),
      ('SAVED',       '${s.contactSaves}'),
      ('LEADS',       '${s.totalLeads}'),
    ];

    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: pills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _StatPill(label: pills[i].$1, value: pills[i].$2),
      ),
    );
  }

  // ── Line chart ────────────────────────────────────────────────────────────────

  Widget _buildChart(AnalyticsSummary s) {
    final maxY = s.last30Days
        .map((d) => d.count.toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('VIEWS — LAST 30 DAYS'),
          const SizedBox(height: 14),
          Container(
            height: 160,
            padding: const EdgeInsets.fromLTRB(4, 12, 12, 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
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
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.border, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(fontSize: 9, color: AppColors.textHint),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      interval: 7,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= s.last30Days.length) {
                          return const SizedBox();
                        }
                        final d = s.last30Days[idx].date;
                        return Text('${d.day}/${d.month}',
                            style: const TextStyle(
                                fontSize: 9, color: AppColors.textHint));
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: s.last30Days.asMap().entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
                        .toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 1.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: spot.y == 0 ? 0 : 2.5,
                        color: AppColors.primary,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Source breakdown ──────────────────────────────────────────────────────────

  Widget _buildSourceBreakdown(AnalyticsSummary s) {
    final total = s.totalViews;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('BY SOURCE'),
          const SizedBox(height: 14),
          ...s.viewsBySource.entries.map((entry) {
            final pct = total == 0 ? 0.0 : entry.value / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(entry.key.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary, letterSpacing: 0.8)),
                      const Spacer(),
                      Text('${entry.value}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text('  ${(pct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 3,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Recent Viewers ────────────────────────────────────────────────────────────

  Widget _buildRecentViewers(List<ViewEvent> viewers) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('RECENT VISITORS'),
          const SizedBox(height: 14),
          ...viewers.map((v) => _ViewerRow(event: v)),
        ],
      ),
    );
  }

  // ── Profile ID ────────────────────────────────────────────────────────────────

  Widget _buildProfileId() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.fingerprint_rounded,
                size: 14, color: AppColors.textHint),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PROFILE ID',
                      style: TextStyle(fontSize: 9, color: AppColors.textHint,
                          fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                  const SizedBox(height: 2),
                  Text(_profileId!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary,
                          fontFamily: 'ui-monospace')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'ui-monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600,
              color: AppColors.textHint, letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerRow extends StatelessWidget {
  final ViewEvent event;
  const _ViewerRow({required this.event});

  IconData _deviceIcon() {
    final d = event.deviceName.toLowerCase();
    if (d.contains('iphone') || d.contains('android')) return Icons.smartphone_rounded;
    if (d.contains('ipad'))                             return Icons.tablet_rounded;
    if (d.contains('mac') || d.contains('windows') ||
        d.contains('linux') || d.contains('pc'))        return Icons.computer_rounded;
    return Icons.devices_rounded;
  }

  String _timeLabel() {
    final diff = DateTime.now().difference(event.viewedAt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(event.viewedAt);
  }

  @override
  Widget build(BuildContext context) {
    final device = event.deviceName.isNotEmpty ? event.deviceName : 'Unknown Device';
    final ip     = event.ipAddress.isNotEmpty  ? event.ipAddress  : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_deviceIcon(), size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(ip,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint,
                        fontFamily: 'ui-monospace')),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_timeLabel(),
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              if (event.contactSaved) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: const Color(0xFF0A84FF).withOpacity(0.3),
                        width: 0.5),
                  ),
                  child: const Text('SAVED',
                      style: TextStyle(
                          fontSize: 8, fontWeight: FontWeight.w700,
                          color: Color(0xFF0A84FF), letterSpacing: 0.8)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: AppColors.textHint, letterSpacing: 1.4,
    ),
  );
}
