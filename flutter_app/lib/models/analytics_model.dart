/// A single profile view event — maps to `profile_views` Supabase table
class ViewEvent {
  final String id;
  final String profileId;
  final String source;      // 'qr' | 'link'
  final String country;
  final String ipAddress;     // visitor IP (captured on web)
  final String deviceName;    // e.g. 'iPhone', 'Android', 'Mac'
  final String userAgent;
  final bool contactSaved;    // true if they downloaded the vCard
  final DateTime viewedAt;

  const ViewEvent({
    required this.id,
    required this.profileId,
    this.source        = 'qr',
    this.country       = '',
    this.ipAddress     = '',
    this.deviceName    = '',
    this.userAgent     = '',
    this.contactSaved  = false,
    required this.viewedAt,
  });

  factory ViewEvent.fromSupabase(Map<String, dynamic> row) => ViewEvent(
    id:           row['id']             ?? '',
    profileId:    row['profile_id']     ?? '',
    source:       row['source']         ?? 'qr',
    country:      row['country']        ?? '',
    ipAddress:    row['ip_address']     ?? '',
    deviceName:   row['device_name']    ?? '',
    userAgent:    row['user_agent']     ?? '',
    contactSaved: row['contact_saved']  == true,
    viewedAt:     DateTime.tryParse(row['viewed_at'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toSupabase() => {
    'profile_id':  profileId,
    'source':      source,
    'country':     country,
    'ip_address':  ipAddress,
    'device_name': deviceName,
    'user_agent':  userAgent,
    'viewed_at':   viewedAt.toIso8601String(),
  };
}

/// Aggregated analytics summary
class AnalyticsSummary {
  final int totalViews;
  final int totalLeads;
  final int totalContacts;
  final int viewsToday;
  final int viewsThisWeek;
  final int viewsThisMonth;
  final Map<String, int> viewsBySource;
  final List<DailyViews> last30Days;
  final int contactSaves;              // how many saved the vCard
  final List<ViewEvent> recentViewers; // last 20, newest first

  const AnalyticsSummary({
    this.totalViews     = 0,
    this.totalLeads     = 0,
    this.totalContacts  = 0,
    this.viewsToday     = 0,
    this.viewsThisWeek  = 0,
    this.viewsThisMonth = 0,
    this.contactSaves   = 0,
    this.viewsBySource  = const {},
    this.last30Days     = const [],
    this.recentViewers  = const [],
  });
}

class DailyViews {
  final DateTime date;
  final int count;
  const DailyViews({required this.date, required this.count});
}
