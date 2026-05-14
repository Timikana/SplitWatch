# Changelog

Toutes les versions notables de **SplitWatch** sont listées ici.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
versionnage selon [SemVer](https://semver.org/lang/fr/).

## [Unreleased]

## [0.3.2] - 2026-05-14

### Ajouté
- **Section "Liens" sur l'onglet À propos** — 5 champs cliquables (sélection + Ctrl+C pour copier) alignés sur la convention des addons frères BossWatch / TankWatch :
  - **Dépôt GitHub** — `https://github.com/Timikana/SplitWatch`
  - **Signaler un bug** — `https://github.com/Timikana/SplitWatch/issues`
  - **CurseForge** — `https://www.curseforge.com/wow/addons/splitwatch`
  - **Wago** — `https://addons.wago.io/addons/splitwatch`
  - **Discord (support / bugs / suggestions)** — invitation vers le serveur communautaire partagé BWTW (catégorie 🧩 SPLITWATCH avec forums dédiés `#sw-bugs`, `#sw-support`, `#sw-suggestions` + salon `#sw-changelog`)
- Section repliable + reset par section comme les autres blocs de À propos.

### Outils dev
- `scripts/_post_discord.py <version>` — poste le bloc CHANGELOG d'une version donnée vers le webhook `#sw-changelog` (couleur dorée `#FFD100` pour les stables, orange pour les beta). Couplage 1:1 avec BossWatch / TankWatch — utile manuellement après chaque tag.
- `scripts/extract_changelog.sh <version>` — extrait un bloc `## [X.Y.Z]` de `CHANGELOG.md`, utilisable pour `git tag -a vX.Y.Z -F -` ou la commande Discord ci-dessus.

- **0 addons requis**. Sister addons : BossWatch, TankWatch.

## [0.3.1] - 2026-05-14

### Changements internes
- **Refactor du panneau d'options** — l'ancien `Options/Panel.lua` monolithique (~2070 lignes) est découpé en 6 fichiers, calqué sur la convention des addons frères BossWatch / TankWatch :
  - `Options/Widgets.lua` — fabriques de widgets partagées (addTooltip, markAsNew, makeCheck/Slider/Dropdown/Button/Label) + petits helpers (classColor, fmtNum, roleIcon)
  - `Options/Panel.lua` — système de sections, harnais `build()`, side tabs, slash, API publique (~607 lignes)
  - `Options/Pages/Setup.lua` — onglet Réglages
  - `Options/Pages/Composition.lua` — onglet Composition (Contraintes + Verrouillages + Poids manuels)
  - `Options/Pages/Preview.lua` — onglet Aperçu + les `StaticPopupDialogs` associés au workflow Apply
  - `Options/Pages/About.lua` — onglet À propos + Changelog intégré
- Aucun changement visible côté utilisateur — l'UI, les fonctionnalités et la base SavedVariables sont identiques. Le découpage rend chaque onglet éditable en isolation et facilite l'ajout futur de nouveaux onglets (créer `Options/Pages/<Nom>.lua`, l'enregistrer dans les deux TOCs).
- **0 addons requis** — Details! / Recount / Skada restent optionnels, les sources Item Level (inspect) + Manuel restent les défauts sans dépendance. Sister addons : BossWatch, TankWatch.

## [0.3.0] - 2026-05-12

### Ajouté
- **Verrouillages manuels** — épingle un joueur sur une équipe spécifique avant le calcul. L'algo place les verrouillés en premier puis snake-distribue les autres en respectant les locks à toutes les passes (rebalance, contraintes, melee/ranged). **Clic droit** sur un nom dans les colonnes Aperçu ouvre un menu Lock A / Lock B / Free. Icône cadenas affichée à côté des noms verrouillés. Section **"Verrouillages actifs"** sur Composition avec boutons Libérer + Tout déverrouiller. Commandes : `/splitw lock <nom> A|B|free`, `/splitw lock clear`.
- **Annonce sur Apply** — option pour poster automatiquement la composition (Team A + Team B) dans un canal de chat après un Apply réussi. Canaux : `RAID`, `RAID_WARNING` (auto-fallback sur RAID si pas chef/assistant), `PARTY`, `SAY`. Toggle + dropdown sur Réglages → Général.
- **Presets nommés** — sauvegarde/charge des configurations complètes (contraintes + locks + source DPS). UI sur Réglages avec champ texte + bouton Sauvegarder, liste scrollable des presets avec boutons Charger / Supprimer par ligne. Commandes : `/splitw preset save|load|delete <nom>`, `/splitw preset list`.
- **Détection de spec via inspect** — capturé en même temps que l'ilvl (zero coût additionnel), affine la classification melee/distance pour les classes hybrides (Druide / Chaman / Hunter / Moine / Paladin). Cache 90s, fallback sur class-default quand le spec n'est pas encore inspecté.
- **Infobulle par joueur** sur les lignes des colonnes équipe — hover affiche classe, rôle, DPS, HPS, poids manuel, statut de verrouillage.
- **Onglet "Composition"** (renommé depuis "Joueurs") — reflète mieux le contenu : Contraintes + Verrouillages + Poids manuels.

- **Deux nouvelles contraintes** :
  - **CD externe heal par équipe** (Paladin / Prêtre / Druide / Moine **filtré au rôle HEALER** uniquement) — assure qu'au moins un soigneur avec un CD externe ciblable (BoP, Suppression de la douleur, Écorce de fer, Cocon vital) est dans chaque équipe pour mitiger les pics de dégâts tank.
  - **Immunité soak par équipe** (Paladin / Mage / Hunter) — au moins une classe avec immunité complète aux dégâts (Bouclier divin / Bloc de glace / Aspect de la tortue) par équipe pour les mécaniques de soak.
- **Drag-and-drop dans Aperçu** — clic gauche sur un nom dans une colonne équipe, puis clic gauche sur n'importe quel joueur de l'AUTRE équipe pour les échanger. Les deux sont auto-verrouillés pour que l'échange persiste à travers les recompute.
- **Indicateur de mouvement** — flèche orange à côté des joueurs dont l'équipe a changé depuis le dernier Apply réussi. `lastAppliedSplit` tracké dans `SplitWatchDB` et comparé à chaque rendu.
- **Bibliothèque de presets pré-packagée** — bouton **"Restaurer les presets"** sur Réglages → Presets charge des configs prêtes pour 4 fights de split connus : *Spirit Kings (MoP)*, *Lei Shen (MoP)*, *Council of Elders (MoP)*, *Conclave of Wind*. Chaque preset configure les contraintes selon la mécanique du fight (Mass Dispel + Decurse pour Spirit Kings, Soak immunités pour Lei Shen, etc.). RL peut éditer / supprimer comme tout autre preset.
- **Bannière changement de roster** — l'event `GROUP_ROSTER_UPDATE` (quelqu'un join/leave) déclenche une bannière jaune sur Aperçu avec un bouton inline **"Recalculer"**. Le RL décide quand committer un nouveau split — pas d'auto-recompute, mais visibilité immédiate du roster stale.
- **Popups de confirmation** sur les actions destructrices : *Tout déverrouiller*, *Réinitialiser tous les poids*, *Supprimer un preset*. Évite les pertes de données accidentelles via `StaticPopup_Show`.

### Corrigé
- **Liste Battle Rez** — seuls Druide / DK / Démoniste ont une résurrection en combat. Hunter / Paladin / DH retirés du tag BR (faux positif qui faisait croire à l'algo qu'il avait une BR alors que non).
- **Liste Decurse** — Detox du Moine ne retire pas les malédictions (Magie + Maladie seulement). Monk retiré du tag Decurse ; seuls Mage / Druide / Chaman peuvent décurse.

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
