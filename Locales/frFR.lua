if GetLocale() ~= "frFR" then return end
local addonName, SplitW = ...
local L = SplitW.L

-- Pages / tabs
L["Setup"]    = "Réglages"
L["Players"]  = "Joueurs"
L["Composition"] = "Composition"
L["Preview"]  = "Aperçu"
L["About"]    = "À propos"
L["Enable test mode"]  = "Activer le mode test"
L["Disable test mode"] = "Désactiver le mode test"
L["not installed"] = "non installé"
L["Item Level (inspect)"] = "Niveau d'objet (inspect)"
L["Details!/Recount/Skada read live DPS+HPS from those addons when loaded. Item Level inspects each raid member (28y range). Manual uses the per-player sliders on the Weights tab."] =
    "Details!/Recount/Skada lisent DPS et HPS en direct depuis ces addons quand ils sont chargés. Niveau d'objet inspecte chaque membre du raid (portée 28y). Manuel utilise les sliders par joueur de l'onglet Joueurs."
L["Scan raid ilvl"] = "Scanner l'ilvl du raid"
L["Inspect every raid member to fetch their average item level. Each inspect is ~1.5s and limited to a 28-yard range. Active only when the Item Level source is selected."] =
    "Inspecte chaque membre du raid pour récupérer son niveau d'objet moyen. Chaque inspect prend ~1.5s et est limité à 28 yards de portée. Actif seulement quand la source Niveau d'objet est sélectionnée."

-- General
L["General"] = "Général"
L["Show minimap icon"] = "Afficher l'icône minimap"
L["Toggle the minimap launcher button"] = "Active/désactive le bouton lanceur sur la minimap"
L["Confirm before applying"] = "Confirmer avant d'appliquer"
L["Show a popup before mass-moving raid members"] = "Affiche une fenêtre de confirmation avant de déplacer tout le raid"
L["Print summary on apply"] = "Afficher le résumé après application"
L["Print a one-line summary to chat after a successful apply"] = "Affiche un résumé d'une ligne dans le chat après une application réussie"
L["Auto-refresh after combat"] = "Auto-refresh après combat"
L["Recompute weights from the DPS source every time combat ends"] = "Recalcule les poids depuis la source DPS à chaque fin de combat"

L["DPS source"] = "Source DPS"
L["Manual (per-player slider)"] = "Manuel (slider par joueur)"
L["Built-in (combat log)"] = "Intégré (combat log)"
L["Pick the data source for DPS / HPS"] = "Choisir la source des poids DPS / HPS"
L["Built-in parses the WoW combat log natively (no addon needed). Details!/Recount/Skada read from those addons when loaded. Manual uses the Weights tab sliders."] =
    "Intégré : parse le combat log WoW nativement (aucun addon requis). Details!/Recount/Skada : lit depuis ces addons quand ils sont chargés. Manuel : utilise les sliders de l'onglet Poids."
L["Active source"] = "Source active"

L["Permission status"] = "Statut des permissions"
L["You can apply splits (leader or assistant in a raid)."] = "Tu peux appliquer un split (chef ou assistant en raid)."
L["not in a raid"] = "Tu n'es pas en raid."
L["leader or assistant required"] = "Tu dois être chef de raid ou assistant pour appliquer un split."
L["test mode active — apply is disabled"] = "Mode test actif — l'application est désactivée."

-- Weights page
L["Manual weights"] = "Poids manuels"
L["Adjust each DPS player's relative weight (1-100). Higher = goes into the lower-scoring team first. Used only when source = Manual."] =
    "Règle le poids relatif de chaque joueur (1-100). Plus élevé = part dans l'équipe la moins chargée en priorité. Utilisé uniquement quand la source = Manuel."
L["Composition rules applied AFTER the score-based snake distribution. Each toggle swaps minimally-disruptive DPS pairs to satisfy the rule."] =
    "Règles de composition appliquées APRÈS la distribution snake basée sur le score. Chaque toggle swap les paires de DPS les plus proches en score pour satisfaire la règle."
L["Drag to resize the options window. Saved account-wide."] =
    "Glisse pour redimensionner la fenêtre. Sauvegardé pour tout le compte."
L["Reset all weights"] = "Réinitialiser tous les poids"
L["Reset every stored weight back to the default value."] = "Remet tous les poids enregistrés à la valeur par défaut."
L["Refresh roster"] = "Rafraîchir le roster"
L["Re-read the raid roster from Blizzard's API."] = "Relit le roster du raid depuis l'API Blizzard."
L["Toggle test mode"] = "Activer le mode test"
L["Use a simulated 20-man roster for UI testing."] = "Utilise un faux roster de 20 joueurs pour tester l'UI."
L["No raid members detected. Use /splitw test for a simulated 20-man roster."] =
    "Aucun membre de raid détecté. Tape /splitw test pour simuler un raid à 20."

-- Preview page
L["Preview the split"] = "Aperçu du split"
L["Compute split"] = "Calculer le split"
L["Read the current roster and run the snake-distribution algorithm."] =
    "Lit le roster actuel et applique l'algorithme de distribution en serpent."
L["Apply split"] = "Appliquer le split"
L["Move every player to their assigned subgroup. Requires leader or assistant."] =
    "Déplace chaque joueur dans son sous-groupe assigné. Nécessite chef ou assistant."
L["Before"] = "Avant"
L["After"]  = "Après"
L["Current raid distribution"] = "Distribution actuelle du raid"
L["Proposed split"] = "Split proposé"
L["Team A"] = "Équipe A"
L["Team B"] = "Équipe B"
L["No split computed yet — click 'Compute split'."] = "Aucun split calculé — clique sur 'Calculer le split'."
L["(empty)"] = "(vide)"
L["Looks good — no warnings."] = "Tout est bon — aucun avertissement."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tOnly one tank — both teams share the same tank? Check your roster."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tUn seul tank — les deux équipes partagent le même tank ? Vérifie ton roster."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tNo tank detected in the raid."] = "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tAucun tank détecté dans le raid."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tTeam A is too large for any reasonable raid size."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tÉquipe A trop grande pour une taille de raid raisonnable."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tTeam B is too large for any reasonable raid size."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tÉquipe B trop grande pour une taille de raid raisonnable."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tTeams differ by more than 1 player — score is balanced by giving the weakest DPS to the larger team."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tLes équipes diffèrent de plus de 1 joueur — le score est équilibré en mettant le DPS le plus faible dans l'équipe la plus grande."
L["Apply the proposed split? This will move raid members."] =
    "Appliquer le split proposé ? Cela va déplacer les membres du raid."

-- Apply
L["nothing to do — split already matches"] = "Rien à faire — le raid est déjà arrangé."
L["combat detected — resuming after combat ends"] = "Combat détecté — reprise à la fin du combat."
L["combat ended — resuming apply"] = "Combat terminé — reprise de l'application."
L["lost lead/assist — apply aborted"] = "Tu as perdu le chef/assist — application annulée."
L["split applied"] = "Split appliqué."
L["applying split — %d moves queued"] = "Application du split — %d déplacements en file."

-- About / Changelog
L["About SplitWatch"] = "À propos de SplitWatch"
L["Auto-split a 10-40 man raid into 2 balanced teams (tanks, healers by HPS, DPS by damage) for split-mechanic encounters."] =
    "Sépare automatiquement un raid de 10 à 40 en 2 équipes équilibrées (tanks, heals selon HPS, DPS selon dégâts) pour les fights à mécaniques split."
L["Author"] = "Auteur"
L["Slash command"] = "Commande"
L["alias"] = "alias"
L["Sister addons"] = "Addons jumeaux"
L["Slash commands"] = "Commandes /slash"
L["Reset window position"] = "Réinitialiser la position de la fenêtre"
L["Reset the options window to its default center position."] = "Remet la fenêtre d'options au centre de l'écran."
L["Changelog"] = "Historique"
L["• 0 required addons — SplitWatch works standalone. Details!/Recount/Skada are optional for live DPS/HPS readings, otherwise Manual sliders are used."] =
    "• 0 addon requis — SplitWatch fonctionne tout seul. Details!/Recount/Skada sont optionnels pour lire DPS/HPS en live, sinon les sliders Manuels sont utilisés."
L["• Sister addon to BossWatch + TankWatch — shares the side-tab navigation, gold accent UI, and family colour palette."] =
    "• Addon jumeau de BossWatch + TankWatch — partage la navigation par side-tabs, l'UI à accent doré, et la palette de couleurs de la famille."
L["• Initial release: snake-distribution algorithm, preview pane with before/after stats, permission-gated Apply via SetRaidSubgroup."] =
    "• Version initiale : algorithme de distribution en serpent, aperçu avec stats avant/après, application protégée via SetRaidSubgroup."

-- v0.2.0 changelog entries
L["• 0 required addons — Details!/Recount/Skada remain optional integrations alongside the new Item Level (inspect) source and the per-player Manual sliders."] =
    "• 0 addon requis — Details!/Recount/Skada restent des intégrations optionnelles aux côtés de la nouvelle source Niveau d'objet (inspect) et des sliders Manuels."
L["• Sister addon to BossWatch + TankWatch — shares the side-tab navigation and the family UI."] =
    "• Addon jumeau de BossWatch + TankWatch — partage la navigation par side-tabs et l'UI de la famille."
L["• New section 'Constraints' on Setup — Raid Leader can toggle Battle Rez per team (ON by default), Bloodlust per team (ON by default), Balance melee vs ranged, Mass Dispel per team, Decurse per team."] =
    "• Nouvelle section 'Contraintes' sur Réglages — le RL peut activer Battle Rez par équipe (ON par défaut), Bloodlust par équipe (ON par défaut), équilibrer melee vs distance, Mass Dispel par équipe, Décurse par équipe."
L["• Constraint resolver runs AFTER the score-based snake so swaps stay minimal — picks the DPS pair closest in score, preserves role boundaries."] =
    "• Le résolveur de contraintes tourne APRÈS la distribution en serpent — il swap la paire de DPS la plus proche en score pour minimiser l'impact, en préservant les rôles."
L["• Team size rebalance: 2T / 1H / 17DPS no longer ends 11/9 — the weakest DPS migrates until |#A - #B| ≤ 1."] =
    "• Rebalance de taille d'équipe : 2T / 1H / 17DPS ne finit plus en 11/9 — le DPS le plus faible migre jusqu'à un écart ≤ 1."
L["• Source used for the split is now displayed on the Preview tab, no round-trip to Setup needed."] =
    "• La source utilisée pour le calcul est affichée sur l'onglet Aperçu — plus besoin de zapper sur Réglages."
L["• Each team-list line shows ilvl or DPS as a grey suffix next to the name."] =
    "• Chaque ligne d'équipe affiche l'ilvl ou le DPS en suffixe gris à côté du nom."
L["• Team titles include the player count: 'Équipe A (5)'."] =
    "• Les titres d'équipe incluent le compteur : 'Équipe A (5)'."
L["• Escape closes the panel (UISpecialFrames registration)."] =
    "• Échap ferme le panneau (intégration UISpecialFrames)."

-- v0.3.0 changelog
L["• 0 required addons — Details!/Recount/Skada/Item Level/Manual all still optional / built-in."] =
    "• 0 addon requis — Details!/Recount/Skada/Niveau d'objet/Manuel restent optionnels / intégrés."
L["• Sister addon to BossWatch + TankWatch."] =
    "• Addon jumeau de BossWatch + TankWatch."
L["• Manual locks: right-click a player in the Preview team columns to pin them on Team A / Team B / free. Lock icon shows next to pinned names. Active locks listed on the Composition tab with one-click Free buttons + Clear all."] =
    "• Verrouillages manuels : clic droit sur un joueur dans les colonnes Aperçu pour le verrouiller sur Équipe A / Équipe B / libérer. Icône cadenas affichée à côté des noms verrouillés. Liste des verrouillages actifs sur l'onglet Composition avec boutons Libérer + Tout déverrouiller."
L["• Broadcast on Apply: opt-in to auto-post the team rosters to chat (RAID / RAID_WARNING / PARTY / SAY) after a successful Apply."] =
    "• Annonce sur Apply : option pour poster automatiquement la composition (Team A + Team B) dans un canal de chat (RAID / RAID_WARNING / PARTY / SAY) après un Apply réussi."
L["• Named presets: save the current constraints + locks + DPS source under a name; reload before a specific fight. UI section with editbox / Save / Load / Delete + scrollable list."] =
    "• Presets nommés : sauvegarde les contraintes + verrouillages + source DPS sous un nom ; recharge avant un fight. Section UI avec champ texte / Sauvegarder / Charger / Supprimer + liste scrollable."
L["• Spec detection via inspect — captured alongside ilvl, refines melee/ranged classification for Druid / Shaman / Hunter / Monk / Paladin hybrid specs (accurate range instead of class-default)."] =
    "• Détection de spec via inspect — capturé en même temps que l'ilvl, affine la classification melee/distance pour les classes hybrides Druide / Chaman / Hunter / Moine / Paladin (vrai range au lieu du défaut par classe)."
L["• Fixed Battle Rez class list: only Druid / DK / Warlock actually have an in-combat resurrection. Hunter / Paladin / DH removed (false positive)."] =
    "• Fix liste Battle Rez : seuls Druide / DK / Démoniste ont une résurrection en combat. Hunter / Paladin / DH retirés (faux positif)."
L["• Fixed Decurse class list: Monk Detox doesn't remove curses; only Mage / Druid / Shaman do."] =
    "• Fix liste Decurse : Detox du Moine ne retire pas les malédictions ; seuls Mage / Druide / Chaman peuvent."
L["• Per-player tooltip on team-column rows showing class, role, DPS, HPS, manual weight, lock status."] =
    "• Infobulle par joueur sur les lignes des colonnes équipe affichant classe, rôle, DPS, HPS, poids manuel, statut de verrouillage."
L["• Composition tab rename (was 'Joueurs') — covers both Constraints and Manual weights more accurately."] =
    "• Renommage onglet 'Composition' (était 'Joueurs') — couvre mieux Contraintes + Poids manuels."
L["• Two new constraints: External CD healer per team (Pala/Priest/Druid/Monk filtered to HEALER role), Soak immunity per team (Pala/Mage/Hunter)."] =
    "• Deux nouvelles contraintes : CD externe heal par équipe (Pala/Prêtre/Druide/Moine filtrés au rôle HEALER), Immunité soak par équipe (Pala/Mage/Hunter)."
L["• Drag-and-drop swap on Preview team rows: left-click a name, then left-click any player on the OTHER team to swap them. Both auto-locked so the swap persists."] =
    "• Drag-and-drop dans Aperçu : clic gauche sur un nom puis clic gauche sur un joueur de l'AUTRE équipe pour les échanger. Les deux sont auto-verrouillés pour que l'échange persiste."
L["• Movement indicator on Preview rows: orange arrow next to players whose team changed since the last Apply — spot recompute churn at a glance."] =
    "• Indicateur de mouvement dans Aperçu : flèche orange à côté des joueurs qui ont changé d'équipe depuis le dernier Apply — détecte le churn d'un coup d'œil."
L["• Built-in preset library: 'Restore built-ins' button on Réglages → Presets loads ready-to-use configs for Spirit Kings, Lei Shen, Council of Elders, Conclave of Wind."] =
    "• Bibliothèque de presets pré-packagée : bouton 'Restaurer les presets' sur Réglages → Presets charge des configs prêtes pour Spirit Kings, Lei Shen, Council of Elders, Conclave of Wind."
L["• Roster-change banner: GROUP_ROSTER_UPDATE fired → yellow banner on Aperçu with inline Recompute button. RL decides when to commit a new split — no auto-recompute."] =
    "• Bannière changement de roster : déclenchée par GROUP_ROSTER_UPDATE → bannière jaune sur Aperçu avec bouton Recalculer inline. Le RL décide quand committer un nouveau split — pas de recompute auto."
L["• Confirmation popups on destructive actions: Clear all locks, Reset all weights, Delete preset. Avoids accidental data loss."] =
    "• Popups de confirmation sur les actions destructrices : Tout déverrouiller, Réinitialiser les poids, Supprimer un preset. Évite les pertes de données accidentelles."

-- Roster-change banner
L["Roster changed since last compute."] = "Le roster a changé depuis le dernier calcul."
L["Recompute"] = "Recalculer"
L["Re-run the split with the updated roster."] = "Relance le split avec le roster actuel."

-- Built-in presets
L["Restore built-ins"] = "Restaurer les presets"
L["Load the bundled split-fight presets (Spirit Kings, Lei Shen, Council, Conclave). Existing presets with the same name will be overwritten."] =
    "Charge les presets pré-packagés (Spirit Kings, Lei Shen, Council, Conclave). Les presets existants du même nom seront écrasés."
L["Load the built-in split-fight presets? Existing presets with the same name will be overwritten."] =
    "Charger les presets pré-packagés ? Les presets existants du même nom seront écrasés."
L["restored %d built-in presets"] = "%d presets pré-packagés restaurés"

-- Destructive confirmations
L["Remove every player lock?"] = "Retirer tous les verrouillages joueur ?"
L["Reset every stored weight back to the default? This can't be undone."] =
    "Réinitialiser tous les poids stockés à la valeur par défaut ? Action irréversible."
L["Delete the preset '%s'?"] = "Supprimer le preset '%s' ?"
L["• Damage meter sources: Details!, Recount, Skada, Manual — unavailable ones grey out in the dropdown."] =
    "• Sources de damage meter : Details!, Recount, Skada, Manuel — celles non installées sont grisées dans le dropdown."
L["• Healers balanced by HPS (live read from the active source), DPS by damage."] =
    "• Heals équilibrés selon le HPS (lecture live depuis la source active), DPS selon les dégâts."
L["• Supports raids from 10 to 40 members — subgroups assigned dynamically."] =
    "• Compatible raids de 10 à 40 — les sous-groupes sont assignés dynamiquement."
L["• Collapsible sections with per-section reset, persisted across reloads."] =
    "• Sections repliables avec reset par section, persisté entre les /reload."
L["• Initial release: manual weight mode, snake-distribution algorithm, preview pane with before/after stats, permission-gated Apply via SetRaidSubgroup."] =
    "• Version initiale : mode poids manuel, algorithme de distribution en serpent, aperçu avec stats avant/après, application protégée via SetRaidSubgroup."
L["• Supports retail 12.x and MoP Classic 5.5."] = "• Compatible retail 12.x et MoP Classic 5.5."
L["• Test mode (/splitw test) for UI preview without a raid."] =
    "• Mode test (/splitw test) pour prévisualiser l'UI sans raid."

-- Sister-addon side tabs
L["SplitWatch — Options"] = "SplitWatch — Options"
L["Open BossWatch options"] = "Ouvrir les options BossWatch"
L["Open TankWatch options"] = "Ouvrir les options TankWatch"

-- Blizzard settings page
L["Auto-split your 20-man raid — v%s\nClick the button below to open the SplitWatch options panel."] =
    "Sépare automatiquement ton raid 20 — v%s\nClique sur le bouton ci-dessous pour ouvrir le panneau SplitWatch."
L["Open SplitWatch options"] = "Ouvrir les options SplitWatch"
L["Open the floating SplitWatch options panel."] = "Ouvre le panneau d'options flottant de SplitWatch."
L["You can also use the slash command: /splitw"] = "Tu peux aussi utiliser la commande : /splitw"

-- Minimap
L["left-click: options"] = "clic gauche : options"
L["right-click: apply current split"] = "clic droit : appliquer le split actuel"

-- Slash help
L["commands:"] = "commandes :"
L["open options"] = "ouvrir les options"
L["compute and show split preview"] = "calculer et afficher l'aperçu du split"
L["apply the current split via SetRaidSubgroup"] = "appliquer le split actuel via SetRaidSubgroup"
L["toggle simulated 20-man roster"] = "activer/désactiver le faux roster 20"
L["reset all settings + reload"] = "tout réinitialiser + recharger l'UI"
L["pin a player to a team"] = "verrouille un joueur sur une équipe"
L["manage saved presets"] = "gérer les presets sauvegardés"
L["preset saved: %s"] = "preset sauvegardé : %s"
L["preset loaded: %s"] = "preset chargé : %s"
L["preset deleted: %s"] = "preset supprimé : %s"
L["preset not found"] = "preset introuvable"
L["no presets saved"] = "aucun preset sauvegardé"
L["presets:"] = "presets :"
L["usage: /splitw preset save|load|delete <name> | list"] =
    "usage : /splitw preset save|load|delete <nom> | list"
L["locked %s → %s"] = "%s verrouillé sur l'équipe %s"
L["unlocked %s"] = "%s déverrouillé"
L["all locks cleared"] = "tous les verrouillages effacés"
L["usage: /splitw lock <name> A|B|free  |  /splitw lock clear"] =
    "usage : /splitw lock <nom> A|B|free  |  /splitw lock clear"

-- Broadcast UI
L["Broadcast team composition on Apply"] = "Annoncer la composition à l'Apply"
L["Post the team rosters to chat when a split is applied."] =
    "Poste la composition des équipes dans le chat quand un split est appliqué."
L["Broadcast channel"] = "Canal d'annonce"
L["Where to post the team-rosters message when Broadcast is enabled."] =
    "Où poster le message de composition quand l'annonce est activée."
L["Auto-rebalance after manual swap"] = "Recalculer auto après swap manuel"
L["When OFF (default), a 2-click manual swap on Aperçu only moves those two players. When ON, the algorithm recomputes the entire split with the swapped pair locked, redistributing everyone else."] =
    "Quand DÉSACTIVÉ (défaut), un swap manuel à 2 clics sur Aperçu ne déplace que ces deux joueurs. Quand ACTIVÉ, l'algo recalcule tout le split avec la paire échangée verrouillée, redistribuant tout le monde."
L["Raid chat"]    = "Canal raid"
L["Raid warning"] = "Avertissement raid"
L["Party chat"]   = "Canal groupe"
L["Say"]          = "Dire"

-- Presets UI
L["Presets"] = "Presets"
L["Save the current constraints + locks + DPS source under a name. Reload any preset before a specific fight."] =
    "Sauvegarde les contraintes + verrouillages + source DPS actuels sous un nom. Recharge n'importe quel preset avant un fight."
L["Save preset"] = "Sauvegarder le preset"
L["Save the current configuration under the name in the box."] = "Sauvegarde la configuration actuelle sous le nom saisi."
L["Load"] = "Charger"
L["Delete"] = "Supprimer"
L["No presets yet — save the current config to start."] = "Aucun preset encore — sauvegarde la config actuelle pour commencer."

-- Active locks UI
L["Active locks"] = "Verrouillages actifs"
L["Players pinned to a specific team. Right-click a name in the Preview team columns to add a lock; use the buttons below to remove one."] =
    "Joueurs verrouillés sur une équipe précise. Clic droit sur un nom dans les colonnes Aperçu pour ajouter ; bouton ci-dessous pour retirer."
L["Clear all locks"] = "Tout déverrouiller"
L["Remove every player lock."] = "Retire tous les verrouillages."
L["Free"] = "Libérer"
L["No active locks."] = "Aucun verrouillage actif."

-- Team-row right-click + tooltip
L["Lock to Team A"] = "Verrouiller sur Équipe A"
L["Lock to Team B"] = "Verrouiller sur Équipe B"
L["Free lock"] = "Libérer le verrouillage"
L["Class"] = "Classe"
L["Role"] = "Rôle"
L["Manual weight"] = "Poids manuel"
L["Locked on Team %s"] = "Verrouillé sur l'Équipe %s"
L["Right-click for lock options"] = "Clic droit pour les options de verrouillage"
L["Left-click + click another team's player to swap"] = "Clic gauche + clic sur un joueur de l'autre équipe pour échanger"
L["Left-click to select, then left-click an opposing-team player to swap"] =
    "Clic gauche pour sélectionner, puis clic gauche sur un joueur de l'autre équipe pour échanger"

-- New constraints (v0.3.1)
L["Decurse per team (Mage/Druid/Shaman)"] = "Décurse par équipe (Mage/Druide/Chaman)"
L["External CD healer per team (Paladin/Priest/Druid/Monk healer)"] =
    "CD externe heal par équipe (Paladin/Prêtre/Druide/Moine heal)"
L["Enforce at least one healer with a tank-targetable defensive (BoP, Pain Sup, Ironbark, Life Cocoon) per team."] =
    "Force au moins un heal avec un CD externe ciblable (BoP, Sup. douleur, Écorce de fer, Cocon vital) par équipe."
L["Soak immunity per team (Paladin/Mage/Hunter)"] =
    "Immunité soak par équipe (Paladin/Mage/Hunter)"
L["Enforce at least one full damage-immunity class (Divine Shield / Ice Block / Aspect of the Turtle) per team."] =
    "Force au moins une classe avec immunité complète (Bouclier divin / Bloc de glace / Aspect de la tortue) par équipe."

-- Constraint warnings (v0.3.1)
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tNo healer with an external defensive in the raid — constraint cannot be satisfied."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tAucun heal avec un CD externe dans le raid — contrainte non satisfaite."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tCouldn't swap to satisfy external CDs (no compatible healer pair)."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tSwap impossible pour les CD externes (pas de paire de heals compatible)."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tNo immunity class (Paladin / Mage / Hunter) in the raid — constraint cannot be satisfied."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tAucune classe avec immunité (Paladin / Mage / Hunter) dans le raid — contrainte non satisfaite."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tCouldn't swap to satisfy soak immunity."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tSwap impossible pour l'immunité soak."
L["test mode on (20 simulated members)"] = "mode test activé (20 membres simulés)"
L["test mode off"] = "mode test désactivé"

-- Misc
L["|cffffd100SplitWatch|r v%s loaded — type |cffffff00/splitw|r for options"] =
    "|cffffd100SplitWatch|r v%s chargé — tape |cffffff00/splitw|r pour les options"
L["WARN_CLASSIC"] = "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tVersion Classic — UI pas encore testée à fond en raid, merci de signaler les bugs."
L["Panel"] = "Panneau"
L["Panel opacity"] = "Opacité du panneau"
L["Opacity of this options window. Saved account-wide."] = "Opacité de cette fenêtre. Sauvegardée pour tout le compte."
L["Test mode ON (20 simulated)"] = "Mode test ACTIF (20 simulés)"
L["Test mode ON (%d simulated)"] = "Mode test ACTIF (%d simulés)"
L["Test roster size"] = "Taille du raid test"
L["Number of simulated players when test mode is on. Tank/healer/DPS ratios scale automatically (e.g. 10-man → 2T+2H+6DPS, 25-man → 2T+5H+18DPS, 40-man → 3T+9H+28DPS)."] =
    "Nombre de joueurs simulés en mode test. Les ratios tank/heal/DPS s'adaptent automatiquement (ex: 10 → 2T+2H+6DPS, 25 → 2T+5H+18DPS, 40 → 3T+9H+28DPS)."
L["No raid detected — enable test mode to preview"] = "Pas de raid détecté — active le mode test pour visualiser"
L["Live roster (%d members)"] = "Raid réel (%d membres)"
L["Source used for the split:"] = "Source utilisée pour le calcul :"

-- Constraints
L["Constraints"] = "Contraintes"
L["Battle Rez per team (Druid/DK/Warlock/Hunter/Paladin/DH)"] =
    "Battle Rez par équipe (Druide/DK/Démo/Hunter/Paladin/Démoniste Hunter)"
L["Enforce at least one battle-rez class per team."] = "Force au moins une classe avec Battle Rez par équipe."
L["Bloodlust per team (Shaman/Mage/Hunter/Evoker)"] =
    "Bloodlust par équipe (Chaman/Mage/Hunter/Evoker)"
L["Enforce at least one Bloodlust/Heroism/Time Warp/Primal Rage source per team."] =
    "Force au moins une source de Bloodlust / Héroïsme / Hâte temporelle / Rage primitive par équipe."
L["Balance melee vs ranged"] = "Équilibrer melee vs distance"
L["Equalise the melee/ranged DPS ratio between teams. Class-based heuristic (Druid/Shaman/Hunter default to ranged)."] =
    "Équilibre le ratio melee/distance entre les équipes. Heuristique par classe (Druide/Chaman/Hunter par défaut en distance)."
L["Mass Dispel per team (Priest)"] = "Mass Dispel par équipe (Prêtre)"
L["Enforce at least one Priest per team for Mass Dispel."] = "Force au moins un Prêtre par équipe pour Mass Dispel."
L["Decurse per team (Mage/Druid/Shaman/Monk)"] = "Décurse par équipe (Mage/Druide/Chaman/Moine)"
L["Enforce at least one decurse class per team."] = "Force au moins une classe pouvant décurse par équipe."

-- Constraint warnings
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tNo Battle Rez class in the raid — constraint cannot be satisfied."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tAucune classe avec Battle Rez dans le raid — contrainte non satisfaite."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tNo Bloodlust giver in the raid — constraint cannot be satisfied."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tAucun donneur de Bloodlust dans le raid — contrainte non satisfaite."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tNo Priest in the raid — Mass Dispel constraint cannot be satisfied."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tAucun Prêtre dans le raid — contrainte Mass Dispel non satisfaite."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tNo decurse class in the raid — constraint cannot be satisfied."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tAucune classe décurse dans le raid — contrainte non satisfaite."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tCouldn't swap to satisfy Battle Rez (no compatible role pair)."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tSwap impossible pour satisfaire Battle Rez (pas de paire de rôle compatible)."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tCouldn't swap to satisfy Bloodlust (no compatible role pair)."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tSwap impossible pour satisfaire Bloodlust (pas de paire de rôle compatible)."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tCouldn't swap to satisfy Mass Dispel."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tSwap impossible pour satisfaire Mass Dispel."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tCouldn't swap to satisfy Decurse."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tSwap impossible pour satisfaire Décurse."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tCouldn't fully balance melee/ranged ratio."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tImpossible d'équilibrer totalement le ratio melee/distance."
L["Source preview"] = "Aperçu de la source"
L["Live values read from the selected source for the current (or test) roster."] =
    "Valeurs lues en direct depuis la source sélectionnée, pour le roster actuel (ou test)."
L["Live values read from the selected source — use this to confirm your damage meter is feeding data before you compute a split."] =
    "Valeurs lues en direct depuis la source sélectionnée — utilise-le pour confirmer que ton damage meter remonte bien des données avant de calculer un split."
L["No roster — enable test mode or join a raid."] = "Pas de roster — active le mode test ou rejoins un raid."
L["No data — join a raid, enable test mode, or fight something so the active source has actors to show."] =
    "Pas de données — rejoins un raid, active le mode test, ou tape sur quelque chose pour que la source active ait des acteurs à afficher."
L["Details!/Recount/Skada read live DPS+HPS from those addons when loaded. Manual uses the per-player sliders on the Weights tab."] =
    "Details!/Recount/Skada lisent DPS et HPS en direct depuis ces addons quand ils sont chargés. Manuel utilise les sliders par joueur de l'onglet Poids."
L["Click to collapse/expand this section."] = "Clic pour réduire/déplier cette section."
L["Reset this section to default values."] = "Réinitialise cette section aux valeurs par défaut."

-- v0.3.1
L["• Internal refactor of the options panel: the ~2070-line Panel.lua is split into 6 files (Widgets.lua + a slimmer Panel.lua + 4 tab files under Options/Pages/). Mirrors the BossWatch / TankWatch convention. Zero user-visible change."] =
    "• Refactor interne du panneau d'options : l'ancien Panel.lua (~2070 lignes) est découpé en 6 fichiers (Widgets.lua + un Panel.lua allégé + 4 fichiers d'onglet sous Options/Pages/). Calqué sur la convention BossWatch / TankWatch. Zéro changement visible côté utilisateur."

-- About / Links
L["Links"] = "Liens"
L["GitHub repository:"] = "Dépôt GitHub :"
L["Report an issue:"] = "Signaler un bug :"
L["CurseForge:"] = "CurseForge :"
L["Wago:"] = "Wago :"
L["Discord (support / bugs / suggestions):"] = "Discord (support / bugs / suggestions) :"
L["Click to select, then Ctrl+C to copy."] = "Clic pour sélectionner, puis Ctrl+C pour copier."

-- v0.3.2
L["• New \"Links\" section on the About tab — clickable GitHub / Issues / CurseForge / Wago / Discord URL fields. Same convention as BossWatch / TankWatch."] =
    "• Nouvelle section « Liens » sur l'onglet À propos — champs URL cliquables GitHub / Bugs / CurseForge / Wago / Discord. Même convention que BossWatch / TankWatch."
L["• Discord support server now has a dedicated SplitWatch category (#sw-changelog, #sw-bugs, #sw-support, #sw-suggestions). Same BWTW guild as BossWatch / TankWatch."] =
    "• Le serveur Discord d'entraide a maintenant une catégorie SplitWatch dédiée (#sw-changelog, #sw-bugs, #sw-support, #sw-suggestions). Même guild BWTW que BossWatch / TankWatch."
L["• 0 required addons. Sister addons: BossWatch, TankWatch."] =
    "• 0 addon requis. Addons frères : BossWatch, TankWatch."

-- v0.3.3
L["• Fix: Apply was failing with \"group is full\" when a target subgroup already contained an off-split player. BuildPlan now pre-fills each subgroup's counter with current occupancy (non-team members keep their slot)."] =
    "• Fix : Appliquer échouait avec « Votre groupe est complet » quand un sous-groupe cible contenait déjà un joueur hors-split. BuildPlan pré-remplit maintenant le compteur de chaque sous-groupe avec la population actuelle (les non-membres de l'équipe gardent leur slot)."
L["• Apply minimises moves: players whose current subgroup is already in their team's target groups stay put rather than being shuffled around."] =
    "• Apply minimise les déplacements : les joueurs dont le sous-groupe actuel fait déjà partie des groupes cibles de leur équipe restent en place plutôt que d'être déplacés inutilement."

-- v0.3.4
L["• Fix: Details! source preview was empty when the current combat had no actors yet. The reader now probes multiple combat segments and uses the first one with data."] =
    "• Fix : l'aperçu de la source Details! était vide quand le combat courant n'avait pas encore d'acteurs. Le lecteur sonde maintenant plusieurs segments et garde le premier avec des données."
L["• Fix: cross-realm player names (Name-Realm) now match correctly against meters that store them as short names — both forms are tried."] =
    "• Fix : les noms de joueurs cross-realm (Nom-Royaume) sont maintenant matchés correctement avec les damage meters qui les stockent sous forme courte — les deux variantes sont testées."
L["• New /splitw dps debug command — dumps which actors the active source returns and matches them against the roster."] =
    "• Nouvelle commande /splitw dps debug — dump les acteurs renvoyés par la source active et les rapproche du roster."
