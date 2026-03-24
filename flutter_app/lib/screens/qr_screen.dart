import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/profile_model.dart';
import '../models/contact_model.dart';
import '../services/supabase_service.dart';
import '../services/profile_service.dart';
import '../services/contacts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/profile_card_widget.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  ProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final p = await ProfileService.instance.getOrCreateProfile();
    if (mounted) setState(() => _profile = p);
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
            'QR',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 2,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'My Code'),
            Tab(text: 'Scan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _MyQrTab(profile: _profile),
          const _ScanTab(),
        ],
      ),
    );
  }
}

// ── My QR Tab ──────────────────────────────────────────────────────────────────

class _MyQrTab extends StatelessWidget {
  final ProfileModel? profile;
  const _MyQrTab({this.profile});

  String get _profileUrl => profile != null
      ? ProfileService.instance.profileUrl(profile!.id)
      : '';

  void _share(BuildContext ctx) {
    if (profile == null) return;
    Share.share('Scan my QR or visit: $_profileUrl');
  }

  void _copyLink(BuildContext ctx) {
    Clipboard.setData(ClipboardData(text: _profileUrl));
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('Link copied!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // QR Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 30, spreadRadius: -5, offset: const Offset(0, 12),
                )
              ],
            ),
            child: Column(
              children: [
                // Profile mini header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_2_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      profile!.displayName.isEmpty
                          ? 'My QR Code'
                          : profile!.displayName,
                      style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: QrImageView(
                    data: _profileUrl,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF0A0A0F),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF0A0A0F),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _profileUrl,
                  style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scale(
              begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: 'Share',
                  icon: Icons.ios_share_rounded,
                  onTap: () => _share(context),
                  height: 50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionBtn(
                  label: 'Copy Link',
                  icon: Icons.link_rounded,
                  onTap: () => _copyLink(context),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

          const SizedBox(height: 16),

          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.textHint),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'When scanned, people see your full profile with a Save Contact button.',
                    style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary, height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

// ── Scan Tab ───────────────────────────────────────────────────────────────────

class _ScanTab extends StatefulWidget {
  const _ScanTab();

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  final MobileScannerController _scanCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _scanning = true;
  bool _processing = false;

  static const String _netlifyBase = ProfileService.netlifyBaseUrl;

  Future<void> _onDetected(BarcodeCapture capture) async {
    if (!_scanning || _processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final url = barcode!.rawValue!;

    // Only process our own profile links
    if (!url.startsWith('$_netlifyBase/profile/')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not a valid profile QR code')),
        );
      }
      return;
    }

    setState(() { _scanning = false; _processing = true; });
    _scanCtrl.stop();

    final profileId = url.split('/profile/').last;

    try {
      final scannedProfile = await SupabaseService.instance.fetchProfile(profileId);
      if (scannedProfile == null) {
        _showError('Profile not found');
        return;
      }

      final ownerProfile = await ProfileService.instance.getOrCreateProfile();
      final contacts     = await ContactsService.instance.getLocalContacts();

      if (!mounted) return;

      if (ContactsService.instance.alreadySaved(contacts, profileId)) {
        _showScannedSheet(scannedProfile, alreadySaved: true);
      } else {
        _showScannedSheet(scannedProfile, alreadySaved: false,
            ownerProfileId: ownerProfile.id);
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    setState(() { _scanning = true; });
    _scanCtrl.start();
  }

  void _showScannedSheet(
    ProfileModel profile, {
    required bool alreadySaved,
    String? ownerProfileId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ScannedProfileSheet(
        profile:        profile,
        alreadySaved:   alreadySaved,
        ownerProfileId: ownerProfileId,
        onDismiss: () {
          setState(() => _scanning = true);
          _scanCtrl.start();
        },
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() => _scanning = true);
        _scanCtrl.start();
      }
    });
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera
        MobileScanner(
          controller: _scanCtrl,
          onDetect: _onDetected,
        ),

        // Overlay
        _ScannerOverlay(),

        // Bottom hint
        Positioned(
          bottom: 60, left: 24, right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  _processing ? 'Processing…' : 'Point at a profile QR code',
                  style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const boxSize = 250.0;
    final top = (size.height - boxSize) / 2 - 40;
    final left = (size.width - boxSize) / 2;

    return Stack(
      children: [
        // Dark overlay
        ColoredBox(color: Colors.black.withOpacity(0.5),
            child: const SizedBox.expand()),
        // Clear window
        Positioned(
          top: top, left: left,
          width: boxSize, height: boxSize,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary, width: 2.5,
              ),
            ),
          ),
        ),
        // Corners
        ...[ [top - 2, left - 2], [top - 2, left + boxSize - 26],
             [top + boxSize - 24, left - 2],
             [top + boxSize - 24, left + boxSize - 26]
        ].map((pos) => Positioned(
          top: pos[0], left: pos[1],
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 3),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        )),
      ],
    );
  }
}

// ── Scanned Profile Bottom Sheet ───────────────────────────────────────────────

class _ScannedProfileSheet extends StatefulWidget {
  final ProfileModel profile;
  final bool alreadySaved;
  final String? ownerProfileId;
  final VoidCallback onDismiss;

  const _ScannedProfileSheet({
    required this.profile,
    required this.alreadySaved,
    this.ownerProfileId,
    required this.onDismiss,
  });

  @override
  State<_ScannedProfileSheet> createState() => _ScannedProfileSheetState();
}

class _ScannedProfileSheetState extends State<_ScannedProfileSheet> {
  bool _saving = false;
  bool _saved  = false;

  Future<void> _saveContact() async {
    if (widget.ownerProfileId == null) return;
    setState(() => _saving = true);
    await ContactsService.instance.saveContactFromProfile(
      ownerProfileId: widget.ownerProfileId!,
      scannedProfile: widget.profile,
    );
    if (mounted) setState(() { _saving = false; _saved = true; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border, borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ProfileCardWidget(profile: widget.profile),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: widget.alreadySaved || _saved
                      ? 'Already Saved ✓'
                      : 'Save Contact',
                  icon: widget.alreadySaved || _saved
                      ? Icons.check_rounded
                      : Icons.person_add_rounded,
                  onTap: widget.alreadySaved || _saved ? null : _saveContact,
                  loading: _saving,
                  height: 50,
                ),
              ),
              const SizedBox(width: 12),
              _ActionBtn(
                label: 'Close',
                icon: Icons.close_rounded,
                onTap: () {
                  Navigator.pop(context);
                  widget.onDismiss();
                },
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
