# Changelog

Toutes les versions notables de **SplitWatch** sont listées ici.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
versionnage selon [SemVer](https://semver.org/lang/fr/).

## [Unreleased]

### Ajouté
- **Niveau d'objet (inspect)** comme 5ème source de poids — utilise l'API Blizzard `NotifyInspect` / `C_PaperDollInfo.GetInspectItemLevel`, aucun addon tiers requis. File d'inspect throttlée à 1.5s / requête, portée 28y, cache TTL 90s. Bouton **Scanner l'ilvl du raid** sur l'onglet Réglages.

### Corrigé
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
