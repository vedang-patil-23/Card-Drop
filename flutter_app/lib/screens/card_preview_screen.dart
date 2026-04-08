import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

/// In-app preview of how the public profile card looks to visitors.
class CardPreviewScreen extends StatelessWidget {
  final ProfileModel profile;
  const CardPreviewScreen({super.key, required this.profile});

  String get _profileUrl => ProfileService.instance.profileUrl(profile.id);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final socialLinks = profile.socialLinks
        .where((l) => l.isActive && l.url.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // ── Top bar
          Container(
            padding: EdgeInsets.fromLTRB(8, top + 8, 8, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Card Preview',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_browser_rounded,
                      color: Colors.white70, size: 22),
                  onPressed: () async {
                    final url = Uri.parse(_profileUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),

          // ── Preview content (simulates the Netlify public page)
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 40 + bottom),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Avatar + Name
                      Row(
                        children: [
                          _Avatar(profile: profile),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.displayName.isNotEmpty
                                      ? profile.displayName
                                      : 'No Name',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                    height: 1.2,
                                  ),
                                ),
                                if (profile.jobTitle.isNotEmpty ||
                                    profile.company.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    [profile.jobTitle, profile.company]
                                        .where((s) => s.isNotEmpty)
                                        .join(' · '),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      // ── Bio
                      if (profile.bio.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          profile.bio,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E8E93),
                            height: 1.6,
                          ),
                        ),
                      ],

                      // ── Contact rows
                      const SizedBox(height: 20),
                      Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if (profile.email.isNotEmpty)
                              _ContactRow(
                                icon: Icons.email_outlined,
                                text: profile.email,
                                showBorder: profile.phone.isNotEmpty ||
                                    profile.website.isNotEmpty,
                              ),
                            if (profile.phone.isNotEmpty)
                              _ContactRow(
                                icon: Icons.phone_outlined,
                                text: profile.phone,
                                showBorder: profile.website.isNotEmpty,
                              ),
                            if (profile.website.isNotEmpty)
                              _ContactRow(
                                icon: Icons.language_rounded,
                                text: profile.website,
                                showBorder: false,
                              ),
                          ],
                        ),
                      ),

                      // ── Social links
                      if (socialLinks.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: socialLinks.map((link) {
                            final p = SocialPlatform.findById(link.platform);
                            final color = p != null
                                ? Color(p.color)
                                : Colors.white;
                            return Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                _platformIcon(link.platform),
                                size: 20,
                                color: color,
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // ── Action buttons
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Save Contact',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.18)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Share My Info',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ── Branding
                      const SizedBox(height: 32),
                      Center(
                        child: RichText(
                          text: const TextSpan(
                            text: 'Powered by ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF3A3A3C),
                            ),
                            children: [
                              TextSpan(
                                text: 'CardDrop',
                                style: TextStyle(
                                  color: Color(0xFF636366),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom bar with URL
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF1C1C1E), width: 0.5),
              ),
            ),
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _profileUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied'),
                    backgroundColor: Color(0xFF1C1C1E),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.link_rounded,
                      size: 14, color: Color(0xFF555555)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _profileUrl,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF555555),
                        fontFamily: 'ui-monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy_rounded,
                      size: 12, color: Color(0xFF555555)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _platformIcon(String id) {
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
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final ProfileModel profile;
  const _Avatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final initial = (profile.displayName.isNotEmpty
        ? profile.displayName[0]
        : '?')
        .toUpperCase();

    if (profile.photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profile.photoUrl,
          width: 72, height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(initial),
        ),
      );
    }
    return _placeholder(initial);
  }

  Widget _placeholder(String ch) => Container(
    width: 72, height: 72,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color(0xFF2C2C2E),
    ),
    alignment: Alignment.center,
    child: Text(ch, style: const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    )),
  );
}

// ── Contact row ───────────────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool showBorder;
  const _ContactRow({
    required this.icon,
    required this.text,
    required this.showBorder,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      border: showBorder
          ? const Border(
              bottom: BorderSide(
                  color: Color(0x10FFFFFF), width: 0.5))
          : null,
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8E8E93)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(Icons.chevron_right_rounded,
            size: 14, color: Color(0xFF555555)),
      ],
    ),
  );
}
