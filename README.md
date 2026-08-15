# 🏢 ShiftTrack — LA BONEDJIMA

<div align="center">

![ShiftTrack Banner](assets/images/official_logo.jpg)

### **Système Intelligent de Gestion des Pointages & Présence en Temps Réel**
*Intégration directe et sécurisée avec le serveur biométrique ZKBioTime 9.0.3*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![ZKBioTime](https://img.shields.io/badge/ZKBioTime-9.0.3%20Live-10B981?style=for-the-badge&logo=biometrics&logoColor=white)](http://105.96.0.211:8080)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-2563EB?style=for-the-badge)](#)
[![License](https://img.shields.io/badge/License-Proprietary-64748B?style=for-the-badge)](#)

</div>

---

## 🌟 Présentation Générale (Overview)

**ShiftTrack (LA BONEDJIMA)** est une application moderne et ultra-fluide conçue pour le suivi en temps réel des pointages biométriques (visage / empreinte), l'analyse détaillée des présences, la gestion des plannings et l'extraction de fiches de présence et paie au format PDF professionnel.

L'application communique directement avec l'infrastructure **ZKBioTime 9.0.3** via une passerelle sécurisée en mode **100% lecture seule (Safe Read-Only)**, garantissant une intégrité totale des données d'entreprise.

---

## ✨ Fonctionnalités Principales (Core Features)

### ⏱️ 1. Suivi des Pointages en Temps Réel (Live Biometrics)
- Synchronisation instantanée des entrées et sorties via les terminaux biométriques (Visage / Empreinte).
- Détection et calcul automatique des retards, départs anticipés, anomalies et heures supplémentaires.
- Calendrier interactif dynamique avec pastilles de statut (Présent, Retard, Repos / Week-end, Anomalie).

### 📄 2. Extraction & Rapports PDF Professionnels
- Génération instantanée de fiches de présence mensuelles et personnalisées.
- Mise en page exécutif aux normes de l'entreprise **LA BONEDJIMA**.
- Export haute résolution prêt pour impression ou transmission aux Ressources Humaines.

### 🔐 3. Connexion Sécurisée & Session Persistante (Auto-Login)
- Connexion rapide et simplifiée par **Matricule Employé**.
- Sauvegarde intelligente de session via stockage local sécurisé (**Hive Engine**) : l'application reste connectée sans déconnexion intempestive.
- Bouton de **Déconnexion (`Déconnexion`)** sécurisé avec fenêtre de confirmation pour basculer facilement d'un compte à un autre.

### 🎨 4. Design & Ergonomie de Classe Entreprise
- Interface moderne avec micro-animations, glassmorphisme et thème sombre/clair adaptatif.
- Logo officiel de l'entreprise **LA BONEDJIMA** intégré nativement sur toutes les vues (Accueil, Pointages, Paramètres).
- Prise en charge multi-plateforme : **Web, Windows Desktop, Android & iOS**.

---

## 🏗️ Architecture & Technologies

| Composant | Technologie | Description |
| :--- | :--- | :--- |
| **Frontend Framework** | **Flutter 3.x (Dart)** | Architecture réactive, CanvasKit & Web Renderers |
| **State Management** | **Provider 6.x** | Gestion d'état fluide et réactive (`AttendanceProvider`, `AppProvider`) |
| **Base de Données Locale** | **Hive Storage** | Cache hors-ligne ultra-rapide pour la persistance des sessions |
| **Service Biométrique** | **ZKBioTime API / REST Proxy** | Passerelle Node.js / Express sécurisée pour ZKBioTime 9.0.3 |
| **Génération PDF** | **pdf & printing package** | Moteur de rendu vectoriel pour documents PDF certifiés |

---

## 🚀 Installation & Démarrage Rapide

### Prérequis
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.22 ou supérieure)
- [Node.js](https://nodejs.org/) (version 18+)
- Navigateur moderne (Chrome, Edge)

### 1. Cloner le Répertoire
```bash
git clone https://github.com/billelemperor5/ShiftTrack.labonedjma.git
cd ShiftTrack.labonedjma
```

### 2. Installer les Dépendances Flutter
```bash
flutter pub get
```

### 3. Lancer l'Application (Web / Desktop)
```bash
# Pour lancer la version Web
flutter run -d web-server --web-port=8081

# Pour lancer la version Windows Desktop
flutter run -d windows
```

Accédez ensuite à l'application sur : **`http://localhost:8081`**

---

## 📱 Structure du Projet

```text
lib/
├── core/                  # Thèmes, design tokens et styles globaux
├── models/                # Modèles de données (Attendance, UserProfile, Payroll)
├── providers/             # State Management (AttendanceProvider, AppProvider...)
├── screens/
│   ├── attendance/        # Calendrier mensuel et détails des pointages
│   ├── auth/              # Écran de connexion ZKBioTime
│   ├── home/              # Menu principal & tableau de bord
│   └── settings/          # Paramètres, profil et déconnexion
├── services/              # ZKBioTime API, calcul des heures, PDF generator
└── utils/                 # Helpers (Images officielles, Storage, etc.)
```

---

## 👨‍💻 Développeur & Contact

- **Développeur :** Billel Bouraba
- **Entreprise :** LA BONEDJIMA
- **Email :** [billel.dadi123@gmail.com](mailto:billel.dadi123@gmail.com)
- **GitHub :** [@billelemperor5](https://github.com/billelemperor5)

---

<div align="center">
  <sub>Développé avec ❤️ pour <b>LA BONEDJIMA</b> • Tous droits réservés © 2026</sub>
</div>
