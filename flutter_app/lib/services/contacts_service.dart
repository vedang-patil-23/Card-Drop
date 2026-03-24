import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact_model.dart';
import '../models/profile_model.dart';
import 'supabase_service.dart';

/// Manages the local contact wallet (scanned contacts)
class ContactsService {
  ContactsService._();
  static final ContactsService instance = ContactsService._();

  static const _kContactsKey = 'contacts_wallet';

  Future<ContactModel> saveContactFromProfile({
    required String ownerProfileId,
    required ProfileModel scannedProfile,
  }) async {
    final contact = ContactModel(
      id:           scannedProfile.id,
      profileId:    scannedProfile.id,
      displayName:  scannedProfile.displayName,
      jobTitle:     scannedProfile.jobTitle,
      company:      scannedProfile.company,
      email:        scannedProfile.email,
      phone:        scannedProfile.phone,
      website:      scannedProfile.website,
      photoUrl:     scannedProfile.photoUrl,
      profileColor: scannedProfile.profileColor,
      savedAt:      DateTime.now(),
    );

    await SupabaseService.instance.saveContact(ownerProfileId, contact);
    await _cacheContactLocally(contact);
    return contact;
  }

  Future<List<ContactModel>> getLocalContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_kContactsKey);
    if (raw == null) return [];
    final list  = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> _cacheContactLocally(ContactModel contact) async {
    final contacts = await getLocalContacts();
    final idx      = contacts.indexWhere((c) => c.id == contact.id);
    if (idx >= 0) {
      contacts[idx] = contact;
    } else {
      contacts.insert(0, contact);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kContactsKey,
      jsonEncode(contacts.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> deleteContact({
    required String ownerProfileId,
    required String contactId,
  }) async {
    await SupabaseService.instance.deleteContact(contactId);

    final contacts = await getLocalContacts();
    contacts.removeWhere((c) => c.id == contactId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kContactsKey,
      jsonEncode(contacts.map((c) => c.toJson()).toList()),
    );
  }

  bool alreadySaved(List<ContactModel> contacts, String profileId) =>
      contacts.any((c) => c.profileId == profileId);
}
