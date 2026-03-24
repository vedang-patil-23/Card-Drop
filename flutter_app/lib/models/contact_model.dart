/// A contact saved by scanning another user's QR code
class ContactModel {
  final String id;
  final String profileId;
  final String displayName;
  final String jobTitle;
  final String company;
  final String email;
  final String phone;
  final String website;
  final String photoUrl;
  final String profileColor;
  final DateTime savedAt;
  final String note;

  const ContactModel({
    required this.id,
    required this.profileId,
    this.displayName  = '',
    this.jobTitle     = '',
    this.company      = '',
    this.email        = '',
    this.phone        = '',
    this.website      = '',
    this.photoUrl     = '',
    this.profileColor = '#6C63FF',
    required this.savedAt,
    this.note         = '',
  });

  // ── Supabase ───────────────────────────────────────────────────────────────

  factory ContactModel.fromSupabase(Map<String, dynamic> row) => ContactModel(
    id:           row['id']            ?? '',
    profileId:    row['profile_id']    ?? '',
    displayName:  row['display_name']  ?? '',
    jobTitle:     row['job_title']     ?? '',
    company:      row['company']       ?? '',
    email:        row['email']         ?? '',
    phone:        row['phone']         ?? '',
    website:      row['website']       ?? '',
    photoUrl:     row['photo_url']     ?? '',
    profileColor: row['profile_color'] ?? '#6C63FF',
    savedAt:      DateTime.tryParse(row['saved_at'] ?? '') ?? DateTime.now(),
    note:         row['note']          ?? '',
  );

  Map<String, dynamic> toSupabase() => {
    'id':             id,
    'owner_profile_id': '', // filled in by service
    'profile_id':     profileId,
    'display_name':   displayName,
    'job_title':      jobTitle,
    'company':        company,
    'email':          email,
    'phone':          phone,
    'website':        website,
    'photo_url':      photoUrl,
    'profile_color':  profileColor,
    'saved_at':       savedAt.toIso8601String(),
    'note':           note,
  };

  // ── Local JSON ─────────────────────────────────────────────────────────────

  factory ContactModel.fromJson(Map<String, dynamic> j) => ContactModel(
    id:           j['id']           ?? '',
    profileId:    j['profileId']    ?? '',
    displayName:  j['displayName']  ?? '',
    jobTitle:     j['jobTitle']     ?? '',
    company:      j['company']      ?? '',
    email:        j['email']        ?? '',
    phone:        j['phone']        ?? '',
    website:      j['website']      ?? '',
    photoUrl:     j['photoUrl']     ?? '',
    profileColor: j['profileColor'] ?? '#6C63FF',
    savedAt:      DateTime.tryParse(j['savedAt'] ?? '') ?? DateTime.now(),
    note:         j['note']         ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id':           id,
    'profileId':    profileId,
    'displayName':  displayName,
    'jobTitle':     jobTitle,
    'company':      company,
    'email':        email,
    'phone':        phone,
    'website':      website,
    'photoUrl':     photoUrl,
    'profileColor': profileColor,
    'savedAt':      savedAt.toIso8601String(),
    'note':         note,
  };

  String toVCard() => '''BEGIN:VCARD
VERSION:3.0
FN:$displayName
TITLE:$jobTitle
ORG:$company
EMAIL:$email
TEL:$phone
URL:$website
END:VCARD''';

  ContactModel copyWith({String? note}) => ContactModel(
    id:           id,
    profileId:    profileId,
    displayName:  displayName,
    jobTitle:     jobTitle,
    company:      company,
    email:        email,
    phone:        phone,
    website:      website,
    photoUrl:     photoUrl,
    profileColor: profileColor,
    savedAt:      savedAt,
    note:         note ?? this.note,
  );
}
