/// Social link entry on a user's profile
class SocialLink {
  final String platform;
  final String url;
  final bool isActive;

  const SocialLink({
    required this.platform,
    required this.url,
    this.isActive = true,
  });

  factory SocialLink.fromMap(Map<String, dynamic> map) => SocialLink(
    platform: map['platform'] ?? '',
    url:      map['url']      ?? '',
    isActive: map['isActive'] ?? true,
  );

  Map<String, dynamic> toMap() => {
    'platform': platform,
    'url':      url,
    'isActive': isActive,
  };

  SocialLink copyWith({String? platform, String? url, bool? isActive}) =>
      SocialLink(
        platform: platform ?? this.platform,
        url:      url      ?? this.url,
        isActive: isActive ?? this.isActive,
      );
}

/// Core user profile — stored locally + synced to Supabase `profiles` table
class ProfileModel {
  final String id;
  final String displayName;
  final String jobTitle;
  final String company;
  final String bio;
  final String email;
  final String phone;
  final String website;
  final String photoUrl;
  final String profileColor;
  final List<SocialLink> socialLinks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileModel({
    required this.id,
    this.displayName  = '',
    this.jobTitle     = '',
    this.company      = '',
    this.bio          = '',
    this.email        = '',
    this.phone        = '',
    this.website      = '',
    this.photoUrl     = '',
    this.profileColor = '#6C63FF',
    this.socialLinks  = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Supabase (snake_case columns) ──────────────────────────────────────────

  factory ProfileModel.fromSupabase(Map<String, dynamic> row) => ProfileModel(
    id:           row['id']            ?? '',
    displayName:  row['display_name']  ?? '',
    jobTitle:     row['job_title']     ?? '',
    company:      row['company']       ?? '',
    bio:          row['bio']           ?? '',
    email:        row['email']         ?? '',
    phone:        row['phone']         ?? '',
    website:      row['website']       ?? '',
    photoUrl:     row['photo_url']     ?? '',
    profileColor: row['profile_color'] ?? '#6C63FF',
    socialLinks:  (row['social_links'] as List<dynamic>? ?? [])
        .map((e) => SocialLink.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
    createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(row['updated_at'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toSupabase() => {
    'id':            id,
    'display_name':  displayName,
    'job_title':     jobTitle,
    'company':       company,
    'bio':           bio,
    'email':         email,
    'phone':         phone,
    'website':       website,
    'photo_url':     photoUrl,
    'profile_color': profileColor,
    'social_links':  socialLinks.map((e) => e.toMap()).toList(),
    'updated_at':    DateTime.now().toIso8601String(),
  };

  // ── Local JSON cache ───────────────────────────────────────────────────────

  factory ProfileModel.fromJson(Map<String, dynamic> j) => ProfileModel(
    id:           j['id']           ?? '',
    displayName:  j['displayName']  ?? '',
    jobTitle:     j['jobTitle']     ?? '',
    company:      j['company']      ?? '',
    bio:          j['bio']          ?? '',
    email:        j['email']        ?? '',
    phone:        j['phone']        ?? '',
    website:      j['website']      ?? '',
    photoUrl:     j['photoUrl']     ?? '',
    profileColor: j['profileColor'] ?? '#6C63FF',
    socialLinks:  (j['socialLinks'] as List<dynamic>? ?? [])
        .map((e) => SocialLink.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id':           id,
    'displayName':  displayName,
    'jobTitle':     jobTitle,
    'company':      company,
    'bio':          bio,
    'email':        email,
    'phone':        phone,
    'website':      website,
    'photoUrl':     photoUrl,
    'profileColor': profileColor,
    'socialLinks':  socialLinks.map((e) => e.toMap()).toList(),
    'createdAt':    createdAt.toIso8601String(),
    'updatedAt':    updatedAt.toIso8601String(),
  };

  ProfileModel copyWith({
    String? displayName, String? jobTitle, String? company,
    String? bio, String? email, String? phone, String? website,
    String? photoUrl, String? profileColor, List<SocialLink>? socialLinks,
  }) => ProfileModel(
    id:           id,
    displayName:  displayName  ?? this.displayName,
    jobTitle:     jobTitle     ?? this.jobTitle,
    company:      company      ?? this.company,
    bio:          bio          ?? this.bio,
    email:        email        ?? this.email,
    phone:        phone        ?? this.phone,
    website:      website      ?? this.website,
    photoUrl:     photoUrl     ?? this.photoUrl,
    profileColor: profileColor ?? this.profileColor,
    socialLinks:  socialLinks  ?? this.socialLinks,
    createdAt:    createdAt,
    updatedAt:    DateTime.now(),
  );

  String toVCard() => '''BEGIN:VCARD
VERSION:3.0
FN:$displayName
TITLE:$jobTitle
ORG:$company
EMAIL:$email
TEL:$phone
URL:$website
NOTE:$bio
END:VCARD''';

  bool get isEmpty => displayName.isEmpty && email.isEmpty && phone.isEmpty;
}

/// Supported social platforms config
class SocialPlatform {
  final String id;
  final String label;
  final String placeholder;
  final String iconAsset;
  final int color;

  const SocialPlatform({
    required this.id,
    required this.label,
    required this.placeholder,
    required this.iconAsset,
    required this.color,
  });

  static const List<SocialPlatform> all = [
    SocialPlatform(id: 'linkedin',  label: 'LinkedIn',    placeholder: 'linkedin.com/in/username',  iconAsset: 'linkedin',  color: 0xFF0077B5),
    SocialPlatform(id: 'instagram', label: 'Instagram',   placeholder: 'instagram.com/username',    iconAsset: 'instagram', color: 0xFFE1306C),
    SocialPlatform(id: 'twitter',   label: 'X / Twitter', placeholder: 'x.com/username',            iconAsset: 'twitter',   color: 0xFF1DA1F2),
    SocialPlatform(id: 'tiktok',    label: 'TikTok',      placeholder: 'tiktok.com/@username',      iconAsset: 'tiktok',    color: 0xFF010101),
    SocialPlatform(id: 'facebook',  label: 'Facebook',    placeholder: 'facebook.com/username',     iconAsset: 'facebook',  color: 0xFF1877F2),
    SocialPlatform(id: 'youtube',   label: 'YouTube',     placeholder: 'youtube.com/@channel',      iconAsset: 'youtube',   color: 0xFFFF0000),
    SocialPlatform(id: 'github',    label: 'GitHub',      placeholder: 'github.com/username',       iconAsset: 'github',    color: 0xFF333333),
    SocialPlatform(id: 'snapchat',  label: 'Snapchat',    placeholder: 'snapchat.com/add/username', iconAsset: 'snapchat',  color: 0xFFFFFC00),
    SocialPlatform(id: 'website',   label: 'Website',     placeholder: 'https://yoursite.com',      iconAsset: 'website',   color: 0xFF6C63FF),
    SocialPlatform(id: 'calendly',  label: 'Calendly',    placeholder: 'calendly.com/username',     iconAsset: 'calendly',  color: 0xFF006BFF),
    SocialPlatform(id: 'cashapp',   label: 'Cash App',    placeholder: r'cash.app/$username',       iconAsset: 'cashapp',   color: 0xFF00D632),
    SocialPlatform(id: 'venmo',     label: 'Venmo',       placeholder: 'venmo.com/u/username',      iconAsset: 'venmo',     color: 0xFF3D95CE),
  ];

  static SocialPlatform? findById(String id) {
    try { return all.firstWhere((p) => p.id == id); }
    catch (_) { return null; }
  }
}
