class AuthService {
  static String? _role;

  static String? get role => _role;

  static void setRole(String value) {
    _role = value;
  }

  static Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<void> register(String email, String password, String role) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _role = role;
  }
}