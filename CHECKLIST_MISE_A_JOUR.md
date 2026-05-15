# 📋 CHECKLIST DE MISE À JOUR - PROJET FONAQO

**Date**: $(date +%Y-%m-%d)  
**Statut**: ✅ Nettoyage et mise à jour effectués

---

## 🧹 1. NETTOYAGE EFFECTUÉ

### Fichiers supprimés (6 fichiers vides/obsolètes)
- ✅ `/workspace/lib/features/agent/widgets/profile_info_tile.dart` (vide)
- ✅ `/workspace/lib/features/agent/widgets/agent_section_title.dart` (vide)
- ✅ `/workspace/lib/features/auth/role_selection_screen.dart` (vide - switch Client/Agent supprimé)
- ✅ `/workspace/lib/features/auth/widgets/social_buttons.dart` (vide)
- ✅ `/workspace/lib/features/auth/auth_fake_service.dart` (vide - fake service inutile)
- ✅ `/workspace/lib/screens/main_wrapper.dart` (vide - doublon)
- ✅ `/workspace/lib/features/agent/screens/agent_wallet_screen_backup.dart` (backup)
- ✅ `/workspace/lib/features/client/missions/mission_detail_screen_backup.dart` (backup)

### Dossiers nettoyés
- ✅ Suppression du dossier `/workspace/lib/screens/` (vide et inutilisé)

---

## ✅ 2. ÉTAT ACTUEL DU CODEBASE

### Architecture générale
- **Pattern**: Provider State Management + Repository Pattern
- **Structure**: Clean Architecture simplifiée (Features / Core / Shared)
- **Total fichiers Dart**: 120 fichiers (après nettoyage)

### Repositories implémentés
| Repository | Chemin | Statut | Lignes |
|------------|--------|--------|--------|
| `AgentRepository` | `lib/features/agent/repository/` | ✅ Actif | ~501 lignes |
| `MissionRepository` | `lib/features/client/missions/` | ✅ Actif | ~270 lignes |

### Providers actifs
| Provider | Rôle | Statut |
|----------|------|--------|
| `AuthProvider` | Gestion authentification, tokens JWT, user profile | ✅ Connecté API |
| `MissionProvider` | Liste et suivi des missions | ✅ Utilise MissionRepository |
| `WalletProvider` | Gestion portefeuille, transactions | ⚠️ À vérifier |
| `AgentProvider` | État spécifique agent (dashboard, stats) | ⚠️ À vérifier |

### Services HTTP & API
| Service | Description | Statut |
|---------|-------------|--------|
| `BaseClient` (Dio) | Client HTTP centralisé avec intercepteurs | ✅ Complet |
| `ApiConfig` | Configuration URLs (dev/prod/local) | ✅ Configurable |
| Intercepteurs | Auth token, logging, retry, gestion 401 | ✅ Implémentés |

### Gestion d'erreurs
- ✅ `ApiException` avec types d'erreurs sémantiques
- ✅ Messages user-friendly en français
- ✅ Gestion automatique refresh token JWT
- ✅ Déconnexion automatique sur 401 réel

---

## 🔍 3. POINTS CRITIQUES IDENTIFIÉS

### ⚠️ Incohérences détectées

#### A. Système de mode Agent/Client
**Problème**: Le contexte mentionne la suppression totale du switch Client/Agent, MAIS:
- `AuthProvider` contient toujours `_isAgentMode` (ligne 31)
- Méthode `toggleAppMode()` existe toujours (ligne 584)
- `MainRouter` référence encore le basculement (lignes 20-27)

**Recommandation**: 
```dart
// À SUPPRIMER dans auth_provider.dart:
- Ligne 31: bool _isAgentMode = false;
- Ligne 44: bool get isAgentMode => _isAgentMode;
- Lignes 584-645: Future<bool> toggleAppMode() {...}
- Lignes 647-650: void setAppMode(bool isAgentMode) {...}
- Lignes 603-625: Vérifications dans toggleAppMode
```

**Correction recommandée**: Le rôle doit être déterminé UNIQUEMENT par `user.role` depuis le backend.

#### B. Routing incohérent
**Problème**: 
- `AppRoutes.agentMainShell` défini mais jamais utilisé
- `AgentMainShell` existe mais est commenté dans `MainRouter`
- `MainWrapper` semble être uniquement pour les clients

**Recommandation**:
```dart
// Dans main_router.dart, remplacer par:
if (!authProvider.isAuthenticated) {
  return const LoginScreen(); // ou MainWrapper qui gère login
}

// Redirection basée sur le rôle utilisateur
if (authProvider.isAgent) {
  return const AgentMainShell(); // Shell dédié agent
} else {
  return const MainWrapper(); // Shell dédié client
}
```

#### C. Wallet non implémenté dans AgentMainShell
**Problème**: Dans `agent_main_shell.dart` ligne 22:
```dart
const Center(child: Text('Wallet - En cours de développement')),
```

**Action requise**: Remplacer par `AgentWalletScreen` qui existe déjà.

---

## 📦 4. DÉPENDANCES À VÉRIFIER

### Dans pubspec.yaml
```yaml
# ✅ Dépendances critiques présentes:
- dio: ^5.8.0+1              # HTTP client
- provider: ^6.1.5           # State management
- flutter_secure_storage     # Tokens JWT
- web_socket_channel         # WebSocket pour chat/GPS
- firebase_messaging         # Notifications push
- google_sign_in             # Auth Google

# ⚠️ À vérifier si utilisés:
- flutter_map: ^7.0.2        # Cartes (alternative Google Maps?)
- google_maps_flutter: ^2.12.3 # Les deux sont-ils nécessaires?
- record, audioplayers       # Messages vocaux - testés?
- pdf, printing              # Export PDF - fonctionnel?
```

---

## 🔌 5. CONNECTEURS BACKEND À TESTER

### Endpoints Django (à valider avec `dev-innocent`)

| Endpoint | Méthode | Repository | Statut |
|----------|---------|------------|--------|
| `accounts/login/` | POST | AuthProvider | ✅ Testé |
| `accounts/register/` | POST | AuthProvider | ⚠️ À tester |
| `accounts/token/refresh/` | POST | BaseClient | ✅ Auto-géré |
| `agent/balance/` | GET | AgentRepository | ⚠️ À tester |
| `agent/missions/available/` | GET | AgentRepository | ⚠️ À tester |
| `agent/missions/{id}/accept/` | POST | AgentRepository | ⚠️ À tester |
| `missions/` | GET/POST | MissionRepository | ⚠️ À tester |

### Configuration API actuelle
```dart
// api_config.dart
static const String baseUrl = 'http://192.168.1.73:8000/api/v1/';
// ⚠️ À modifier pour prod: https://api.fonaqo.com/api/v1/
```

---

## 🛠️ 6. ACTIONS REQUISES PAR PRIORITÉ

### 🔴 Priorité 1 (Critique)
1. **Supprimer le système de bascule Agent/Client** dans `AuthProvider`
2. **Implémenter le routing basé sur le rôle** dans `MainRouter`
3. **Connecter AgentWalletScreen** dans `AgentMainShell`
4. **Tester la connexion réelle** au backend Django

### 🟡 Priorité 2 (Important)
5. **Vérifier WalletProvider** - Est-il connecté à l'API?
6. **Vérifier AgentProvider** - Quelles données gère-t-il?
7. **Unifier la gestion GPS** entre `LocationService` et repositories
8. **Tester upload de preuves** (multipart/form-data)

### 🟢 Priorité 3 (Secondaire)
9. **Nettoyer les imports inutilisés** (linting)
10. **Ajouter des tests unitaires** pour les repositories
11. **Documenter les endpoints API** manquants
12. **Configurer les flavors** Dev/Prod/Staging

---

## 📝 7. TODOs DANS LE CODE

Fichiers contenant des TODO/FIXME (20 fichiers identifiés):
- `user_model.dart`: Validation rôle par défaut
- `auth_provider.dart`: Vérification localisation (commentée)
- `notification_service.dart`: Intégration complète Firebase
- `chat_service.dart`: WebSocket vs polling
- `feedback_service.dart`: Améliorations UX
- `agent_repository.dart`: Upload preuves photos
- `agent_boost_screen.dart`: Intégration paiement
- `agent_chat_screen.dart`: Messages vocaux
- `agent_mission_detail_screen.dart`: Timeline temps réel
- `agent_wallet_screen.dart`: Retraits bancaires
- Et 10 autres fichiers...

**Recommandation**: Créer des tickets GitHub/Linear pour chaque TODO critique.

---

## 🎯 8. RECOMMANDATIONS GLOBALES

### Architecture
✅ **Points forts**:
- Séparation claire UI/Business logic
- Repositories bien structurés
- Gestion d'erreurs centralisée
- Intercepteurs HTTP complets

⚠️ **Points à améliorer**:
- Cohérence du routing (Client vs Agent)
- Documentation des endpoints API
- Tests unitaires absents
- Gestion des états de chargement

### Code Quality
```bash
# Commands à exécuter régulièrement:
flutter analyze          # Static analysis
flutter test             # Tests unitaires
flutter pub run build_runner build --delete-conflicting-outputs  # Si codegen
```

### Sécurité
✅ Tokens JWT stockés dans flutter_secure_storage  
✅ Refresh token automatique  
✅ Déconnexion sur 401  
⚠️ **À ajouter**: Certificate pinning en production  

---

## 📊 9. MÉTRIQUES DU PROJET

| Métrique | Valeur |
|----------|--------|
| Fichiers Dart totaux | 120 |
| Fichiers supprimés (cette session) | 8 |
| Lignes de code estimées | ~15,000 |
| Repositories API | 2 |
| Providers | 4 |
| Screens (écrans) | ~30 |
| Services | ~10 |
| Widgets personnalisés | ~20 |

---

## ✅ 10. VALIDATION FINALE

### Checklist de validation avant déploiement
- [ ] Backend Django accessible et répond aux endpoints
- [ ] Tokens JWT fonctionnels (login → refresh → logout)
- [ ] Routing Agent/Client basé sur le rôle uniquement
- [ ] Plus aucune référence au "switch" Client/Agent
- [ ] Upload de preuves photo fonctionnel
- [ ] Notifications push Firebase opérationnelles
- [ ] Géolocalisation active pour les missions
- [ ] Chat en temps réel (WebSocket ou polling)
- [ ] Thèmes Light/Dark persistants
- [ ] Gestion d'erreurs user-friendly partout

---

**Prochaine étape recommandée**: 
1. Commencer par supprimer le système de bascule (`toggleAppMode`)
2. Implémenter le routing basé sur `user.role`
3. Tester end-to-end avec le backend Django

**Contact**: Consulter le dépôt `dev-innocent` pour la documentation complète des endpoints API.

---

*Généré automatiquement après analyse du codebase FONAQO*
