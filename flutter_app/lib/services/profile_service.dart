import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/profile_model.dart';
import 'supabase_service.dart';

/// Manages the local (device-owner) profile — creation, caching, Supabase sync
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  static const _kProfileKey   = 'owner_profile';
  static const _kProfileIdKey = 'owner_profile_id';

  ProfileModel? _cachedProfile;

  // ── Public profile URL ─────────────────────────────────────────────────────

  /// Change this to your Netlify app URL after deployment
  static const String netlifyBaseUrl = 'https://YOUR_SITE.netlify.app';

  String profileUrl(String profileId) => '$netlifyBaseUrl/profile/$profileId';

  // ── Load / Save ────────────────────────────────────────────────────────────

  Future<ProfileModel> getOrCreateProfile() async {
    if (_cachedProfile != null) return _cachedProfile!;

    final prefs = await SharedPreferences.getInstance();
    final json  = prefs.getString(_kProfileKey);

    if (json != null) {
      _cachedProfile = ProfileModel.fromJson(jsonDecode(json));
      return _cachedProfile!;
    }

    final id = prefs.getString(_kProfileIdKey) ?? const Uuid().v4();
    await prefs.setString(_kProfileIdKey, id);

    _cachedProfile = ProfileModel(
      id:        id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _persistLocally(_cachedProfile!);
    return _cachedProfile!;
  }

  Future<ProfileModel> saveProfile(ProfileModel profile) async {
    _cachedProfile = profile;
    await _persistLocally(profile);
    await SupabaseService.instance.saveProfile(profile);
    return profile;
  }

  Future<ProfileModel> updateProfilePhoto(ProfileModel profile, File imageFile) async {
    final url     = await SupabaseService.instance.uploadProfilePhoto(
      profile.id, imageFile,
    );
    final updated = profile.copyWith(photoUrl: url);
    return saveProfile(updated);
  }

  Future<ProfileModel> removeProfilePhoto(ProfileModel profile) async {
    await SupabaseService.instance.deleteProfilePhoto(profile.id);
    final updated = profile.copyWith(photoUrl: '');
    return saveProfile(updated);
  }

  Future<void> _persistLocally(ProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileKey, jsonEncode(profile.toJson()));
  }

  void clearCache() => _cachedProfile = null;
}
