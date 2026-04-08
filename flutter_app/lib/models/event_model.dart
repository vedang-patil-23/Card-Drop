class EventModel {
  final String id;
  final String ownerProfileId;
  final String name;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.ownerProfileId,
    required this.name,
    required this.createdAt,
  });

  factory EventModel.fromSupabase(Map<String, dynamic> row) => EventModel(
    id:             row['id']               ?? '',
    ownerProfileId: row['owner_profile_id'] ?? '',
    name:           row['name']             ?? '',
    createdAt:      DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toSupabase() => {
    'id':               id,
    'owner_profile_id': ownerProfileId,
    'name':             name,
    'created_at':       createdAt.toIso8601String(),
  };
}
