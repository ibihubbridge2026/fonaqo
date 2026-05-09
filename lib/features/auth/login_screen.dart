import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();

  _Country _country = _Country.ci();
  bool _usePhone = false;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 309,
              width: double.infinity,
              color: const Color(0xFFFFD400),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/icon/fonaco.png',
                    width: 120,
                    color: Colors.black,
                    errorBuilder: (_, __, ___) => const Icon(Icons.bolt, color: Colors.black, size: 120),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Bon retour",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Connectez-vous maintenant !",
                            style: TextStyle(color: Color(0xFF5E5E5E)),
                          ),
                          const SizedBox(height: 18),

                          _LoginMethodToggle(
                            usePhone: _usePhone,
                            onChanged: (v) => setState(() => _usePhone = v),
                          ),
                          const SizedBox(height: 12),
                          if (!_usePhone)
                            _InputCard(
                              child: TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: 'nom@exemple.com',
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                              ),
                            )
                          else
                            _PhoneInputCard(
                              country: _country,
                              onCountryPressed: () async {
                                final picked = await _pickCountry(context, _country);
                                if (picked == null) return;
                                setState(() => _country = picked);
                              },
                              controller: _phone,
                            ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('MOT DE PASSE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                                child: const Text("Mot de passe oublié ?", style: TextStyle(color: Color(0xFF715D00), fontSize: 12)),
                              ),
                            ],
                          ),
                          _InputCard(
                            child: TextField(
                              controller: _password,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: '••••••••',
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.mainShell),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD400),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              ),
                              child: const Text("Se connecter", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            ),
                          ),

                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  "OU CONTINUER AVEC",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF5E5E5E)),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SocialCircleButton(
                                color: const Color(0xFFEA4335),
                                icon: FontAwesomeIcons.google,
                                onTap: () {},
                              ),
                              const SizedBox(width: 20),
                              _SocialCircleButton(
                                color: const Color(0xFF1877F2),
                                icon: FontAwesomeIcons.facebookF,
                                onTap: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Pas encore de compte ?", style: TextStyle(fontSize: 14, color: Color(0xFF5E5E5E))),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                                child: const Text("S'inscrire", style: TextStyle(color: Color(0xFF715D00), fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text("Propulsé par IBIHUB BRIDGE", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final Widget child;
  const _InputCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: child,
    );
  }
}

class _PhoneInputCard extends StatelessWidget {
  final _Country country;
  final VoidCallback onCountryPressed;
  final TextEditingController controller;

  const _PhoneInputCard({
    required this.country,
    required this.onCountryPressed,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _InputCard(
      child: Row(
        children: [
          InkWell(
            onTap: onCountryPressed,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text('${country.flag} ${country.dialCode}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Numéro de téléphone',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialCircleButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialCircleButton({required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: FaIcon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _LoginMethodToggle extends StatelessWidget {
  final bool usePhone;
  final ValueChanged<bool> onChanged;

  const _LoginMethodToggle({required this.usePhone, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleButton(
            label: 'Email',
            isActive: !usePhone,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToggleButton(
            label: 'Téléphone',
            isActive: usePhone,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.black : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isActive ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

Future<_Country?> _pickCountry(BuildContext context, _Country current) {
  final countries = <_Country>[
    _Country.ci(),
    const _Country(name: 'France', flag: '🇫🇷', dialCode: '+33'),
    const _Country(name: 'Sénégal', flag: '🇸🇳', dialCode: '+221'),
    const _Country(name: 'Cameroun', flag: '🇨🇲', dialCode: '+237'),
    const _Country(name: 'Mali', flag: '🇲🇱', dialCode: '+223'),
  ];

  return showModalBottomSheet<_Country>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Choisir un pays', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 10),
                ...countries.map((c) {
                  final selected = c.dialCode == current.dialCode;
                  return ListTile(
                    leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text(c.dialCode, style: const TextStyle(color: Colors.grey)),
                    trailing: selected ? const Icon(Icons.check, color: Colors.black) : null,
                    onTap: () => Navigator.pop(context, c),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _Country {
  final String name;
  final String flag;
  final String dialCode;

  const _Country({required this.name, required this.flag, required this.dialCode});

  factory _Country.ci() => const _Country(name: "Côte d’Ivoire", flag: '🇨🇮', dialCode: '+225');
}