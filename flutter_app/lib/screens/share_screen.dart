import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});
  @override State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  ProfileModel? _profile;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ProfileService.instance.getOrCreateProfile();
    if (mounted) setState(() => _profile = p);
  }

  String get _url => _profile != null
      ? ProfileService.instance.profileUrl(_profile!.id) : '';

  String get _name => _profile?.displayName.isNotEmpty == true
      ? _profile!.displayName : 'Your Card';

  /// Build a vCard string for offline sharing
  String get _vCard {
    if (_profile == null) return '';
    final p = _profile!;
    final nameParts = p.displayName.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.length > 1
        ? nameParts.sublist(0, nameParts.length - 1).join(' ')
        : (nameParts.firstOrNull ?? '');
    final lastName = nameParts.length > 1 ? nameParts.last : '';
    final lines = <String>[
      'BEGIN:VCARD', 'VERSION:3.0',
      'FN:${p.displayName}',
      'N:$lastName;$firstName;;;',
    ];
    if (p.jobTitle.isNotEmpty) lines.add('TITLE:${p.jobTitle}');
    if (p.company.isNotEmpty)  lines.add('ORG:${p.company}');
    if (p.email.isNotEmpty)    lines.add('EMAIL;TYPE=INTERNET:${p.email}');
    if (p.phone.isNotEmpty)    lines.add('TEL;TYPE=CELL:${p.phone}');
    if (p.website.isNotEmpty)  lines.add('URL:${p.website}');
    if (p.bio.isNotEmpty)      lines.add('NOTE:${p.bio}');
    lines.add('END:VCARD');
    return lines.join('\r\n');
  }

  /// QR data changes based on offline toggle
  String get _qrData => _offline ? _vCard : _url;

  Future<void> _shareVCard() async {
    if (_profile == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${_profile!.displayName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.vcf');
    await file.writeAsString(_vCard);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/vcard', name: file.uri.pathSegments.last)],
      subject: '${_profile!.displayName} - Contact Card',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  _CloseBtn(onTap: () => Navigator.pop(context)),
                  Expanded(
                    child: Text(
                      'Sharing $_name',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 36), // balance
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── QR block ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3A3A3C), width: 0.5),
                ),
                child: Column(
                  children: [
                    _qrData.isNotEmpty
                        ? QrImageView(
                            data: _qrData,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: const Color(0xFF1C1C1E),
                            eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.circle,
                                color: Colors.white),
                            dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.circle,
                                color: Colors.white),
                          )
                        : const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 1))),
                    const SizedBox(height: 10),
                    // Share offline toggle
                    Row(
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 14, color: Color(0xFF8E8E93)),
                        const SizedBox(width: 6),
                        const Text('Share offline',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF8E8E93))),
                        const Spacer(),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _offline,
                            onChanged: (v) {
                              HapticFeedback.lightImpact();
                              setState(() => _offline = v);
                            },
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF3A3A3C),
                            inactiveThumbColor: const Color(0xFF636366),
                            inactiveTrackColor: const Color(0xFF2C2C2C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Description ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Text(
                _offline
                    ? 'QR now contains your contact card directly — works without internet'
                    : 'Have someone point their camera at this QR code to share your card',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Share options ────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _OptionGroup(options: [
                  if (_offline)
                    _Option(
                      icon: Icons.contact_page_rounded,
                      label: 'Share vCard File',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _shareVCard();
                      },
                    ),
                  _Option(
                    icon: Icons.ios_share_rounded,
                    label: _offline ? 'Share vCard Text' : 'Share Your Card',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (_offline) {
                        Share.share(_vCard);
                      } else if (_url.isNotEmpty) {
                        Share.share(_url);
                      }
                    },
                  ),
                  if (!_offline) ...[
                    _Option(
                      icon: Icons.copy_rounded,
                      label: 'Copy Card Link',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (_url.isEmpty) return;
                        Clipboard.setData(ClipboardData(text: _url));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Link copied!'),
                            backgroundColor: Color(0xFF1C1C1E),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    _Option(
                      icon: Icons.message_rounded,
                      label: 'Share Card via Text',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (_url.isNotEmpty) Share.share(_url);
                      },
                    ),
                    _Option(
                      icon: Icons.mail_outline_rounded,
                      label: 'Share Card via Email',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (_url.isNotEmpty) Share.share(_url);
                      },
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Option group (iOS-style grouped rows) ────────────────────────────────────

class _OptionGroup extends StatelessWidget {
  final List<_Option> options;
  const _OptionGroup({required this.options});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: options.asMap().entries.map((e) {
          final isLast = e.key == options.length - 1;
          return Column(
            children: [
              _OptionTile(option: e.value),
              if (!isLast)
                const Divider(
                    height: 0.5, thickness: 0.5,
                    color: Color(0xFF2C2C2C), indent: 50),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _OptionTile extends StatefulWidget {
  final _Option option;
  const _OptionTile({required this.option});
  @override State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => setState(() => _p = true),
    onTapUp:     (_) { setState(() => _p = false); widget.option.onTap(); },
    onTapCancel: ()  => setState(() => _p = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      color: _p ? Colors.white.withOpacity(0.05) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Icon(widget.option.icon, size: 20, color: Colors.white70),
          const SizedBox(width: 14),
          Text(widget.option.label,
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w400)),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded,
              size: 16, color: Color(0xFF555555)),
        ],
      ),
    ),
  );
}

class _Option {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Option({required this.icon, required this.label, required this.onTap});
}

// ── Close button ──────────────────────────────────────────────────────────────

class _CloseBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _CloseBtn({required this.onTap});
  @override State<_CloseBtn> createState() => _CloseBtnState();
}

class _CloseBtnState extends State<_CloseBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => setState(() => _p = true),
    onTapUp:     (_) { setState(() => _p = false); widget.onTap(); },
    onTapCancel: ()  => setState(() => _p = false),
    child: AnimatedScale(
      scale: _p ? 0.88 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: 36, height: 36,
        alignment: Alignment.center,
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
      ),
    ),
  );
}
