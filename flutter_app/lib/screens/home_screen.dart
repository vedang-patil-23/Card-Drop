import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_card_widget.dart';
import '../widgets/gradient_button.dart';
import '../widgets/section_header.dart';
import 'edit_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProfileModel? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await ProfileService.instance.getOrCreateProfile();
    if (mounted) setState(() { _profile = p; _loading = false; });
  }

  Future<void> _goToEdit() async {
    final updated = await Navigator.push<ProfileModel>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: _profile!)),
    );
    if (updated != null && mounted) setState(() => _profile = updated);
  }

  void _shareProfile() {
    if (_profile == null) return;
    final url = ProfileService.instance.profileUrl(_profile!.id);
    Share.share(
      'Check out my digital card 👇\n$url',
      subject: '${_profile!.displayName} — Digital Card',
    );
  }

  void _copyLink() {
    if (_profile == null) return;
    final url = ProfileService.instance.profileUrl(_profile!.id);
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile link copied!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildProfileCard(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildLinks(),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: false,
      floating: true,
      backgroundColor: AppColors.background,
      expandedHeight: 60,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: const Text(
                'My Card',
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: AppColors.textSecondary,
              onPressed: _goToEdit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    if (_profile == null) return const SizedBox.shrink();

    if (_profile!.isEmpty) {
      return _EmptyProfilePrompt(onTap: _goToEdit)
          .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
    }

    return ProfileCardWidget(profile: _profile!)
        .animate().fadeIn(duration: 400.ms).slideY(begin: 0.08);
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Share'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GradientButton(
                label: 'Share Profile',
                icon: Icons.share_rounded,
                onTap: _shareProfile,
                height: 48,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OutlineAction(
                label: 'Copy Link',
                icon: Icons.link_rounded,
                onTap: _copyLink,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildLinks() {
    if (_profile == null || _profile!.socialLinks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Links',
          actionLabel: 'Edit',
          onAction: _goToEdit,
        ),
        ..._profile!.socialLinks
            .where((l) => l.isActive && l.url.isNotEmpty)
            .map((link) => _SocialLinkTile(link: link))
            .toList(),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _EmptyProfilePrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyProfilePrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
              child: const Icon(Icons.person_add_rounded,
                  size: 52, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Set Up Your Card',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your name, photo, and social links to get started',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Create Card',
                style: TextStyle(
                  color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlineAction({
    required this.label, required this.icon, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialLinkTile extends StatelessWidget {
  final SocialLink link;
  const _SocialLinkTile({required this.link});

  @override
  Widget build(BuildContext context) {
    final platform = SocialPlatform.findById(link.platform);
    final color = platform != null
        ? Color(platform.color)
        : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.link_rounded, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform?.label ?? link.platform,
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  link.url,
                  style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.textHint),
        ],
      ),
    );
  }
}
