import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AnonymousIdService {
  static const String _anonymousIdKey = 'anonymous_id';
  static const String _displayNameKey = 'display_name';
  static const String _createdAtKey = 'created_at';

  final SharedPreferences _prefs;
  final Uuid _uuid = const Uuid();

  AnonymousIdService(this._prefs);

  static Future<AnonymousIdService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AnonymousIdService(prefs);
  }

  /// Get or create anonymous ID
  Future<String> getOrCreateAnonymousId() async {
    String? anonymousId = _prefs.getString(_anonymousIdKey);

    if (anonymousId == null) {
      anonymousId = _uuid.v4();
      await _prefs.setString(_anonymousIdKey, anonymousId);
      await _prefs.setString(_createdAtKey, DateTime.now().toIso8601String());

      // Generate random display name
      final displayName = _generateDisplayName();
      await _prefs.setString(_displayNameKey, displayName);
    }

    return anonymousId;
  }

  /// Get current anonymous user
  Future<AnonymousUser?> getCurrentUser() async {
    final anonymousId = _prefs.getString(_anonymousIdKey);
    if (anonymousId == null) return null;

    final displayName = _prefs.getString(_displayNameKey) ?? 'Anonymous User';
    final createdAtStr = _prefs.getString(_createdAtKey);
    final createdAt =
        createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();

    return AnonymousUser(
      anonymousId: anonymousId,
      displayName: displayName,
      createdAt: createdAt,
    );
  }

  /// Export profile data (for saving across devices)
  Future<Map<String, String>> exportProfile() async {
    final anonymousId = await getOrCreateAnonymousId();
    final displayName = _prefs.getString(_displayNameKey) ?? 'Anonymous User';
    final createdAt =
        _prefs.getString(_createdAtKey) ?? DateTime.now().toIso8601String();

    return {
      'anonymousId': anonymousId,
      'displayName': displayName,
      'createdAt': createdAt,
    };
  }

  /// Import profile data (for restoring on new device)
  Future<void> importProfile(Map<String, String> profileData) async {
    await _prefs.setString(_anonymousIdKey, profileData['anonymousId']!);
    await _prefs.setString(_displayNameKey, profileData['displayName']!);
    await _prefs.setString(_createdAtKey, profileData['createdAt']!);
  }

  /// Clear all data (start fresh)
  Future<void> clearProfile() async {
    await _prefs.remove(_anonymousIdKey);
    await _prefs.remove(_displayNameKey);
    await _prefs.remove(_createdAtKey);
  }

  /// Generate random anonymous display name
  String _generateDisplayName() {
    final adjectives = [
      'Brave',
      'Kind',
      'Gentle',
      'Strong',
      'Peaceful',
      'Hopeful',
      'Calm',
      'Bright',
      'Wise',
      'Caring',
      'Thoughtful',
      'Resilient'
    ];
    final animals = [
      'Butterfly',
      'Dove',
      'Phoenix',
      'Owl',
      'Deer',
      'Swan',
      'Eagle',
      'Dolphin',
      'Panda',
      'Fox',
      'Wolf',
      'Bear'
    ];

    final random = DateTime.now().millisecondsSinceEpoch;
    final adjective = adjectives[random % adjectives.length];
    final animal = animals[(random ~/ 1000) % animals.length];

    return 'Anonymous $adjective $animal';
  }
}
