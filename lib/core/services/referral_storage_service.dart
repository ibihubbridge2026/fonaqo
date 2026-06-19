import 'package:shared_preferences/shared_preferences.dart';

import '../api/base_client.dart';

/// Parrainage capturé uniquement via deep link `/join/:code` (validé côté API).
class ReferralPending {
  final String code;
  final String? influencerName;

  const ReferralPending({required this.code, this.influencerName});
}

class ReferralStorageService {
  ReferralStorageService._();
  static final ReferralStorageService instance = ReferralStorageService._();

  static const _keyCode = 'referral_code_cache';
  static const _keyInfluencer = 'referral_influencer_name';

  final BaseClient _client = BaseClient();

  Map<String, dynamic>? _unwrap(dynamic body) {
    if (body is! Map) return null;
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return Map<String, dynamic>.from(body);
  }

  /// Valide via GET /public/join/{code}/ puis stocke si OK.
  Future<bool> captureFromDeepLink(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) return false;

    try {
      final res = await _client.get('public/join/$code/');
      if (res.statusCode != 200) {
        await clear();
        return false;
      }
      final preview = _unwrap(res.data);
      if (preview == null || preview['valid'] != true) {
        await clear();
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final storedCode =
          (preview['referral_code']?.toString().trim().isNotEmpty == true)
              ? preview['referral_code'].toString().trim()
              : code;
      await prefs.setString(_keyCode, storedCode);
      final name = preview['influencer_name']?.toString();
      if (name != null && name.isNotEmpty) {
        await prefs.setString(_keyInfluencer, name);
      } else {
        await prefs.remove(_keyInfluencer);
      }
      return true;
    } catch (_) {
      await clear();
      return false;
    }
  }

  /// Re-valide un code déjà stocké (évite les caches invalides).
  Future<bool> revalidateStored() async {
    final code = await readCode();
    if (code == null) return false;
    return captureFromDeepLink(code);
  }

  Future<String?> readCode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyCode);
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<ReferralPending?> readPending() async {
    final code = await readCode();
    if (code == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyInfluencer);
    return ReferralPending(
      code: code,
      influencerName: name?.trim().isNotEmpty == true ? name!.trim() : null,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCode);
    await prefs.remove(_keyInfluencer);
  }
}
