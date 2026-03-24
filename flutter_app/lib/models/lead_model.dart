/// A lead captured via the in-app form or Netlify public page
class LeadModel {
  final String id;
  final String ownerProfileId;
  final String name;
  final String email;
  final String phone;
  final String organization;
  final String note;
  final String source;       // 'app' | 'web'
  final DateTime capturedAt;
  final bool isNew;

  const LeadModel({
    required this.id,
    required this.ownerProfileId,
    this.name         = '',
    this.email        = '',
    this.phone        = '',
    this.organization = '',
    this.note         = '',
    this.source       = 'app',
    required this.capturedAt,
    this.isNew        = true,
  });

  // ── Supabase ───────────────────────────────────────────────────────────────

  factory LeadModel.fromSupabase(Map<String, dynamic> row) => LeadModel(
    id:             row['id']               ?? '',
    ownerProfileId: row['owner_profile_id'] ?? '',
    name:           row['name']             ?? '',
    email:          row['email']            ?? '',
    phone:          row['phone']            ?? '',
    organization:   row['organization']     ?? '',
    note:           row['note']             ?? '',
    source:         row['source']           ?? 'app',
    capturedAt:     DateTime.tryParse(row['captured_at'] ?? '') ?? DateTime.now(),
    isNew:          row['is_new']           ?? true,
  );

  Map<String, dynamic> toSupabase() => {
    'id':               id,
    'owner_profile_id': ownerProfileId,
    'name':             name,
    'email':            email,
    'phone':            phone,
    'organization':     organization,
    'note':             note,
    'source':           source,
    'captured_at':      capturedAt.toIso8601String(),
    'is_new':           isNew,
  };

  // ── Local JSON ─────────────────────────────────────────────────────────────

  factory LeadModel.fromJson(Map<String, dynamic> j) => LeadModel(
    id:             j['id']             ?? '',
    ownerProfileId: j['ownerProfileId'] ?? '',
    name:           j['name']           ?? '',
    email:          j['email']          ?? '',
    phone:          j['phone']          ?? '',
    organization:   j['organization']   ?? '',
    note:           j['note']           ?? '',
    source:         j['source']         ?? 'app',
    capturedAt:     DateTime.tryParse(j['capturedAt'] ?? '') ?? DateTime.now(),
    isNew:          j['isNew']          ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id':             id,
    'ownerProfileId': ownerProfileId,
    'name':           name,
    'email':          email,
    'phone':          phone,
    'organization':   organization,
    'note':           note,
    'source':         source,
    'capturedAt':     capturedAt.toIso8601String(),
    'isNew':          isNew,
  };

  LeadModel copyWith({bool? isNew, String? note}) => LeadModel(
    id:             id,
    ownerProfileId: ownerProfileId,
    name:           name,
    email:          email,
    phone:          phone,
    organization:   organization,
    note:           note  ?? this.note,
    source:         source,
    capturedAt:     capturedAt,
    isNew:          isNew ?? this.isNew,
  );
}
