import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import 'analytics_screen.dart';
import 'card_preview_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ProfileService.instance.getOrCreateProfile();
    if (mounted) setState(() => _profile = p);
  }

  Future<void> _editProfile() async {
    if (_profile == null) return;
    final updated = await Navigator.push<ProfileModel>(
      context,
      PageRouteBuilder(
        fullscreenDialog: true,
        pageBuilder: (_, a, __) => EditProfileScreen(profile: _profile!),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
    if (updated != null && mounted) setState(() => _profile = updated);
  }

  void _preview() {
    if (_profile == null) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        fullscreenDialog: true,
        pageBuilder: (_, a, __) => CardPreviewScreen(profile: _profile!),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  void _showAbout() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3C),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('CardDrop',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Version 1.0.0',
                style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
            const SizedBox(height: 20),
            const Text(
              'Your digital networking card. Share your contact info, '
              'social links, and professional details with a single tap or QR scan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  _AboutRow(label: 'Platform', value: 'iOS & macOS'),
                  SizedBox(height: 10),
                  _AboutRow(label: 'Backend', value: 'Supabase'),
                  SizedBox(height: 10),
                  _AboutRow(label: 'Profile Hosting', value: 'Netlify'),
                  SizedBox(height: 10),
                  _AboutRow(label: 'Developer', value: 'Open Source'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Open Source Project',
              style: TextStyle(fontSize: 12, color: Color(0xFF555555)),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelp() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3C),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Help & Support',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 20),
            _HelpTile(
              icon: Icons.qr_code_rounded,
              title: 'Sharing your card',
              body: 'Go to the Share tab to display your QR code. Anyone who scans it will see your public profile.',
            ),
            const SizedBox(height: 10),
            _HelpTile(
              icon: Icons.people_outline_rounded,
              title: 'Managing contacts',
              body: 'Contacts appear in the Contacts tab when someone shares their info with you or you add them manually.',
            ),
            const SizedBox(height: 10),
            _HelpTile(
              icon: Icons.calendar_today_rounded,
              title: 'Using events',
              body: 'Create events to categorize contacts by occasion (conferences, meetups, etc). Filter and export by event.',
            ),
            const SizedBox(height: 10),
            _HelpTile(
              icon: Icons.bar_chart_rounded,
              title: 'Analytics',
              body: 'View who scanned your card, when, and from which device in Settings > Analytics.',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, top + 16, 16, 28),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF3A3A3C), width: 0.5),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Invite',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                        SizedBox(width: 5),
                        Text('🎁', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Profile section ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _Section(items: [
              _RowItem(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                subtitle: _profile?.displayName ?? '',
                onTap: _editProfile,
              ),
              _RowItem(
                icon: Icons.open_in_browser_rounded,
                label: 'Preview Card',
                subtitle: 'See your public profile',
                onTap: _preview,
              ),
            ]),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Analytics ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _Section(items: [
              _RowItem(
                icon: Icons.bar_chart_rounded,
                label: 'Analytics',
                subtitle: 'Views, saves & visitor details',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AnalyticsScreen(key: ValueKey(DateTime.now())),
                  ),
                ),
              ),
            ]),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── App section ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _Section(items: [
              _RowItem(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () => _showHelp(),
              ),
              _RowItem(
                icon: Icons.info_outline_rounded,
                label: 'About CardDrop',
                subtitle: 'Version 1.0',
                onTap: () => _showAbout(),
              ),
            ]),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

// ── iOS-style section group ───────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final List<_RowItem> items;
  const _Section({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                e.value,
                if (!isLast)
                  const Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: Color(0xFF2C2C2C),
                      indent: 50),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Settings row ─────────────────────────────────────────────────────────────

class _RowItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _RowItem({
    required this.icon,
    required this.label,
    this.subtitle = '',
    required this.onTap,
  });

  @override State<_RowItem> createState() => _RowItemState();
}

class _RowItemState extends State<_RowItem> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => setState(() => _p = true),
    onTapUp:     (_) { setState(() => _p = false); HapticFeedback.lightImpact(); widget.onTap(); },
    onTapCancel: ()  => setState(() => _p = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      color: _p ? Colors.white.withOpacity(0.06) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(widget.icon, size: 21, color: Colors.white70),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label,
                    style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w400)),
                if (widget.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(widget.subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8E8E93))),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 16, color: Color(0xFF555555)),
        ],
      ),
    ),
  );
}

// ── About row ────────────────────────────────────────────────────────────────

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
      const Spacer(),
      Text(value,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
    ],
  );
}

// ── Help tile ────────────────────────────────────────────────────────────────

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _HelpTile({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF2C2C2E),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8E8E93)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 4),
              Text(body,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF8E8E93), height: 1.5)),
            ],
          ),
        ),
      ],
    ),
  );
}
