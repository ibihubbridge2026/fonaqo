
![alt text](favicon.png)
# Fonaqo — Service de Conciergerie Moderne

**Fonaqo** est une application mobile développée avec Flutter qui connecte des utilisateurs (**Requesters**) à des agents (**Waiters**) afin de réaliser des missions du quotidien : banque, administration, courses, files d’attente, livraisons et bien plus encore.

Pensée pour offrir une expérience fluide, rapide et moderne, Fonaqo simplifie la gestion des tâches quotidiennes grâce à une interface intuitive et des fonctionnalités temps réel.

---

# Fonctionnalités Principales

## Dashboard Dynamique
Visualisation instantanée des missions en cours, des statistiques et des suggestions de services.

## Slider Interactif
Mise en avant des services premium, nouveautés et promotions via un carrousel moderne et fluide.

## Système de Chat Temps Réel
Communication directe entre le demandeur et l’agent pour un suivi rapide et efficace.

## Gestion des Missions
Création, suivi, historique et mise à jour des demandes en quelques clics.

## Interface Responsive
Design moderne et optimisé pour Android et iOS avec une expérience utilisateur homogène.

---

# Architecture du Projet

Le projet suit une architecture modulaire afin de faciliter la maintenance, la scalabilité et l’évolution des fonctionnalités.

```plaintext
lib/
├── features/                 # Modules par fonctionnalités
│   ├── auth/                 # Connexion, inscription, choix de rôle
│   ├── home/                 # Dashboard Requester / Waiter
│   ├── chat/                 # Messagerie temps réel
│   ├── onboarding/           # Écrans de bienvenue
│   └── missions/             # Gestion des missions
│
├── screens/                  # Conteneurs globaux
│   └── main_wrapper.dart     # Navigation principale
│
├── widgets/                  # Composants UI réutilisables
│   ├── custom_app_bar.dart
│   └── main_navigation_bar.dart
│
└── main.dart                 # Point d’entrée de l’application
```

---

# Installation & Configuration

## Prérequis

Avant de commencer, assurez-vous d’avoir installé :

- Flutter SDK (dernière version stable)
- Dart SDK
- Android Studio ou Xcode
- Un émulateur Android/iOS ou un appareil physique

---

## Cloner le projet

```bash
git clone https://github.com/votre-utilisateur/fonaqo.git
cd fonaqo
```

---

## Installer les dépendances

```bash
flutter pub get
```

---

## Configuration des Assets

Placez vos images dans le dossier `assets/` puis déclarez-les dans le fichier `pubspec.yaml`.

```yaml
flutter:
  assets:
    - assets/images/
    - assets/images/hero/
    - assets/images/avatar/
```

---

## Lancer l’application

```bash
flutter run
```

---

# Composants UI Personnalisés

## MainWrapper
Le composant principal qui gère la navigation via la Bottom Navigation Bar sans recharger l’ensemble de l’interface.

## CustomAppBar
Barre d’outils dynamique qui adapte son comportement selon le contexte de navigation.

## HeroSlider
Slider automatique et infini intégré au Dashboard pour une expérience immersive.

---

# Tests

Exécuter les tests unitaires et widgets :

```bash
flutter test
```

---

# Déploiement

## Android

```bash
flutter build apk --release
```

## iOS

```bash
flutter build ios --release
```

---

# Contribution

Les contributions sont les bienvenues.

1. Forkez le projet
2. Créez une branche :

```bash
git checkout -b feature/AmazingFeature
```

3. Commitez vos modifications :

```bash
git commit -m 'Add some AmazingFeature'
```

4. Pushez votre branche :

```bash
git push origin feature/AmazingFeature
```

5. Ouvrez une Pull Request

---

# Licence

Ce projet est distribué sous licence MIT.

Consultez le fichier `LICENSE` pour plus d’informations.

---

# Équipe

Développé avec passion par l’équipe **IBIHUB BRIDGE**.
