import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/profile_model.dart';

// Shared helper — used by home_screen social strip too
IconData platformIcon(String id) {
  const m = {
    'linkedin':  Icons.work_rounded,
    'instagram': Icons.camera_alt_rounded,
    'twitter':   Icons.alternate_email_rounded,
    'tiktok':    Icons.music_note_rounded,
    'facebook':  Icons.facebook_rounded,
    'youtube':   Icons.smart_display_rounded,
    'github':    Icons.code_rounded,
    'snapchat':  Icons.chat_bubble_rounded,
    'website':   Icons.language_rounded,
    'calendly':  Icons.calendar_today_rounded,
    'cashapp':   Icons.attach_money_rounded,
    'venmo':     Icons.payments_rounded,
  };
  return m[id] ?? Icons.link_rounded;
}

class ProfileCardWidget extends StatelessWidget {
  final ProfileModel profile;
  final String? qrUrl;         // if set, QR is embedded inside the card
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;

  const ProfileCardWidget({
    super.key,
    required this.profile,
    this.qrUrl,
    this.compact = false,
    this.onTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) =>
      compact ? _buildCompact() : _buildFull();

  // ── Full POPL-style card ─────────────────────────────────────────────────

  Widget _buildFull() {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Abstract art top section
          _TopArt(onMenuTap: onMenuTap),

          // ── Name / title / company
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName : 'Your Name',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                if (profile.jobTitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(profile.jobTitle,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF8E8E93))),
                ],
                if (profile.company.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(profile.company,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF8E8E93))),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── QR embedded in card ─────────────────────────────────────────
          if (qrUrl != null && qrUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF3A3A3C), width: 0.5),
                ),
                child: Column(
                  children: [
                    Center(
                      child: QrImageView(
                        data: qrUrl!,
                        version: QrVersions.auto,
                        size: 190,
                        backgroundColor: const Color(0xFF2C2C2E),
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.circle,
                          color: Colors.white,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Scan to share card',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Compact variant (used in leads list) ────────────────────────────────

  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
      ),
      child: Row(
        children: [
          _CircleAvatar(profile: profile, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.displayName.isEmpty ? 'Unknown' : profile.displayName,
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                if (profile.jobTitle.isNotEmpty || profile.company.isNotEmpty)
                  Text(
                    [profile.jobTitle, profile.company]
                        .where((s) => s.isNotEmpty).join(' · '),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8E8E93)),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 16, color: Color(0xFF555555)),
        ],
      ),
    );
  }
}

// ── Top abstract-art section ─────────────────────────────────────────────────

class _TopArt extends StatelessWidget {
  final VoidCallback? onMenuTap;
  const _TopArt({this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 115,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _WavePainter()),
          // "..." menu — top right
          if (onMenuTap != null)
            Positioned(
              top: 10, right: 10,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onMenuTap!();
                },
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.more_horiz_rounded,
                      size: 18, color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Abstract wave shapes — two overlapping bezier blobs
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Blob 1 — left sweep
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * 0.58, 0)
        ..cubicTo(
          size.width * 0.70, size.height * 0.35,
          size.width * 0.38, size.height * 0.80,
          0, size.height * 0.95,
        )
        ..close(),
      Paint()
        ..color = Colors.white.withOpacity(0.07)
        ..style = PaintingStyle.fill,
    );

    // Blob 2 — right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.52, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height * 0.60)
        ..cubicTo(
          size.width * 0.88, size.height * 0.48,
          size.width * 0.68, size.height * 0.28,
          size.width * 0.52, 0,
        )
        ..close(),
      Paint()
        ..color = Colors.white.withOpacity(0.04)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Reusable circle avatar ────────────────────────────────────────────────────

class _CircleAvatar extends StatelessWidget {
  final ProfileModel profile;
  final double size;
  const _CircleAvatar({required this.profile, required this.size});

  @override
  Widget build(BuildContext context) {
    if (profile.photoUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: profile.photoUrl,
          width: size, height: size, fit: BoxFit.cover,
          placeholder: (_, __) => _initials(),
          errorWidget: (_, __, ___) => _initials(),
        ),
      );
    }
    return _initials();
  }

  Widget _initials() {
    final ch = profile.displayName.isNotEmpty
        ? profile.displayName[0].toUpperCase() : '?';
    return Container(
      width: size, height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF3A3A3C),
      ),
      alignment: Alignment.center,
      child: Text(ch, style: TextStyle(
        fontSize: size * 0.38,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      )),
    );
  }
}
