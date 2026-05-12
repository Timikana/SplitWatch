# Changelog

Toutes les versions notables de **SplitWatch** sont listées ici.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
versionnage selon [SemVer](https://semver.org/lang/fr/).

## [Unreleased]

## [0.2.0] - 2026-05-12

### Ajouté
- **Contraintes d'équilibrage** (nouvelle section sur Réglages) — passe de résolution appliquée **après** la distribution snake. Chaque contrainte vérifie une condition sur les équipes et swap le DPS le plus proche en score si elle n'est pas satisfaite :
  - **☑ Battle Rez par équipe** (Druide / DK / Démoniste / Hunter / Paladin / DH) — *ON par défaut*
  - **☑ Bloodlust par équipe** (Chaman / Mage / Hunter / Evoker) — *ON par défaut*
  - **☐ Équilibrer melee vs distance** — heuristique par classe (Druide / Chaman / Hunter par défaut en distance)
  - **☐ Mass Dispel par équipe** (Prêtre)
  - **☐ Décurse par équipe** (Mage / Druide / Chaman / Moine)
- **Avertissements** ajoutés dans l'aperçu si une contrainte ne peut pas être satisfaite (aucune classe matching dans le raid, ou pas de paire de rôle swappable).
- **Niveau d'objet (inspect)** comme 5ème source de poids — utilise l'API Blizzard `NotifyInspect` / `C_PaperDollInfo.GetInspectItemLevel`, aucun addon tiers requis. File d'inspect throttlée à 1.5s / requête, portée 28y, cache TTL 90s. Bouton **Scanner l'ilvl du raid** sur l'onglet Réglages, désactivé quand la source ILVL n'est pas sélectionnée.
- **Source utilisée pour le calcul** affichée sur l'onglet Aperçu (sous le statut roster) — plus besoin de zapper sur Réglages pour vérifier.
- **Ilvl visible** à côté du nom de chaque joueur dans les colonnes Team A/B (`[ilvl 432]`), ou DPS k-formatté pour les autres sources (`[245.6k]`).
- **Compteur par équipe** dans les titres : `Équipe A (5)` `Équipe B (5)`.
- **Échap ferme le panneau** via `UISpecialFrames` (oubli porté depuis le squelette BossWatch).

### Corrigé
- **Tailles d'équipe inégales >1 joueur** : la distribution par rôle indépendante pouvait produire 11/9 pour un 20-man avec compositions impaires (2T / 1H / 17DPS). Ajout d'une passe de rebalance qui déplace le DPS le plus faible de la team plus grande vers la plus petite jusqu'à un écart ≤ 1.
- **Chaîne de refresh cassée** depuis le wrap ScrollFrame — `pages[id]:refresh()` appelait la SF au lieu de son contenu, donc les callbacks (`_syncIlvlBtn`, refresh source, etc.) ne firaient pas après changement de source.
- **Récupération auto si la fenêtre est hors écran.** Si tu déplaces le panneau sur un grand moniteur puis relances WoW sur un plus petit (ou en fenêtré réduit), la position sauvegardée est validée contre les dimensions actuelles de `UIParent`. Si `|x|` ou `|y|` dépasse la largeur/hauteur de l'écran, le panneau est ramené au centre et la position sauvegardée est nettoyée. Idem pour le handoff entre addons jumeaux (`ShowOptionsAt`).

## [0.1.0] - 2026-05-11

### Ajouté
- **0 addon requis** — SplitWatch fonctionne en standalone. Details! / Recount / Skada sont des intégrations **optionnelles** : quand l'un est chargé, l'algorithme lit DPS et HPS en direct depuis lui ; sinon, les sliders Manuels de l'onglet **Joueurs** sont utilisés.
- **Addon jumeau** de [BossWatch](https://github.com/Timikana/BossWatch) + TankWatch — partage la navigation par side-tabs sur le bord gauche, l'UI à accent doré (`#FFD100`), `PortraitFrameTemplate` et la palette de couleurs de la famille.
- **Algorithme de distribution en serpent** — les tanks alternent A/B, les heals se distribuent en serpent par HPS, les DPS en serpent par dégâts. Pour un raid impair (ex: 11), le joueur le plus faible va dans l'équipe la plus grande pour équilibrer le score.
- **Compatible raids 10 à 40 membres** — les sous-groupes cibles sont assignés dynamiquement :
  - 10 → groupe 1 vs groupe 2
  - 11-20 → 1+2 vs 3+4
  - 21-30 → 1+2+3 vs 4+5+6
  - 31-40 → 1+2+3+4 vs 5+6+7+8
- **Sources de damage meter** : Details!, Recount, Skada, Manuel — les sources non installées sont automatiquement **grisées et désactivées** dans le dropdown pour éviter les faux choix.
- **Aperçu live de la source** dans l'onglet Réglages — liste les membres du roster (ou tous les acteurs trackés par la source quand solo) avec leurs valeurs DPS et HPS en direct. Auto-refresh toutes les 1.5s.
- **Aperçu avant / après** dans l'onglet Aperçu — stats par équipe (compte de tanks, heals, DPS + scores DPS et HPS), séparateur vertical entre les deux équipes, listes nominatives avec icône de rôle et couleur de classe.
- **Apply protégé par permission** — bouton grisé hors raid ou si tu n'es pas chef/assistant. La file de `SetRaidSubgroup` est différée jusqu'à `PLAYER_REGEN_ENABLED` quand tu es en combat (correction pour le combat-lockdown 4.0.1).
- **Mode test** (`/splitw test`) — simule un roster 20 joueurs (2 tanks, 4 heals, 14 DPS) pour prévisualiser l'UI sans raid.
- **Panneau d'options** avec :
  - 4 onglets : Réglages, Joueurs, Aperçu, À propos
  - Sections **repliables** par section (chevron à droite du titre) avec **reset** par section (icône refresh), état persisté entre les /reload
  - **Side tabs cross-addon** vers BossWatch et TankWatch quand chargés — clic conserve la position de la fenêtre
  - **Scrollbar** sur chaque onglet pour gérer le contenu long
  - **Opacité du panneau** ajustable (slider account-wide dans À propos)
  - Bouton **réinitialiser la position de la fenêtre**
- **Icône minimap** via LibDBIcon — clic gauche ouvre les options, clic droit applique le split actuel.
- **Multi-toc** : un seul zip installe sur **Retail 12.x** ET **MoP Classic 5.5**.
- **Slash commands** : `/splitw`, `/splitw preview`, `/splitw apply`, `/splitw test`, `/splitw reset` (+ alias `/splitwatch`).
- **Locale frFR** complète à parité avec enUS (deDE / esES / itIT / ptBR en placeholder).

### Notes techniques
- Le tracker built-in (parseur combat log natif) est désactivé : Blizzard 12.0 émet `ADDON_ACTION_FORBIDDEN` sur `RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")` pour notre frame dans certains contextes de chargement, malgré le fait que Details! / Recount / Skada y arrivent sans souci. Le code est en place mais ne s'enregistre pas tant que la cause exacte n'est pas identifiée. Les 4 autres sources couvrent largement le besoin.
