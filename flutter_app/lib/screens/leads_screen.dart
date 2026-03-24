import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../models/lead_model.dart';
import '../services/supabase_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/section_header.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<LeadModel> _leads = [];
  bool _loading = true;
  String? _profileId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final profile = await ProfileService.instance.getOrCreateProfile();
    _profileId = profile.id;
    final leads = await SupabaseService.instance.fetchLeads(profile.id);
    if (mounted) setState(() { _leads = leads; _loading = false; });
  }

  Future<void> _markSeen(String leadId) async {
    if (_profileId == null) return;
    await SupabaseService.instance.markLeadSeen(leadId);
    setState(() {
      final idx = _leads.indexWhere((l) => l.id == leadId);
      if (idx >= 0) _leads[idx] = _leads[idx].copyWith(isNew: false);
    });
  }

  Future<void> _delete(String leadId) async {
    if (_profileId == null) return;
    await SupabaseService.instance.deleteLead(leadId);
    setState(() => _leads.removeWhere((l) => l.id == leadId));
  }

  int get _newCount => _leads.where((l) => l.isNew).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: ShaderMask(
          shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
          child: const Text(
            'Leads',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
        ),
        actions: [
          if (_newCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_newCount new',
                style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white,
                ),
              ),
            ),
        ],
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
            Tab(text: 'Capture Lead'),
            Tab(text: 'My Leads'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _CaptureTab(
                  profileId: _profileId,
                  onLeadAdded: (lead) {
                    setState(() => _leads.insert(0, lead));
                    _tabCtrl.animateTo(1);
                  },
                ),
                _LeadsListTab(
                  leads: _leads,
                  onMarkSeen: _markSeen,
                  onDelete: _delete,
                ),
              ],
            ),
    );
  }
}

// ── Capture Tab ────────────────────────────────────────────────────────────────

class _CaptureTab extends StatefulWidget {
  final String? profileId;
  final ValueChanged<LeadModel> onLeadAdded;

  const _CaptureTab({this.profileId, required this.onLeadAdded});

  @override
  State<_CaptureTab> createState() => _CaptureTabState();
}

class _CaptureTabState extends State<_CaptureTab> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCt   = TextEditingController();
  final _emailCt  = TextEditingController();
  final _phoneCt  = TextEditingController();
  final _orgCt    = TextEditingController();
  final _noteCt   = TextEditingController();
  bool _saving    = false;

  @override
  void dispose() {
    for (final c in [_nameCt, _emailCt, _phoneCt, _orgCt, _noteCt]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.profileId == null) return;

    setState(() => _saving = true);
    try {
      final lead = LeadModel(
        id:             const Uuid().v4(),
        ownerProfileId: widget.profileId!,
        name:           _nameCt.text.trim(),
        email:          _emailCt.text.trim(),
        phone:          _phoneCt.text.trim(),
        organization:   _orgCt.text.trim(),
        note:           _noteCt.text.trim(),
        source:         'app',
        capturedAt:     DateTime.now(),
        isNew:          true,
      );

      await SupabaseService.instance.saveLead(lead);
      widget.onLeadAdded(lead);

      // Reset form
      _nameCt.clear(); _emailCt.clear(); _phoneCt.clear();
      _orgCt.clear();  _noteCt.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead captured & synced!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.subtleGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGlow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_add_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Capture a Lead',
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        Text('Fill in their details — it syncs automatically',
                            style: TextStyle(fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 24),
            AppTextField(
              label: 'Full Name', controller: _nameCt,
              prefixIcon: Icons.person_outline_rounded, required: true,
              validator: (v) =>
                  (v?.isEmpty ?? true) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Email', controller: _emailCt,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Phone', controller: _phoneCt,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Organization', controller: _orgCt,
              prefixIcon: Icons.business_outlined,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Note', controller: _noteCt,
              prefixIcon: Icons.notes_rounded,
              maxLines: 3,
              hint: 'Where you met, what you discussed…',
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Save Lead',
              icon: Icons.check_rounded,
              onTap: _submit,
              loading: _saving,
              width: double.infinity,
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ── Leads List Tab ─────────────────────────────────────────────────────────────

class _LeadsListTab extends StatefulWidget {
  final List<LeadModel> leads;
  final ValueChanged<String> onMarkSeen;
  final ValueChanged<String> onDelete;

  const _LeadsListTab({
    required this.leads,
    required this.onMarkSeen,
    required this.onDelete,
  });

  @override
  State<_LeadsListTab> createState() => _LeadsListTabState();
}

class _LeadsListTabState extends State<_LeadsListTab> {
  String _search = '';

  List<LeadModel> get _filtered => _search.isEmpty
      ? widget.leads
      : widget.leads.where((l) =>
          l.name.toLowerCase().contains(_search.toLowerCase()) ||
          l.organization.toLowerCase().contains(_search.toLowerCase()) ||
          l.email.toLowerCase().contains(_search.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    if (widget.leads.isEmpty) {
      return _EmptyLeads()
          .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search leads…',
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
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: _filtered.length,
            itemBuilder: (_, i) {
              final lead = _filtered[i];
              return _LeadTile(
                lead: lead,
                onTap: () => widget.onMarkSeen(lead.id),
                onDelete: () => widget.onDelete(lead.id),
              ).animate(delay: Duration(milliseconds: i * 40))
               .fadeIn(duration: 300.ms).slideX(begin: -0.05);
            },
          ),
        ),
      ],
    );
  }
}

class _LeadTile extends StatelessWidget {
  final LeadModel lead;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _LeadTile({
    required this.lead, required this.onTap, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(lead.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Delete Lead?',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Text('Remove ${lead.name}?',
              style: const TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ) ?? false,
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: lead.isNew
                  ? AppColors.primary.withOpacity(0.4)
                  : AppColors.border,
              width: lead.isNew ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Source badge
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: lead.source == 'web'
                      ? AppColors.accent.withOpacity(0.12)
                      : AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  lead.source == 'web'
                      ? Icons.language_rounded
                      : Icons.phone_android_rounded,
                  size: 18,
                  color: lead.source == 'web'
                      ? AppColors.accent
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lead.name.isEmpty ? 'No Name' : lead.name,
                            style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (lead.isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('New',
                                style: TextStyle(fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                      ],
                    ),
                    if (lead.organization.isNotEmpty)
                      Text(lead.organization,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    if (lead.email.isNotEmpty)
                      Text(lead.email,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint)),
                    Text(
                      _formatDate(lead.capturedAt),
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _EmptyLeads extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
            child: const Icon(Icons.person_search_rounded,
                size: 64, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text('No Leads Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Capture leads using the form, or people can fill in their info on your public profile page',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary,
                height: 1.5),
          ),
        ],
      ),
    ),
  );
}
