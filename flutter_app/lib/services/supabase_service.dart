import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/profile_model.dart';
import '../models/contact_model.dart';
import '../models/lead_model.dart';
import '../models/event_model.dart';
import '../models/analytics_model.dart';

/// Single access point for all Supabase operations.
/// Tables: profiles, contacts, leads, profile_views
/// Storage bucket: profile-photos
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;
  final _uuid = const Uuid();

  // ── Profile ────────────────────────────────────────────────────────────────

  /// Upsert profile row (insert or update by primary key)
  Future<void> saveProfile(ProfileModel profile) async {
    await _client
        .from('profiles')
        .upsert(profile.toSupabase());
  }

  /// Fetch a single profile by UUID
  Future<ProfileModel?> fetchProfile(String profileId) async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', profileId)
          .maybeSingle();
      if (row == null) return null;
      return ProfileModel.fromSupabase(row);
    } catch (_) {
      return null;
    }
  }

  /// Upload profile photo to Supabase Storage and return public URL
  Future<String> uploadProfilePhoto(String profileId, File imageFile) async {
    final path = '$profileId/photo.jpg';
    await _client.storage
        .from('profile-photos')
        .upload(
          path,
          imageFile,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    final url = _client.storage
        .from('profile-photos')
        .getPublicUrl(path);
    // Bust cache by appending timestamp
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Delete profile photo from storage
  Future<void> deleteProfilePhoto(String profileId) async {
    try {
      await _client.storage
          .from('profile-photos')
          .remove(['$profileId/photo.jpg']);
    } catch (_) {}
  }

  // ── Leads ──────────────────────────────────────────────────────────────────

  Future<void> saveLead(LeadModel lead) async {
    await _client.from('leads').upsert(lead.toSupabase());
  }

  Future<List<LeadModel>> fetchLeads(String profileId) async {
    final rows = await _client
        .from('leads')
        .select()
        .eq('owner_profile_id', profileId)
        .order('captured_at', ascending: false);
    return rows.map((r) => LeadModel.fromSupabase(r)).toList();
  }

  Future<void> markLeadSeen(String leadId) async {
    await _client
        .from('leads')
        .update({'is_new': false})
        .eq('id', leadId);
  }

  Future<void> deleteLead(String leadId) async {
    await _client.from('leads').delete().eq('id', leadId);
  }

  Future<void> archiveLead(String leadId, bool archived) async {
    await _client
        .from('leads')
        .update({'archived': archived})
        .eq('id', leadId);
  }

  // ── Events ─────────────────────────────────────────────────────────────────

  Future<void> saveEvent(EventModel event) async {
    await _client.from('events').upsert(event.toSupabase());
  }

  Future<List<EventModel>> fetchEvents(String profileId) async {
    final rows = await _client
        .from('events')
        .select()
        .eq('owner_profile_id', profileId)
        .order('created_at', ascending: false);
    return rows.map((r) => EventModel.fromSupabase(r)).toList();
  }

  Future<void> updateEventName(String eventId, String name) async {
    await _client
        .from('events')
        .update({'name': name})
        .eq('id', eventId);
  }

  Future<void> deleteEvent(String eventId) async {
    // Clear event_id from leads referencing this event
    await _client
        .from('leads')
        .update({'event_id': ''})
        .eq('event_id', eventId);
    await _client.from('events').delete().eq('id', eventId);
  }

  // ── Contacts ───────────────────────────────────────────────────────────────

  Future<void> saveContact(String ownerProfileId, ContactModel contact) async {
    final row = contact.toSupabase();
    row['owner_profile_id'] = ownerProfileId;
    await _client.from('contacts').upsert(row);
  }

  Future<List<ContactModel>> fetchContacts(String ownerProfileId) async {
    final rows = await _client
        .from('contacts')
        .select()
        .eq('owner_profile_id', ownerProfileId)
        .order('saved_at', ascending: false);
    return rows.map((r) => ContactModel.fromSupabase(r)).toList();
  }

  Future<void> deleteContact(String contactId) async {
    await _client.from('contacts').delete().eq('id', contactId);
  }

  // ── Analytics ──────────────────────────────────────────────────────────────

  /// Insert a profile view event
  Future<void> recordView({
    required String profileId,
    String source  = 'qr',
    String country = '',
  }) async {
    await _client.from('profile_views').insert({
      'profile_id': profileId,
      'source':     source,
      'country':    country,
      'viewed_at':  DateTime.now().toIso8601String(),
    });
  }

  Future<AnalyticsSummary> fetchAnalytics(String profileId) async {
    final now      = DateTime.now();
    final today    = DateTime(now.year, now.month, now.day);
    final weekAgo  = today.subtract(const Duration(days: 7));
    final monthAgo = today.subtract(const Duration(days: 30));

    // Run counts in parallel
    final results = await Future.wait([
      _client
          .from('profile_views')
          .select()
          .eq('profile_id', profileId),
      _client
          .from('leads')
          .select('id')
          .eq('owner_profile_id', profileId),
      _client
          .from('contacts')
          .select('id')
          .eq('owner_profile_id', profileId),
    ]);

    final views = (results[0] as List)
        .map((r) => ViewEvent.fromSupabase(r as Map<String, dynamic>))
        .toList();
    final leadsCount    = (results[1] as List).length;
    final contactsCount = (results[2] as List).length;

    // Source breakdown
    final Map<String, int> bySource = {};
    for (final v in views) {
      bySource[v.source] = (bySource[v.source] ?? 0) + 1;
    }

    // Daily buckets
    final Map<String, int> dailyMap = {};
    for (final v in views) {
      if (v.viewedAt.isAfter(monthAgo)) {
        final key = _dateKey(v.viewedAt);
        dailyMap[key] = (dailyMap[key] ?? 0) + 1;
      }
    }

    final List<DailyViews> last30 = [];
    for (int i = 29; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      last30.add(DailyViews(date: d, count: dailyMap[_dateKey(d)] ?? 0));
    }

    // Most recent 20 viewers (newest first)
    final recentViewers = ([...views]
      ..sort((a, b) => b.viewedAt.compareTo(a.viewedAt)))
      .take(20)
      .toList();

    return AnalyticsSummary(
      totalViews:     views.length,
      totalLeads:     leadsCount,
      totalContacts:  contactsCount,
      viewsToday:     views.where((v) => v.viewedAt.isAfter(today)).length,
      viewsThisWeek:  views.where((v) => v.viewedAt.isAfter(weekAgo)).length,
      viewsThisMonth: views.where((v) => v.viewedAt.isAfter(monthAgo)).length,
      contactSaves:   views.where((v) => v.contactSaved).length,
      viewsBySource:  bySource,
      last30Days:     last30,
      recentViewers:  recentViewers,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String generateId() => _uuid.v4();

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
