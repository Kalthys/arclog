PLAN.md - Projet ARCLOG ⚡
1. Vision du Projet
Arclog est un carnet de bord pour jeux vidéo (Gaming Journal) orienté Offline-First. L'application permet aux joueurs de suivre leur progression, de documenter leurs sessions et de créer leurs propres objectifs/succès personnalisés.
Esthétique : "Electric Cyberpunk" (Noir profond, Cyan néon, Jaune électrique, effets de lueurs et lignes de circuits imprimés).

2. Architecture Technique & Dossiers
L'application utilisera une architecture Clean Architecture découpée par couches pour garantir la maintenance et la scalabilité.
Structure des dossiers (Folder Tree)
lib/
├── core/                # Logique partagée, thèmes, constantes
│   ├── theme/           # Définition des couleurs (Neon), fonts et ombres
│   ├── utils/           # Helpers (formatage date, temps de jeu)
│   └── constants/       # Assets (icons, images)
├── data/                # Couche de données (Offline-first)
│   ├── database/        # Configuration SQLite (Drift) ou Hive
│   ├── repositories/    # Implémentations des accès aux données
│   └── sources/         # Sources locales (Local Data Sources)
├── domain/              # Logique métier (Entités & Use Cases)
│   ├── entities/        # Modèles de données (Game, Session, Achievement, Objective, GameStatus)
│   └── repositories/    # Interfaces des repositories
└── presentation/        # Interface Utilisateur (UI)
    ├── widgets/         # Composants réutilisables (NeonCard, ElectricLine, GameStatusBadge)
    ├── pages/           # Écrans principaux (Dashboard, Library, Detail)
    ├── state/           # Gestion d'état (Riverpod)
    └── animations/      # Shaders ou animations de circuits électriques

3. Charte Graphique (UI/UX)
Directives prioritaires pour Claude Code :

Palette : 
Fond : #050A0E (Deep Black/Navy).
Primaire : #00FBFF (Cyan Glow).
Secondaire : #FFD700 (Electric Yellow).
Lignes de circuit : #1A2C38 (Bleu sombre discret).
Succès/Terminé : #39FF14 (Neon Green).
Erreur/Abandonné : #FF2D55 (Neon Red).


Composants clés :
Electric Timeline : Une ligne verticale centrale imitant un éclair ou un circuit imprimé reliant les événements.
Glow Cards : Les cartes de jeux doivent avoir une bordure en dégradé néon avec un léger box-shadow diffus (effet glow).
Energy Progress Bars : Les barres de progression doivent ressembler à des jauges d'énergie futuristes.
Game Status Badge : Tag néon coloré indiquant le statut du jeu (BACKLOG → gris, PLAYING → cyan, COMPLETED → vert, MASTERED → jaune, DROPPED → rouge).
Platform Badge : Tag sobre (fond sombre, texte gris) indiquant la plateforme du jeu.


4. Spécifications Fonctionnelles (Roadmap)
Phase 1 : Cœur du Système (Hors-ligne)

 Setup de la base de données locale (Stockage des jeux et sessions).
 Système CRUD pour ajouter un jeu manuellement (Titre, Image, Temps de jeu, Statut, Plateforme).
 Logique de calcul du temps de jeu total.

Phase 2 : Interface Dashboard & Timeline

 Création du composant Timeline Électrique (Vue chronologique des sessions).
 Affichage "EN CE MOMENT" avec les cartes néon (Glow Cards avec statut + plateforme).
 Widget de statistiques "Gamer Stats" (Nom joueur, jeux, temps joué, quêtes).

Phase 3 : Objectifs & Succès Personnalisés

 Module Objectifs (quêtes personnelles) avec suivi de quantité.
 Module Trophées (succès officiels, préparé pour l'API Steam).
 Système de paliers de progression visuels (NEWCOMER → LEGEND).
 Système de favoris (swipe droite) sur objectifs et trophées.

Phase 4 : Enrichissement du modèle Game

 Statut du jeu (GameStatus) : BACKLOG, PLAYING, COMPLETED, MASTERED, DROPPED.
 Plateforme (Platform) : champ libre (PC, PS5, Switch, Xbox, Mobile…).
 Tags visuels néon sur les Glow Cards du carousel.

Phase 5 : Intégration API Steam (à venir)

 Récupération automatique des achievements officiels via l'API Steam.
 Import de la bibliothèque Steam dans Arclog.


5. Directives de Codage pour Claude Code

Priorité Offline : Toutes les données doivent être persistées localement. Aucune API externe n'est requise pour le MVP.
Performance UI : Utiliser des widgets optimisés pour les effets de flou (Blur) et les gradients afin de ne pas ralentir l'app.
Typographie : Utiliser une police géométrique et futuriste (ex: Michroma, Orbitron ou une police Sans-Serif moderne).
Modèles de données : Chaque Game doit avoir : Sessions, Achievements (trophées officiels), Objectives (quêtes personnelles), GameStatus, Platform.
Séparation domaine/présentation : Les entités du domaine sont en Dart pur. Les couleurs et icônes liées au statut vivent dans la couche présentation.


6. Prochaines Étapes Immédiates

Initialiser le projet avec la structure de dossiers définie au point 2.
Configurer le thème sombre ArclogTheme avec les couleurs néon.
Créer le modèle de données Game et la base de données locale.
