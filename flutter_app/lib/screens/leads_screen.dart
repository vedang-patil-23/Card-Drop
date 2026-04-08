import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/lead_model.dart';
import '../models/event_model.dart';
import '../services/supabase_service.dart';
import '../services/profile_service.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});
  @override State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  List<LeadModel>  _leads  = [];
  List<EventModel> _events = [];
  bool _loading             = true;
  String? _profileId;
  String _search            = '';
  String? _filterEventId;        // null = all, '' = no event, else event id
  bool _showArchived         = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final profile = await ProfileService.instance.getOrCreateProfile();
    _profileId    = profile.id;
    final results = await Future.wait([
      SupabaseService.instance.fetchLeads(profile.id),
      SupabaseService.instance.fetchEvents(profile.id),
    ]);
    if (mounted) setState(() {
      _leads  = results[0] as List<LeadModel>;
      _events = results[1] as List<EventModel>;
      _loading = false;
    });
  }

  // ── Export ───────────────────────────────────────────────────────────────────

  void _showExportSheet() {
    if (_leads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contacts to export')),
      );
      return;
    }
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ExportSheet(
        events: _events,
        onExport: (eventId) {
          Navigator.pop(context);
          _doExport(eventId);
        },
      ),
    );
  }

  Future<void> _doExport(String? eventId) async {
    // Filter leads
    List<LeadModel> toExport;
    String fileName;
    if (eventId == null) {
      toExport = _leads;
      fileName = 'carddrop_contacts';
    } else {
      toExport = _leads.where((l) => l.eventId == eventId).toList();
      final ev = _events.firstWhere((e) => e.id == eventId,
          orElse: () => EventModel(id: '', ownerProfileId: '', name: 'event', createdAt: DateTime.now()));
      fileName = 'carddrop_${ev.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase()}';
    }

    if (toExport.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No contacts in this selection')),
        );
      }
      return;
    }

    final wb    = Excel.createExcel();
    final sheet = wb['Contacts'];
    wb.delete('Sheet1');

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1C1C1E'),
      fontColorHex:        ExcelColor.fromHexString('#FFFFFF'),
    );
    final headers = ['Name', 'Email', 'Phone', 'Designation', 'Organization', 'Event', 'Captured At'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value      = TextCellValue(headers[i]);
      cell.cellStyle  = headerStyle;
    }

    for (var r = 0; r < toExport.length; r++) {
      final l = toExport[r];
      final eventName = l.eventId.isNotEmpty
          ? (_events.where((e) => e.id == l.eventId).firstOrNull?.name ?? '')
          : '';
      final values = [
        l.name, l.email, l.phone, l.note, l.organization, eventName,
        l.capturedAt.toLocal().toString().split('.').first,
      ];
      for (var c = 0; c < values.length; c++) {
        sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
          .value = TextCellValue(values[c]);
      }
    }

    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 24.0);
    }

    final bytes = wb.encode()!;
    final dir   = await getApplicationDocumentsDirectory();
    final file  = File('${dir.path}/$fileName.xlsx');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(
        file.path,
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        name: '$fileName.xlsx',
      )],
      subject: 'CardDrop Contacts Export',
    );
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  Future<void> _delete(String leadId) async {
    await SupabaseService.instance.deleteLead(leadId);
    if (mounted) setState(() => _leads.removeWhere((l) => l.id == leadId));
  }

  Future<void> _archive(String leadId) async {
    await SupabaseService.instance.archiveLead(leadId, true);
    if (mounted) setState(() {
      final idx = _leads.indexWhere((l) => l.id == leadId);
      if (idx >= 0) _leads[idx] = _leads[idx].copyWith(archived: true);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Contact archived'),
        backgroundColor: const Color(0xFF1C1C1E),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () => _unarchive(leadId),
        ),
      ));
    }
  }

  Future<void> _unarchive(String leadId) async {
    await SupabaseService.instance.archiveLead(leadId, false);
    if (mounted) setState(() {
      final idx = _leads.indexWhere((l) => l.id == leadId);
      if (idx >= 0) _leads[idx] = _leads[idx].copyWith(archived: false);
    });
  }

  Future<void> _deleteEvent(String eventId) async {
    await SupabaseService.instance.deleteEvent(eventId);
    if (mounted) setState(() {
      _events.removeWhere((e) => e.id == eventId);
      // Clear eventId from local leads
      _leads = _leads.map((l) =>
        l.eventId == eventId ? l.copyWith(eventId: '') : l
      ).toList();
      if (_filterEventId == eventId) _filterEventId = null;
    });
  }

  List<LeadModel> get _filtered {
    var list = _leads.where((l) => l.archived == _showArchived).toList();
    // Event filter
    if (_filterEventId != null) {
      list = list.where((l) => l.eventId == _filterEventId).toList();
    }
    // Search filter
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((l) =>
        l.name.toLowerCase().contains(q) ||
        l.organization.toLowerCase().contains(q) ||
        l.email.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // ── Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, top + 16, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Contacts',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  _HdrBtn(icon: Icons.calendar_today_rounded, onTap: _showEventsSheet),
                  const SizedBox(width: 6),
                  _HdrBtn(icon: Icons.download_rounded,       onTap: _showExportSheet),
                  const SizedBox(width: 6),
                  _HdrBtn(icon: Icons.add,                    onTap: _showAddSheet),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Event filter chips
          if (_events.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: 'All',
                      active: _filterEventId == null,
                      onTap: () => setState(() => _filterEventId = null),
                    ),
                    const SizedBox(width: 8),
                    ..._events.map((e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: e.name,
                        active: _filterEventId == e.id,
                        onTap: () => setState(() =>
                          _filterEventId = _filterEventId == e.id ? null : e.id),
                      ),
                    )),
                  ],
                ),
              ),
            ),

          if (_events.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Search bar + archive toggle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF3A3A3C), width: 0.5),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _showArchived
                              ? 'Search archived'
                              : 'Search ${_leads.where((l) => !l.archived).length} Contacts',
                          hintStyle: const TextStyle(
                              fontSize: 14, color: Color(0xFF555555)),
                          prefixIcon: const Icon(Icons.search_rounded,
                              size: 18, color: Color(0xFF555555)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _showArchived = !_showArchived);
                    },
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _showArchived
                            ? Colors.white.withOpacity(0.12)
                            : const Color(0xFF1C1C1E),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _showArchived
                                ? Colors.white.withOpacity(0.3)
                                : const Color(0xFF3A3A3C),
                            width: 0.5),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _showArchived
                            ? Icons.inventory_2_rounded
                            : Icons.inventory_2_outlined,
                        size: 18,
                        color: _showArchived
                            ? Colors.white
                            : const Color(0xFF8E8E93)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Body
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 1),
              ),
            )
          else if (_filtered.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(hasLeads: _leads.isNotEmpty),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final lead = _filtered[i];
                  final isLast = i == _filtered.length - 1;
                  final eventName = lead.eventId.isNotEmpty
                      ? (_events.where((e) => e.id == lead.eventId).firstOrNull?.name)
                      : null;
                  return Dismissible(
                    key: ValueKey(lead.id),
                    // Swipe RIGHT → delete (red)
                    background: Container(
                      color: const Color(0xFFFF453A),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 24),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    // Swipe LEFT → archive/unarchive (amber/green)
                    secondaryBackground: Container(
                      color: _showArchived
                          ? const Color(0xFF30D158)
                          : const Color(0xFFFF9F0A),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _showArchived ? 'Unarchive' : 'Archive',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _showArchived
                                ? Icons.unarchive_rounded
                                : Icons.archive_rounded,
                            color: Colors.white, size: 22),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        // Delete — confirm first
                        HapticFeedback.mediumImpact();
                        return await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xFF1C1C1E),
                            title: const Text('Delete Contact',
                                style: TextStyle(color: Colors.white)),
                            content: Text(
                              'Permanently delete ${lead.name.isNotEmpty ? lead.name : "this contact"}?',
                              style: const TextStyle(color: Color(0xFF8E8E93)),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel',
                                    style: TextStyle(color: Color(0xFF8E8E93))),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete',
                                    style: TextStyle(color: Color(0xFFFF453A))),
                              ),
                            ],
                          ),
                        ) ?? false;
                      } else {
                        // Archive/unarchive — instant
                        HapticFeedback.lightImpact();
                        return true;
                      }
                    },
                    onDismissed: (direction) {
                      if (direction == DismissDirection.startToEnd) {
                        _delete(lead.id);
                      } else {
                        if (_showArchived) {
                          _unarchive(lead.id);
                        } else {
                          _archive(lead.id);
                        }
                      }
                    },
                    child: _ContactTile(
                      lead: lead,
                      eventName: eventName,
                      showDivider: !isLast,
                      onTap: () => _showEditSheet(lead),
                      onDelete: () => _delete(lead.id),
                    ),
                  );
                },
                childCount: _filtered.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ── Edit contact bottom sheet ───────────────────────────────────────────────

  void _showEditSheet(LeadModel lead) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditLeadSheet(
        lead: lead,
        events: _events,
        onSaved: (updated) {
          if (mounted) setState(() {
            final idx = _leads.indexWhere((l) => l.id == updated.id);
            if (idx >= 0) _leads[idx] = updated;
          });
        },
      ),
    );
  }

  // ── Add lead bottom sheet ─────────────────────────────────────────────────

  void _showAddSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddLeadSheet(
        profileId: _profileId ?? '',
        events: _events,
        onSaved: (lead) {
          if (mounted) setState(() => _leads.insert(0, lead));
        },
      ),
    );
  }

  // ── Events management sheet ───────────────────────────────────────────────

  void _showEventsSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EventsSheet(
        profileId: _profileId ?? '',
        events: _events,
        onCreated: (event) {
          if (mounted) setState(() => _events.insert(0, event));
        },
        onEdited: (event) {
          if (mounted) setState(() {
            final idx = _events.indexWhere((e) => e.id == event.id);
            if (idx >= 0) _events[idx] = event;
          });
        },
        onDeleted: (eventId) => _deleteEvent(eventId),
      ),
    );
  }
}

// ── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? Colors.white : const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? Colors.white : const Color(0xFF3A3A3C),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: active ? Colors.black : const Color(0xFF8E8E93),
        ),
      ),
    ),
  );
}

// ── Contact tile ─────────────────────────────────────────────────────────────

class _ContactTile extends StatefulWidget {
  final LeadModel lead;
  final String? eventName;
  final bool showDivider;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _ContactTile(
      {required this.lead,
      this.eventName,
      required this.showDivider,
      required this.onTap,
      required this.onDelete});
  @override State<_ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<_ContactTile> {
  bool _p = false;

  String _initial() {
    final n = widget.lead.name.trim();
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  String _dateLabel() {
    final d = widget.lead.capturedAt;
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today';
    }
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _p = true),
      onTapUp:     (_) { setState(() => _p = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _p = false),
      onLongPress: ()  => _confirmDelete(),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            color: _p
                ? Colors.white.withOpacity(0.04)
                : Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initial(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + company + event
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.lead.name.isNotEmpty
                                  ? widget.lead.name : 'Unknown',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.lead.isNew)
                            Container(
                              width: 8, height: 8,
                              margin: const EdgeInsets.only(left: 6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF0A84FF),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (widget.lead.organization.isNotEmpty)
                            widget.lead.organization,
                          if (widget.eventName != null)
                            widget.eventName!,
                          if (widget.lead.organization.isEmpty && widget.eventName == null)
                            'CardDrop',
                        ].join(' · '),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8E8E93)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _dateLabel(),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF555555)),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.credit_card_outlined,
                        size: 16, color: Color(0xFF555555)),
                  ],
                ),
              ],
            ),
          ),
          if (widget.showDivider)
            const Divider(
              height: 0.5, thickness: 0.5,
              color: Color(0xFF1C1C1C), indent: 76,
            ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Remove Contact',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove ${widget.lead.name.isNotEmpty ? widget.lead.name : "this contact"}?',
          style: const TextStyle(color: Color(0xFF8E8E93)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8E8E93))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            child: const Text('Remove',
                style: TextStyle(color: Color(0xFFFF453A))),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasLeads;
  const _EmptyState({required this.hasLeads});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.people_outline_rounded,
            size: 52, color: Color(0xFF3A3A3C)),
        const SizedBox(height: 16),
        Text(
          hasLeads ? 'No results' : 'No contacts yet',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          hasLeads
              ? 'Try a different search or filter'
              : 'Share your card and contacts will appear here',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF555555)),
        ),
      ],
    ),
  );
}

// ── Header icon button ───────────────────────────────────────────────────────

class _HdrBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HdrBtn({required this.icon, required this.onTap});
  @override State<_HdrBtn> createState() => _HdrBtnState();
}

class _HdrBtnState extends State<_HdrBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => setState(() => _p = true),
    onTapUp:     (_) { setState(() => _p = false); widget.onTap(); },
    onTapCancel: ()  => setState(() => _p = false),
    child: AnimatedScale(
      scale: _p ? 0.85 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Icon(widget.icon, size: 24, color: Colors.white70),
    ),
  );
}

// ── Export sheet ──────────────────────────────────────────────────────────────

class _ExportSheet extends StatelessWidget {
  final List<EventModel> events;
  final ValueChanged<String?> onExport;
  const _ExportSheet({required this.events, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Export Contacts',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Select which contacts to export as XLSX',
              style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
          const SizedBox(height: 20),
          _ExportOption(
            label: 'All Contacts',
            icon: Icons.people_rounded,
            onTap: () => onExport(null),
          ),
          if (events.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text('BY EVENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555),
                    letterSpacing: 1.2,
                  )),
            ),
            ...events.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ExportOption(
                label: e.name,
                icon: Icons.calendar_today_rounded,
                onTap: () => onExport(e.id),
              ),
            )),
          ],
        ],
      ),
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ExportOption({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8E8E93)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: Color(0xFF555555)),
        ],
      ),
    ),
  );
}

// ── Events management sheet ──────────────────────────────────────────────────

class _EventsSheet extends StatefulWidget {
  final String profileId;
  final List<EventModel> events;
  final ValueChanged<EventModel> onCreated;
  final ValueChanged<EventModel> onEdited;
  final ValueChanged<String> onDeleted;
  const _EventsSheet({
    required this.profileId,
    required this.events,
    required this.onCreated,
    required this.onEdited,
    required this.onDeleted,
  });
  @override State<_EventsSheet> createState() => _EventsSheetState();
}

class _EventsSheetState extends State<_EventsSheet> {
  final _nameCtrl = TextEditingController();
  bool _saving = false;
  String? _editingId;
  final _editCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _editCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final event = EventModel(
        id:             const Uuid().v4(),
        ownerProfileId: widget.profileId,
        name:           name,
        createdAt:      DateTime.now(),
      );
      await SupabaseService.instance.saveEvent(event);
      widget.onCreated(event);
      _nameCtrl.clear();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveEdit(EventModel event) async {
    final newName = _editCtrl.text.trim();
    if (newName.isEmpty || newName == event.name) {
      setState(() => _editingId = null);
      return;
    }
    await SupabaseService.instance.updateEventName(event.id, newName);
    final updated = EventModel(
      id: event.id,
      ownerProfileId: event.ownerProfileId,
      name: newName,
      createdAt: event.createdAt,
    );
    widget.onEdited(updated);
    if (mounted) setState(() => _editingId = null);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Events',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Create events to categorize your contacts',
              style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
          const SizedBox(height: 20),
          // Create new
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Event name (e.g. Tech Summit 2026)',
                    hintStyle: const TextStyle(color: Color(0xFF555555)),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _saving ? null : _create,
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: _saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: Colors.black))
                      : const Icon(Icons.add_rounded,
                          size: 22, color: Colors.black),
                ),
              ),
            ],
          ),
          if (widget.events.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('YOUR EVENTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF555555),
                  letterSpacing: 1.2,
                )),
            const SizedBox(height: 10),
            ...widget.events.map((e) {
              final isEditing = _editingId == e.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: Color(0xFF8E8E93)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: isEditing
                            ? TextField(
                                controller: _editCtrl,
                                autofocus: true,
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.white),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (_) => _saveEdit(e),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.name,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white)),
                                  Text(
                                    '${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year}',
                                    style: const TextStyle(
                                        fontSize: 11, color: Color(0xFF555555)),
                                  ),
                                ],
                              ),
                      ),
                      if (isEditing) ...[
                        GestureDetector(
                          onTap: () => _saveEdit(e),
                          child: const Icon(Icons.check_rounded,
                              size: 20, color: Color(0xFF30D158)),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => setState(() => _editingId = null),
                          child: const Icon(Icons.close_rounded,
                              size: 20, color: Color(0xFF8E8E93)),
                        ),
                      ] else ...[
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _editingId = e.id;
                              _editCtrl.text = e.name;
                            });
                          },
                          child: const Icon(Icons.edit_outlined,
                              size: 18, color: Color(0xFF8E8E93)),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            widget.onDeleted(e.id);
                          },
                          child: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: Color(0xFFFF453A)),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
      ),
    );
  }
}

// ── Add lead bottom sheet ────────────────────────────────────────────────────

class _AddLeadSheet extends StatefulWidget {
  final String profileId;
  final List<EventModel> events;
  final ValueChanged<LeadModel> onSaved;
  const _AddLeadSheet({required this.profileId, required this.events, required this.onSaved});
  @override State<_AddLeadSheet> createState() => _AddLeadSheetState();
}

class _AddLeadSheetState extends State<_AddLeadSheet> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _companyCtrl = TextEditingController();
  String _selectedEventId = '';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _companyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final lead = LeadModel(
        id:             const Uuid().v4(),
        ownerProfileId: widget.profileId,
        name:           _nameCtrl.text.trim(),
        email:          _emailCtrl.text.trim(),
        phone:          _phoneCtrl.text.trim(),
        organization:   _companyCtrl.text.trim(),
        note:           '',
        source:         'app',
        capturedAt:     DateTime.now(),
        eventId:        _selectedEventId,
      );
      await SupabaseService.instance.saveLead(lead);
      widget.onSaved(lead);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Add Contact',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 20),
          _Field(controller: _nameCtrl,    hint: 'Name*',   icon: Icons.person_outline_rounded),
          const SizedBox(height: 10),
          _Field(controller: _emailCtrl,   hint: 'Email',   icon: Icons.mail_outline_rounded,   type: TextInputType.emailAddress),
          const SizedBox(height: 10),
          _Field(controller: _phoneCtrl,   hint: 'Phone',   icon: Icons.phone_outlined,          type: TextInputType.phone),
          const SizedBox(height: 10),
          _Field(controller: _companyCtrl, hint: 'Company', icon: Icons.business_outlined),
          // Event selector
          if (widget.events.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedEventId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2C2C2E),
                  icon: const Icon(Icons.expand_more_rounded,
                      size: 18, color: Color(0xFF555555)),
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('No Event',
                          style: TextStyle(color: Color(0xFF555555))),
                    ),
                    ...widget.events.map((e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.name),
                    )),
                  ],
                  onChanged: (v) => setState(() => _selectedEventId = v ?? ''),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: _saving
                    ? const CircularProgressIndicator(
                        color: Colors.black, strokeWidth: 1.5)
                    : const Text('Save Contact',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Edit lead bottom sheet ───────────────────────────────────────────────────

class _EditLeadSheet extends StatefulWidget {
  final LeadModel lead;
  final List<EventModel> events;
  final ValueChanged<LeadModel> onSaved;
  const _EditLeadSheet({required this.lead, required this.events, required this.onSaved});
  @override State<_EditLeadSheet> createState() => _EditLeadSheetState();
}

class _EditLeadSheetState extends State<_EditLeadSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _noteCtrl;
  late String _selectedEventId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl    = TextEditingController(text: widget.lead.name);
    _emailCtrl   = TextEditingController(text: widget.lead.email);
    _phoneCtrl   = TextEditingController(text: widget.lead.phone);
    _companyCtrl = TextEditingController(text: widget.lead.organization);
    _noteCtrl    = TextEditingController(text: widget.lead.note);
    _selectedEventId = widget.lead.eventId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _companyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final updated = LeadModel(
        id:             widget.lead.id,
        ownerProfileId: widget.lead.ownerProfileId,
        name:           _nameCtrl.text.trim(),
        email:          _emailCtrl.text.trim(),
        phone:          _phoneCtrl.text.trim(),
        organization:   _companyCtrl.text.trim(),
        note:           _noteCtrl.text.trim(),
        source:         widget.lead.source,
        capturedAt:     widget.lead.capturedAt,
        isNew:          false,
        eventId:        _selectedEventId,
        archived:       widget.lead.archived,
      );
      await SupabaseService.instance.saveLead(updated);
      widget.onSaved(updated);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Edit Contact',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 20),
          _Field(controller: _nameCtrl,    hint: 'Name*',   icon: Icons.person_outline_rounded),
          const SizedBox(height: 10),
          _Field(controller: _emailCtrl,   hint: 'Email',   icon: Icons.mail_outline_rounded,   type: TextInputType.emailAddress),
          const SizedBox(height: 10),
          _Field(controller: _phoneCtrl,   hint: 'Phone',   icon: Icons.phone_outlined,          type: TextInputType.phone),
          const SizedBox(height: 10),
          _Field(controller: _companyCtrl, hint: 'Company', icon: Icons.business_outlined),
          const SizedBox(height: 10),
          _Field(controller: _noteCtrl,    hint: 'Note',    icon: Icons.notes_rounded),
          // Event selector
          if (widget.events.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedEventId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2C2C2E),
                  icon: const Icon(Icons.expand_more_rounded,
                      size: 18, color: Color(0xFF555555)),
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('No Event',
                          style: TextStyle(color: Color(0xFF555555))),
                    ),
                    ...widget.events.map((e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.name),
                    )),
                  ],
                  onChanged: (v) => setState(() => _selectedEventId = v ?? ''),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: _saving
                    ? const CircularProgressIndicator(
                        color: Colors.black, strokeWidth: 1.5)
                    : const Text('Update Contact',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType type;
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: type,
    style: const TextStyle(fontSize: 15, color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF555555)),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF555555)),
      filled: true,
      fillColor: const Color(0xFF2C2C2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
