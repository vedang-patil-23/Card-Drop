import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../widgets/profile_card_widget.dart';
import 'card_preview_screen.dart';
import 'edit_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProfileModel? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ProfileService.instance.getOrCreateProfile();
    if (mounted) setState(() { _profile = p; _loading = false; });
  }

  Future<void> _edit() async {
    if (_profile == null) return;
    final updated = await Navigator.push<ProfileModel>(
      context,
      PageRouteBuilder(
        fullscreenDialog: true,
        pageBuilder: (_, a, b) => EditProfileScreen(profile: _profile!),
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

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 1))
          : CustomScrollView(
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, top + 16, 16, 0),
                    child: Row(
                      children: [
                        const Spacer(),
                        Text(
                          _profile?.displayName.isNotEmpty == true
                              ? _profile!.displayName
                              : 'Your Card',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        _IconBtn(icon: Icons.add, onTap: _edit),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Edit / Preview pills ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _PillBtn(label: 'Edit',    onTap: _edit),
                        const SizedBox(width: 10),
                        _PillBtn(label: 'Preview', onTap: _preview),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── Card ────────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _profile == null || _profile!.isEmpty
                        ? _SetupCard(onTap: _edit)
                        : ProfileCardWidget(
                            profile:    _profile!,
                            qrUrl:      ProfileService.instance.profileUrl(_profile!.id),
                            onMenuTap:  _edit,
                          ),
                  ),
                ),

                // ── Social links strip ──────────────────────────────────────
                if (_profile != null &&
                    _profile!.socialLinks.any((l) => l.isActive && l.url.isNotEmpty)) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SocialStrip(profile: _profile!),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
    );
  }
}

// ── Social strip ──────────────────────────────────────────────────────────────

class _SocialStrip extends StatelessWidget {
  final ProfileModel profile;
  const _SocialStrip({required this.profile});

  IconData _icon(String id) {
    const m = {
      'linkedin': Icons.work_rounded,
      'instagram': Icons.camera_alt_rounded,
      'twitter': Icons.alternate_email_rounded,
      'tiktok': Icons.music_note_rounded,
      'facebook': Icons.facebook_rounded,
      'youtube': Icons.smart_display_rounded,
      'github': Icons.code_rounded,
      'snapchat': Icons.chat_bubble_rounded,
      'website': Icons.language_rounded,
      'calendly': Icons.calendar_today_rounded,
      'cashapp': Icons.attach_money_rounded,
      'venmo': Icons.payments_rounded,
    };
    return m[id] ?? Icons.link_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final active = profile.socialLinks
        .where((l) => l.isActive && l.url.isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LINKS',
          style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: Color(0xFF555555), letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: active.map((link) {
            final p = SocialPlatform.findById(link.platform);
            final c = p != null ? Color(p.color) : Colors.white;
            final dc = c.computeLuminance() < 0.02 ? const Color(0xFF8E8E93) : c;
            return Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
              ),
              alignment: Alignment.center,
              child: Icon(_icon(link.platform), size: 20, color: dc),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Pill button ───────────────────────────────────────────────────────────────

class _PillBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PillBtn({required this.label, required this.onTap});
  @override State<_PillBtn> createState() => _PillBtnState();
}

class _PillBtnState extends State<_PillBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => setState(() => _p = true),
    onTapUp:     (_) { setState(() => _p = false); HapticFeedback.lightImpact(); widget.onTap(); },
    onTapCancel: ()  => setState(() => _p = false),
    child: AnimatedScale(
      scale: _p ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        height: 36,
        constraints: const BoxConstraints(minWidth: 90),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF3A3A3C), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

// ── Icon button ───────────────────────────────────────────────────────────────

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => setState(() => _p = true),
    onTapUp:     (_) { setState(() => _p = false); widget.onTap(); },
    onTapCancel: ()  => setState(() => _p = false),
    child: AnimatedScale(
      scale: _p ? 0.88 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: SizedBox(
        width: 36, height: 36,
        child: Icon(widget.icon, size: 26, color: Colors.white),
      ),
    ),
  );
}

// ── Setup card ────────────────────────────────────────────────────────────────

class _SetupCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SetupCard({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.person_add_rounded, size: 44, color: Colors.white54),
          SizedBox(height: 16),
          Text('Set up your card', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white,
          )),
          SizedBox(height: 6),
          Text('Tap to add your info',
              style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93))),
        ],
      ),
    ),
  );
}
