import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/contact_model.dart';
import '../services/contacts_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'qr_screen.dart' show _ActionBtn;

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<ContactModel> _contacts = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final contacts = await ContactsService.instance.getLocalContacts();
    if (mounted) setState(() { _contacts = contacts; _loading = false; });
  }

  List<ContactModel> get _filtered => _search.isEmpty
      ? _contacts
      : _contacts.where((c) =>
          c.displayName.toLowerCase().contains(_search.toLowerCase()) ||
          c.company.toLowerCase().contains(_search.toLowerCase()) ||
          c.email.toLowerCase().contains(_search.toLowerCase())).toList();

  Future<void> _delete(ContactModel contact) async {
    final ownerProfile = await ProfileService.instance.getOrCreateProfile();
    await ContactsService.instance.deleteContact(
      ownerProfileId: ownerProfile.id,
      contactId: contact.id,
    );
    setState(() => _contacts.removeWhere((c) => c.id == contact.id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact removed')),
      );
    }
  }

  Future<void> _exportVCard(ContactModel contact) async {
    final dir     = await getTemporaryDirectory();
    final file    = File('${dir.path}/${contact.displayName.replaceAll(' ', '_')}.vcf');
    await file.writeAsString(contact.toVCard());
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Contact: ${contact.displayName}',
    );
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
            'Contacts',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '${_contacts.length}',
              style: const TextStyle(
                fontSize: 13, color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_contacts.isEmpty) {
      return _EmptyContacts()
          .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search contacts…',
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 18, color: AppColors.textHint),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          size: 16, color: AppColors.textHint),
                      onPressed: () => setState(() => _search = ''),
                    )
                  : null,
            ),
          ),
        ).animate().fadeIn(duration: 300.ms),

        Expanded(
          child: _filtered.isEmpty
              ? const Center(
                  child: Text('No contacts match your search',
                      style: TextStyle(color: AppColors.textHint)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _ContactTile(
                    contact: _filtered[i],
                    onDelete: () => _delete(_filtered[i]),
                    onExport: () => _exportVCard(_filtered[i]),
                  ).animate(delay: Duration(milliseconds: i * 40))
                   .fadeIn(duration: 300.ms).slideX(begin: -0.05),
                ),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback onDelete;
  final VoidCallback onExport;

  const _ContactTile({
    required this.contact,
    required this.onDelete,
    required this.onExport,
  });

  Color get _color {
    try {
      return Color(int.parse(
          'FF${contact.profileColor.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(contact.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Remove Contact?',
                style: TextStyle(color: AppColors.textPrimary)),
            content: Text(
              'Remove ${contact.displayName} from your wallet?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove',
                    style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_color, _color.withOpacity(0.5)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  contact.displayName.isNotEmpty
                      ? contact.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.displayName,
                      style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (contact.jobTitle.isNotEmpty || contact.company.isNotEmpty)
                      Text(
                        [contact.jobTitle, contact.company]
                            .where((s) => s.isNotEmpty).join(' · '),
                        style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary,
                        ),
                      ),
                    if (contact.email.isNotEmpty)
                      Text(
                        contact.email,
                        style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint,
                        ),
                      ),
                  ],
                ),
              ),
              // Export button
              IconButton(
                icon: const Icon(Icons.ios_share_rounded,
                    size: 16, color: AppColors.textHint),
                onPressed: onExport,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ContactDetailSheet(
        contact: contact,
        onExport: onExport,
        onDelete: () {
          Navigator.pop(context);
          onDelete();
        },
      ),
    );
  }
}

class _ContactDetailSheet extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const _ContactDetailSheet({
    required this.contact,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    try {
      color = Color(int.parse(
          'FF${contact.profileColor.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      color = AppColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          // Avatar + name
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.5)]),
            ),
            alignment: Alignment.center,
            child: Text(
              contact.displayName.isNotEmpty
                  ? contact.displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(contact.displayName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          if (contact.jobTitle.isNotEmpty || contact.company.isNotEmpty)
            Text(
              [contact.jobTitle, contact.company]
                  .where((s) => s.isNotEmpty).join(' · '),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          const SizedBox(height: 20),
          // Info chips
          if (contact.email.isNotEmpty) _InfoRow(Icons.email_outlined, contact.email),
          if (contact.phone.isNotEmpty) _InfoRow(Icons.phone_outlined, contact.phone),
          if (contact.website.isNotEmpty) _InfoRow(Icons.language_rounded, contact.website),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: 'Export vCard',
                  icon: Icons.download_rounded,
                  onTap: onExport, height: 48,
                ),
              ),
              const SizedBox(width: 12),
              _ActionBtn(
                label: 'Remove',
                icon: Icons.delete_outline_rounded,
                onTap: onDelete,
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        ),
      ],
    ),
  );
}

class _EmptyContacts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
              child: const Icon(Icons.contacts_rounded,
                  size: 64, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Contacts Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan someone\'s QR code to save them here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
