import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/app_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  final ProfileModel profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCt    = TextEditingController();
  final _titleCt   = TextEditingController();
  final _companyCt = TextEditingController();
  final _bioCt     = TextEditingController();
  final _emailCt   = TextEditingController();
  final _phoneCt   = TextEditingController();
  final _websiteCt = TextEditingController();

  late List<SocialLink> _links;
  String _profileColor = '#6C63FF';
  File?  _pendingPhoto;
  bool   _saving = false;

  static const List<String> _colorOptions = [
    '#6C63FF', '#00D4FF', '#FF6B6B', '#00E676',
    '#FFD93D', '#FF6B9D', '#C77DFF', '#4ECDC4',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCt.text    = p.displayName;
    _titleCt.text   = p.jobTitle;
    _companyCt.text = p.company;
    _bioCt.text     = p.bio;
    _emailCt.text   = p.email;
    _phoneCt.text   = p.phone;
    _websiteCt.text = p.website;
    _links          = List.from(p.socialLinks);
    _profileColor   = p.profileColor;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCt, _titleCt, _companyCt, _bioCt,
      _emailCt, _phoneCt, _websiteCt,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, maxHeight: 800, imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _pendingPhoto = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      var updated = widget.profile.copyWith(
        displayName:  _nameCt.text.trim(),
        jobTitle:     _titleCt.text.trim(),
        company:      _companyCt.text.trim(),
        bio:          _bioCt.text.trim(),
        email:        _emailCt.text.trim(),
        phone:        _phoneCt.text.trim(),
        website:      _websiteCt.text.trim(),
        profileColor: _profileColor,
        socialLinks:  _links.where((l) => l.url.isNotEmpty).toList(),
      );

      if (_pendingPhoto != null) {
        updated = await ProfileService.instance
            .updateProfilePhoto(updated, _pendingPhoto!);
      } else {
        updated = await ProfileService.instance.saveProfile(updated);
      }

      if (mounted) Navigator.pop(context, updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GradientButton(
              label: 'Save',
              onTap: _save,
              loading: _saving,
              height: 36,
              borderRadius: 10,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildPhotoSection(),
            const SizedBox(height: 24),
            _buildColorPicker(),
            const SizedBox(height: 28),
            _sectionTitle('Basic Info'),
            const SizedBox(height: 12),
            AppTextField(label: 'Full Name', controller: _nameCt,
                prefixIcon: Icons.person_outline_rounded, required: true,
                validator: (v) => (v?.isEmpty ?? true) ? 'Name is required' : null),
            const SizedBox(height: 14),
            AppTextField(label: 'Job Title', controller: _titleCt,
                prefixIcon: Icons.work_outline_rounded),
            const SizedBox(height: 14),
            AppTextField(label: 'Company', controller: _companyCt,
                prefixIcon: Icons.business_outlined),
            const SizedBox(height: 14),
            AppTextField(label: 'Bio', controller: _bioCt,
                prefixIcon: Icons.notes_rounded, maxLines: 3,
                hint: 'A short bio about yourself…'),
            const SizedBox(height: 28),
            _sectionTitle('Contact Info'),
            const SizedBox(height: 12),
            AppTextField(label: 'Email', controller: _emailCt,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            AppTextField(label: 'Phone', controller: _phoneCt,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            AppTextField(label: 'Website', controller: _websiteCt,
                prefixIcon: Icons.language_rounded,
                keyboardType: TextInputType.url),
            const SizedBox(height: 28),
            _sectionTitle('Social Links'),
            const SizedBox(height: 12),
            _SocialLinksEditor(
              links: _links,
              onChanged: (updated) => setState(() => _links = updated),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 14, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary, letterSpacing: 0.8,
    ),
  );

  Widget _buildPhotoSection() {
    final hasPhoto = _pendingPhoto != null || widget.profile.photoUrl.isNotEmpty;
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 2),
                color: AppColors.surfaceElevated,
              ),
              child: ClipOval(
                child: _pendingPhoto != null
                    ? Image.file(_pendingPhoto!, fit: BoxFit.cover)
                    : widget.profile.photoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.profile.photoUrl,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.person_rounded,
                            size: 44, color: AppColors.textHint),
              ),
            ),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Card Color',
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: AppColors.textSecondary, letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _colorOptions.map((hex) {
            final color = Color(
              int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
            final selected = _profileColor == hex;
            return GestureDetector(
              onTap: () => setState(() => _profileColor = hex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: selected
                      ? Border.all(color: Colors.white, width: 2.5)
                      : null,
                  boxShadow: selected
                      ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10)]
                      : null,
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Social Links Editor ────────────────────────────────────────────────────────

class _SocialLinksEditor extends StatelessWidget {
  final List<SocialLink> links;
  final ValueChanged<List<SocialLink>> onChanged;

  const _SocialLinksEditor({required this.links, required this.onChanged});

  void _togglePlatform(String platformId) {
    final updated = List<SocialLink>.from(links);
    final idx = updated.indexWhere((l) => l.platform == platformId);
    if (idx >= 0) {
      updated.removeAt(idx);
    } else {
      updated.add(SocialLink(platform: platformId, url: ''));
    }
    onChanged(updated);
  }

  void _updateUrl(String platformId, String url) {
    final updated = List<SocialLink>.from(links);
    final idx = updated.indexWhere((l) => l.platform == platformId);
    if (idx >= 0) {
      updated[idx] = updated[idx].copyWith(url: url);
    }
    onChanged(updated);
  }

  bool _isActive(String platformId) =>
      links.any((l) => l.platform == platformId);

  String _urlFor(String platformId) =>
      links.firstWhere(
        (l) => l.platform == platformId,
        orElse: () => SocialLink(platform: platformId, url: ''),
      ).url;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: SocialPlatform.all.map((platform) {
        final active = _isActive(platform.id);
        final color  = Color(platform.color);
        final ctrl   = TextEditingController(text: _urlFor(platform.id));

        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: active
                  ? color.withOpacity(0.06)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? color.withOpacity(0.4) : AppColors.border,
              ),
            ),
            child: Column(
              children: [
                // Header row
                InkWell(
                  onTap: () => _togglePlatform(platform.id),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.link_rounded,
                              size: 16, color: color),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          platform.label,
                          style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active ? color : AppColors.border,
                          ),
                          child: Icon(
                            active
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // URL field (only when active)
                if (active)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: TextFormField(
                      controller: ctrl,
                      onChanged: (v) => _updateUrl(platform.id, v),
                      style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: platform.placeholder,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: color.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: color.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: color, width: 1.5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
