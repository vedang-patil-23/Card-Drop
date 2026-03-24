import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/profile_model.dart';
import '../theme/app_theme.dart';

class ProfileCardWidget extends StatelessWidget {
  final ProfileModel profile;
  final bool compact;
  final VoidCallback? onTap;

  const ProfileCardWidget({
    super.key,
    required this.profile,
    this.compact = false,
    this.onTap,
  });

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _parseColor(profile.profileColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              cardColor.withOpacity(0.25),
              AppColors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: cardColor.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.18),
              blurRadius: 30,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background glow
              Positioned(
                top: -40, right: -40,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardColor.withOpacity(0.12),
                  ),
                ),
              ),
              Padding(
                padding: compact
                    ? const EdgeInsets.all(16)
                    : const EdgeInsets.all(24),
                child: compact
                    ? _buildCompact(cardColor)
                    : _buildFull(cardColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFull(Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _Avatar(
              photoUrl: profile.photoUrl,
              name: profile.displayName,
              color: cardColor,
              size: 72,
            ),
            const Spacer(),
            _ColorDot(color: cardColor),
          ],
        ),
        const SizedBox(height: 16),
        if (profile.displayName.isNotEmpty)
          Text(
            profile.displayName,
            style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        if (profile.jobTitle.isNotEmpty || profile.company.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              [profile.jobTitle, profile.company]
                  .where((s) => s.isNotEmpty)
                  .join(' · '),
              style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            profile.bio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5,
            ),
          ),
        ],
        if (profile.socialLinks.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),
          _SocialLinksRow(links: profile.socialLinks, color: cardColor),
        ],
      ],
    );
  }

  Widget _buildCompact(Color cardColor) {
    return Row(
      children: [
        _Avatar(
          photoUrl: profile.photoUrl,
          name: profile.displayName,
          color: cardColor,
          size: 44,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                profile.displayName.isEmpty ? 'No Name' : profile.displayName,
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (profile.jobTitle.isNotEmpty || profile.company.isNotEmpty)
                Text(
                  [profile.jobTitle, profile.company]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded,
            size: 18, color: AppColors.textHint),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String photoUrl;
  final String name;
  final Color color;
  final double size;

  const _Avatar({
    required this.photoUrl,
    required this.name,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: size, height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 10, height: 10,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [
        BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 1),
      ],
    ),
  );
}

class _SocialLinksRow extends StatelessWidget {
  final List<SocialLink> links;
  final Color color;
  const _SocialLinksRow({required this.links, required this.color});

  @override
  Widget build(BuildContext context) {
    final active = links.where((l) => l.isActive && l.url.isNotEmpty).take(6);
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: active.map((link) {
        final platform = SocialPlatform.findById(link.platform);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            platform?.label ?? link.platform,
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }
}
