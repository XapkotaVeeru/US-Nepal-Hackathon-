import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AnonymousIdService {
  static const String _anonymousIdKey = 'anonymous_id';
  static const String _displayNameKey = 'display_name';
  static const String _createdAtKey = 'created_at';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _chatRequestsEnabledKey = 'chat_requests_enabled';
  static const String _groupInvitesEnabledKey = 'group_invites_enabled';

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
      await _saveDefaultSettings();
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
      notificationsEnabled: _prefs.getBool(_notificationsEnabledKey) ?? true,
      soundEnabled: _prefs.getBool(_soundEnabledKey) ?? true,
      chatRequestsEnabled:
          _prefs.getBool(_chatRequestsEnabledKey) ?? true,
      groupInvitesEnabled:
          _prefs.getBool(_groupInvitesEnabledKey) ?? true,
    );
  }

  Future<void> saveCurrentUser(AnonymousUser user) async {
    await _prefs.setString(_anonymousIdKey, user.anonymousId);
    await _prefs.setString(_displayNameKey, user.displayName);
    await _prefs.setString(_createdAtKey, user.createdAt.toIso8601String());
    await _prefs.setBool(
      _notificationsEnabledKey,
      user.notificationsEnabled,
    );
    await _prefs.setBool(_soundEnabledKey, user.soundEnabled);
    await _prefs.setBool(
      _chatRequestsEnabledKey,
      user.chatRequestsEnabled,
    );
    await _prefs.setBool(
      _groupInvitesEnabledKey,
      user.groupInvitesEnabled,
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
      'notificationsEnabled':
          (_prefs.getBool(_notificationsEnabledKey) ?? true).toString(),
      'soundEnabled': (_prefs.getBool(_soundEnabledKey) ?? true).toString(),
      'chatRequestsEnabled':
          (_prefs.getBool(_chatRequestsEnabledKey) ?? true).toString(),
      'groupInvitesEnabled':
          (_prefs.getBool(_groupInvitesEnabledKey) ?? true).toString(),
    };
  }

  /// Import profile data (for restoring on new device)
  Future<void> importProfile(Map<String, String> profileData) async {
    await _prefs.setString(_anonymousIdKey, profileData['anonymousId']!);
    await _prefs.setString(_displayNameKey, profileData['displayName']!);
    await _prefs.setString(_createdAtKey, profileData['createdAt']!);
    await _prefs.setBool(
      _notificationsEnabledKey,
      _parseBool(profileData['notificationsEnabled'], fallback: true),
    );
    await _prefs.setBool(
      _soundEnabledKey,
      _parseBool(profileData['soundEnabled'], fallback: true),
    );
    await _prefs.setBool(
      _chatRequestsEnabledKey,
      _parseBool(profileData['chatRequestsEnabled'], fallback: true),
    );
    await _prefs.setBool(
      _groupInvitesEnabledKey,
      _parseBool(profileData['groupInvitesEnabled'], fallback: true),
    );
  }

  /// Clear all data (start fresh)
  Future<void> clearProfile() async {
    await _prefs.remove(_anonymousIdKey);
    await _prefs.remove(_displayNameKey);
    await _prefs.remove(_createdAtKey);
    await _prefs.remove(_notificationsEnabledKey);
    await _prefs.remove(_soundEnabledKey);
    await _prefs.remove(_chatRequestsEnabledKey);
    await _prefs.remove(_groupInvitesEnabledKey);
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

  Future<void> _saveDefaultSettings() async {
    await _prefs.setBool(_notificationsEnabledKey, true);
    await _prefs.setBool(_soundEnabledKey, true);
    await _prefs.setBool(_chatRequestsEnabledKey, true);
    await _prefs.setBool(_groupInvitesEnabledKey, true);
  }

  bool _parseBool(String? raw, {required bool fallback}) {
    if (raw == null) return fallback;
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    return fallback;
  }
}
