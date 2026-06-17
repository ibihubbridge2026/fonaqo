import 'package:shared_preferences/shared_preferences.dart';

/// Stocke le code parrainage capturé via deep link avant inscription.
class ReferralStorageService {
  ReferralStorageService._();
  static final ReferralStorageService instance = ReferralStorageService._();

  static const _key = 'referral_code_cache';

  Future<void> save(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, trimmed);
  }

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
